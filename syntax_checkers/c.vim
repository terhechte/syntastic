"============================================================================
"File:        c.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  Gregor Uhlenheuer <kongo2002 at gmail dot com>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

" in order to also check header files add this to your .vimrc:
" (this usually creates a .gch file in your source directory)
"
"   let g:syntastic_c_check_header = 1

if exists('loaded_c_syntax_checker')
    finish
endif
let loaded_c_syntax_checker = 1

if !executable('gcc')
    finish
endif

" initialize handlers
function! s:Init()
    let s:handlers = []
    call s:RegHandler('\%(gtk\|glib\)', s:CheckGtk())
    call s:RegHandler('ruby', s:CheckRuby())

    unlet! s:RegHandler
endfunction

function! SyntaxCheckers_c_GetLocList()
    let makeprg = 'gcc -fsyntax-only %'
    let errorformat =  '%-G%f:%s:,%f:%l: %m'

    if expand('%') =~? '.h$'
        if exists('g:syntastic_c_check_header')
            let makeprg = 'gcc -c %'
        else
            return []
        endif
    endif

    let makeprg .= s:SearchHeaders(s:handlers)

    return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction

" search the first 100 lines for include statements that are
" given in the s:handlers dictionary
function! s:SearchHeaders(handlers)
    let includes = ''
    let found = {}
    for i in range(100)
        for handler in a:handlers
            if !has_key(found, handler["func"]) 
                if getline(i) =~? '^#include.*' . handler["regex"]
                    let includes .= handler["func"]
                    let found[handler["func"]] = 1
                endif
            endif
        endfor
    endfor
    return includes
endfunction

" try to find the gtk headers with 'pkg-config'
function! s:CheckGtk()
    if executable('pkg-config')
        if !exists('s:gtk_flags')
            let s:gtk_flags = system('pkg-config --cflags gtk+-2.0')
            let s:gtk_flags = substitute(s:gtk_flags, "\n", '', '')
            let s:gtk_flags = ' ' . s:gtk_flags
        endif
        return s:gtk_flags
    endif
    return ''
endfunction

" try to find the headers with 'rbconfig'
function! s:CheckRuby()
    if executable('ruby')
        if !exists('s:ruby_flags')
            let s:ruby_flags = system('ruby -r rbconfig -e '
                        \ . '''puts Config::CONFIG["archdir"]''')
            let s:ruby_flags = substitute(s:ruby_flags, "\n", '', '')
            let s:ruby_flags = ' -I' . s:ruby_flags
        endif
        return s:ruby_flags
    endif
    return ''
endfunction

" return a handler dictionary object
function! s:RegHandler(regex, function)
    let handler = {}
    let handler["regex"] = a:regex
    let handler["func"] = a:function
    call add(s:handlers, handler)
endfunction

call s:Init()