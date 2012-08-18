"=================================================
" File: undotree.vim
" Description: Visualize your undo history.
" Author: Ming Bai <mbbill@gmail.com>
" License: BSD

" At least version 7.0 is needed for undo branches.
if v:version < 700
     finish
endif

" Options
if !exists('g:undotreeSplitLocation')
    let g:undotreeSplitLocation = 'topleft'
endif

if !exists('g:undotreeSplitMode')
    let g:undotreeSplitMode = 'vertical'
endif

" TODO remember split size.
if !exists('g:undotreeSplitSize')
    let g:undotreeSplitSize = 24
endif


"=================================================
" Golbal buf counter.
let s:undobufNr = 0

" Keymap
let s:keymap = {}
let s:keymap['<cr>']='enter'
let s:keymap['J']='godown'
let s:keymap['K']='goup'
let s:keymap['u']='undo'
let s:keymap['<c-r>']='redo'
let s:keymap['<c>']='clear'


function! s:new(obj)
    let newobj = deepcopy(a:obj)
    call newobj.Init()
    return newobj
endfunction

" Get formatted time
function! s:gettime(time)
    if a:time == 0
        return "--------"
    endif
    let today = substitute(strftime("%c",localtime())," .*$",'','g')
    if today == substitute(strftime("%c",a:time)," .*$",'','g')
        return strftime("%H:%M:%S",a:time)
    else
        return strftime("%H:%M:%S %b%d %Y",a:time)
    endif
endfunction

"=================================================
" Template object, like a class.
let s:undotree = {}

function! s:undotree.Init()
    let self.bufname = "undotree_".s:undobufNr
    let self.location = g:undotreeSplitLocation
    let self.mode = g:undotreeSplitMode
    let self.size = g:undotreeSplitSize
    let self.targetBufname = ''
    let self.rawtree = {}  "data passed from undotree()
    let self.tree = {}     "data converted to internal format.
    let self.nodelist = {} "stores an ordered list of items points to self.tree
    let self.current = -1  "current node is the latest.
    let self.asciitree = []     "output data.
    let self.asciimeta = []     "meta data behind ascii tree.
    " Increase to make it unique.
    let s:undobufNr = s:undobufNr + 1
endfunction

function! s:undotree.BindKey()
    silent! exec "nnoremap <buffer> "."<cr>"." :UndotreeAction "."
endfunction

function! s:undotree.IsVisible()
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:undotree.SetFocus()
    let winnr = bufwinnr(self.bufname)
    if winnr == -1
        echoerr "Fatal: can not create window!"
        return
    endif
    exec winnr . " wincmd w"
endfunction

function! s:undotree.RestoreFocus()
    let previousWinnr = winnr("#")
    if previousWinnr > 0
        exec previousWinnr . "wincmd w"
    endif
endfunction

function! s:undotree.Show()
    if self.IsVisible()
        return
    endif
    let cmd = self.location . " " .
                \self.mode . " " .
                \self.size . " " .
                \' new ' . self.bufname
    silent! exec cmd
    call self.SetFocus()
    setlocal winfixwidth
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nonumber
    "setlocal cursorline
    setlocal nomodifiable
    setfiletype undotree
    call s:undotree.BindKey()
    call self.RestoreFocus()
endfunction

function! s:undotree.Hide()
    if !self.IsVisible()
        return
    endif
    let winnr = bufwinnr(self.bufname)
    exec winnr . " wincmd w"
    quit
    " quit this window will restore focus to the previous window automatically.
endfunction

function! s:undotree.Toggle()
    if self.IsVisible()
        call self.Hide()
    else
        call self.Show()
    endif
endfunction

function! s:undotree.Update(bufname, rawtree)
    if !self.IsVisible()
        return
    endif
    let self.targetBufname = a:bufname
    let self.rawtree = a:rawtree
    let self.current = -1
    let self.nodelist = {}
    call self.ConvertInput()
    call self.Render()
    call self.Draw()
endfunction

