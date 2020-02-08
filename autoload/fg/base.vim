let s:obj = {}

function! s:obj.new() abort
  return deepcopy(self)
endfunction

function! s:obj.init(item) abort
  let self['config'] = a:item
endfunction

function! s:obj.getGrepPrg(...) abort
  let param = extend(get(g: ,'fg#grepprg#param', {}), {
  \
  \}, 'keep')

  let cmd = []
  let cmd = add(cmd, self.config.name)
  let cmd = extend(cmd, self.config.opt.set.base)
  let cmd = extend(cmd, self.config.opt.set.search)

  return join(cmd, ' ')
endfunction

let g:fg#base#object = s:obj
unlet s:obj
