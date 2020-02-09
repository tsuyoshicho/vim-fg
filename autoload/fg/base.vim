let s:obj = {}

function! s:obj.new() abort
  return deepcopy(self)
endfunction

function! s:obj.init(item) abort
  let self['config'] = a:item
endfunction

function! s:obj.getGrepPrg(...) abort
  let param = extend(get(g: ,'fg#param', {}), {
  \  'grepprg': {
  \    'set': {
  \      'base':   v:true,
  \      'search': v:true,
  \    },
  \    'variant': {
  \      'case':  'smart',
  \      'word':  'regex',
  \    },
  \  }
  \}, 'keep')

  let cmd = s:build(self.config, param.grepprg)

  return join(cmd, ' ')
endfunction

function! s:build(config, param) abort
  let cmd = []

  let cmd = add(cmd, a:config.name)

  " set join
  for [name, value] in items(a:param.set)
    if value && has_key(a:config.opt.set, name)
      let cmd = extend(cmd, a:config.opt.set[name])
    endif
  endfor

  " variant join
  for [name, value] in items(a:param.variant)
    if has_key(a:config.opt.variant, name) && has_key(a:config.opt.variant[name], value)
      let cmd = extend(cmd, a:config.opt.variant[name][value])
    endif
  endfor

  return cmd
endfunction

let g:fg#base#object = s:obj
unlet s:obj
