let s:obj = {}

function! s:obj.new() abort
  return deepcopy(self)
endfunction

function! s:obj.init(item) abort
  let self['config'] = item
endfunction

let g:fg#base#object = s:obj
unlet s:obj
