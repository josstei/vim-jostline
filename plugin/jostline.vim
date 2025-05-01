let s:mode_map = {
  \ 'n':'NORMAL','i':'INSERT','R':'REPLACE','v':'VISUAL','V':'VISUAL LINE','^V':'VISUAL BLOCK',
  \ 'c':'COMMAND','C':'COMMAND-LINE','s':'SELECT','S':'SELECT LINE','t':'TERMINAL','nI':'NORMAL INSERT',
  \ 'N':'INSERT NORMAL','N:':'NORMAL EX','iN':'INSERT NORMAL','p':'PREVIEW','l':'LITERAL','R?':'REPLACE MODE',
  \ 'o':'OPERATOR-PENDING','O':'OPERATOR PENDING','r':'REPEAT','a':'ARGUMENT'}

let s:sl_cfg = {}
let s:theme_map = {
  \ 'gruvbox': [['#ebdbb2','#3c3836'],['#d5c4a1','#504945'],['#fbf1c7','#665c54'],['#fbf1c7','#7c6f64']],
  \ 'tokyonight': [['#c0caf5','#1a1b26'],['#7aa2f7','#24283b'],['#9ece6a','#414868'],['#bb9af7','#1f2335']],
  \ 'nord': [['#eceff4','#3b4252'],['#d8dee9','#434c5e'],['#a3be8c','#4c566a'],['#81a1c1','#2e3440']],
  \ 'onedark': [['#abb2bf','#282c34'],['#e5c07b','#3e4451'],['#98c379','#4b5263'],['#61afef','#21252b']],
  \ 'dracula': [['#f8f8f2','#282a36'],['#50fa7b','#44475a'],['#ff79c6','#6272a4'],['#bd93f9','#1e1f29']],
  \ 'solarized_dark': [['#839496','#002b36'],['#93a1a1','#073642'],['#b58900','#586e75'],['#268bd2','#073642']],
  \ 'catppuccin': [['#cdd6f4','#1e1e2e'],['#f38ba8','#313244'],['#a6e3a1','#45475a'],['#89b4fa','#1e1e2e']],
  \ 'everforest': [['#d3c6aa','#2f383e'],['#a7c080','#374145'],['#e67e80','#4d555b'],['#83c092','#2f383e']],
  \ 'monokai': [['#f8f8f2','#272822'],['#a6e22e','#3e3d32'],['#fd971f','#49483e'],['#f92672','#383830']],
  \ 'papercolor_light': [['#000000','#eeeeee'],['#444444','#d7d7d7'],['#005f87','#ffffff'],['#870000','#eeeeee']],
\}

function! jostline#init() abort
	call s:init_cfg() | call s:init_theme()
	set statusline=%!jostline#build()
endfunction

function! jostline#build() abort
	let status = win_getid() == g:statusline_winid ? 'active' : 'inactive'
	return s:render_side('left',status) . s:get_hl('jostline_gap_'.status, '%=') . s:render_side('right',status)
endfunction

