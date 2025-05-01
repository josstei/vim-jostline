let s:theme_map = {
	\ 'gruvbox': [['#ebdbb2','#3c3836'],['#d5c4a1','#504945'],['#fbf1c7','#665c54'],['#fbf1c7','#7c6f64']],
	\ 'tokyonight': [['#c0caf5','#1a1b26'],['#7aa2f7','#24283b'],['#9ece6a','#414868'],['#bb9af7','#1f2335']],
	\ 'nord': [['#eceff4','#3b4252'],['#d8dee9','#434c5e'],['#a3be8c','#4c566a'],['#81a1c1','#2e3440']],
	\ 'onedark': [['#abb2bf','#282c34'],['#e5c07b','#3e4451'],['#98c379','#4b5263'],['#61afef','#21252b']],
	\ 'dracula': [['#f8f8f2','#282a36'],['#50fa7b','#44475a'],['#ff79c6','#6272a4'],['#bd93f9','#1e1f29']],
	\ 'solarized_dark': [['#839496','#002b36'],['#93a1a1','#073642'],['#b58900','#586e75'],['#268bd2','#073642']],
	\ 'catppuccin': [['#cdd6f4','#1e1e2e'],['#f38ba8','#313244'],['#a6e3a1','#45475a'],['#89b4fa','#1e1e2e']],
	\ 'everforest': [['#d3c6aa','#2f383e'],['#a7c080','#374145'],['#e67e80','#4d555b'],['#83c092','#2f383e']],
	\ 'papercolor_light': [['#000000','#eeeeee'],['#444444','#d7d7d7'],['#005f87','#ffffff'],['#870000','#eeeeee']],
	\ 'catppuccin_mocha': [['#cdd6f4','#1e1e2e'],['#f38ba8','#313244'],['#a6e3a1','#45475a'],['#89b4fa','#1e1e2e']],
	\ 'catppuccin_latte': [['#4c4f69','#eff1f5'],['#dc8a78','#e6e9ef'],['#40a02b','#ccd0da'],['#1e66f5','#eff1f5']],
	\ 'catppuccin_frappe': [['#c6d0f5','#303446'],['#e78284','#3b3f51'],['#a6d189','#51576d'],['#8caaee','#303446']],
	\ 'catppuccin_macchiato': [['#cad3f5','#24273a'],['#ed8796','#363a4f'],['#a6da95','#494d64'],['#8aadf4','#24273a']],
  \ 'monokai': [['#f8f8f2','#272822'],['#a6e22e','#3e3d32'],['#fd971f','#49483e'],['#f92672','#383830']],
\}

let s:gap_bg = ''

function! jostline#theme#init_theme() abort
	let cs = get(g:, 'colors_name', 'default')
	let theme = get(s:theme_map, cs, [])
	for idx in range(len(theme))
		let [fg,bg] = theme[idx]
		let sec = 'section_'.(idx+1)
		for side in ['left','right']
			let cfg = jostline#core#get_cfg()[side]
			if has_key(cfg, sec)
				for status in ['active','inactive']
					let cfg[sec][status].highlight = {'fg': fg, 'bg': bg}
				endfor
			endif
		endfor
	endfor
	for status in ['active','inactive']
		let cfg = jostline#core#get_cfg()
		if has_key(cfg['left'], 'section_1')
			let gap_fg = 'NONE'
			let s:gap_bg = cfg['left']['section_1'][status].highlight.bg
			let gap_name = 'jostline_gap_'.status
			execute printf('highlight %s guifg=%s guibg=%s', gap_name, gap_fg, s:gap_bg)
		endif
	endfor
endfunction

function! jostline#theme#get_gap_bg() abort
	return s:gap_bg
endfunction
