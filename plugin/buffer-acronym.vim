" Switching buffer by acronym

if exists("g:buffer_acronym_loaded")
  finish
endif
let g:buffer_acronym_loaded = 1

if !exists("g:buffer_acronym_from_start")
  " Acronym starts from the first word.
  let g:buffer_acronym_from_start = 1
endif

command! -complete=customlist,MatchBuffers -nargs=1 BufferAcronym :call SwitchBuffer(<f-args>)
nnoremap - :BufferAcronym<space>
nnoremap _ :ls<cr>:BufferAcronym<space>

let s:sep = '[ _.-]'

function! SwitchBuffer(buf)
  let name = substitute(a:buf, "=", Prefix(bufname('%')), "g")
  let indexes = filter(range(1, bufnr('$')), "buflisted(v:val)")
  let buffers = map(indexes, "bufname(v:val)")
  let matches = filter(buffers, "v:val == name")
  if len(matches) == 0
    let matches = MatchBuffers(name, "", 0)
  endif
  if len(matches) == 0
    let matches = [ name ]
  endif
  if tabpagewinnr(tabpagenr(), '$') == 1
    exe "vertical sbuffer " . matches[0]
  else
    "exe "normal!x"
    exe "buffer " . matches[0]
  endif
endfunction

function! MatchBuffers(acronym, L, P)
  let pattern = Pattern(a:acronym)
  let indexes = filter(range(1, bufnr('$')), "buflisted(v:val)")
  let buffers = map(indexes, "bufname(v:val)")
  if a:acronym =~ '='
    let name = substitute(a:acronym, "=", Prefix(bufname('%')), "g")
    return filter(buffers, "v:val =~ name")
  endif
  let matches = []
  for path in buffers
    if empty(path)
      continue
    endif
    let name = split(path, '/')[-1]
    if name =~ pattern
      let num_words = len(split(name, s:sep))
      call add(matches, [path, num_words])
    endif
  endfor
  return map(sort(matches, "FewerWordsFirst"), "v:val[0]")
endfunction

function! Pattern(acronym)
  let pattern = ''
  for char in split(a:acronym, '\zs')
    if char =~ '\u'
      let pattern = pattern . s:sep . '\?\u\@<!' . char . '\u*\l*\d*'
    elseif pattern == ''
      let pattern = pattern . s:sep . '\?' . char . '\l*\d*'
    else
      let pattern = pattern . s:sep . char . '\l*\d*'
    endif
  endfor
  "echom 'pattern=' . pattern
  if g:buffer_acronym_from_start == 1
    return '^' . pattern
  else
    return pattern
  endif
endfunction

function! FewerWordsFirst(x, y)
  return a:x[1] - a:y[1]
endfunction

function! Prefix(buf)
  let pos = len(a:buf) - 1
  while pos >= 0 && a:buf[pos] !~ s:sep
    let pos -= 1
  endwhile
  return pos > 0 ? a:buf[0:pos-1] . '.' : ""
endfunction
