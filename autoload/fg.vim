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
"  command FgXx
"  Todo
"   - efm support
"   - search file pattern
"   - recursive?
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
    echo 'nothing grep program'
    return
  endif
  let name = s:prio.to_list()[0]

  call s:grep(name, '', {}, {})
endfunction

function! s:grep(cmd, pattern, opt, args) abort
  let pattern = a:pattern
  if empty(pattern)
    let pattern = input('Search for pattern: ', expand('<cword>'))
    if pattern == ''
      return
    endif
  endif

  let grep = s:instance[a:cmd]
  " echomsg 'grep obj:' grep

  let cmd = grep.getSearchCmd(a:opt)
  let cmd = extend(cmd, [pattern, '.']) " temp fix current dir

  " echomsg 'cmd:' cmd

  if get(g: ,'fg#async', 1) && s:AsyncProcess.is_available()
    " echomsg 'search async'
    let result = s:AsyncProcess.start(cmd).then({v -> s:asyncResult(grep,v)})
    " echomsg 'async promise:' result
  else
    " echomsg 'search sync'
    let result = s:Process.execute(cmd, {
    \  'split_output' : 1,
    \})
    call s:syncResult(grep,result)
  endif
endfunction

" inner function
function! s:init() abort
  if !has_key(s:config,'tool')
    throw 'config file error'
  endif
  for item in s:config.tool
    let item['global'] = deepcopy(get(s:config, 'global', {}))
    let item.executable = executable(item.command)
    if item.executable
      try
        " first time direct call need
        call fg#{item.name}#init(item)
      catch
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

function! s:asyncResult(grep,value) abort
  " echomsg 'grep:' a:grep
  " echomsg 'async:' a:value
  call s:resultSet(a:value.args[0], a:value.args[-2], a:value.stdout,
  \ get(a:grep.config.opt,'grepformat', v:null))
endfunction

function! s:syncResult(grep,value) abort
  " echomsg 'grep:' a:grep
  " echomsg 'sync:' a:value
  call s:resultSet(a:value.args[0], a:value.args[-2], a:value.content,
  \ get(a:grep.config.opt,'grepformat', v:null))
endfunction

function! s:resultSet(cmd, pattern, result, efm) abort
  " clear qf
  call setqflist([], 'r')

  let title = '[Search results for ' . a:pattern . ']'
  caddexpr title . "\n"
  "caddexpr 'Search cmd: "' . a:cmd . '"'
  call setqflist([], 'a', {'title' : title})

  " echomsg 'result:' a:result
  " echomsg 'efm:' a:efm
  if !a:efm
    call setqflist([], 'a', { 'efm' : a:efm})
  endif
  let result = s:List.map(a:result, {v -> substitute(v, '\r', '', '')})
  call setqflist([], 'a', { 'lines' : result})

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

  call s:parser.add_argument('--word', 'word target', {
  \ 'type': s:ArgumentParser.types.choice,
  \ 'choices': ['regex', 'pattern'],
  \ 'default': 'regex',
  \})

  call s:parser.add_argument('--case', 'case type', {
  \ 'type': s:ArgumentParser.types.choice,
  \ 'choices': ['smart', 'ignore', 'none'],
  \ 'default': 'smart',
  \})

  " command mapping default
  let prefix = get(g: ,'fg#prefix', 'Fg')
  execute 'command! -nargs=? -range=% -bang -complete=customlist,<SID>complete'
  \ . ' ' . prefix . ' '
  \ . ':call <SID>grepbind('
  \ . "'" . s:prio.to_list()[0] . "'"
  \ . ', <q-bang>, [<line1>, <line2>], <f-args>)'
  " per command
  for item in values(s:instance)
    let cmdPrefix = item.config.symbol
    let cmdName = item.config.name
    execute 'command! -nargs=? -range=% -bang -complete=customlist,<SID>complete'
    \ . ' ' . prefix . cmdPrefix . ' '
    \ . ':call <SID>grepbind('
    \ . "'" . cmdName . "'"
    \ . ', <q-bang>, [<line1>, <line2>], <f-args>)'
  endfor
endfunction

function! s:grepbind(cmd, ...) abort
  let args = call(s:parser.parse, a:000, s:parser)
  if empty(args)
    " help
    return
  endif

  " echomsg a:cmd args

  let unknown = get(args, '__unknown__', [])
  let pattern = len(unknown) == 1 ? unknown[0] : ''
  let opt = {}
  let opt['word'] = get(args, 'word', 'regex')
  let opt['case'] = get(args, 'case', 'none')

  call s:grep(a:cmd, pattern, opt, args)
endfunction

function! s:complete(...) abort
  return call(s:parser.complete, a:000, s:parser)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
