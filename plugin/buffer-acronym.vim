" Switching buffer by acronym

if exists("g:loaded_buffer_acronym")
  finish
endif
let g:loaded_buffer_acronym = 1

command! -complete=customlist,MatchBuffers -nargs=1 BufferAcronym :call SwitchBuffer(<f-args>)
nnoremap - :BufferAcronym<space>
nnoremap _ :ls<cr>:BufferAcronym<space>

function! MatchBuffers(acronym, L, P)
  let sep = '[_.-]'
  let pattern = '\v' . join(map(split(a:acronym, '\zs'), "v:val . '\\a*' . sep"), '') . '*'
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
    if name =~ '^' . pattern || name =~ '\.' . pattern
      let num_words = len(split(name, sep))
      call add(matches, [path, num_words])
    endif
  endfor
  return map(sort(matches, "FewerWordsFirst"), "v:val[0]")
endfunction

function! FewerWordsFirst(x, y)
  return a:x[1] - a:y[1]
endfunction

function! Prefix(buf)
  let sep = '[_.-]'
  let pos = len(a:buf) - 1
  while pos >= 0 && a:buf[pos] !~ sep
    let pos -= 1
  endwhile
  return pos > 0 ? a:buf[0:pos-1] . '.' : ""
endfunction

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
