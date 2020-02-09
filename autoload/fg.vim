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
let s:Filepath     = s:V.import('System.Filepath')
let s:TOML         = s:V.import('Text.TOML')
let s:List         = s:V.import('Data.List')
let s:String       = s:V.import('Data.String')
let s:OrderedSet   = s:V.import('Data.OrderedSet')
let s:Arg          = s:V.import('ArgumentParser')
let s:AsyncProcess = s:V.import('Async.Promise.Process')

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

" " from grep.vim
" function! fg#grep(cmd, grep, action, ...) abort
"   if a:0 > 0 && (a:1 ==# '-?' || a:1 ==# '-h')
"     echo 'Usage: ' . a:cmd . ' [<options>] [<search_pattern> ' .
"    \ '[<file_name(s)>]]'
"     return
"   endif
"
"   " Parse the arguments and get the grep options, search pattern
"   " and list of file names/patterns
"   let [opts, pattern, filenames] = s:parseArgs(a:grep, a:000)
"
"   " Get the identifier and file list from user
"   if pattern == ''
"     let pattern = input('Search for pattern: ', expand('<cword>'))
"     if pattern == ''
"       return
"     endif
"     echo "\r"
"   endif
"
"   " file and recursive re-implement
"
"   " Form the complete command line and run it
"   let cmd = s:formFullCmd(a:grep, opts, pattern, filenames)
"   call s:runGrepCmd(cmd, pattern, a:action)
" endfunction

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

" function! s:parseArgs(program, args)
"   let cmdopt = ''
"   let pattern = ''
"   let filepattern = ''
"
"   " re-implement arg parse
"
"   return [cmdopt, pattern, filepattern]
" endfunction
"
" function! s:formFullCmd(program, opts, pattern, filenames)
"   let fullcmd = ''
"
"   " re-implement command build
"
"   return fullcmd
" endfunction
"
" function! s:runGrepCmd(cmd, pattern, action)
"   " if need cmd setup
"   "
"   "
"   if s:AsyncProcess.is_available()
"     " Asynchronous operations using Process Promise
"   else
"     " Fallback into synchronous operations
"   endif
"   if s:Job.is_available()
"     return s:runGrepCmdAsync(a:cmd, a:pattern, a:action)
"   else
"     let cmd_output = s:runGrepCmdSync(a:cmd, a:pattern, a:action)
"
"     if cmd_output == ''
"       call s:warnMsg('Error: Pattern ' . a:pattern . ' not found')
"       return
"     endif
"
"     " Open the grep output window
"     if v:true
"       " Open the quickfix window below the current window
"       botright copen
"     endif
"   endif
" endfunction
"
" let s:current_job = v:null
" function! s:on_stdout(data) abort dict
"   " Check whether the quickfix list is still present
"     let l = getqflist({'id' : self['qf_id']})
"     if !has_key(l, 'id') || l.id == 0
"       " Quickfix list is not present. Stop the search.
"       call s:current_job.stop()
"       return
"     endif
"
"     let datalist = split(a:data[0], '\n')
"     call setqflist([], 'a', {'id' : self.['qf_id'],
"    \ 'lines' : datalist})
"
"     " if support efm
"     "\ 'efm' : '%f:%\\s%#%l:%c:%m,%f:%\s%#%l:%m',
" endfunction
"
" function! s:on_stderr(data) abort dict
"   " not support?
" endfunction
"
" function! s:on_exit(exitval) abort dict
"   let self.exit_status = a:exitval
"
"   if v:true
"     botright copen
"   endif
" endfunction
"
" " runGrepCmdAsync()
" " Run the grep command asynchronously
" function! s:runGrepCmdAsync(cmd, pattern, action) abort
"   let qf = v:false
"   if a:action ==? 'set'
"     let qf = v:true
"   endif
"
"   if !s:current_job
"     call s:current_job.stop()
"     caddexpr '[Search command interrupted]'
"     let s:current_job = v:null
"   endif
"
"   let title = '[Search results for ' . a:pattern . ']'
"   if qf | call setqflist([], 'r') | endif
"   caddexpr title . "\n"
"   "caddexpr 'Search cmd: "' . a:cmd . '"'
"   call setqflist([], 'a', {'title' : title})
"   " Save the quickfix list id, so that the grep output can be added to
"   " the correct quickfix list
"   let l = getqflist({'id' : 0})
"   if has_key(l, 'id')
"     let qf_id = l.id
"   else
"     let qf_id = -1
"   endif
"
"   " need cmd
"   let s:current_job = s:Job.start(cmd , {
"  \ 'stdout': [''],
"  \ 'stderr': [''],
"  \ 'exit_status': -1,
"  \ 'qf_id': qf_id,
"  \ 'on_stdout': function('on_stdout'),
"  \ 'on_stderr': function('on_stderr'),
"  \ 'on_exit': function('on_exit'),
"  \})
"
"   if s:current_job.status() ==# 'dead'
"     let s:current_job = v:null
"     call s:warnMsg('Error: Failed to start the grep command')
"     return
"   endif
" endfunction
"
" function! s:warnMsg(msg) abort
"   echohl WarningMsg
"   echomsg a:msg
"   echohl None
" endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
