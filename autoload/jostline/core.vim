let s:mode_map = {
	\ 'n':'NORMAL','i':'INSERT','R':'REPLACE','v':'VISUAL','V':'VISUAL LINE','^V':'VISUAL BLOCK',
	\ 'c':'COMMAND','C':'COMMAND-LINE','s':'SELECT','S':'SELECT LINE','t':'TERMINAL','nI':'NORMAL INSERT',
	\ 'N':'INSERT NORMAL','N:':'NORMAL EX','iN':'INSERT NORMAL','p':'PREVIEW','l':'LITERAL','R?':'REPLACE MODE',
	\ 'o':'OPERATOR-PENDING','O':'OPERATOR PENDING','r':'REPEAT','a':'ARGUMENT'}

let s:sl_cfg = {}

function! jostline#core#get_cfg()
	return s:sl_cfg
endfunction

function! s:set_cfg(side, cfg)
	let s:sl_cfg[a:side] = a:cfg
endfunction

function! jostline#core#init_cfg() abort
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
		call s:set_cfg(side, cfg)
	endfor
endfunction

function! jostline#core#get_mode_map() abort
	return s:mode_map
endfunction

