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
let s:Filepath       = s:V.import('System.Filepath')
let s:TOML           = s:V.import('Text.TOML')
let s:List           = s:V.import('Data.List')
let s:String         = s:V.import('Data.String')
let s:OrderedSet     = s:V.import('Data.OrderedSet')
let s:ArgumentParser = s:V.import('ArgumentParser')
let s:Process        = s:V.import('System.Process')
let s:AsyncProcess   = s:V.import('Async.Promise.Process')

" all of init in fg#enter
let s:config = {}
let s:prio = [] " s:OrderedSet.new()
let s:instance = {}
let s:parser = {} " s:ArgumentParser.new()

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
  call s:command()
endfunction

function! fg#new(...) abort
  let name = s:prio.to_list()[0]
  if a:0 > 0
    let name = a:1
  endif
  return s:new(name)
endfunction

" first impl simply
function! fg#grep() abort
  if s:prio.size() == 0
    return
  endif

  let pattern = input('Search for pattern: ', expand('<cword>'))
  if pattern == ''
    return
  endif

  let grep = s:instance[s:prio.to_list()[0]]
  " echomsg 'grep obj:' grep
  let cmd = grep.getSearchCmd()
  let cmd = extend(cmd, [pattern, '.']) " temp fix current dir
  " echomsg 'cmd:' cmd
  if get(g: ,'fg#async', 1) && s:AsyncProcess.is_available()
    " echomsg 'search async'
    let result = s:AsyncProcess.start(cmd).then({v -> s:asyncResult(v)})
    " echomsg 'async promise:' result
  else
    " echomsg 'search sync'
    let result = s:Process.execute(cmd, {
    \  'split_output' : 1,
    \})
    call s:syncResult(result)
  endif
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

  let s:prio = s:OrderedSet.new()
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

function! s:asyncResult(value) abort
  " echomsg 'async:' a:value
  call s:resultSet(a:value.args[0], a:value.args[-2], a:value.stdout)
endfunction

function! s:syncResult(value) abort
  " echomsg 'sync:' a:value
  call s:resultSet(a:value.args[0], a:value.args[-2], a:value.content)
endfunction

function! s:resultSet(cmd, pattern, result) abort
  " clear qf
  call setqflist([], 'r')

  let title = '[Search results for ' . a:pattern . ']'
  caddexpr title . "\n"
  "caddexpr 'Search cmd: "' . a:cmd . '"'
  call setqflist([], 'a', {'title' : title})

  call setqflist([], 'a', { 'lines' : a:result})
  " echomsg 'result:' a:result

  if v:true
    " Open the quickfix window below the current window
    botright copen
  endif
endfunction

function! s:command(...) abort
  " arg setup
  let s:parser = s:ArgumentParser.new({
  \ 'name': 'Fg',
  \ 'description': [
  \   'Async,multi command grep and find utility',
  \ ],
  \})

  call s:parser.add_argument('--regex', 'regular expression', {
  \ 'type': 'switch',
  \})

  " command mapping default
  command! -nargs=? -range=% -bang
  \ -complete=customlist,<SID>complete Fg
  \ :call <SID>grepbind(<q-bang>, [<line1>, <line2>], <f-args>)
  " per command
endfunction

function! s:grepbind(...) abort
  let args = call(s:parser.parse, a:000, s:parser)
  echomsg args
endfunction

function! s:complete(...) abort
  return call(s:parser.complete, a:000, s:parser)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
