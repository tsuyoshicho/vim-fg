let s:obj = g:fg#base#object.new()

function! fg#grep#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#grep#new() abort
  return deepcopy(s:obj)
endfunction

" method
