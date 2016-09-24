" Switching buffer by acronym

if exists("g:buffer_acronym_loaded")
  finish
endif
let g:buffer_acronym_loaded = 1

if !exists("g:buffer_acronym_with_path")
  " Whether an acronym includes the path component.
  let g:buffer_acronym_with_path = 1
endif

if !exists("g:buffer_acronym_from_start")
  " Whether an acronym starts from the first word.
  let g:buffer_acronym_from_start = 0
endif

command! -complete=customlist,MatchBuffers -nargs=1 BufferAcronym :call SwitchBuffer(<f-args>)
nnoremap - :BufferAcronym<space>
nnoremap _ :ls<cr>:BufferAcronym<space>

let s:sep = '[/ _.-]'

function! SwitchBuffer(buf)
  let name = substitute(a:buf, "=", Prefix(bufname('%')), "g")
  let indexes = filter(range(1, bufnr('$')), "buflisted(v:val)")
  let buffers = map(indexes, "bufname(v:val)")
  let matches = filter(buffers, "v:val == name")
  if len(matches) == 0
    let matches = MatchBuffers(name, "", 0)
  endif
  if len(matches) == 0
    let matches = [name]
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
  return Match(pattern, buffers)
endfunction

function! Match(pattern, buffers)
  let matches = []
  for buffer in a:buffers
    if empty(buffer)
      continue
    endif
    if g:buffer_acronym_with_path == 1
      let name = buffer
    else
      let name = split(buffer, '/')[-1]
    endif
    if name =~ a:pattern
      call add(matches, buffer)
    endif
  endfor
  return matches
endfunction

function! Pattern(acronym)
  let all_chars = split(a:acronym, '\zs')
  let first_char = all_chars[0]
  if g:buffer_acronym_from_start == 1
    if first_char =~ '\u'
      let pattern = '^' . s:sep . '\?' . first_char . '\u*\l*\d*'
    else
      let pattern = '^' . s:sep . '\?' . first_char . '\l*\d*'
    endif
  else
    if first_char =~ '\u'
      let pattern = '\(^\|\u\@<!\)' . first_char . '\u*\l*\d*'
    else
      let pattern = '\(^\|' . s:sep . '\)' . first_char . '\l*\d*'
    endif
  endif

  for char in all_chars[1:]
    if char =~ '\u'
      let pattern = pattern . s:sep . '\?\u\@<!' . char . '\u*\l*\d*'
    else
      let pattern = pattern . s:sep . char . '\l*\d*'
    endif
  endfor

  "echom 'pattern=' . pattern
  return pattern
endfunction

function! Prefix(buf)
  let pos = len(a:buf) - 1
  while pos >= 0 && a:buf[pos]!~ s:sep
    let pos -= 1
  endwhile
  return pos > 0 ? a:buf[0:pos-1]. '.' : ""
endfunction

" =============================== Unit tests ===============================

function! ExpectMatch(acronym, buffers, expected)
  let actual = Match(Pattern(a:acronym), a:buffers)
  if a:expected != actual
    echo 'Acronym "' . a:acronym . '" failed, expecting '
    echo a:expected
    echo 'actual '
    echo actual
  endif
endfunction

function! TestMatchFromStart(with_path)
  echo 'TestMatchFromStart with_path=' . a:with_path
  let g:buffer_acronym_from_start = 1
  let g:buffer_acronym_with_path = a:with_path

  let buffers = ['awesome.cc', 'awesome.h']
  call ExpectMatch('a', buffers, buffers)
  call ExpectMatch('ac', buffers, ['awesome.cc'])
  call ExpectMatch('ah', buffers, ['awesome.h'])
  call ExpectMatch('ach', buffers, [])
  call ExpectMatch('c', buffers, [])
  call ExpectMatch('h', buffers, [])
  call ExpectMatch('w', buffers, [])

  let buffers = ['test-program.cc', 'test.py', 'test env']
  call ExpectMatch('t', buffers, buffers)
  call ExpectMatch('tp', buffers, ['test-program.cc', 'test.py'])
  call ExpectMatch('tpc', buffers, ['test-program.cc'])
  call ExpectMatch('te', buffers, ['test env'])
  call ExpectMatch('tee', buffers, [])
  call ExpectMatch('tpe', buffers, [])
  call ExpectMatch('p', buffers, [])
  call ExpectMatch('c', buffers, [])
  call ExpectMatch('e', buffers, [])
  call ExpectMatch('y', buffers, [])

  let buffers = ['ReadMe.md', 'README.md', 'readMe.1st', 'READ_ME.1st']
  call ExpectMatch('R', buffers, ['ReadMe.md', 'README.md', 'READ_ME.1st'])
  call ExpectMatch('RM', buffers, ['ReadMe.md', 'READ_ME.1st'])
  call ExpectMatch('RMm', buffers, ['ReadMe.md'])
  call ExpectMatch('RM1', buffers, ['READ_ME.1st'])
  call ExpectMatch('Rm', buffers, ['README.md'])
  call ExpectMatch('r', buffers, ['readMe.1st'])
  call ExpectMatch('rM', buffers, ['readMe.1st'])
  call ExpectMatch('rM1', buffers, ['readMe.1st'])
  call ExpectMatch('rMs', buffers, [])
  call ExpectMatch('M', buffers, [])
  call ExpectMatch('m', buffers, [])
  call ExpectMatch('Mm', buffers, [])
  call ExpectMatch('e', buffers, [])
  call ExpectMatch('eM', buffers, [])
  call ExpectMatch('dM', buffers, [])
  call ExpectMatch('ME', buffers, [])
  call ExpectMatch('Me', buffers, [])
  call ExpectMatch('M1', buffers, [])
  call ExpectMatch('1', buffers, [])
  call ExpectMatch('D', buffers, [])
  call ExpectMatch('E', buffers, [])