function! s:undotree.Draw()
    call self.SetFocus()
    setlocal modifiable
    silent normal! ggdG
    call append(0,self.asciitree)
    "remove the last empty line
    silent normal! Gdd
    setlocal nomodifiable
    call self.RestoreFocus()
endfunction

" tree node class
let s:node = {}

function! s:node.Init()
    let self.seq = -1
    let self.p = []
    let self.newhead = 0
    let self.curhead = 0
    let self.time = -1
    let self.curpos = 0 " =1 if this node is the current one
endfunction

function! s:undotree._parseNode(in,out)
    " type(in) == type([]) && type(out) == type({})
    if len(a:in) == 0 "empty
        return
    endif
    let curnode = a:out
    for i in a:in
        if has_key(i,'alt')
            call self._parseNode(i.alt,curnode)
        endif
        let newnode = s:new(s:node)
        let newnode.seq = i.seq
        let newnode.time = i.time
        if has_key(i,'newhead')
            let newnode.newhead = i.newhead
        endif
        if has_key(i,'curhead')
            let newnode.curhead = i.curhead
            let curnode.curpos = 1
            " See 'Note' below.
            let self.current = curnode.seq
        endif
        "endif
        let self.nodelist[newnode.seq] = newnode
        call extend(curnode.p,[newnode])
        let curnode = newnode
    endfor
endfunction

"Sample:
"let s:test={'seq_last': 4, 'entries': [{'seq': 3, 'alt': [{'seq': 1, 'time': 1345131443}, {'seq': 2, 'time': 1345131445}], 'time': 1345131490}, {'seq': 4, 'time': 1345131492, 'newhead': 1}], 'time_cur': 1345131493, 'save_last': 0, 'synced': 0, 'save_cur': 0, 'seq_cur': 4}

function! s:undotree.ConvertInput()
    "Generate root node
    let self.tree = s:new(s:node)
    let self.tree.seq = 0
    let self.tree.time = 0

    "Add root node to list, we need a sorted list to calculate current node index.
    let self.nodelist[self.tree.seq] = self.tree

    call self._parseNode(self.rawtree.entries,self.tree)

    " Note: Normally, the current node should be the one that seq_cur points to,
    " but in fact it's not. May be bug, bug anyway I found a workaround:
    " first try to find the parent node of 'curhead', if not found, then use
    " seq_cur.
    if self.current == -1
        let self.current = self.rawtree.seq_cur
        let self.nodelist[self.current].curpos = 1
    endif
endfunction


"=================================================
" Ascii undo tree generator
"
" Example:
" 6 8  7
" |/   |
" 2    4
"  \   |
"   1  3  5
"    \ | /
"      0

