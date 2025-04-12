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
			\   'section_1': { 'items': ['windowNumber'], 'highlight': {'bg': '#c678dd', 'fg': '#000000'} },
			\   'section_2': { 'items': ['mode'],         'highlight': {'bg': '#4b2a55', 'fg': '#efd7f6'} },
			\   'section_3': { 'items': ['fileName'],     'highlight': {'bg': '#333333', 'fg': '#ffffff'} },
			\   'separator': '',
			\   'side': 'LEFT'
			\ },
			\ 'right': {
			\   'section_1': { 'items': ['someOtherItem'], 'highlight': {'bg': '#c678dd', 'fg': ''} },
			\   'section_2': { 'items': ['anotherItem'],   'highlight': {'bg': '#c678dd', 'fg': ''} },
			\   'section_3': { 'items': ['yetAnotherItem'],  'highlight': {'bg': '#c678dd', 'fg': ''} },
			\   'separator': '',
			\   'side': 'RIGHT'
			\ }
			\}

function! jostline#set() abort
	set statusline=%!g:jostline#build()
  	call s:setDynamicSectionHighlights()
endfunction

function! g:jostline#build()
	let is_active = g:statusline_winid == win_getid()
	let cfg = deepcopy(g:statusline_config)

	if !is_active
		if has_key(cfg.left, 'section_1')
			let cfg.left.section_1.items = ['windowNumber']
		endif
		if has_key(cfg.left, 'section_2')
			let cfg.left.section_2.items = []
		endif
		if has_key(cfg.left, 'section_3')
			let cfg.left.section_3.items = []
		endif
	endif

  return ''.s:parseSectionGroup(cfg.left).'%='.s:parseSectionGroup(cfg.right).' '
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

function! s:parseSectionItems(items)
	let l:itemValues = filter(map(copy(a:items),'s:getItemValue(v:val)'), 'v:val !=v:null' )
	return empty(l:itemValues) ? v:null : join(l:itemValues, '')
endfunction

function! s:getSections(map)
	return filter(copy(a:map), 'v:key =~# "^section_\\d\\+$"')
endfunction

function! s:parseSectionGroup(map)
	let l:groupMap = a:map
  	let l:sections = s:getSections(l:groupMap)
  	let l:separator = l:groupMap ->get('separator','')
	let l:side = l:groupMap ->get('side','')
	let l:parts = []

	for [name, data] in items(l:sections)
	   	let l:itemsStr = s:parseSectionItems(data.items)
		let l:highlighted = s:appendHighlights(name, l:itemsStr, l:side, l:separator)

		if l:highlighted != v:null
			call add(l:parts,l:highlighted)
		endif
	endfor
  return empty(l:parts) ? '' : join(l:parts, '')
endfunction

function! s:appendHighlights(name,items,side,separator) 
	if a:items == v:null 
		return a:items
	endif

	let l:items = s:appendItemHighlight(a:name,a:items,a:side)
	let l:separator = s:appendSeparatorHighlight(a:name,a:separator,a:side) 

	return  a:side == 'LEFT'  ? l:items.l:separator:
		   \a:side == 'RIGHT' ? l:separator.l:items:
		   \v:null
endfunction

function! s:appendItemHighlight(name,items,side) 
	return '%#'.a:name.'_'.a:side.'# '.a:items.'%*'		
endfunction

function! s:appendSeparatorHighlight(name,separator,side) 
	return '%#'.a:name.'_'.a:side.'_separator#'.a:separator.'%*'		
endfunction


function! s:parseHighlightMap(map,key,default)
	let l:value = get(a:map,a:key,a:default)
	return l:value == '' ? a:default : l:value
endfunction

function! s:setDynamicSectionHighlights()
	let l:cfg = deepcopy(g:statusline_config)
	let l:sections = s:getSections(l:cfg.left)
	" not used yet
	let style = 'bold'

	for [name, data] in items(l:sections)
		let l:foreground = s:parseHighlightMap(data.highlight,'fg','#ffffff')
		let l:background = s:parseHighlightMap(data.highlight,'bg','#000000')

		let l:cmdSeparatorHighlight = printf('highlight %s_%s_separator guifg=%s guibg=%s',name, 'left', l:foreground, l:background)
		let l:cmdSectionHighlight = printf('highlight %s_%s guifg=%s guibg=%s',name, 'left', l:foreground, l:background)

 		execute l:cmdSeparatorHighlight
 		execute l:cmdSectionHighlight
	endfor
endfunction




