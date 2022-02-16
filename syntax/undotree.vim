"=================================================
" File: undotree.vim
" Description: undotree syntax
" Author: Ming Bai <mbbill@gmail.com>
" License: BSD

execute "syn match UndotreeNode ' \\zs".escape(g:undotree_TreeNodeShape,'*')."\\ze '"
execute "syn match UndotreeNodeCurrent '\\zs".escape(g:undotree_TreeNodeShape,'*')."\\ze.*>\d\+<'"
syn match UndotreeTimeStamp '(.*)$'
syn match UndotreeFirstNode 'Original'
execute "syn match UndotreeBranch '[".escape(g:undotree_TreeVertShape.g:undotree_TreeSplitShape.g:undotree_TreeReturnShape,'\')."]'"
syn match UndotreeSeq ' \zs\d\+\ze '
syn match UndotreeCurrent '>\d\+<'
syn match UndotreeNext '{\d\+}'
syn match UndotreeHead '\[\d\+]'
syn match UndotreeHelp '^".*$' contains=UndotreeHelpKey,UndotreeHelpTitle
syn match UndotreeHelpKey '^" \zs.\{-}\ze:' contained
syn match UndotreeHelpTitle '===.*===' contained
syn match UndotreeSavedSmall ' \zss\ze '
syn match UndotreeSavedBig ' \zsS\ze '

hi def link UndotreeNode Question
hi def link UndotreeNodeCurrent Statement
hi def link UndotreeTimeStamp Function
hi def link UndotreeFirstNode Function
hi def link UndotreeBranch Constant
hi def link UndotreeSeq Comment
hi def link UndotreeCurrent Statement
hi def link UndotreeNext Type
hi def link UndotreeHead Identifier
hi def link UndotreeHelp Comment
hi def link UndotreeHelpKey Function
hi def link UndotreeHelpTitle Type
hi def link UndotreeSavedSmall WarningMsg
hi def link UndotreeSavedBig MatchParen

" vim: set et fdm=marker sts=4 sw=4:
