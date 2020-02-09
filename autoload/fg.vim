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
let s:String     = s:V.import('Data.String')
let s:OrderedSet = s:V.import('Data.OrderedSet')
let s:Arg        = s:V.import('ArgumentParser')
let s:Job        = s:V.import('System.Job')

let s:config = {}
let s:prio = s:OrderedSet.new()
let s:instance = {}

" API function
function! fg#dump() abort
  return [s:config, s:prio.to_list(), s:instance]
endfunction

function! fg#enter() abort
  " load toml config
  let s:config = s:TOML.parse_file(s:config_file)
  " call init (exec check, static instance create)
  call s:init()
  " call command define
endfunction

function! fg#new(...) abort
  let name = s:prio.to_list()[0]
  if a:0 > 0
    let name = a:1
  endif
  return s:new(name)
endfunction

" from grep.vim
function! fg#grep(cmd, grep, action, ...) abort
  if a:0 > 0 && (a:1 ==# '-?' || a:1 ==# '-h')
    echo 'Usage: ' . a:cmd . ' [<options>] [<search_pattern> ' .
    \ '[<file_name(s)>]]'
    return
  endif

  " Parse the arguments and get the grep options, search pattern
  " and list of file names/patterns
  let [opts, pattern, filenames] = s:parseArgs(a:grep, a:000)

  " Get the identifier and file list from user
  if pattern == ''
    let pattern = input('Search for pattern: ', expand('<cword>'))
    if pattern == ''
      return
    endif
    echo "\r"
  endif

  if empty(filenames) && !s:recursiveSearchCmd(a:grep)
    let filenames = input('Search in files: ', g:Grep_Default_Filelist,
    \ 'file')
    if filenames == ''
      return
    endif
    echo "\r"
  endif

  " Form the complete command line and run it
  let cmd = s:formFullCmd(a:grep, opts, pattern, filenames)
  call s:runGrepCmd(cmd, pattern, a:action)
endfunction

" inner function
function! s:init() abort
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

function! s:new(name) abort
  if s:prio.size() == 0
    return v:null
  endif

  try
    return fg#{a:name}#new()
  catch
    throw printf('not configured:%s', a:name)
  endtry
endfunction

" parseArgs()
" Parse arguments to the grep command. The expected order for the various
" arguments is:
" 	<grep_option[s]> <search_pattern> <file_pattern[s]>
" grep command-line flags are specified using the "-flag" format.
" the next argument is assumed to be the pattern.
" and the next arguments are assumed to be filenames or file patterns.
function! s:parseArgs(cmd_name, args)
  let cmdopt = ''
  let pattern = ''
  let filepattern = ''

  " temp
  let shortrefix = ''
  let fullrefix = ''

  for one_arg in a:args
    if (s:String.starts_with(one_arg ,shortrefix)
    \   || s:String.starts_with(one_arg ,shortrefix))
    \  && empty(pattern)
      " Process grep arguments at the beginning of the argument list
      let cmdopt = cmdopt . ' ' . one_arg
    elseif pattern == ''
      " Only one search pattern can be specified
      let pattern = one_arg
    else
      " More than one file patterns can be specified
      if filepattern != ''
        let filepattern = filepattern . ' ' . one_arg
      else
        let filepattern = one_arg
      endif
    endif
  endfor

  return [cmdopt, pattern, filepattern]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
