let s:mode_map = {
	\ 'n':'NORMAL','i':'INSERT','R':'REPLACE','v':'VISUAL','V':'VISUAL LINE','^V':'VISUAL BLOCK',
	\ 'c':'COMMAND','C':'COMMAND-LINE','s':'SELECT','S':'SELECT LINE','t':'TERMINAL','nI':'NORMAL INSERT',
	\ 'N':'INSERT NORMAL','N:':'NORMAL EX','iN':'INSERT NORMAL','p':'PREVIEW','l':'LITERAL','R?':'REPLACE MODE',
	\ 'o':'OPERATOR-PENDING','O':'OPERATOR PENDING','r':'REPEAT','a':'ARGUMENT'}

let s:sl_cfg = {}

let s:theme_map = {
	\ 'gruvbox':[['#ebdbb2','#3c3836'],['#d5c4a1','#504945'],['#fbf1c7','#665c54'],['#fbf1c7','#7c6f64']],
	\ 'tokyonight':[['#c0caf5','#1a1b26'],['#7aa2f7','#24283b'],['#9ece6a','#414868'],['#bb9af7','#1f2335']],
	\ 'nord':[['#eceff4','#3b4252'],['#d8dee9','#434c5e'],['#a3be8c','#4c566a'],['#81a1c1','#2e3440']],
	\ 'onedark':[['#abb2bf','#282c34'],['#e5c07b','#3e4451'],['#98c379','#4b5263'],['#61afef','#21252b']],
	\ 'dracula':[['#f8f8f2','#282a36'],['#50fa7b','#44475a'],['#ff79c6','#6272a4'],['#bd93f9','#1e1f29']],
	\ 'solarized_dark':[['#839496','#002b36'],['#93a1a1','#073642'],['#b58900','#586e75'],['#268bd2','#073642']],
	\ 'catppuccin':[['#cdd6f4','#1e1e2e'],['#f38ba8','#313244'],['#a6e3a1','#45475a'],['#89b4fa','#1e1e2e']],
	\ 'everforest':[['#d3c6aa','#2f383e'],['#a7c080','#374145'],['#e67e80','#4d555b'],['#83c092','#2f383e']],
	\ 'monokai':[['#f8f8f2','#272822'],['#a6e22e','#3e3d32'],['#fd971f','#49483e'],['#f92672','#383830']],
	\ 'papercolor_light':[['#000000','#eeeeee'],['#444444','#d7d7d7'],['#005f87','#ffffff'],['#870000','#eeeeee']],
\ }

let s:git_branch_stats = ''
let s:git_branch_stats_time = 0

function! jostline#init() abort
	call s:init_cfg()
	if exists('g:jostline_theme') | call s:set_theme(g:jostline_theme, s:sl_cfg) | endif
	call s:init_hl()
	set statusline=%!jostline#build()
endfunction

function! g:jostline#build()
	let l:status = g:statusline_winid == win_getid() ? 'active' : 'inactive'
	return s:get_sl_side('left',l:status) . '%=' . s:get_sl_side('right',l:status)
endfunction

function! s:set_theme(name, cfg) abort
	let l:theme = get(s:theme_map,a:name, [])
	
	call map(copy(l:theme),{i,hl -> map(['left','right'], {_,side ->
				\	has_key(a:cfg,side) && 
				\	has_key(a:cfg[side],'section_'.(i+1)) 
				\	? map(['active','inactive'], {_,status ->
				\		extend(a:cfg[side]['section_'.(i+1)][status],
				\			{'highlight': {'fg': hl[0], 'bg': hl[1]}}
				\		)}) 
				\	: 0
				\	})})
endfunction

function! s:set_sec_vals(var) abort
	let val = get(g:, a:var, {})
	let items = get(val, 'items', [])
	let hl = get(val, 'highlight', [])
	let fg = get(hl,'fg','NONE')
	let bg = get(hl,'bg','NONE')
	return {'items': items, 'highlight': {'fg': fg, 'bg': bg}}
endfunction

