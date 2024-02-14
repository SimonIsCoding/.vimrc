set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'sainnhe/vim-color-forest-night'
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this linesyntax enable

" Important!!
        if has('termguicolors')
          set termguicolors
        endif

        " For dark version.
        set background=dark

		let g:lightline = {'colorscheme' : 'everforest'}

        " For light version.
        "set background=light

        " Set contrast.
        " This configuration option should be placed before `colorscheme everforest`.
        " Available values: 'hard', 'medium'(default), 'soft'
        let g:everforest_background = 'hard'

        " For better performance
        let g:everforest_better_performance = 1 
		"let g:everforest_diagnostic_text_highlight = 1
		let g:everforest_highlight = 1
		let g:everforest_disable_italic_comment = 1


colorscheme everforest


syntax on
set mouse=a
set number
set cursorline
runtime! ftplugin/man.vim
set colorcolumn=81
set tabstop=4
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent
set noexpandtab
set smarttab
set nowrap
set noswapfile
set termguicolors
set fileformat=unix
set encoding=UTF-8
set ruler
set wildmenu
"autocmd BufNewFile * :setlocal noswapfile | put =''
"autocmd BufNewFile * :setlocal noswapfile | :0put =''

inoremap <c-x> <Esc>:Lex<cr>:vertical resize 23<cr>
nnoremap <c-x> <Esc>:Lex<cr>:vertical resize 23<cr>
vnoremap <C-C> "*y
nnoremap <C-V> "*p
"nnoremap <c-a> :below term<cr><cr>
vnoremap <C-w> :s/^/\/\//<CR>gv
vnoremap <C-e> :s/^\/\/\s*//<CR>gv

