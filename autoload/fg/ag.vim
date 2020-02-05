let s:obj = { 'config': v:null }

function fg#ag#init(config) abort
  let s:obj.config = a:config
endfunction

function fg#ag#new() abort
  if s:obj.config is# v:null
    throw 'not configured'
  endif
  return deepcopy(s:obj)
endfunction

" method
function s:obj.setGrepPrg() abort
  " setup `grepprg`
endfunction


