let s:obj = g:fg#base#object.new()

function! fg#ag#init(item) abort
  call s:obj.init(item)
endfunction

function! fg#ag#new() abort
  return deepcopy(s:obj)
endfunction

" method
