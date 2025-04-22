let s:mode_map = {
	\ 'n':'NORMAL','i':'INSERT','R':'REPLACE','v':'VISUAL','V':'VISUAL LINE','^V':'VISUAL BLOCK',
	\ 'c':'COMMAND','C':'COMMAND-LINE','s':'SELECT','S':'SELECT LINE','t':'TERMINAL','nI':'NORMAL INSERT',
	\ 'N':'INSERT NORMAL','N:':'NORMAL EX','iN':'INSERT NORMAL','p':'PREVIEW','l':'LITERAL','R?':'REPLACE MODE',
	\ 'o':'OPERATOR-PENDING','O':'OPERATOR PENDING','r':'REPEAT','a':'ARGUMENT'}

let s:jostline_theme_gruvbox = [['#ebdbb2','#3c3836'], ['#d5c4a1','#504945'], ['#fbf1c7','#665c54'], ['#fbf1c7','#7c6f64']]
let s:jostline_theme_tokyonight = [['#c0caf5','#1a1b26'], ['#7aa2f7','#24283b'], ['#9ece6a','#414868'], ['#bb9af7','#1f2335']]
let s:jostline_theme_nord = [['#eceff4','#3b4252'], ['#d8dee9','#434c5e'], ['#a3be8c','#4c566a'], ['#81a1c1','#2e3440']]
let s:jostline_theme_onedark = [['#abb2bf','#282c34'], ['#e5c07b','#3e4451'], ['#98c379','#4b5263'], ['#61afef','#21252b']]
let s:jostline_theme_dracula = [['#f8f8f2','#282a36'], ['#50fa7b','#44475a'], ['#ff79c6','#6272a4'], ['#bd93f9','#1e1f29']]
let s:jostline_theme_solarized_dark = [['#839496','#002b36'], ['#93a1a1','#073642'], ['#b58900','#586e75'], ['#268bd2','#073642']]
let s:jostline_theme_catppuccin = [['#cdd6f4','#1e1e2e'], ['#f38ba8','#313244'], ['#a6e3a1','#45475a'], ['#89b4fa','#1e1e2e']]
let s:jostline_theme_everforest = [['#d3c6aa','#2f383e'], ['#a7c080','#374145'], ['#e67e80','#4d555b'], ['#83c092','#2f383e']]
let s:jostline_theme_monokai = [['#f8f8f2','#272822'], ['#a6e22e','#3e3d32'], ['#fd971f','#49483e'], ['#f92672','#383830']]
let s:jostline_theme_papercolor_light = [['#000000','#eeeeee'], ['#444444','#d7d7d7'], ['#005f87','#ffffff'], ['#870000','#eeeeee']]

let s:git_branch_stats = ''
let s:git_branch_stats_time = 0

function! jostline#init() abort
	call s:generateStatuslineConfig()

	if exists('g:jostline_theme')
		call jostline#applyTheme(g:jostline_theme, g:statusline_config)
	endif

	call s:generateSectionHighlights()
	set statusline=%!jostline#build()
endfunction


function! g:jostline#build()
	let l:status = g:statusline_winid == win_getid() ? 'active' : 'inactive'
	return s:getSide('left',l:status) . '%=' . s:getSide('right',l:status)
endfunction

function! jostline#applyTheme(name, config) abort
	let l:theme = get(s:, 'jostline_theme_' . a:name, [])
	if type(l:theme) != type([]) | return | endif
	
	call map(copy(l:theme),{i,hl -> map(['left','right'], {_,side ->
				\	has_key(a:config,side) && 
				\	has_key(a:config[side],'section_'.(i+1)) 
				\	? map(['active','inactive'], {_,status ->
				\		extend(a:config[side]['section_'.(i+1)][status],
				\			{'highlight': {'fg': hl[0], 'bg': hl[1]}}
				\		)}) 
				\	: 0
		\	})})
endfunction

function! s:defaultValues(var) abort
	let val = get(g:, a:var, {})
	let items = get(val, 'items', [])
	let highlight = get(val, 'highlight', [])
	let fg = get(val, 'fg', len(highlight) == 2 ? highlight['fg'] : 'NONE')
	let bg = get(val, 'bg', len(highlight) == 2 ? highlight['bg'] : 'NONE')
	return {'items': items, 'highlight': {'fg': fg, 'bg': bg}}
endfunction