function! s:init_cfg() abort
	for side in ['left', 'right']
		let nums = filter(keys(g:), {_,var -> var =~# printf('^jostline_%s_section_\d\+_\(active\|inactive\)$', side)})
	 	call map(nums,{_, var -> matchstr(var, '\d\+')})

		let sideCfg = {
			\ 'sep': get(g:, side.'_separator', side=='left'?'':''),
			\ 'subsep': get(g:, side.'_subseparator', '|')
			\ }
		for n in s:sort_by_side(nums,side)
			let sideCfg['section_'.n] = {}
			for status in ['active', 'inactive']
				let sideCfg['section_'.n][status] = s:set_sec_vals('jostline_'.side.'_section_'.n.'_'.status)
			endfor
		endfor
		let s:sl_cfg[side] = sideCfg 
	endfor
endfunction

function! s:get_git_stats()
	let l:mtime = getftime('.git/index')
	if s:git_branch_stats ==# '' || s:git_branch_stats_time != l:mtime
		let l:branch = substitute(system('git rev-parse --abbrev-ref HEAD'), '\n$', '', '')
		let l:stats = substitute(system('git diff --shortstat'), '\n$', '', '')

		let l:ins = matchstr(l:stats, '\d\+\s\+insertion')
		let l:del = matchstr(l:stats, '\d\+\s\+deletion')
		let l:plus = l:ins !=# '' ? '+' . matchstr(l:ins,'\d\+') : ''
		let l:minus = l:del !=# '' ? '-' . matchstr(l:del,'\d\+') : ''

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

function! s:get_item_val(item)
	let l:item_map= {
		\ 'mode': get(s:mode_map, mode(), 'UNKNOWN MODE'),
		\ 'fileName': expand('%:t') ==# '' ? '[No Name]' : expand('%:t'),
		\ 'fileType': '%{&filetype}',
		\ 'filePath': expand('%:p:h'),
		\ 'windowNumber': '%{winnr()}',
		\ 'modified': &modified ? 'Modified [+]' : 'No Changes',
		\ 'gitStats': s:get_git_stats()
		\ }
	return has_key(l:item_map,a:item) ? ' ' . l:item_map[a:item] . ' ' : ''
endfunction

function! s:get_sec_items(items)
	return join(filter(map(copy(a:items),'s:get_item_val(v:val)'),'v:val !=""'),'')
endfunction

function! s:get_secs(map,side,status)
 	return s:sort_by_side(filter(keys(copy(a:map)), { _, sec -> sec =~# '^section_\d\+$' && 
				\	!empty(a:map[sec][a:status].items) && a:map[sec][a:status].items[0] !=# ''})
				\	,a:side)
endfunction

function! s:get_sl_side(side,status) abort
	let l:cfg = deepcopy(s:sl_cfg[a:side])
	return join(map(s:get_secs(l:cfg,a:side,a:status),{_,sec-> join(s:sort_by_side([
		\			s:build_hl(sec.'_'.a:side.'_'.a:status, s:get_sec_items(get(l:cfg[sec][a:status],'items',{}))),
		\			s:build_hl(sec.'_'.a:side.'_'.a:status.'_sep',l:cfg.sep)
		\			],a:side),'')
		\ 	}),'')
endfunction

function! s:sort_by_side(arr,side)
	let l:arr = copy(a:arr)
	if a:side ==# 'right' | call reverse(l:arr) | else | call sort(l:arr) | endif
	return l:arr
endfunction

function! s:build_hl(hl,val) 
	return a:val != '' ? join(['%#',a:hl,'#',a:val,'%*'],'') : ''
endfunction

function! s:init_hl() abort
	for side in ['left', 'right']
		let l:cfg = deepcopy(s:sl_cfg[side])
		for status in ['active', 'inactive']
			let l:secs = s:get_secs(l:cfg,side,status)
			for i in range(0, len(l:secs) - 1)
				let l:nextBG = s:get_hl(l:cfg,i + 1,l:secs,status,'bg')
				let l:currFG = s:get_hl(l:cfg,i,l:secs,status,'fg')
				let l:currBG = s:get_hl(l:cfg,i,l:secs,status,'bg')
				let l:sec_hl = l:secs[i] . '_' . side . '_' . status
				let l:sep_hl = l:sec_hl.'_sep'

				execute 'highlight ' . l:sec_hl. ' guifg=' . l:currFG . ' guibg=' . l:currBG
				execute 'highlight ' . l:sep_hl. ' guifg=' . l:currBG . ' guibg=' . l:nextBG
			endfor
		endfor
	endfor
endfunction

function! s:get_hl(map,idx,secs,status,hl)
	return a:idx < len(a:secs) ? a:map[a:secs[a:idx]][a:status]['highlight'][a:hl] : 'NONE'
endfunction
