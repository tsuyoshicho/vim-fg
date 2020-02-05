"=============================================================================
" File: vim-fg
" Author: Tsuyoshi CHO
" Created: 2020-02-05
"=============================================================================

scriptencoding utf-8

if !exists('g:loaded_vim_fg')
    finish
endif
let g:loaded_vim_fg = 1

let s:save_cpo = &cpo
set cpo&vim

let s:config_dir = expand('<sfile>:h:h').'/config/fg'
let s:config_file = s:config_dir . '/settings.toml'

let s:config = {}

let s:V = vital#fg#new()
let s:Filepath = s:V.import('System.Filepath')
let s:TOML = s:V.import('Text.TOML')

function fg#enter() abort
  " load toml config
  let s:config = s:TOML.parse_file(s:config_file)
  call s:init()
endfunction

function fg#dump() abort
  return s:config
endfunction

function fg#new(name) abort
  let name = a:name
  if exists("*fg#{name}#new")
    return fg#{name}#new()
  else
    throw 'not configured'
  endif
endfunction

function s:init() abort
  if !has_key(s:config,'tool')
    throw 'config file error'
  endif
  for item in s:config.tool
    let name = item.name
    if exists("*fg#{name}#init")
      call fg#{name}#init(item)
    endif
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
