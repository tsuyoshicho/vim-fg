let s:obj = g:fg#base#object.new()

function! fg#ripgrep#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#ripgrep#new() abort
  return deepcopy(s:obj)
endfunction

" method
