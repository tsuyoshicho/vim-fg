" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_fg#System#Filepath#import() abort', printf("return map({'path_separator': '', 'is_case_tolerant': '', 'dirname': '', 'abspath': '', 'relpath': '', 'realpath': '', 'unify_separator': '', 'to_slash': '', 'is_root_directory': '', 'split': '', 'path_extensions': '', 'unixpath': '', 'which': '', 'winpath': '', 'from_slash': '', 'join': '', 'separator': '', 'is_relative': '', 'basename': '', 'remove_last_separator': '', 'is_absolute': '', 'contains': ''}, \"vital#_fg#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
" You should check the following related builtin functions.
" fnamemodify()
" resolve()
" simplify()

let s:save_cpo = &cpo
set cpo&vim

let s:path_sep_pattern = (exists('+shellslash') ? '[\\/]' : '/') . '\+'

" See https://github.com/vim-jp/vital.vim/wiki/Coding-Rule#how-to-check-if-the-runtime-os-is-windows
let s:is_windows = has('win32')

let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))
let s:is_case_tolerant = filereadable(expand('<sfile>:r') . '.VIM')

if s:is_windows
  function! s:to_slash(path) abort
    return tr(a:path, '\', '/')
  endfunction
else
  function! s:to_slash(path) abort
    return a:path
  endfunction
endif

if s:is_windows
  function! s:from_slash(path) abort
    return tr(a:path, '/', '\')
  endfunction
else
  function! s:from_slash(path) abort
    return a:path
  endfunction
endif


" Get the directory separator.
function! s:separator() abort
  return fnamemodify('.', ':p')[-1 :]
endfunction

" Get the path separator.
let s:path_separator = s:is_windows ? ';' : ':'
function! s:path_separator() abort
  return s:path_separator
endfunction

" Get the path extensions
function! s:path_extensions() abort
  if !exists('s:path_extensions')
    if s:is_windows
      if exists('$PATHEXT')
        let pathext = $PATHEXT
      else
        " get default PATHEXT
        let pathext = matchstr(system('set pathext'), '\C^pathext=\zs.*\ze\n', 'i')
      endif
      let s:path_extensions = map(split(pathext, s:path_separator), 'tolower(v:val)')
    elseif s:is_cygwin
      " cygwin is not use $PATHEXT
      let s:path_extensions = ['', '.exe']
    else
      let s:path_extensions = ['']
    endif
  endif
  return s:path_extensions
endfunction

" Convert all directory separators to "/".
function! s:unify_separator(path) abort
  return substitute(a:path, s:path_sep_pattern, '/', 'g')
endfunction

" Get the full path of command.
if exists('*exepath')
  function! s:which(str) abort
    return exepath(a:str)
  endfunction
else
  function! s:which(command, ...) abort
    let pathlist = a:command =~# s:path_sep_pattern ? [''] :
    \              !a:0                  ? split($PATH, s:path_separator) :
    \              type(a:1) == type([]) ? copy(a:1) :
    \                                      split(a:1, s:path_separator)

    let pathext = s:path_extensions()
    if index(pathext, '.' . tolower(fnamemodify(a:command, ':e'))) != -1
      let pathext = ['']
    endif

    let dirsep = s:separator()
    for dir in pathlist
      let head = dir ==# '' ? '' : dir . dirsep
      for ext in pathext
        let full = fnamemodify(head . a:command . ext, ':p')
        if filereadable(full)
          if s:is_case_tolerant()
            let full = glob(substitute(
            \               toupper(full), '\u:\@!', '[\0\L\0]', 'g'), 1)
          endif
          if full !=# ''
            return full
          endif
        endif
      endfor
    endfor

    return ''
  endfunction
endif

" Split the path with directory separator.
" Note that this includes the drive letter of MS Windows.
function! s:split(path) abort
  return split(a:path, s:path_sep_pattern)
endfunction

" Join the paths.
" join('foo', 'bar')            => 'foo/bar'
" join('foo/', 'bar')           => 'foo/bar'
" join('/foo/', ['bar', 'buz/']) => '/foo/bar/buz/'
function! s:join(...) abort
  let sep = s:separator()
  let path = ''
  for part in a:000
    let path .= sep .
    \ (type(part) is type([]) ? call('s:join', part) :
    \                           part)
    unlet part
  endfor
  return substitute(path[1 :], s:path_sep_pattern, sep, 'g')
endfunction

" Check if the path is absolute path.
if s:is_windows
  function! s:is_absolute(path) abort
    return a:path =~# '^[a-zA-Z]:[/\\]'
  endfunction
else
  function! s:is_absolute(path) abort
    return a:path[0] ==# '/'
  endfunction
endif

function! s:is_relative(path) abort
  return !s:is_absolute(a:path)
endfunction

" Return the parent directory of the path.
" NOTE: fnamemodify(path, ':h') does not return the parent directory
" when path[-1] is the separator.
function! s:dirname(path) abort
  let path = a:path
  let orig = a:path

  let path = s:remove_last_separator(path)
  if path ==# ''
    return orig    " root directory
  endif

  let path = fnamemodify(path, ':h')
  return path
endfunction

" Return the basename of the path.
" NOTE: fnamemodify(path, ':h') does not return basename
" when path[-1] is the separator.
function! s:basename(path) abort
  let path = a:path
  let orig = a:path

  let path = s:remove_last_separator(path)
  if path ==# ''
    return orig    " root directory
  endif

  let path = fnamemodify(path, ':t')
  return path
endfunction

" Remove the separator at the end of a:path.
function! s:remove_last_separator(path) abort
  let sep = s:separator()
  let pat = escape(sep, '\') . '\+$'
  return substitute(a:path, pat, '', '')
endfunction


" Return true if filesystem ignores alphabetic case of a filename.
" Return false otherwise.
function! s:is_case_tolerant() abort
  return s:is_case_tolerant
endfunction


function! s:abspath(path) abort
  if s:is_absolute(a:path)
    return a:path
  endif
  " Note:
  "   the behavior of ':p' for non existing file path/directory is not defined
  return (filereadable(a:path) || isdirectory(a:path))
        \ ? fnamemodify(a:path, ':p')
        \ : s:join(fnamemodify(getcwd(), ':p'), a:path)
endfunction

function! s:relpath(path) abort
  if s:is_relative(a:path)
    return a:path
  endif
  return fnamemodify(a:path, ':~:.')
endfunction

function! s:unixpath(path) abort
  return fnamemodify(a:path, ':gs?\\?/?')
endfunction

function! s:winpath(path) abort
  return fnamemodify(a:path, ':gs?/?\\?')
endfunction

if s:is_windows
  function! s:realpath(path) abort
    if exists('&shellslash') && &shellslash
      return s:unixpath(a:path)
    else
      return s:winpath(a:path)
    endif
  endfunction
else
  function! s:realpath(path) abort
    return s:unixpath(a:path)
  endfunction
endif

if s:is_windows
  function! s:is_root_directory(path) abort
    return a:path =~# '^[a-zA-Z]:[/\\]$'
  endfunction
else
  function! s:is_root_directory(path) abort
    return a:path ==# '/'
  endfunction
endif

function! s:contains(path, base) abort
  if a:path ==# '' || a:base ==# ''
    return 0
  endif
  let pathlist = s:split(a:path)
  let baselist = s:split(a:base)
  let pathlistlen = len(pathlist)
  let baselistlen = len(baselist)
  if pathlistlen < baselistlen
    return 0
  endif
  if baselistlen == 0
    return 1
  endif
  if s:is_case_tolerant
    call map(pathlist, 'tolower(v:val)')
    call map(baselist, 'tolower(v:val)')
  endif
  return pathlist[: baselistlen - 1] ==# baselist
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
