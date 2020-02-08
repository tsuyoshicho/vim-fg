"=============================================================================
" File: vim-fg
" Author: Tsuyoshi CHO
" Created: 2020-02-05
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" coding note
"  init in VimEnter
"   load config
"   check executable with prioriy
"   call init per custom init code
"   create static instance
"
" usage memo
" let grep = fg#new() or fg#new('pt')
" (if not support or no exist command return v:null)
" call grep.search('word') result to quickfix
" let &grepprg = grep.getGrepPrg(param)
" let comand = grep.getGrepComand(param)
" let comand = grep.getFilelistCommand(param)
" simply support fg#getXxx redirect high prio instans same method

let s:config_dir = expand('<sfile>:h:h').'/config/fg'
let s:config_file = s:config_dir . '/settings.toml'

let s:V = vital#fg#new()
let s:Filepath   = s:V.import('System.Filepath')
let s:TOML       = s:V.import('Text.TOML')
let s:List       = s:V.import('Data.List')
let s:OrderedSet = s:V.import('Data.OrderedSet')

let s:config = {}
let s:prio = s:OrderedSet.new()
let s:instance = {}

function fg#dump() abort
  return [s:config, s:prio.to_list(), s:instance]
endfunction

function fg#enter() abort
  " load toml config
  let s:config = s:TOML.parse_file(s:config_file)
  " call init (exec check, static instance create)
  call s:init()
  " call command define
endfunction

function s:init() abort
  if !has_key(s:config,'tool')
    throw 'config file error'
  endif
  for item in s:config.tool
    let name = item.name
    let item.executable = executable(name)
    if item.executable
      try
        " first time direct call need
        call fg#{name}#init(item)
      endtry
    endif
  endfor

  let prio_list = get(g:, 'fg#priority', [])
  call s:List.map(prio_list, {v -> s:prio.push(v)})
  call s:List.map(s:config.tool, {v -> !v.executable && s:prio.remove(v.name)})
  call s:List.map(s:config.tool, {v -> v.executable && s:prio.push(v.name)})

  let greplist = s:prio.to_list()
  for name in greplist
    let s:instance[name] = s:new(name)
  endfor
endfunction

function fg#new(...) abort
  let name = s:prio.to_list()[0]
  if a:0 > 0
    let name = a:1
  endif
  return s:new(name)
endfunction

function s:new(name) abort
  if s:prio.size() == 0
    return v:null
  endif

  try
    return fg#{a:name}#new()
  catch
    throw printf('not configured:%s', a:name)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
