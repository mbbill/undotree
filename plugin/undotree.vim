"=================================================
" File: undotree.vim
" Description: Manage your undo history in a graph.
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
    let g:undotreeSplitSize = 28
endif


"=================================================
" Golbal buf counter.
let s:undobufNr = 0

" Help text
let s:helpmore = ['" Undotree quick help',
            \'" -------------------']
let s:helpless = ['" Press ? for help.']

" Keymap
let s:keymap = []
" action, key, help.
let s:keymap += [['Enter','<cr>','Revert to current state']]
let s:keymap += [['Enter','<2-LeftMouse>','Revert to current state']]
let s:keymap += [['Godown','J','Revert to previous state']]
let s:keymap += [['Goup','K','Revert to next state']]
let s:keymap += [['Undo','u','Undo']]
let s:keymap += [['Redo','<c-r>','Redo']]
let s:keymap += [['Help','?','Toggle quick help']]

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

" Exec without autocommands
function! s:exec(cmd)
    let ei_bak= &eventignore
    set eventignore=all
    silent exe a:cmd
    let &eventignore = ei_bak
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
    let self.currentseq = -1  "current node is the latest.
    let self.asciitree = []     "output data.
    let self.asciimeta = []     "meta data behind ascii tree.
    let self.currentIndex = -1 "line of the current node in ascii tree.
    let self.showHelp = 0
    " Increase to make it unique.
    let s:undobufNr = s:undobufNr + 1
endfunction

function! s:undotree.BindKey()
    for i in s:keymap
        silent exec 'nnoremap <silent> <buffer> '.i[1].' :UndotreeAction '.i[0].'<cr>'
    endfor
endfunction

function! s:undotree.Action(action)
    if !self.IsVisible() || bufname("%") != self.bufname
        "echoerr "Fatal: window does not exists."
        return
    endif
    if !has_key(self,'Action'.a:action)
        echoerr "Fatal: Action does not exists!"
        return
    endif
    silent exec 'call self.Action'.a:action.'()'
endfunction

function! s:undotree.ActionHelp()
    let self.showHelp = !self.showHelp
    call self.Draw()
endfunction

" Helper function, do action in target window, and then update itself.
function! s:undotree.ActionInTarget(cmd)
    if !self.SetTargetFocus()
        return
    endif
    call s:exec(a:cmd)
    call self.UpdateTarget()
    call self.SetFocus()
    call self.Update()
endfunction

function! s:undotree.ActionEnter()
    let index = self.Screen2Index(line('.'))
    if index < 0
        return
    endif
    if (self.asciimeta[index].seq) == -1
        return
    endif
    call self.ActionInTarget('u '.self.asciimeta[index].seq)
endfunction

function! s:undotree.ActionUndo()
    call self.ActionInTarget('undo')
endfunction

function! s:undotree.ActionRedo()
    call self.ActionInTarget("redo")
endfunction

function! s:undotree.ActionGodown()
    call self.ActionInTarget('earlier')
endfunction

function! s:undotree.ActionGoup()
    call self.ActionInTarget('later')
endfunction

