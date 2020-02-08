let s:obj = g:fg#base#object.new()

function! fg#pt#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#pt#new() abort
  return deepcopy(s:obj)
endfunction

" method
