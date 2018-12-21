" setup things
:command Rim call s:startRim(g:DEFAULT_TERM)
:command Jim call s:startRim(g:JULIA_TERM)
:command Pim call s:startRim(g:PYTHON_TERM)
:command RW call s:rimWipe(g:CURRENT_TERM)
:command RR call s:rimRestart()
:command EF call s:executeBuffers(g:CURRENT_TERM)
:command -nargs=* EB call s:executeBuffers(g:CURRENT_TERM, <f-args>) " execute given list of buffers
:command -range ES call s:executeSelection(s:get_visual_selection())
:command EL call s:executeSelection(getline(".")) " execute line

let g:CURRENT_TERM = ""
let g:DEFAULT_TERM = "bash"
let g:JULIA_TERM = "julia"
let g:PYTHON_TERM = "python"
let g:SUPPORTED_TERMS = [g:DEFAULT_TERM, g:JULIA_TERM, g:PYTHON_TERM]

let g:RUN_TERM_CMD = "vert term "

function! s:startRim(termType)
    if g:CURRENT_TERM == ""
        if count(g:SUPPORTED_TERMS, a:termType) == 0
            echo "Not supported terminal type!"
            return -1
        endif

        call s:setCurrentTerm(a:termType)

        if a:termType == g:DEFAULT_TERM
            execute(g:RUN_TERM_CMD)
        else
            execute (g:RUN_TERM_CMD . a:termType)
        endif

        execute ("file " . a:termType)
    else
        echo "Only one terminal is supported for now."
    endif
endfunction

function! s:rimWipe(termType)
    execute ("bw! " . a:termType)
    call s:setCurrentTerm("")
endfunction

function! s:rimRestart()
    let l:currTerm = g:CURRENT_TERM
    call s:rimWipe(g:CURRENT_TERM)
    call s:startRim(l:currTerm)
endfunction

function! s:executeBuffers(termType, ...)
    if s:checkTerm()
        if a:0 == 0
            call s:executeFile(a:termType, @%)
        else
            for bn in a:000
                call s:executeFile(a:termType, s:getFilePathFromBuffer(bn))
            endfor
        endif
    endif
endfunction

function! s:executeSelection(selection)
    if s:checkTerm()
        call term_sendkeys(bufnr(g:CURRENT_TERM), a:selection . "\<cr>")
    endif
endfunction

" utility functions

function! s:executeFile(termType, file)
    if s:checkTerm()
        if a:termType == g:DEFAULT_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "./" . a:file . "\<cr>")
            return
        endif

        if a:termType == g:JULIA_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "include(\"" . a:file . "\")\<cr>")
            return
        endif

        if a:termType == g:PYTHON_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "exec(open(\"" . a:file . "\").read(), globals())\<cr>")
        endif
    endif
endfunction

function! s:setCurrentTerm(termType)
    let g:CURRENT_TERM = a:termType
endfunction

function! s:checkTerm()
    if g:CURRENT_TERM == ""
        echo "No terminal opened."
        return 0
    endif

    return 1
endfunction
function! s:getFilePathFromBuffer(bufferNum)
    return expand("#" . a:bufferNum . ":p")
endfunction

function! s:get_visual_selection() " credits to https://stackoverflow.com/a/6271254
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction
