let s:git_branch = ''
let s:git_diff   = ''

function! jostline#git#refresh_git_stats() abort
	let root = finddir('.git', expand('%:p:h').' ;')
	if empty(root) | return | endif
	let cwd = fnamemodify(root, ':h')
	call job_start(['git','-C',cwd,'rev-parse','--abbrev-ref','HEAD'],
		\ {'out_cb': function('s:on_branch'), 'out_mode':'nl'})
	call job_start(['git','-C',cwd,'diff','--shortstat'],
		\ {'out_cb': function('s:on_diff'), 'out_mode':'nl'})
endfunction

function! s:on_branch(job, data) abort
	if !empty(a:data)
		let s:git_branch = a:data
	endif
endfunction

function! s:on_diff(job, data) abort
	if empty(a:data)
		return
	endif
	let stats = a:data
	let ins = matchstr(stats, '\d\+\s\+insertion')
	let del = matchstr(stats, '\d\+\s\+deletion')
	let plus = ins !=# '' ? '+'.matchstr(ins, '\d\+') : ''
	let minus = del !=# '' ? '-'.matchstr(del, '\d\+') : ''
	let s:git_diff = '  '.s:git_branch.' '.plus.' '.minus
endfunction

function! jostline#git#get_git_stats() abort
	return s:git_diff
endfunction

