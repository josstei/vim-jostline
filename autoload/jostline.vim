function! jostline#init() abort
	call jostline#core#init_cfg()
	call jostline#theme#init_theme()
	set statusline=%!jostline#render#build()
endfunction

