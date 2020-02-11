"=============================================================================
" File: vim-fg
" Author: Tsuyoshi CHO
" Created: 2020-02-05
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_vim_fg')
    finish
endif
let g:loaded_vim_fg = 1

let s:save_cpo = &cpo
set cpo&vim

let g:fg#priority = get(g:, 'fg#priority', [])
let g:fg#param = get(g: ,'fg#param', {})
let g:fg#async = get(g: ,'fg#async', 1)
let g:fg#prefix = get(g: ,'fg#prefix', 'Fg')

augroup vim-fg-init
  autocmd!
  autocmd VimEnter * call fg#enter() | autocmd! vim-fg-init
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
