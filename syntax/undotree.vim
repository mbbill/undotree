"=================================================
" File: undotree.vim
" Description: undotree syntax
" Author: Ming Bai <mbbill@gmail.com>
" License: BSD

if exists("b:undotree_syntax")
    finish
endif

syn match UndotreeNode ' \zs\*\ze '
syn match UndotreeNodeCurrent '\zs\*\ze.*>\d\+<'
syn match UndotreeTime '..:..:..*$'
syn match UndotreeFirstNode '-*$'
syn match UndotreeBranch '[|/\\]'
syn match UndotreeSeq ' \zs\d\+\ze '
syn match UndotreeCurrent '>\d\+<'
syn match UndotreeNext '{\d\+}'
syn match UndotreeHead '\[\d\+]'
syn match UndotreeSaved '-\d\+-'
syn match UndotreeHelp '^".*$' contains=UndotreeHelpKey
syn match UndotreeHelpKey '^" \zs.\{-}\ze:' contained

hi link UndotreeNode Question
hi link UndotreeNodeCurrent Statement
hi link UndotreeTime Underlined
hi link UndotreeFirstNode Function
hi link UndotreeBranch Constant
hi link UndotreeSeq Comment
hi link UndotreeCurrent Statement
hi link UndotreeNext Type
hi link UndotreeHead Identifier
hi link UndotreeHelp Comment
hi link UndotreeHelpKey Type
hi link UndotreeSaved Constant

let b:undotree_syntax = 'undotree'

" vim: set et fdm=marker sts=4 sw=4:
