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

function! jostline#init() abort
	call s:init_cfg() | call s:init_theme(s:sl_cfg)
	set statusline=%!jostline#build()
endfunction

function! g:jostline#build() abort
	let l:status = g:statusline_winid == win_getid() ? 'active' : 'inactive'
	return s:init_sl_side('left',status).'%='.s:init_sl_side('right',status)
endfunction

function! s:init_theme(cfg) abort
	let l:colorscheme= exists('g:colors_name') ? g:colors_name : 'default'
	let l:theme = get(s:theme_map,l:colorscheme, [])
	
	call map(copy(l:theme),{i,hl -> map(['left','right'], {_,side ->
				\	has_key(a:cfg[side],'section_'.(i+1)) 
				\	? map(['active','inactive'], {_,status ->
				\		extend(a:cfg[side]['section_'.(i+1)][status],{'highlight': {'fg': hl[0], 'bg': hl[1]}}
				\		)}) 
				\	: 0
				\	})})
endfunction

function! s:set_sec_vals(side,sec,status) abort
	let val = get(g:,'jostline_'.a:side.'_'.a:sec.'_'.a:status,{})
	let items = get(val, 'items', [])
	let hl = get(val, 'highlight', {})
	let fg = get(hl,'fg','NONE')
	let bg = get(hl,'bg','NONE')
	return {'items':items,'highlight':{'fg':fg,'bg':bg}}
endfunction

function! s:init_cfg() abort
	for side in ['left', 'right']
		let nums = filter(keys(g:), {_,var -> var =~# printf('^jostline_%s_section_\d\+_\(active\|inactive\)$', side)})
	 	call map(nums,{_, var -> matchstr(var, '\d\+')})

		let sideCfg = {
			\ 'sep': get(g:, side.'_separator', side=='left'?'':''),
			\ 'subsep': get(g:, side.'_subseparator', '|')
			\ }

		for n in s:sort_side(copy(nums),side)
			let sec = 'section_'.n
			let sideCfg[sec] = {}
			for status in ['active', 'inactive']
				let sideCfg[sec][status] = s:set_sec_vals(side,sec,status)
			endfor
		endfor
		let s:sl_cfg[side] = sideCfg 
	endfor
endfunction

let s:git_branch = ''
let s:git_diff   = ''

function! s:refresh_git_stats() abort
	let l:root = finddir('.git', expand('%:p:h').' ;')
	if empty(l:root) | return | endif
	let l:cwd = fnamemodify(l:root, ':h')

	call job_start(['git','-C',l:cwd,'rev-parse','--abbrev-ref','HEAD'],{'out_cb':function('s:on_branch'),'out_mode':'nl'})
	call job_start(['git','-C',l:cwd,'diff','--shortstat'],{'out_cb':function('s:on_diff'),'out_mode':'nl'})
endfunction

function! s:on_branch(job, data) abort
	if !empty(a:data) | let s:git_branch = a:data | endif
endfunction

function! s:on_diff(job, data) abort
	if !empty(a:data)
		let l:stats = a:data
		let l:ins = matchstr(l:stats,'\d\+\s\+insertion')
		let l:del = matchstr(l:stats,'\d\+\s\+deletion')
		let l:plus = l:ins !=# '' ? '+'.matchstr(l:ins,'\d\+') : ''
		let l:minus = l:del !=# '' ? '-'.matchstr(l:del,'\d\+') : ''
		let s:git_diff = ' '.s:git_branch.' '.l:plus.' '.l:minus
		redrawstatus
	endif
endfunction

function! s:get_git_stats() abort
	return s:git_diff
endfunction

augroup UpdateGitStats 
	autocmd!
	autocmd VimEnter,BufWritePost,BufReadPost * call s:refresh_git_stats()
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
	return get(l:item_map,a:item,'')
endfunction

function! s:get_secs(map,status)
	 return filter(keys(copy(a:map)), { _, sec -> sec =~# '^section_\d\+$'})
endfunction

function! s:get_sec_items(arr)
	return join(filter(map(a:arr,'s:get_item_val(v:val)'),'v:val!=""'),'')
endfunction

function! s:sort_side(arr,side) abort
	if a:side ==# 'right' | call reverse(a:arr) | else | call sort(a:arr) | endif | return a:arr
endfunction

function! s:init_sl_side(side,status) abort
	let cfg = deepcopy(s:sl_cfg[a:side]) 
	let sl_parts = []
	for sec in s:sort_side(s:get_secs(l:cfg,a:status),a:side)
		let data = cfg[sec][a:status]
		let name = a:side.sec.a:status
		let items = s:get_sec_items(data['items'])
		call s:exec_hl(name,data['highlight'])
		call add(sl_parts,'%#'.name.'#'.items.' %*'.'%#'.name.'#'.cfg.sep.' %*')
	endfor
	return join(sl_parts,'')
endfunction

function! s:exec_hl(hl,map)
	execute 'highlight '.a:hl.' guifg='.a:map['fg'].' guibg='.a:map['bg']
	execute 'highlight '.a:hl.'sep'.' guifg='.a:map['bg'].' guibg='.a:map['fg']
endfunction
