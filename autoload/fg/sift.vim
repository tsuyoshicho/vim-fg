let s:obj = g:fg#base#object.new()

function! fg#sift#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#sift#new() abort
  return deepcopy(s:obj)
endfunction

" method
