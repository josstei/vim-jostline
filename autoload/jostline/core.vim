let s:mode_map = {
	\ 'n':'NORMAL','i':'INSERT','R':'REPLACE','v':'VISUAL','V':'VISUAL LINE','^V':'VISUAL BLOCK',
	\ 'c':'COMMAND','C':'COMMAND-LINE','s':'SELECT','S':'SELECT LINE','t':'TERMINAL','nI':'NORMAL INSERT',
	\ 'N':'INSERT NORMAL','N:':'NORMAL EX','iN':'INSERT NORMAL','p':'PREVIEW','l':'LITERAL','R?':'REPLACE MODE',
	\ 'o':'OPERATOR-PENDING','O':'OPERATOR PENDING','r':'REPEAT','a':'ARGUMENT'}

let s:separator_default = 'bar'
let s:subseparator_default = 'dot'
let s:separator_map = {
      \ 'rounded_left':       '', 
      \ 'rounded_right':      '',
      \ 'rounded_thin_left':  '',
      \ 'rounded_thin_right': '',
      \ 'triangle_left':      '',
      \ 'triangle_right':     '',
      \ 'triangle_bold_left': '',
      \ 'triangle_bold_right':'',
      \ 'arrow_left':         '➔',
      \ 'arrow_right':        '←',
      \ 'bar_left':           '|',
      \ 'bar_right':          '|',
      \ 'doublebar_left':     '||',
      \ 'doublebar_right':    '||',
      \ 'dot_left':           '·',
      \ 'dot_right':          '·',
      \ 'equals_left':        '=',
      \ 'equals_right':       '=',
      \ }

let s:sl_cfg = {}

function! jostline#core#get_cfg()
	return s:sl_cfg
endfunction

function! s:set_cfg(side, cfg)
	let s:sl_cfg[a:side] = a:cfg
endfunction

function! s:get_separator(var, side)
	let l:sep = get(g:, 'jostline_'.a:side.'_'.a:var, '')
	if empty(l:sep)
		let l:sep = get(g:, 'jostline_'.a:var, '')
	endif
	if empty(l:sep)
		if a:var==# 'subseparator'
			let l:sep = s:subseparator_default
		else
			let l:sep = s:separator_default
		endif
	endif
	return s:resolve_separator(l:sep, a:side)
endfunction


function! s:resolve_separator(word, side)
	let l:map = s:separator_map
	if empty(a:word)
		return a:side ==# 'left' ? '' : ''
	endif
	if a:word =~# '_\(left\|right\)$'
		let l:key = a:word
	else
		let l:key = a:word . '_' . a:side
	endif
	return get(l:map, l:key, a:word)
endfunction


function! jostline#core#init_cfg() abort
	for side in ['left','right']
		let sep = s:get_separator('separator',side)
		let subsep = s:get_separator('subseparator',side)
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
		call s:set_cfg(side, cfg)
	endfor
endfunction

function! jostline#core#get_mode_map() abort
	return s:mode_map
endfunction