" Tree sieve, p:fork, x:none
"
" x         8
" 8x        | 7
" 87         \ \
" x87       6 | |
" 687       |/ /
" p7x       | | 5
" p75       | 4 |
" p45       | 3 |
" p35       | |/
" pp        2 |
" 2p        1 |
" 1p        |/
" p         0
" 0
"
" Data sample:
"let example = {'seq':0,'p':[{'seq':1,'p':[{'seq':2,'p':[{'seq':6,'p':[]},{'seq':8,'p':[]}]}]},{'seq':3,'p':[{'seq':4,'p':[{'seq':7,'p':[]}]}]},{'seq':5,'p':[]}]}
"
" Convert self.tree -> self.asciitree
function! s:undotree.Render()
    " We gonna modify self.tree so we'd better make a copy first.
    " Can not make a copy because variable nested too deep, gosh.. okay,
    " fine..
    " let tree = deepcopy(self.tree)
    let tree = self.tree
    let slots = [tree]
    "let curr_seq = 0
    let out = []
    let outmeta = []
    let TYPE_E = type({})
    let TYPE_P = type([])
    let TYPE_X = type('x')
    while slots != []
        "find next node
        let foundx = 0 " 1 if x element is found.
        let index = 0 " Next element to be print.
    
        " Find x element first.
        for i in range(len(slots))
            if type(slots[i]) == TYPE_X
                let foundx = 1
                let index = i
                break
            endif
        endfor
    
        " Then, find the element with minimun seq.
        if foundx == 0
            "assume undo level isn't more than this... of course
            let minseq = 99999999
            for i in range(len(slots))
                if type(slots[i]) == TYPE_E
                    if slots[i].seq < minseq
                        let minseq = slots[i].seq
                        let index = i
                        continue
                    endif
                endif
                if type(slots[i]) == TYPE_P
                    for j in slots[i]
                        if j.seq < minseq
                            let minseq = j.seq
                            let index = i
                            continue
                        endif
                    endfor
                endif
            endfor
        endif

        " output.
        let newline = " "
        let newmeta = {}
        let node = slots[index]
        if type(node) == TYPE_X
            let newmeta = s:new(s:node) "invalid node.
            if index+1 != len(slots) " not the last one, append '\'
                for i in range(len(slots))
                    if i < index
                        let newline = newline.'| '
                    endif
                    if i > index
                        let newline = newline.' \'
                    endif
                endfor
            endif
            call remove(slots,index)
        endif
        if type(node) == TYPE_E
            let newmeta = node
            for i in range(len(slots))
                if index == i
                    "let newline = newline.(node.seq)." "
                    let newline = newline.'* '
                else
                    let newline = newline.'| '
                endif
            endfor
            " append meta info.
            let padding = ' '
            let newline = newline . padding
            if node.curpos
                let newline = newline.'>'.(node.seq).'< '.
                            \s:gettime(node.time)
            else
                if node.newhead
                    let newline = newline.'['.(node.seq).'] '.
                                \s:gettime(node.time)
                else
                    if node.curhead
                        let newline = newline.'{'.(node.seq).'} '.
                                    \s:gettime(node.time)
                    else
                        let newline = newline.' '.(node.seq).'  '.
                                    \s:gettime(node.time)
                    endif
                endif
            endif
            " update the printed slot to its child.
            if len(node.p) == 0
                let slots[index] = 'x'
            endif
            if len(node.p) == 1 "only one child.
                let slots[index] = node.p[0]
            endif
            if len(node.p) > 1 "insert p node
                let slots[index] = node.p
            endif
            let node.p = [] "cut reference.
        endif
        if type(node) == TYPE_P
            let newmeta = s:new(s:node) "invalid node.
            for k in range(len(slots))
                if k < index
                    let newline = newline."| "
                endif
                if k == index
                    let newline = newline."|/ "
                endif
                if k > index
                    let newline = newline."/ "
                endif
            endfor
            " split P to E+P if elements in p > 2
            call remove(slots,index)
            if len(node) == 2
                call insert(slots,node[0],index)
                call insert(slots,node[1],index)
            endif
            if len(node) > 2
                call insert(slots,node[0],index)
                call remove(node,0)
                call insert(slots,node,index)
            endif
        endif
        unlet node
        if newline != " "
            call insert(out,newline,0)
            call insert(outmeta,newmeta,0)
        endif
    endwhile
    let self.asciitree = out
    let self.asciimeta = outmeta
endfunction

"=================================================
" It will set the target of undotree window to the current editing buffer.
function! s:undotreeUpdate()
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        return
    endif
    if &bt != '' "it's nor a normal buffer, could be help, quickfix, etc.
        return
    endif
    let bufname = bufname("%") "current buffer
    let rawtree = undotree()
    call t:undotree.Update(bufname, rawtree)
endfunction

function! s:undotreeToggle()
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        let t:undotree = s:new(s:undotree)
    endif
    call t:undotree.Toggle()
endfunction

function! s:undotreeAction(action)
    echo a:action
endfunction

" internal commands, args:linenr, action
command! -n=1 -bar UndotreeAction   :call s:undotreeAction(<f-args>)
command! -n=0 -bar UndotreeUpdate   :call s:undotreeUpdate()


command! -n=0 -bar UndotreeToggle   :call s:undotreeToggle()

" need a timer to reduce cpu consumption.
autocmd InsertEnter,InsertLeave,WinEnter,WinLeave,CursorHold,CursorHoldI,CursorMoved * call s:undotreeUpdate()

" vim: set et fdm=marker sts=4 sw=4:
