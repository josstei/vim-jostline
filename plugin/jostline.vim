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

let g:right_section_1_active_items = ['windowNumber']
let g:right_section_1_active_highlight = ['#000000','#c678dd']
let g:right_section_1_inactive_items = ['windowNumber']
let g:right_section_1_inactive_highlight = ['#222222','#5e4b6e']

let g:statusline_config = {}

let g:git_branch_stats = ''
let g:git_branch_stats_time = 0

function! jostline#init() abort
  call s:generateStatuslineConfig()
  set statusline=%!jostline#build()
  call s:setDynamicSectionHighlights()
endfunction


function! g:jostline#build()
	let l:configMap = deepcopy(g:statusline_config)
	let l:windowStatus = g:statusline_winid == win_getid()
	
	return s:parseConfig(l:windowStatus,l:configMap)
endfunction

" ************************************************************
" **************** SECTION ITEM GETTERS START ****************
" ************************************************************

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

function! s:getFilePath()
	return expand('%:p:h')
endfunction

function! s:getFileExtension()
	return expand('%:e')
endfunction

function! s:getFileRoot()
	return expand('%:r')
endfunction

function! s:getModifiable()
	return &modifiable ? '' : 'Not Editable'
endfunction

function! s:getLines()
	return 'Lines: ' . line('$')
endfunction

function! s:getWordCount()
	return wordcount().words
endfunction

function! s:getColumns()
	return 'Columns: ' . &columns
endfunction

function! s:getDate()
	return strftime('%Y-%m-%d')
endfunction

" ************************************************************
" **************** SECTION ITEM GETTERS END ******************
" ************************************************************

function! s:getItemValue(item)
	let l:itemValueMap = {
		\ 'mode':         s:getMode(),
		\ 'fileName':     s:getFilename(),
		\ 'fileType':     s:getFiletype(),
		\ 'filePath':     s:getFilePath(),
		\ 'windowNumber': s:getWindowNumber(),
		\ 'modified':     s:getModified(),
		\ 'date':     	  s:getDate(),
		\ 'lines':     	  s:getLines(),
		\ 'columns':   	  s:getColumns(),
		\ 'gitStats': 	  s:getGitBranchStats()
		\ }

	return has_key(l:itemValueMap,a:item) ? ' ' . l:itemValueMap[a:item] . ' ' : ''
endfunction

function! s:parseItems(items)
	return join(filter(map(copy(a:items),'s:getItemValue(v:val)'),'v:val !=""'),'')
endfunction

function! s:getSections(map)
	return filter(copy(a:map), { key, val ->
		\ key =~# '^section_\d\+$' &&
		\ type(val) == type({}) &&
		\ (s:hasNonEmptyItems(get(val, 'active', {})) ||
		\  s:hasNonEmptyItems(get(val, 'inactive', {})))
		\ })
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

function! s:hasNonEmptyItems(submap)
	return has_key(a:submap, 'items') &&
		\ type(a:submap.items) == type([]) &&
		\ !empty(a:submap.items) &&
		\ a:submap.items[0] !=# ''
endfunction

function! s:getSides(map)
	return filter(copy(a:map), 'v:key ==# "left" || v:key ==# "right"')
endfunction

function! s:getStatuses(map)
	return filter(copy(a:map), 'v:key ==# "active" || v:key ==# "inactive"')
endfunction

function! s:generateStatuslineConfig() abort
	let l:cfg = {}

	for side in ['left','right']
		let l:side_cfg = {
			  \ 'separator':    get(g:, side . '_separator',    side ==# 'left' ? '' : ''),
			  \ 'subseparator': get(g:, side . '_subseparator', '|'),
			  \ }
		let l:sections = map(
			  \ filter(
			  \   keys(g:),
			  \   'v:val =~# "^'.side.'_section_\\d\\+_active_items$"'
			  \ ),
			  \ 'matchstr(v:val, "\\d\\+")'
			\)

		call sort(l:sections)
		call uniq(l:sections)

		if side ==# 'right'
			call reverse(l:sections)
		endif

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

function! s:parseConfig(windowIsCurrent, config) abort
	let status = a:windowIsCurrent ? 'active' : 'inactive'
	let left  = s:buildSideStr(a:config.left,  status, 'left')
	let right = s:buildSideStr(a:config.right, status, 'right')

	return left . '%=' . right
endfunction

function! s:buildSideStr(side_cfg, status, side) abort
	let l:sections = filter(keys(copy(a:side_cfg)), { _, section ->
		\   section =~# '^section_\d\+$' &&
		\   type(a:side_cfg[section]) == type({}) &&
		\   type(a:side_cfg[section][a:status]) == type({}) &&
		\   type(a:side_cfg[section][a:status].items) == type([]) &&
		\   !empty(a:side_cfg[section][a:status].items) &&
		\   a:side_cfg[section][a:status].items[0] !=# ''
		\})

	call sort(l:sections)
	if a:side ==# 'right'
		call reverse(l:sections)
	endif

	let l:parts = []

	for section in l:sections
		let l:data		= a:side_cfg[section][a:status]
		let l:items		= s:parseItems(l:data.items)
		let l:separator	= a:side_cfg.separator

		let l:sectionHighlight	 = section . '_' . a:side . '_' . a:status
		let l:separatorHighlight = l:sectionHighlight . '_separator'

		let l:itemHighlightStr		= s:buildHighlightStr({'highlight':l:sectionHighlight,'value':l:items})
		let l:separatorHighlightStr	= s:buildHighlightStr({'highlight':l:separatorHighlight,'value':l:separator})

		if a:side ==# 'left'
			let l:arrSectionParts	= [l:itemHighlightStr, l:separatorHighlightStr]
		else
			let l:arrSectionParts	= [l:separatorHighlightStr, l:itemHighlightStr]
		endif
		call extend(l:parts, l:arrSectionParts)
	endfor

	return join(l:parts, '')
endfunction

function! s:buildHighlightStr(map) 
	let l:data = copy(a:map)

	if l:data.value != ''
		return join(['%#',l:data.highlight,'#',l:data.value,'%*'],'')
	endif

	return ''
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


function! s:sortSectionsBySide(side,sections)
	if a:side == 'left'
		call sort(a:sections)
	else
		call reverse(sort(a:sections))
	endif
endfunction`

augroup UpdateGitBranchStats
    autocmd!
    autocmd BufWritePost * let g:git_branch_stats = '' | let g:git_branch_stats_time = 0
augroup END

function! s:setDynamicSectionHighlights() abort
	let l:config = deepcopy(g:statusline_config)

	for side in ['left', 'right']
		for status in ['active', 'inactive']
			let l:sections = s:getValidSections(l:config[side], status)
			
			call sort(l:sections)
			if side ==# 'right'
				call reverse(l:sections)
			endif

			for i in range(0, len(l:sections) - 1)

				if i + 1 < len(l:sections)
					let l:nextBG = get(l:config[side][l:sections[i + 1]][status]['highlight'],'bg','NONE')
				else
					let l:nextBG = 'NONE'
				endif

				let l:currFG = get(l:config[side][l:sections[i]][status]['highlight'],'fg','NONE')
				let l:currBG = get(l:config[side][l:sections[i]][status]['highlight'],'bg','NONE')

				let l:sectionHighlight = l:sections[i] . '_' . side . '_' . status
				let l:separatorHighlight = l:sectionHighlight . '_separator'

				call s:executeHighlight(l:sectionHighlight, l:currFG, l:currBG)
				call s:executeHighlight(l:separatorHighlight, l:currBG, l:nextBG)
			endfor
		endfor
	endfor
endfunction