function! s:init_cfg() abort
  for side in ['left','right']
    let sep = get(g:, side.'_separator', side=='left' ? '' : '')
    let subsep = get(g:, side.'_subseparator', '|')
		let nums = filter(keys(g:), {_,var -> var =~# printf('^jostline_%s_section_\d\+_\(active\|inactive\)$', side)})
	 	call map(nums,{_, var -> matchstr(var, '\d\+')})
    let cfg = {'sep': sep, 'subsep': subsep}
    for n in nums
      let sec = 'section_'.n
      let cfg[sec] = {}
      for status in ['active','inactive']
        let key = 'jostline_'.side.'_'.sec.'_'.status
        let val = get(g:, key, {})
        let items = get(val, 'items', [])
        let hl = get(val, 'highlight', {})
        let cfg[sec][status] = {'items': items,'highlight': {'fg': get(hl,'fg','NONE'),'bg': get(hl,'bg','NONE')}}
      endfor
    endfor
    let s:sl_cfg[side] = cfg
  endfor
endfunction

function! s:init_theme() abort
	let cs = get(g:, 'colors_name', 'default')
	let theme = get(s:theme_map, cs, [])
	for idx in range(len(theme))
		let [fg,bg] = theme[idx]
		let sec = 'section_'.(idx+1)
		for side in ['left','right']
			if has_key(s:sl_cfg[side], sec)
				for status in ['active','inactive']
					let s:sl_cfg[side][sec][status].highlight = {'fg': fg, 'bg': bg}
				endfor
			endif
		endfor
	endfor
	for status in ['active','inactive']
		if has_key(s:sl_cfg['left'], 'section_1')
			let gap_fg = 'NONE'
			let gap_bg = s:sl_cfg['left']['section_1'][status].highlight.bg
			let gap_name = 'jostline_gap_'.status
			execute printf('highlight %s guifg=%s guibg=%s', gap_name, gap_fg, gap_bg)
		endif
	endfor
endfunction

augroup jostline_git
	autocmd!
	autocmd VimEnter,BufWritePost,BufReadPost * call s:refresh_git_stats()
augroup END

let s:git_branch = ''
let s:git_diff   = ''

function! s:refresh_git_stats() abort
  let root = finddir('.git', expand('%:p:h').' ;')
  if empty(root) | return | endif
  let cwd = fnamemodify(root, ':h')
  call job_start(['git','-C',cwd,'rev-parse','--abbrev-ref','HEAD'],{'out_cb': function('s:on_branch'),'out_mode':'nl'})
  call job_start(['git','-C',cwd,'diff','--shortstat'],{'out_cb': function('s:on_diff'),'out_mode':'nl'})
endfunction

function! s:on_branch(job,data) abort
	if !empty(a:data) | let s:git_branch = a:data | endif
endfunction

function! s:on_diff(job,data) abort
	if empty(a:data) | return | endif
	let stats = a:data
	let ins = matchstr(stats,'\d\+\s\+insertion')
	let del = matchstr(stats,'\d\+\s\+deletion')
	let plus = ins !=# '' ? '+'.matchstr(ins,'\d\+') : ''
	let minus = del !=# '' ? '-'.matchstr(del,'\d\+') : ''
	let s:git_diff = '  '.s:git_branch.' '.plus.' '.minus
endfunction

function! s:get_git_stats() abort
	return s:git_diff
endfunction

function! s:render_side(side,status) abort
	let cfg = deepcopy(s:sl_cfg[a:side]) 
	let secs = sort(filter(keys(cfg), 'v:val =~# "^section_\\d\\+$"'))
	call s:rev_arr(a:side,'left',secs)
	let result = []
	let prev_bg = 'NONE'
	let loop_secs = a:side ==# 'right' ? reverse(copy(secs)) : secs
	for sec in loop_secs
		let data = cfg[sec][a:status]
		let name = a:side.'_'.sec.'_'.a:status
		let items = s:get_items(data)
		if items != ''
			let parts = [s:get_hl(name,items),s:get_hl(name.'sep',cfg.sep)] 
			call s:rev_arr(a:side,'right',parts)
			call add(result,join(parts,''))
			call s:exec_hl(name, data.highlight, prev_bg)
			let prev_bg = data.highlight.bg
		endif
	endfor
	call s:rev_arr(a:side,'left',result)
	return join(result,'')
endfunction

function! s:rev_arr(side,cond,arr)
	if a:side ==# a:cond | call reverse(a:arr) | endif
endfunction

function! s:get_hl(name,val) abort
	return '%#'.a:name.'#'.a:val.'%*'
endfunction

function! s:exec_hl(name, hl, sep_bg) abort
	execute printf('highlight %s guifg=%s guibg=%s', a:name, a:hl.fg, a:hl.bg)
	execute printf('highlight %ssep guifg=%s guibg=%s', a:name, a:hl.bg, a:sep_bg)
endfunction

function! s:get_items(data) abort
	let arr = map(copy(a:data.items), 's:get_item_val(v:val)')
	return join(filter(arr, 'trim(v:val) != ""'), '')
endfunction

function! s:get_item_val(item) abort
	let m = {
		\ 'mode': get(s:mode_map, mode(), 'UNKNOWN'),
		\ 'fileName': expand('%:t') ==# '' ? '[No Name]' : expand('%:t'),
		\ 'fileType': '%{&filetype}',
		\ 'filePath': expand('%:p:h'),
		\ 'windowNumber': '%{winnr()}',
		\ 'modified': &modified ? 'Modified [+]' : 'No Changes',
		\ 'gitStats': s:get_git_stats()
		\ }
	return ' '.get(m,a:item,'').' '
endfunction

augroup jostline_colorscheme
  autocmd!
  autocmd ColorScheme * call s:init_theme()
augroup END
