let s:obj = g:fg#base#object.new()

function! fg#rg#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#rg#new() abort
  return deepcopy(s:obj)
endfunction

" method
