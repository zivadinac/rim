" setup things
:command Rim call s:startRim(g:DEFAULT_TERM)
:command Jim call s:startRim(g:JULIA_TERM)
:command Pim call s:startRim(g:PYTHON_TERM)
:command RW call s:rimWipe(g:CURRENT_TERM)
:command RR call s:rimRestart()
:command EF call s:executeFile(g:CURRENT_TERM)
:command -range ES call s:executeSelection(s:get_visual_selection())
:command EL call s:executeSelection(getline("."))

let g:CURRENT_TERM = ""
let g:DEFAULT_TERM = "bash"
let g:JULIA_TERM = "julia"
let g:PYTHON_TERM = "python"
let g:SUPPORTED_TERMS = [g:DEFAULT_TERM, g:JULIA_TERM, g:PYTHON_TERM]

function! s:startRim(termType)
    if g:CURRENT_TERM == ""
        if count(g:SUPPORTED_TERMS, a:termType) == 0
            echo "Not supported terminal type!"
            return -1
        endif

        call s:setCurrentTerm(a:termType)

        if a:termType == g:DEFAULT_TERM
            :terminal
        else
            execute ("term " . a:termType)
        endif

        execute ("file " . a:termType)
    else
        echo "Only one terminal is supported for now."
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

function! s:rimWipe(termType)
    execute ("bw! " . a:termType)
    call s:setCurrentTerm("")
endfunction

function! s:rimRestart()
    let l:currTerm = g:CURRENT_TERM
    call s:rimWipe(g:CURRENT_TERM)
    call s:startRim(l:currTerm)
endfunction

function! s:executeFile(termType)
    if s:checkTerm()
        if a:termType == g:DEFAULT_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "./" . @% . "\<cr>")
            return
        endif

        if a:termType == g:JULIA_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "include(\"" . @% . "\")\<cr>")
            return
        endif

        if a:termType == g:PYTHON_TERM
            call term_sendkeys(bufnr(g:CURRENT_TERM), "exec(open(\"" . @% . "\").read(), globals())\<cr>")
        endif
    endif
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

function! s:executeSelection(selection)
    if s:checkTerm()
        call term_sendkeys(bufnr(g:CURRENT_TERM), a:selection . "\<cr>")
    endif
endfunction
