![Stable](https://img.shields.io/badge/status-stable-brightgreen) ![License](https://img.shields.io/badge/license-MIT-blue)

# vim-jostline

A fast, lightweight, and highly customizable statusline plugin for Vim (compatible with Vim 8+ and Vim 9). vim-jostline enhances your Vim experience by providing dynamic, informative, and visually appealing statusline updates.

---

## 🚀 Key Features

- ✅ **Automatic setup**: Initializes automatically on startup.
- ✅ **Git integration**: Displays current branch and file diff stats (`+added -removed`).
- ✅ **Dynamic theming**: Matches your Vim colorscheme automatically.
- ✅ **Customizable layout**: Easily configure the order and content of your statusline sections.
- ✅ **No dependencies**: Pure Vimscript implementation for fast performance.

---

## 📥 Installation

### Using vim-plug (Recommended)

Add to your `.vimrc`:

```vim
call plug#begin('~/.vim/plugged')
Plug 'josstei/vim-jostline'
call plug#end()
```

Then reload Vim and run:

```vim
:PlugInstall
```

### Using Pathogen

Clone directly into your Vim bundles:

```bash
cd ~/.vim/bundle
git clone https://github.com/josstei/vim-jostline.git
```

---

## 📋 Setup Requirements

For optimal experience, ensure your Vim supports true colors:

```vim
if has('termguicolors')
  set termguicolors
endif
```

---

## ⚙️ Customization Guide

vim-jostline is fully customizable via global Vim variables within your `.vimrc`

### Separators

You can customize visual separators for clarity and aesthetics:

| Variable              | Default | Description                |
|-----------------------|---------|----------------------------|
| `g:left_separator`    | ``     | Separator on the left side |
| `g:right_separator`   | ``     | Separator on the right side|
| `g:left_subseparator` | `|`     | Subsection separator (left)|
| `g:right_subseparator`| `|`     | Subsection separator (right)|

Example:

```vim
let g:left_separator       = '▶'
let g:right_separator      = '◀'
let g:left_subseparator    = '|'
let g:right_subseparator   = '|'
```

### Statusline Sections

Sections are organized using global variables with the format:

```vim
g:jostline_<side>_section_<number>_<status>
```

- `<side>`: `left` or `right`
- `<number>`: order of sections (`1`, `2`, ...)
- `<status>`: `active` (focused window) or `inactive` (unfocused window)

#### Items Available:

- `mode`: Vim mode (e.g., NORMAL, INSERT)
- `fileName`: Name of the current file
- `fileType`: File type (`&filetype`)
- `filePath`: Path of the current file
- `windowNumber`: Window number in Vim
- `modified`: Shows `[+]` if the file has unsaved changes
- `gitStats`: Current Git branch and diff stats

Example Configuration:

```vim
" Left Section
let g:jostline_left_section_1_active = { 'items': ['windowNumber'], 'highlight': {'fg': '#000000','bg': '#c678dd'}}
let g:jostline_left_section_2_active = { 'items': ['mode'], 'highlight': {'fg': '#ffffff','bg': '#4b2a55'}}
let g:jostline_left_section_3_active = { 'items': ['gitStats'], 'highlight': {'fg': '#ffffff','bg': '#333333'}}
let g:jostline_left_section_4_active = { 'items': ['fileName'], 'highlight': {'fg': '#000000','bg': '#c678dd'}}

" Right Section
let g:jostline_right_section_1_active = { 'items': ['fileType'], 'highlight': {'fg': '#000000','bg': '#c678dd'}}
let g:jostline_right_section_2_active = { 'items': ['modified'], 'highlight': {'fg': '#ffffff','bg': '#4b2a55'}}

```

---

## 🎨 Built-in Theme Support

vim-jostline automatically recognizes and matches colors with popular themes:

- **Dark Themes**:
  - gruvbox
  - nord
  - onedark
  - dracula
  - solarized_dark
  - monokai
  - everforest
  - catppuccin ( mocha, latte, frappe, macchiato)

- **Light Themes**:
  - papercolor_light

## 📝 License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for full details.