endfunction

function! TestMatchFromStartWithPath()
  echo 'TestMatchFromStartWithPath'
  let g:buffer_acronym_from_start = 1
  let g:buffer_acronym_with_path = 1

  let buffers = ['debug/makefile', 'test/makefile', 'makefile']
  call ExpectMatch('m', buffers, ['makefile'])
  call ExpectMatch('d', buffers, ['debug/makefile'])
  call ExpectMatch('dm', buffers, ['debug/makefile'])
  call ExpectMatch('t', buffers, ['test/makefile'])
  call ExpectMatch('tm', buffers, ['test/makefile'])
  call ExpectMatch('f', buffers, [])
  call ExpectMatch('md', buffers, [])
  call ExpectMatch('mt', buffers, [])
  call ExpectMatch('mf', buffers, [])

  let buffers = ['long/path/file', 'long-path/File', 'long-path_file']
  call ExpectMatch('l', buffers, buffers)
  call ExpectMatch('lp', buffers, buffers)
  call ExpectMatch('lpf', buffers, ['long/path/file', 'long-path_file'])
  call ExpectMatch('lpF', buffers, ['long-path/File'])
  call ExpectMatch('p', buffers, [])
  call ExpectMatch('pf', buffers, [])
  call ExpectMatch('lf', buffers, [])
  call ExpectMatch('f', buffers, [])
  call ExpectMatch('F', buffers, [])
endfunction

function! TestMatchFromStartWithoutPath()
  echo 'TestMatchFromStartWithoutPath'
  let g:buffer_acronym_from_start = 1
  let g:buffer_acronym_with_path = 0

  let buffers = ['debug/makefile', 'test/makefile', 'makefile']
  call ExpectMatch('m', buffers, buffers)
  call ExpectMatch('d', buffers, [])
  call ExpectMatch('dm', buffers, [])
  call ExpectMatch('t', buffers, [])
  call ExpectMatch('tm', buffers, [])
  call ExpectMatch('f', buffers, [])
  call ExpectMatch('md', buffers, [])
  call ExpectMatch('mt', buffers, [])
  call ExpectMatch('mf', buffers, [])

  let buffers = ['long/path/file', 'long-path/File', 'long-path_file']
  call ExpectMatch('l', buffers, ['long-path_file'])
  call ExpectMatch('lp', buffers, ['long-path_file'])
  call ExpectMatch('lpf', buffers, ['long-path_file'])
  call ExpectMatch('lpF', buffers, [])
  call ExpectMatch('p', buffers, [])
  call ExpectMatch('pf', buffers, [])
  call ExpectMatch('lf', buffers, [])
  call ExpectMatch('f', buffers, ['long/path/file'])
  call ExpectMatch('F', buffers, ['long-path/File'])
endfunction