function! s:undotree.IsVisible()
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:undotree.IsTargetVisible()
    if bufwinnr(self.targetBufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:undotree.SetFocus()
    let winnr = bufwinnr(self.bufname)
    if winnr == -1
        echoerr "Fatal: undotree window does not exist!"
        return
    else
        " wincmd would cause cursor outside window.
        call s:exec("norm! ".winnr."\<c-w>\<c-w>")
        return
    endif
endfunction

" May fail due to target window closed.
function! s:undotree.SetTargetFocus()
    let winnr = bufwinnr(self.targetBufname)
    if winnr == -1
        return 0
    else
        call s:exec("norm! ".winnr."\<c-w>\<c-w>")
        return 1
    endif
endfunction

function! s:undotree.RestoreFocus()
    let previousWinnr = winnr("#")
    if previousWinnr > 0
        call s:exec("norm! ".previousWinnr."\<c-w>\<c-w>")
    endif
endfunction

function! s:undotree.Show()
    if self.IsVisible()
        return
    endif
    " store info for the first update.
    call self.UpdateTarget()
    " Create undotree window.
    let cmd = self.location . " " .
                \self.mode . " " .
                \self.size . " " .
                \' new ' . self.bufname
    call s:exec("silent ".cmd)
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
    setlocal cursorline
    setlocal nomodifiable
    setfiletype undotree
    call s:undotree.BindKey()
    call self.Update()
    call self.RestoreFocus()
endfunction

function! s:undotree.Hide()
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
    " quit this window will restore focus to the previous window automatically.
endfunction

function! s:undotree.Toggle()
    if self.IsVisible()
        call self.Hide()
    else
        call self.Show()
    endif
endfunction

function! s:undotree.Update()
    if !self.IsVisible()
        return
    endif
    let self.currentseq = -1
    let self.nodelist = {}
    let self.currentIndex = -1
    call self.ConvertInput()
    call self.Render()
    call self.Draw()
endfunction

" execute this in target window.
function! s:undotree.UpdateTarget()
    let self.targetBufname = bufname("%") "current buffer
    let self.rawtree = undotree()
endfunction

function! s:undotree.AppendHelp()
    call append(0,'') "empty line
    if self.showHelp
        for i in s:keymap
            call append(0,'" '.i[1].' : '.i[2])
        endfor
        call append(0,s:helpmore)
    else
        call append(0,s:helpless)
    endif
endfunction

function! s:undotree.Index2Screen(index)
    " calculate line number according to the help text.
    " index starts from zero and lineNr starts from 1.
    if self.showHelp
        " 2 means 1 empty line + 1 index padding (index starts from zero)
        let lineNr = a:index + len(s:keymap) + len(s:helpmore) + 2
    else
        let lineNr = a:index + len(s:helpless) + 2
    endif
    return lineNr
endfunction

" <0 if index is invalid. e.g. current line is in help text.
function! s:undotree.Screen2Index(line)
    if self.showHelp
        let index = a:line - len(s:keymap) - len(s:helpmore) - 2
    else
        let index = a:line - len(s:helpless) - 2
    endif
    return index
endfunction

" Current window must be undotree.
function! s:undotree.Draw()
    " remember the current cursor position.
    let linePos = line('.') "Line number of cursor
    normal! H
    let topPos = line('.') "Line number of the first line in screen.

    setlocal modifiable
    " Delete text into blackhole register.
    call s:exec('1,$ d _')
    call append(0,self.asciitree)

    call self.AppendHelp()

    "remove the last empty line
    call s:exec('$d _')

    " restore previous cursor position.
    call s:exec("normal! " . topPos . "G")
    normal! zt
    call s:exec("normal! " . linePos . "G")

    call s:exec("normal! " . self.Index2Screen(self.currentIndex) . "G")
    setlocal nomodifiable
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
            let self.currentseq = curnode.seq
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
    if self.currentseq == -1
        let self.currentseq = self.rawtree.seq_cur
        let self.nodelist[self.currentseq].curpos = 1
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
            let padding = ''
            let newline = newline . padding
            if node.curpos
                let newline = newline.'>'.(node.seq).'< '.
                            \s:gettime(node.time)
                let self.currentIndex = len(out) + 1 "index from zero.
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
            call remove(slots,index)
            if len(node) == 2
                if node[0].seq > node[1].seq
                    call insert(slots,node[0],index)
                    call insert(slots,node[1],index)
                else
                    call insert(slots,node[1],index)
                    call insert(slots,node[0],index)
                endif
            endif
            " split P to E+P if elements in p > 2
            if len(node) > 2
                call insert(slots,node[0],index)
                call remove(node,0)
                call insert(slots,node,index+1)
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
    let self.currentIndex = len(out) - self.currentIndex
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
    if mode() != 'n' "not in normal mode, return.
        return
    endif
    call t:undotree.UpdateTarget()
    call t:undotree.SetFocus()
    call t:undotree.Update()
    call t:undotree.RestoreFocus()
endfunction

function! s:undotreeToggle()
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        let t:undotree = s:new(s:undotree)
    endif
    call t:undotree.Toggle()
endfunction

function! s:undotreeAction(action)
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        echoerr "Fatal: t:undotree does not exists!"
        return
    endif
    call t:undotree.Action(a:action)
endfunction

" Internal commands, args:linenr, action
command! -n=1 -bar UndotreeAction   :call s:undotreeAction(<f-args>)
command! -n=0 -bar UndotreeUpdate   :call s:undotreeUpdate()


" User commands.
command! -n=0 -bar UndotreeToggle   :call s:undotreeToggle()

autocmd InsertEnter,InsertLeave,WinEnter,WinLeave,CursorMoved * call s:undotreeUpdate()

" vim: set et fdm=marker sts=4 sw=4:
