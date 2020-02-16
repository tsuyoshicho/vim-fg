let s:obj = g:fg#base#object.new()

function! fg#jvgrep#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#jvgrep#new() abort
  return deepcopy(s:obj)
endfunction

" method
