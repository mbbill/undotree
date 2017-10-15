"=================================================
" File: autoload/undotree.vim
" Description: Manage your undo history in a graph.
" Author: David Knoble <ben.knoble@gmail.com>
" License: BSD

" Avoid installing twice.
if exists('g:autoloaded_undotree')
    finish
endif
let g:autoloaded_undotree = 0

" At least version 7.3 with 005 patch is needed for undo branches.
" Refer to https://github.com/mbbill/undotree/issues/4 for details.
" Thanks kien
if v:version < 703
    finish
endif
if (v:version == 703 && !has("patch005"))
    finish
endif
let g:loaded_undotree = 1   " Signal plugin availability with a value of 1.


