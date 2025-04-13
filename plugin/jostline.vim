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
      \     'active':   { 'items': ['someOtherItem'], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
      \     'inactive': { 'items': ['someOtherItem'], 'highlight': {'bg': '#5e4b6e', 'fg': '#222222'} }
      \   },
      \   'section_2': {
      \     'active':   { 'items': ['anotherItem'], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
      \     'inactive': { 'items': ['anotherItem'], 'highlight': {'bg': '#5e4b6e', 'fg': '#222222'} }
      \   },
      \   'section_3': {
      \     'active':   { 'items': ['yetAnotherItem'], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
      \     'inactive': { 'items': ['yetAnotherItem'], 'highlight': {'bg': '#5e4b6e', 'fg': '#222222'} }
      \   },
      \   'separator': '',
      \ }
      \}

function! jostline#set() abort
	set statusline=%!g:jostline#build()
  	call s:setDynamicSectionHighlights()
endfunction

function! g:jostline#build()
	let l:configMap = deepcopy(g:statusline_config)
	let isActive = g:statusline_winid == win_getid()

	return s:parseConfig(isActive,l:configMap)
endfunction

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
	return &modified ? '[+]' : ''
endfunction

function! s:getItemValue(item)
	let l:itemValueMap = {
		\ 'mode':         s:getMode(),
		\ 'fileName':     s:getFilename(),
		\ 'fileType':     s:getFiletype(),
		\ 'windowNumber': s:getWindowNumber(),
		\ 'modified':     s:getModified()
		\ }
	return has_key(l:itemValueMap, a:item) ? l:itemValueMap[a:item] : v:null 
endfunction

function! s:parseItems(items)
	let l:itemValues = filter(map(copy(a:items),'s:getItemValue(v:val)'), 'v:val !=v:null' )
	return empty(l:itemValues) ? v:null : join(l:itemValues, '')
endfunction

function! s:getSections(map)
	return filter(copy(a:map), 'v:key =~# "^section_\\d\\+$"')
endfunction

function! s:parseConfig(isActive,configMap)
	let l:statuslineParts = []
	let l:configMap = a:configMap
	let l:status = a:isActive ? 'active' : 'inactive'

	for side in ['left', 'right']
		let l:separator = get(l:configMap,'separator','')
		let l:groupParts = []

		for section in ['section_1', 'section_2', 'section_3']
			let l:items = s:parseItems(l:configMap[side][section][status].items)
			let l:highlight = join([section,side,status],'_')	
			let l:sectionHighlight = s:buildHighlightStr(l:highlight,l:items) 

			call add(l:groupParts,l:sectionHighlight)
		endfor

		call add(l:statuslineParts,join(l:groupParts,''))
	endfor

	return empty(l:statuslineParts) ? '' : join(l:statuslineParts, '%=')
endfunction

function! s:buildHighlightStr(highlightName,value) 
	return join(['%#',a:highlightName,'#',a:value,'%*'],'')
endfunction

" function! s:appendHighlights(name,items,side,separator,status) 
" 	if a:items == v:null 
" 		return a:items
" 	endif
" 
" 	let l:items = s:appendItemHighlight(a:name,a:items,a:side,a:status)
" 	let l:separator = s:appendSeparatorHighlight(a:name,a:separator,a:side) 
" 
" 	return  a:side == 'LEFT'  ? l:items.l:separator:
" 		   \a:side == 'RIGHT' ? l:separator.l:items:
" 		   \v:null
" endfunction

function! s:appendItemHighlight(name,items,side,status) 
	return '%#'.a:name.'_'.a:side.'_'.a:status.'#'.a:items.'%*'		
endfunction

function! s:appendSeparatorHighlight(name,separator,side) 
	return '%#'.a:name.'_'.a:side.'_separator#'.a:separator.'%*'		
endfunction


function! s:parseHighlightMap(map,key,default)
	let l:value = get(a:map,a:key,a:default)
	return l:value == '' ? a:default : l:value
endfunction

function! s:setDynamicSectionHighlights()
	let l:configMap = deepcopy(g:statusline_config)
" 	let style = 'bold'

	for side in ['left', 'right']
		for section in ['section_1', 'section_2', 'section_3']
			for status in ['active', 'inactive']
				let l:foreground = s:parseHighlightMap(l:configMap[side][section][status].highlight,'fg','#ffffff')
				let l:background = s:parseHighlightMap(l:configMap[side][section][status].highlight,'bg','#000000')
				let l:highlight = join([section,side,status],'_')	

				call s:executeHighlight(l:highlight,l:foreground,l:background)
			endfor
		endfor
	endfor
endfunction

function! s:executeHighlight(highlight,foreground,background)
	let l:highlightName = 'highlight '.a:highlight
	let l:highlightForeground = 'guifg='.a:foreground
	let l:highlightBackground = 'guibg='.a:background
	let l:cmd = join([l:highlightName,l:highlightForeground,l:highlightBackground],' ')

	execute l:cmd
endfunction



