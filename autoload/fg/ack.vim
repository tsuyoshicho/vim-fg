let s:obj = g:fg#base#object.new()

function! fg#ack#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#ack#new() abort
  return deepcopy(s:obj)
endfunction

" method
