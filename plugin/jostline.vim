let g:mode_map = { 
			\ 'n': 'NORMAL', 
			\ 'i': 'INSERT', 
			\ 'R': 'REPLACE', 
			\ 'v': 'VISUAL', 
			\ 'V': 'VISUAL LINE', 
			\ '^V': 'VISUAL BLOCK', 
			\ 'c': 'COMMAND', 
			\ 'C': 'COMMAND-LINE', 
			\ 's': 'SELECT', 
			\ 'S': 'SELECT LINE', 
			\ 't': 'TERMINAL', 
			\ 'nI': 'NORMAL INSERT', 
			\ 'N': 'INSERT NORMAL', 
			\ 'N:': 'NORMAL EX', 
			\ 'iN': 'INSERT NORMAL', 
			\ 'p': 'PREVIEW', 
			\ 'l': 'LITERAL', 
			\ 'R?': 'REPLACE MODE', 
			\ 'o': 'OPERATOR-PENDING', 
			\ 'O': 'OPERATOR PENDING', 
			\ 'r': 'REPEAT', 
			\ 'a': 'ARGUMENT', 
			\}


let g:statusline_config = {
      \ 'left': {
      \   'section_1': {
      \     'active':   { 'items': ['windowNumber'], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
      \     'inactive': { 'items': ['windowNumber'], 'highlight': {'bg': '#5e4b6e', 'fg': '#222222'} }
      \   },
      \   'section_2': {
      \     'active':   { 'items': ['mode'], 'highlight': {'bg': '#4b2a55', 'fg': '#efd7f6'} },
      \     'inactive': { 'items': [''], 'highlight': {'bg': '#3a2d3f', 'fg': '#a3a3a3'} }
      \   },
      \   'section_3': {
      \     'active':   { 'items': ['fileName'], 'highlight': {'bg': '#333333', 'fg': '#ffffff'} },
      \     'inactive': { 'items': [''], 'highlight': {'bg': '#1f1f1f', 'fg': '#666666'} }
      \   },
      \   'separator': '',
      \ },
      \ 'right': {
      \   'section_1': {
      \     'active':   { 'items': [''], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
      \     'inactive': { 'items': [''], 'highlight': {'bg': '#5e4b6e', 'fg': '#222222'} }
      \   },
      \   'section_2': {
      \     'active':   { 'items': ['fileType'], 'highlight': {'bg': '#4b2a55', 'fg': '#efd7f6'} },
      \     'inactive': { 'items': [''], 'highlight': {'bg': '#3a2d3f', 'fg': '#a3a3a3'} }
      \   },
      \   'section_3': {
      \     'active':   { 'items': ['modified'], 'highlight': {'bg': '#333333', 'fg': '#ffffff'} },
      \     'inactive': { 'items': [''], 'highlight': {'bg': '#1f1f1f', 'fg': '#666666'} }
      \   },
      \   'separator': '',
      \ }
      \}

function! jostline#init() abort
	set statusline=%!jostline#build()
	call s:setDynamicSectionHighlights()
endfunction

function! g:jostline#build()
	let l:configMap = deepcopy(g:statusline_config)
	let l:windowStatus = g:statusline_winid == win_getid()
	
	return s:parseConfig(l:windowStatus,l:configMap)
endfunction

" ************************************************************
" *****************SECTION ITEM GETTERS **********************
" ************************************************************
function! s:getMode() 
	return get(g:mode_map, mode(), 'UNKNOWN MODE')
endfunction

function! s:getFilename() 
	return expand('%:t') ==# '' ? '[No Name]' : expand('%:t') 
endfunction

function! s:getFiletype() 
	return '%{&filetype}'
endfunction

function! s:getWindowNumber() 
	return '%{winnr()}'
endfunction

function! s:getModified() 
	return &modified ? 'Modified [+]' : 'No Changes'
endfunction

function! s:getItemValue(item)
	let l:itemValueMap = {
		\ 'mode':         s:getMode(),
		\ 'fileName':     s:getFilename(),
		\ 'fileType':     s:getFiletype(),
		\ 'windowNumber': s:getWindowNumber(),
		\ 'modified':     s:getModified()
		\ }

	return has_key(l:itemValueMap,a:item) ? ' ' . l:itemValueMap[a:item] . ' ' : ''
endfunction

function! s:parseItems(items)
	return join(filter(map(copy(a:items),'s:getItemValue(v:val)'),'v:val !=""'),'')
endfunction

function! s:getSections(map)
	return filter(copy(a:map), 'v:key =~# "^section_\\d\\+$"')
endfunction

function! s:getSides(map)
	return filter(copy(a:map), 'v:key ==# "left" || v:key ==# "right"')
endfunction

function! s:getStatuses(map)
	return filter(copy(a:map), 'v:key ==# "active" || v:key ==# "inactive"')
endfunction

function! s:parseConfig(windowStatus,configMap)
	try
		let l:slDataMap = s:initStatuslineDataMap()
		let l:windowStatus = a:windowStatus ? 'active' : 'inactive'
		let l:sideMap = s:getSides(a:configMap)

		for [side,side_data] in items(l:sideMap)
			let l:sideParts= []
			let l:separator = get(l:side_data,'separator','')
			let l:sectionMap = s:getSections(side_data)

			for [section,section_data] in items(l:sectionMap)
				let l:secDataMap = s:initSectionDataMap()
				let l:statusMap = s:getStatuses(section_data)
				
				for [status,status_data] in items(l:statusMap)
					if l:windowStatus ==# status
						let l:items = s:parseItems(status_data.items)

						if l:items != ''
							call s:mapAdd(l:secDataMap.items,'highlight',join([section,side,status],'_'))
							call s:mapAdd(l:secDataMap.items,'value',l:items)
							call s:mapAdd(l:secDataMap.separator,'highlight',join([section,side,status,'separator'],'_'))
							call s:mapAdd(l:secDataMap.separator,'value',l:separator)
							call s:mapAdd(l:secDataMap.separator,'value',l:separator)

							call add(l:sideParts,s:buildSectionStr(l:secDataMap,side))
						endif
					endif
				endfor
			endfor

			call s:mapAdd(l:slDataMap,side,join(l:sideParts,''))
		endfor

		return l:slDataMap['left'] . '%=' . l:slDataMap['right']
	catch /.*/
		echohl ErrorMsg
		echom 'Jostline - Error: ' . v:exception . ' At: ' . v:throwpoint
		echohl None
	endtry
endfunction

function! s:mapAdd(map,key,val)
	let a:map[a:key] = a:val
endfunction

function! s:initSectionDataMap()
	let l:dataMap = {}
	let l:dataMap['items'] = {}
	let l:dataMap['separator'] = {}
	return l:dataMap
endfunction

function! s:initStatuslineDataMap()
	let l:dataMap = {}
	let l:dataMap['left'] = ''
	let l:dataMap['right'] = ''
	return l:dataMap
endfunction

function! s:buildHighlightStr(map) 
	let l:data = copy(a:map)
	return join(['%#',l:data.highlight,'#',l:data.value,'%*'],'')
endfunction

function! s:buildSectionStr(buildMap,side) 
  	let l:data = copy(a:buildMap)
	let l:items = s:buildHighlightStr(l:data.items)
	let l:separator = s:buildHighlightStr(l:data.separator)

	return (a:side ==# 'left') ? l:items . l:separator : l:separator . l:items
endfunction

function! s:parseHighlightMap(map,key,default)
	let l:value = get(a:map,a:key,a:default)
	return l:value == '' ? a:default : l:value
endfunction

function! s:executeHighlight(highlight,foreground,background)
	let l:highlight = 'highlight '.a:highlight
	let l:highlightForeground = 'guifg='.a:foreground
	let l:highlightBackground = 'guibg='.a:background
	let l:cmd = join([l:highlight,l:highlightForeground,l:highlightBackground],' ')

	execute l:cmd
endfunction

" hacky first step with separators, need to clean up loops
function! s:setDynamicSectionHighlights()
	let l:configMap = deepcopy(g:statusline_config)
	let l:sideMap = s:getSides(l:configMap)

	for [side, side_data] in items(l:sideMap)
		let l:sectionMap = s:getSections(side_data)
		let l:sectionNames = keys(l:sectionMap)
		call sort(l:sectionNames)

		for l:i in range(0, len(l:sectionNames) - 1)
			let l:currSection = l:sectionNames[l:i]
			let l:nextSection = get(l:sectionNames, l:i + 1, '')

			if l:nextSection != ''
				for l:status in ['active', 'inactive']
					let l:currData = get(sectionMap[currSection], l:status, {})
					let l:nextData = get(sectionMap[nextSection], l:status, {})

					let l:currBG = s:parseHighlightMap(l:currData.highlight, 'bg', '#000000')
					let l:nextFG = s:parseHighlightMap(l:nextData.highlight, 'bg', '#ffffff')
					let l:currFG = s:parseHighlightMap(l:currData.highlight, 'fg', '#ffffff')

					let l:highlight = join([currSection, side, l:status], '_')
					let l:sepHighlight = join([currSection, side, l:status, 'separator'], '_')

					call s:executeHighlight(l:highlight, l:currFG, l:currBG)
					call s:executeHighlight(l:sepHighlight, l:currBG, l:nextFG)
  				endfor
			endif
		endfor
		
    	let l:lastSection = l:sectionNames[-1]
		for l:status in ['active', 'inactive']
			let l:data = get(sectionMap[lastSection], l:status, {})
			let l:bg = s:parseHighlightMap(l:data.highlight, 'bg', '#000000')
			let l:fg = s:parseHighlightMap(l:data.highlight, 'fg', '#ffffff')
			let l:highlight = join([lastSection, side, l:status], '_')
			let l:sepHighlight = join([lastSection, side, l:status, 'separator'], '_')

			call s:executeHighlight(l:highlight, l:fg, l:bg)
			call s:executeHighlight(l:sepHighlight, l:bg, '#1a1a1a')
		endfor
	endfor
endfunction

