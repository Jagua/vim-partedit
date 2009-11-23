" Edit a part of a buffer with a another buffer.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim



function! partedit#start(startline, endline, splitcmd)
  let original_bufnr = bufnr('%')
  let contents = getline(a:startline, a:endline)
  let filetype = &l:filetype

  let partial_bufname = printf('%s#%d-%d', bufname(original_bufnr),
  \                            a:startline, a:endline)

  execute a:splitcmd
  noautocmd hide edit `=partial_bufname`

  silent put =s:adjust(contents)
  silent 1 delete _

  let b:partedit_bufnr = original_bufnr
  let b:partedit_lines = [a:startline, a:endline]
  let b:partedit_contents = contents
  setlocal buftype=acwrite nomodified bufhidden=wipe noswapfile

  let &l:filetype = filetype

  augroup plugin-partedit
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> nested call s:apply()
  augroup END
endfunction



function! s:apply()
  let [start, end] = b:partedit_lines

  if !v:cmdbang &&
  \    b:partedit_contents != getbufline(b:partedit_bufnr, start, end)
    " TODO: Takes a proper step.
    let all = getbufline(b:partedit_bufnr, 1, '$')
    let line = s:search_partial(all, b:partedit_contents, start) + 1
    if line
      let [start, end] = [line, line + end - start]

    else
      echo 'The range in the original buffer was changed.  Overwrite? [yN]'
      if getchar() !~? 'y'
        return
      endif
    endif
  endif

  let contents = getline(1, '$')
  let bufnr = bufnr('%')

  setlocal bufhidden=hide
  noautocmd execute 'keepjumps' b:partedit_bufnr 'buffer'

  let modified = &l:modified

  silent execute printf('%d,%d delete _', start, end)
  silent execute start - 1 'put' '=s:adjust(contents)'

  if !modified
    write
  endif

  noautocmd execute 'keepjumps hide' bufnr 'buffer'
  setlocal bufhidden=wipe

  let b:partedit_contents = contents
  let b:partedit_lines = [start, start + len(contents) - 1]
  setlocal nomodified
endfunction



function! s:adjust(lines)
  return a:lines[-1] == '' ? a:lines + [''] : a:lines
endfunction



function! s:search_partial(all, part, base)
  let l = len(a:part)
  let last = len(a:all)
  let s:base = a:base
  for n in sort(range(last), s:sorter)
    if n + l <= last && a:all[n] == a:part[0] &&
  \      a:all[n : n + l - 1] == a:part
      return n
    end
  endfor
  return -1
endfunction



function! s:sort(a, b)
  return abs(a:a - s:base) - abs(a:b - s:base)
endfunction


function! s:SID()
  return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\zeSID$')
endfunction

let s:sorter = function(s:SID() . 'sort')





let &cpo = s:save_cpo
unlet s:save_cpo
