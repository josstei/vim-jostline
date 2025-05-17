function! jostline#render#build() abort
	let status = win_getid() == g:statusline_winid ? 'active' : 'inactive'
  return s:render_side('left', status)
		\ . s:get_hl('jostline_gap_'.status, '%=')
		\ . s:render_side('right', status)
endfunction

function! s:render_side(side, status) abort
	let cfg = deepcopy(jostline#core#get_cfg()[a:side])
	let secs = sort(filter(keys(cfg), 'v:val =~# "^section_\\d\\+$"'))
	call s:rev_arr(a:side, 'left', secs)

	let result = []
	let prev_bg =  jostline#theme#get_gap_bg()

	let loop_secs = a:side ==# 'right' ? reverse(copy(secs)) : secs
	for sec in loop_secs
		let data = cfg[sec][a:status]
		let name = a:side.'_'.sec.'_'.a:status
		let items = s:get_items(data,cfg.subsep)
		if items != ''
			let parts = [s:get_hl(name, items),
			\ s:get_hl(name.'sep', cfg.sep)]
			call s:rev_arr(a:side, 'right', parts)
			call add(result, join(parts, ''))
			call s:exec_hl(name, data.highlight, prev_bg)
			let prev_bg = data.highlight.bg
		endif
	endfor
	call s:rev_arr(a:side, 'left', result)
	return join(result, '')
endfunction

function! s:rev_arr(side, cond, arr)
	if a:side ==# a:cond
		call reverse(a:arr)
	endif
endfunction

function! s:get_hl(name, val) abort
	return '%#'.a:name.'#'.a:val.'%*'
endfunction

function! s:exec_hl(name, hl, sep_bg) abort
	execute printf('highlight %s guifg=%s guibg=%s gui=bold cterm=bold', a:name, a:hl.fg, a:hl.bg)
	execute printf('highlight %ssep guifg=%s guibg=%s gui=bold cterm=bold', a:name, a:hl.bg, a:sep_bg)
endfunction

function! s:get_items(data,subsep) abort
	let arr = map(copy(a:data.items), 's:get_item_val(v:val)')
	let result = filter(arr, 'trim(v:val) != ""')
	let l:subsep = len(result) > 1 ? a:subsep : ''
	return join(result, l:subsep)
endfunction

" autoload/jostline/render.vim
function! s:get_item_val(item) abort
	let m = {
		\ 'mode':        get(jostline#core#get_mode_map(), mode(), 'UNKNOWN'),
		\ 'fileName':    expand('%:t') ==# '' ? '[No Name]' : expand('%:t'),
		\ 'fileType':    &filetype,
		\ 'filePath':    expand('%:p:h'),
		\ 'windowNumber':'%{winnr()}',
		\ 'readonly':    &readonly     ? '🔒' : '',
		\ 'modified':&modified     ? 'Modified' : '',
		\ 'cursorPos':   printf('%d:%d', line('.'), col('.')),
		\ 'percentage':  printf('%d%%', (line('.') * 100) / max([1, line('$')])),
		\ 'fileEncoding':&fileencoding,
		\ 'fileFormat':  &fileformat,
		\ 'lineCount':   line('$'),
		\ 'gitStats':    jostline#git#get_git_stats(),
		\ }
	return (has_key(m, a:item) ? ' '.m[a:item] : '')
endfunction

