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

let g:left_section_1_active_items = ['windowNumber']
let g:left_section_1_active_highlight = ['#000000','#c678dd']
let g:left_section_1_inactive_items = ['windowNumber']
let g:left_section_1_inactive_highlight = ['#222222','#5e4b6e']

let g:left_section_2_active_items = ['mode']
let g:left_section_2_active_highlight = ['#efd7f6','#4b2a55']
let g:left_section_2_inactive_items = ['']
let g:left_section_2_inactive_highlight = ['#000000','#c678dd']

let g:left_section_3_active_items = ['gitStats']
let g:left_section_3_active_highlight = ['#ffffff','#333333']
let g:left_section_3_inactive_items = ['']
let g:left_section_3_inactive_highlight = ['#000000','#c678dd']

let g:left_section_4_active_items = ['fileName']
let g:left_section_4_active_highlight = ['#000000','#c678dd']
let g:left_section_4_inactive_items = ['']
let g:left_section_4_inactive_highlight = ['#000000','#c678dd']

let g:right_section_1_active_items = ['']
let g:right_section_1_active_highlight = ['#000000','#c678dd']
let g:right_section_1_inactive_items = ['']
let g:right_section_1_inactive_highlight = ['#222222','#5e4b6e']

let g:statusline_config = {}

function! jostline#init() abort
	call s:initialize()
	set statusline=%!jostline#build()
endfunction

function! g:jostline#build()
	let l:left  = s:buildStatuslineSide('left')
	let l:right = s:buildStatuslineSide('right')

	return l:left . '%=' . l:right
endfunction

function! s:initialize()
	call s:generateStatuslineConfig()
	call s:generateSectionHighlights()
endfunction

" ************************************************************
" **************** GIT INTEGRATION START *********************
" ************************************************************

let g:git_branch_stats = ''
let g:git_branch_stats_time = 0

function! s:getGitBranchStats()
	let l:mtime = getftime('.git/index')
	if g:git_branch_stats ==# '' || g:git_branch_stats_time != l:mtime
		let l:branch = substitute(system('git rev-parse --abbrev-ref HEAD'), '\n$', '', '')
		let l:stats = substitute(system('git diff --shortstat'), '\n$', '', '')

		let l:insert = matchstr(l:stats, '\d\+\s\+insertion')
		let l:delete = matchstr(l:stats, '\d\+\s\+deletion')
		let l:plus = l:insert !=# '' ? '+' . matchstr(l:insert, '\d\+') : ''
		let l:minus = l:delete !=# '' ? '-' . matchstr(l:delete, '\d\+') : ''

		let l:parts = filter([' ' . l:branch, l:plus, l:minus], 'v:val !=# ""')
		let g:git_branch_stats = join(l:parts, ' ')
		let g:git_branch_stats_time = l:mtime
	endif

	return g:git_branch_stats
endfunction

augroup UpdateGitBranchStats
    autocmd!
    autocmd BufWritePost * let g:git_branch_stats = '' | let g:git_branch_stats_time = 0
augroup END

" ************************************************************
" **************** GIT INTEGRATION END ***********************
" ************************************************************

function! s:getItemValue(item)
	let l:itemValueMap = {
		\ 'mode': 		  get(g:mode_map, mode(), 'UNKNOWN MODE'),
		\ 'fileName':     expand('%:t') ==# '' ? '[No Name]' : expand('%:t'),
		\ 'fileType':     '%{&filetype}',
		\ 'filePath':     expand('%:p:h'),
		\ 'windowNumber': '%{winnr()}',
		\ 'modified':     &modified ? 'Modified [+]' : 'No Changes',
		\ 'gitStats': 	  s:getGitBranchStats()
		\ }
	return has_key(l:itemValueMap,a:item) ? ' ' . l:itemValueMap[a:item] . ' ' : ''
endfunction

function! s:parseItems(items)
	return join(filter(map(copy(a:items),'s:getItemValue(v:val)'),'v:val !=""'),'')
endfunction

function! s:getValidSections(map,status)
	return filter(keys(copy(a:map)), { key, section ->
		\	 section =~# '^section_\d\+$' &&
		\	 type(a:map[section]) == type({}) &&
		\	 type(a:map[section][a:status]) == type({}) &&
		\	 type(a:map[section][a:status].items) == type([]) &&
		\	 !empty(a:map[section][a:status].items) &&
		\	 a:map[section][a:status].items[0] !=# ''
		\})
endfunction