function! s:generateStatuslineConfig() abort
	let g:statusline_config = {}
	for side in ['left', 'right']
		let nums = filter(keys(g:), {_,var -> var =~# printf('^jostline_%s_section_\d\+_\(active\|inactive\)$', side)})
	 	call map(nums,{_, var -> matchstr(var, '\d\+')})

		let sideConfig = {
			\ 'separator': get(g:, side.'_separator', side=='left'?'':''),
			\ 'subseparator': get(g:, side.'_subseparator', '|')
			\ }
		for n in s:sortArrayBySide(nums,side)
			let sect = {
				  \ 'active': s:defaultValues('jostline_'.side.'_section_'.n.'_active'),
				  \ 'inactive': s:defaultValues('jostline_'.side.'_section_'.n.'_inactive')
				  \ }
			let sideConfig['section_'.n] = sect
		endfor
		let g:statusline_config[side] = sideConfig
	endfor
endfunction

function! s:getGitBranchStats()
	let l:mtime = getftime('.git/index')
	if s:git_branch_stats ==# '' || s:git_branch_stats_time != l:mtime
		let l:branch = substitute(system('git rev-parse --abbrev-ref HEAD'), '\n$', '', '')
		let l:stats = substitute(system('git diff --shortstat'), '\n$', '', '')

		let l:insert = matchstr(l:stats, '\d\+\s\+insertion')
		let l:delete = matchstr(l:stats, '\d\+\s\+deletion')
		let l:plus = l:insert !=# '' ? '+' . matchstr(l:insert, '\d\+') : ''
		let l:minus = l:delete !=# '' ? '-' . matchstr(l:delete, '\d\+') : ''

		let l:parts = filter([' ' . l:branch, l:plus, l:minus], 'v:val !=# ""')
		let s:git_branch_stats = join(l:parts, ' ')
		let s:git_branch_stats_time = l:mtime
	endif
	return s:git_branch_stats
endfunction

augroup UpdateGitBranchStats
    autocmd!
    autocmd BufWritePost * let s:git_branch_stats = '' | let s:git_branch_stats_time = 0
augroup END

function! s:getItemValue(item)
	let l:itemValueMap = {
		\ 'mode': get(s:mode_map, mode(), 'UNKNOWN MODE'),
		\ 'fileName': expand('%:t') ==# '' ? '[No Name]' : expand('%:t'),
		\ 'fileType': '%{&filetype}',
		\ 'filePath': expand('%:p:h'),
		\ 'windowNumber': '%{winnr()}',
		\ 'modified': &modified ? 'Modified [+]' : 'No Changes',
		\ 'gitStats': s:getGitBranchStats()
		\ }
	return has_key(l:itemValueMap,a:item) ? ' ' . l:itemValueMap[a:item] . ' ' : ''
endfunction

function! s:parseItems(items)
	return join(filter(map(copy(a:items),'s:getItemValue(v:val)'),'v:val !=""'),'')
endfunction

function! s:getSections(config,status,side)
	return s:sortArrayBySide(filter(keys(copy(a:config)), {_,section -> section =~# '^section_\d\+$'}),a:side)
endfunction

function! s:getSide(side,status) abort
	let l:config = deepcopy(g:statusline_config[a:side])
	let l:sectionParts = map(
		\	s:getSections(l:config,a:status,a:side),{_,section-> 
		\		join(s:sortArrayBySide([
		\			s:buildHighlightStr(section.'_'.a:side.'_'.a:status, s:parseItems(get(l:config[section][a:status],'items',{}))),
		\			s:buildHighlightStr(section.'_'.a:side.'_'.a:status.'_separator',l:config.separator)
		\		],a:side),'')
		\ 	})
	return join(l:sectionParts,'')
endfunction

function! s:sortArrayBySide(arr,side)
	let l:arr = copy(a:arr)
	if a:side ==# 'right' | call reverse(l:arr) | else | call sort(l:arr) | endif
	return l:arr
endfunction

function! s:buildHighlightStr(highlight,value) 
	return a:value != '' ? join(['%#',a:highlight,'#',a:value,'%*'],'') : ''
endfunction

function! s:generateSectionHighlights() abort
	for side in ['left', 'right']
		let l:config = deepcopy(g:statusline_config[side])
		for status in ['active', 'inactive']
			let l:sections = s:getSections(l:config,status,side)

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
