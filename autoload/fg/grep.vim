let s:obj = g:fg#base#object.new()

function! fg#grep#init(item) abort
  call s:obj.init(a:item)
endfunction

function! fg#grep#new() abort
  return deepcopy(s:obj)
endfunction

function! s:obj.init(item) abort
  let self['config'] = a:item
endfunction

function! s:obj.getGrepPrg(...) abort
  let param = extend(get(g: ,'fg#param', {}), {
  \  'grepprg': {}
  \}, 'keep')

  let param.grepprg['set'] = extend(get(param,'set',{}), {
  \  'base'    : v:true,
  \  'search'  : v:true,
  \}, 'keep')

  let param.grepprg['variant'] = extend(get(param,'variant',{}), {
  \  'case':  'smart',
  \  'word':  'regex',
  \}, 'keep')

  let cmd = s:build(self.config, param.grepprg)

  return join(cmd, ' ')
endfunction

function! s:obj.getSearchCmd(...) abort
  let param = extend(get(g: ,'fg#param', {}), {
  \  'search': {}
  \}, 'keep')

  let param.search['set'] = extend(get(param,'set',{}), {
  \  'base'    : v:true,
  \  'search'  : v:true,
  \}, 'keep')

  let param.search['variant'] = extend(get(param,'variant',{}), {
  \  'case':  'smart',
  \  'word':  'regex',
  \}, 'keep')

  let opt = param.search
  if a:0 > 0
    let opt.variant = extend(a:1, opt.variant, 'keep')
  endif

  let cmd = s:build(self.config, opt)

  return cmd
endfunction

function! s:obj.getFileListupCmd(...) abort
  let param = extend(get(g: ,'fg#param', {}), {
  \  'filelist': {}
  \}, 'keep')

  let param.filelist['set'] = extend(get(param,'set',{}), {
  \  'base'    : v:true,
  \  'filelist': v:true,
  \}, 'keep')

  let param.filelist['variant'] = extend(get(param,'variant',{}), {
  \  'case':  'smart',
  \}, 'keep')

  let opt = param.filelist
  if a:0 > 0
    let opt.variant = extend(a:1, opt.variant, 'keep')
  endif

  let cmd = s:build(self.config, opt)

  return cmd
endfunction

" inner function

function! s:build(config, param) abort
  let cmd = []

  let cmd = add(cmd, a:config.command)

  " skiip ignore
  let skipdir  = get(a:config.global, 'skipdir', [])
  if !empty(skipdir)
    let skipdirstr = '{' . join(skipdir, ',') . '}'
    let cmd = extend(cmd, ['--exclude-dir=' . skipdirstr ])
  endif

  " set join
  let filelist_cmd = []
  for [name, value] in items(a:param.set)
    if name !=? 'filelist'
      if value && has_key(a:config.opt.set, name)
        let cmd = extend(cmd, a:config.opt.set[name])
      endif
    else
      if value && has_key(a:config.opt.set, name)
        let filelist_cmd = extend(filelist_cmd, a:config.opt.set[name])
      endif
    endif
  endfor

  " variant join
  let word_cmd = []
  for [name, value] in items(a:param.variant)
    if name !=? 'word'
      if has_key(a:config.opt.variant, name) && has_key(a:config.opt.variant[name], value)
        let cmd = extend(cmd, a:config.opt.variant[name][value])
      endif
    else
      if has_key(a:config.opt.variant, name) && has_key(a:config.opt.variant[name], value)
        let word_cmd = extend(word_cmd, a:config.opt.variant[name][value])
      endif
    endif
  endfor
  " word last in variant
  let cmd = extend(cmd, word_cmd)

  return cmd
endfunction
