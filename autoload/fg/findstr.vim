let s:obj = g:fg#base#object.new()

function! fg#findstr#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#findstr#new() abort
  return deepcopy(s:obj)
endfunction

" method