function! TestMatchFromMiddle(with_path)
  echo 'TestMatchFromMiddle with_path=' . a:with_path
  let g:buffer_acronym_from_start = 0
  let g:buffer_acronym_with_path = a:with_path

  let buffers = ['awesome.cc', 'awesome.h']
  call ExpectMatch('a', buffers, buffers)
  call ExpectMatch('ac', buffers, ['awesome.cc'])
  call ExpectMatch('ah', buffers, ['awesome.h'])
  call ExpectMatch('ach', buffers, [])
  call ExpectMatch('c', buffers, ['awesome.cc'])
  call ExpectMatch('h', buffers, ['awesome.h'])
  call ExpectMatch('w', buffers, [])

  let buffers = ['test-program.cc', 'test.py', 'test env']
  call ExpectMatch('t', buffers, buffers)
  call ExpectMatch('tp', buffers, ['test-program.cc', 'test.py'])
  call ExpectMatch('tpc', buffers, ['test-program.cc'])
  call ExpectMatch('te', buffers, ['test env'])
  call ExpectMatch('tee', buffers, [])
  call ExpectMatch('tpe', buffers, [])
  call ExpectMatch('p', buffers, ['test-program.cc', 'test.py'])
  call ExpectMatch('c', buffers, ['test-program.cc'])
  call ExpectMatch('e', buffers, ['test env'])
  call ExpectMatch('y', buffers, [])

  let buffers = ['ReadMe.md', 'README.md', 'readMe.1st', 'READ_ME.1st']
  call ExpectMatch('R', buffers, ['ReadMe.md', 'README.md', 'READ_ME.1st'])
  call ExpectMatch('RM', buffers, ['ReadMe.md', 'READ_ME.1st'])
  call ExpectMatch('RMm', buffers, ['ReadMe.md'])
  call ExpectMatch('RM1', buffers, ['READ_ME.1st'])
  call ExpectMatch('Rm', buffers, ['README.md'])
  call ExpectMatch('r', buffers, ['readMe.1st'])
  call ExpectMatch('rM', buffers, ['readMe.1st'])
  call ExpectMatch('rM1', buffers, ['readMe.1st'])
  call ExpectMatch('rMs', buffers, [])
  call ExpectMatch('M', buffers, ['ReadMe.md', 'readMe.1st', 'READ_ME.1st'])
  call ExpectMatch('m', buffers, ['ReadMe.md', 'README.md'])
  call ExpectMatch('Mm', buffers, ['ReadMe.md'])
  call ExpectMatch('e', buffers, [])
  call ExpectMatch('eM', buffers, [])
  call ExpectMatch('dM', buffers, [])
  call ExpectMatch('ME', buffers, [])
  call ExpectMatch('Me', buffers, [])
  call ExpectMatch('M1', buffers, ['readMe.1st', 'READ_ME.1st'])
  call ExpectMatch('1', buffers, ['readMe.1st', 'READ_ME.1st'])
  call ExpectMatch('D', buffers, [])
  call ExpectMatch('E', buffers, [])
endfunction

function! TestMatchFromMiddleWithPath()
  echo 'TestMatchFromMiddleWithPath'
  let g:buffer_acronym_from_start = 0
  let g:buffer_acronym_with_path = 1

  let buffers = ['debug/makefile', 'test/makefile', 'makefile']
  call ExpectMatch('m', buffers, buffers)
  call ExpectMatch('d', buffers, ['debug/makefile'])
  call ExpectMatch('dm', buffers, ['debug/makefile'])
  call ExpectMatch('t', buffers, ['test/makefile'])
  call ExpectMatch('tm', buffers, ['test/makefile'])
  call ExpectMatch('f', buffers, [])
  call ExpectMatch('md', buffers, [])
  call ExpectMatch('mt', buffers, [])
  call ExpectMatch('mf', buffers, [])

  let buffers = ['long/path/file', 'long-path/File', 'long-path_file']
  call ExpectMatch('l', buffers, buffers)
  call ExpectMatch('lp', buffers, buffers)
  call ExpectMatch('lpf', buffers, ['long/path/file', 'long-path_file'])
  call ExpectMatch('lpF', buffers, ['long-path/File'])
  call ExpectMatch('p', buffers, buffers)
  call ExpectMatch('pf', buffers, ['long/path/file', 'long-path_file'])
  call ExpectMatch('lf', buffers, [])
  call ExpectMatch('f', buffers, ['long/path/file', 'long-path_file'])
  call ExpectMatch('F', buffers, ['long-path/File'])
endfunction

function! TestMatchFromMiddleWithoutPath()
  echo 'TestMatchFromMiddleWithoutPath'
  let g:buffer_acronym_from_start = 0
  let g:buffer_acronym_with_path = 0

  let buffers = ['debug/makefile', 'test/makefile', 'makefile']
  call ExpectMatch('m', buffers, buffers)
  call ExpectMatch('d', buffers, [])
  call ExpectMatch('dm', buffers, [])
  call ExpectMatch('t', buffers, [])
  call ExpectMatch('tm', buffers, [])
  call ExpectMatch('f', buffers, [])
  call ExpectMatch('md', buffers, [])
  call ExpectMatch('mt', buffers, [])
  call ExpectMatch('mf', buffers, [])

  let buffers = ['long/path/file', 'long-path/File', 'long-path_file']
  call ExpectMatch('l', buffers, ['long-path_file'])
  call ExpectMatch('lp', buffers, ['long-path_file'])
  call ExpectMatch('lpf', buffers, ['long-path_file'])
  call ExpectMatch('lpF', buffers, [])
  call ExpectMatch('p', buffers, ['long-path_file'])
  call ExpectMatch('pf', buffers, ['long-path_file'])
  call ExpectMatch('lf', buffers, [])
  call ExpectMatch('f', buffers, ['long/path/file', 'long-path_file'])
  call ExpectMatch('F', buffers, ['long-path/File'])
endfunction

function! TestAll()
  call TestMatchFromStart(0)
  call TestMatchFromStart(1)
  call TestMatchFromStartWithPath()
  call TestMatchFromStartWithoutPath()

  call TestMatchFromMiddle(0)
  call TestMatchFromMiddle(1)
  call TestMatchFromMiddleWithPath()
  call TestMatchFromMiddleWithoutPath()
endfunction
