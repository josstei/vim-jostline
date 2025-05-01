if exists('g:loaded_jostline')
	finish
endif
let g:loaded_jostline = 1

augroup jostline_init
	autocmd!
	autocmd VimEnter * call jostline#init()
augroup END

augroup jostline_git
  autocmd!
  autocmd VimEnter,BufWritePost,BufReadPost * call jostline#git#refresh_git_stats()
augroup END

augroup jostline_colorscheme
  autocmd!
  autocmd ColorScheme * call jostline#theme#init_theme()
augroup END