function! s:generateStatuslineConfig() abort
	let l:cfg = {}

	for side in ['left','right']
		let l:side_cfg = {
			  \ 'separator': get(g:, side . '_separator', side ==# 'left' ? '' : ''),
			  \ 'subseparator': get(g:, side . '_subseparator', '|'),
			  \ }
		let l:sections = map(
			  \ filter(
			  \   keys(g:),
			  \   'v:val =~# "^'.side.'_section_\\d\\+_active_items$"'
			  \ ),
			  \ 'matchstr(v:val, "\\d\\+")'
			\)

		call uniq(l:sections)
		call s:sortArrayBySide(l:sections,side)

		for num in l:sections
			let l:sectionMap = {}

			for status in ['active', 'inactive']
				let l:item_var = side . '_section_' . num . '_' . status . '_items'
				let l:items = get(g:, l:item_var, [])

				if type(l:items) != type([]) | let l:items = [] | endif

				let l:high_var = side . '_section_' . num . '_' . status . '_highlight'
				let l:highlight = get(g:, l:high_var, ['NONE','NONE'])

				if type(l:highlight) != type([]) || len(l:highlight) != 2 
					let l:highlight = ['NONE', 'NONE']
				endif

				let l:highlightMap = { 'fg': l:highlight[0], 'bg': l:highlight[1] }
				let l:sectionMap[status] = { 'items': l:items, 'highlight': l:highlightMap}
			endfor
			
			let l:side_cfg['section_' . num] = l:sectionMap
		endfor
		
		let l:cfg[side] = l:side_cfg
	endfor

	let g:statusline_config = l:cfg
endfunction

function! s:buildStatuslineSide(side) abort
	let l:config 	= deepcopy(g:statusline_config[a:side])
	let l:status 	= g:statusline_winid == win_getid() ? 'active' : 'inactive'
	let l:separator	= l:config.separator
	let l:sections 	= s:getValidSections(l:config, l:status)
	let l:parts 	= []

	call s:sortArrayBySide(l:sections,a:side)

	for section in l:sections
		let l:items					= s:parseItems(l:config[section][l:status]['items'])
		let l:sectionHighlight	 	= section . '_' . a:side . '_' . l:status
		let l:separatorHighlight 	= l:sectionHighlight . '_separator'
		let l:itemHighlightStr		= s:buildHighlightStr({'highlight':l:sectionHighlight,'value':l:items})
		let l:separatorHighlightStr	= s:buildHighlightStr({'highlight':l:separatorHighlight,'value':l:separator})
		let l:sectionParts 			= [l:itemHighlightStr,l:separatorHighlightStr]

		call s:sortArrayBySide(l:sectionParts,a:side)
		call extend(l:parts,l:sectionParts)
	endfor

	return join(l:parts,'')
endfunction

function! s:sortArrayBySide(arr,side)
	if a:side ==# 'right' | call reverse(a:arr) | else | call sort(a:arr) | endif
endfunction

function! s:buildHighlightStr(map) 
	return a:map.value != '' ? join(['%#',a:map.highlight,'#',a:map.value,'%*'],'') : ''
endfunction

function! s:generateSectionHighlights() abort
	for side in ['left', 'right']
		let l:config = deepcopy(g:statusline_config[side])
		for status in ['active', 'inactive']
			let l:sections = s:getValidSections(l:config,status)

			call s:sortArrayBySide(l:sections,side)

			for i in range(0, len(l:sections) - 1)
				let l:nextBG = s:getSectionHighlight(l:config,i + 1,l:sections,status,'bg')
				let l:currFG = s:getSectionHighlight(l:config,i,l:sections,status,'fg')
				let l:currBG = s:getSectionHighlight(l:config,i,l:sections,status,'bg')

				let l:sectionHighlight	 = l:sections[i] . '_' . side . '_' . status
				let l:separatorHighlight = l:sectionHighlight . '_separator'

				execute 'highlight ' . l:sectionHighlight . ' guifg=' . l:currFG . ' guibg=' . l:currBG
				execute 'highlight ' . l:separatorHighlight . ' guifg=' . l:currBG . ' guibg=' . l:nextBG
			endfor
		endfor
	endfor
endfunction

function! s:getSectionHighlight(dataMap,index,arrSections,status,highlight)
	return a:index < len(a:arrSections) ? a:dataMap[a:arrSections[a:index]][a:status]['highlight'][a:highlight] : 'NONE'
endfunction
