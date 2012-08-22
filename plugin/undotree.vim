"=================================================
" File: undotree.vim
" Description: Manage your undo history in a graph.
" Author: Ming Bai <mbbill@gmail.com>
" License: BSD

" TODO diff panel
" TODO remember split size.
" TODO status line.
" TODO do not need to redraw
" TODO fix diff update cause cursor move.

" At least version 7.0 is needed for undo branches.
if v:version < 700
     finish
endif

" split window location, could also be topright
if !exists('g:undotree_SplitLocation')
    let g:undotree_SplitLocation = 'topleft'
endif

" undotree window width
if !exists('g:undotree_SplitWidth')
    let g:undotree_SplitWidth = 28
endif

" if set, let undotree window get focus after being opened, otherwise
" focus will stay in current window.
if !exists('g:undotree_SetFocusWhenToggle')
    let g:undotree_SetFocusWhenToggle = 0
endif

" diff window height
if !exists('g:undotree_diffpanelHeight')
    let g:undotree_diffpanelHeight = 10
endif

" auto open diff window
if !exists('g:undotree_diffAutoOpen')
    let g:undotree_diffAutoOpen = 0
endif

"=================================================
" Golbal buf counter.
let s:cntr = 0

" Help text
let s:helpmore = ['" Undotree quick help',
            \'" -------------------']
let s:helpless = ['" Press ? for help.']

" Keymap
let s:keymap = []
" action, key, help.
let s:keymap += [['Help','?','Toggle quick help']]
let s:keymap += [['DiffToggle','D','Toggle diff panel']]
let s:keymap += [['Goup','K','Revert to next state']]
let s:keymap += [['Godown','J','Revert to previous state']]
let s:keymap += [['Redo','<c-r>','Redo']]
let s:keymap += [['Undo','u','Undo']]
let s:keymap += [['Enter','<2-LeftMouse>','Revert to current state']]
let s:keymap += [['Enter','<cr>','Revert to current state']]

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
    call s:log("s:exec() ".a:cmd)
    let ei_bak= &eventignore
    set eventignore=all
    silent exe a:cmd
    let &eventignore = ei_bak
endfunction

let s:debug = 0
let s:debugfile = $HOME.'/undotree_debug.log'
" If debug file exists, enable debug output.
if filewritable(s:debugfile)
    let s:debug = 1
    exec 'redir >> '. s:debugfile
    silent echo "=======================================\n"
    redir END
endif

function! s:log(msg)
    if s:debug
        exec 'redir >> ' . s:debugfile
        silent echon strftime('%H:%M:%S') . ': ' . a:msg . "\n"
        redir END
    endif
endfunction

"=================================================
"Base class for panels.
let s:panel = {}

function! s:panel.Init()
    let self.bufname = "invalid"
endfunction

function! s:panel.SetFocus()
    let winnr = bufwinnr(self.bufname)
    call s:log("SetFocus() winnr:".winnr." bufname:".self.bufname)
    " already focused.
    if winnr == winnr()
        return
    endif
    if winnr == -1
        echoerr "Fatal: window does not exist!"
        return
    endif
    " wincmd would cause cursor outside window.
    call s:exec("norm! ".winnr."\<c-w>\<c-w>")
endfunction

function! s:panel.IsVisible()
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:panel.Hide()
    call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
endfunction

"=================================================
" undotree panel class.
" extended from panel.
let s:undotree = s:new(s:panel)

" {rawtree}
"     |
"     | ConvertInput()               [seq2index]--> [seq1:index1]
"     v                                             [seq2:index2] ---+
"  {tree}                                               ...          |
"     |                                    [asciimeta]               |
"     | Render()                                |                    |
"     v                                         v                    |
" [asciitree] --> [" * | SEQ DDMMYY "] <==> [node1{seq,time,..}]     |
"                 [" |/             "]      [node2{seq,time,..}] <---+
"                         ...                       ...

function! s:undotree.Init()
    let self.bufname = "undotree_".s:cntr
    " Increase to make it unique.
    let s:cntr = s:cntr + 1
    let self.location = g:undotree_SplitLocation
    let self.mode = 'vertical'
    let self.size = g:undotree_SplitWidth
    let self.targetBufname = ''
    let self.rawtree = {}  "data passed from undotree()
    let self.tree = {}     "data converted to internal format.
    let self.nodelist = {} "stores an ordered list of items points to self.tree
    let self.currentseq = -1  "current node is the latest.
    let self.asciitree = []     "output data.
    let self.asciimeta = []     "meta data behind ascii tree.
    let self.currentIndex = -1 "line of the current node in ascii tree.
    let self.showHelp = 0
endfunction

function! s:undotree.BindKey()
    for i in s:keymap
        silent exec 'nnoremap <silent> <script> <buffer> '.i[1].' :call <sid>undotreeAction("'.i[0].'")<cr>'
    endfor
endfunction

function! s:undotree.BindAu()
    " Auto exit if it's the last window
    au WinEnter <buffer> if !t:undotree.IsTargetVisible() |
                \call t:undotree.Hide() | call t:diffpanel.Hide() | endif
endfunction

function! s:undotree.Action(action)
    call s:log("undotree.Action() ".a:action)
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

function! s:undotree.ActionDiffToggle()
    call t:diffpanel.Toggle()
endfunction

function! s:undotree.UpdateDiff()
    if !t:diffpanel.IsVisible()
        return
    endif
    let index = self.Screen2Index(line('.'))
    if index < 0
        return
    endif
    " -1: invalid node.
    "  0: no parent node.
    " >0: assume that seq>0 always has parent.
    if (self.asciimeta[index].seq) <= 0
        return
    endif
    call t:diffpanel.Update(self.asciimeta[index].seq,self.targetBufname)
endfunction

function! s:undotree.IsTargetVisible()
    if bufwinnr(self.targetBufname) != -1
        return 1
    else
        return 0
    endif
endfunction

" May fail due to target window closed.
function! s:undotree.SetTargetFocus()
    let winnr = bufwinnr(self.targetBufname)
    call s:log("undotree.SetTargetFocus() winnr:".winnr." targetBufname:".self.targetBufname)
    if winnr == -1
        return 0
    else
        call s:exec("norm! ".winnr."\<c-w>\<c-w>")
        return 1
    endif
endfunction

function! s:undotree.Toggle()
    call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
        call t:diffpanel.Hide()
    else
        call self.Show()
    endif
endfunction

function! s:undotree.Show()
    call s:log("undotree.Show()")
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
    call self.BindKey()
    call self.BindAu()
    " why refresh twice here?
    call self.Update()
    if g:undotree_diffAutoOpen
        call t:diffpanel.Show()
    endif
    if !g:undotree_SetFocusWhenToggle
        call self.SetTargetFocus()
    endif
endfunction

function! s:undotree.Update()
    call s:log("undotree.Update()")
    if !self.IsVisible()
        return
    endif
    let self.currentseq = -1
    let self.nodelist = {}
    let self.currentIndex = -1
    call self.ConvertInput()
    call self.Render()
    call self.Draw()
    call self.UpdateDiff()
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
    call s:exec('normal! H')
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
                let self.currentIndex = len(out) + 1
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
"diff panel
let s:diffpanel = s:new(s:panel)

function! s:diffpanel.Update(seq,targetBufname)
    call s:log('diffpanel.Update(),seq:'.a:seq.' bufname:'.a:targetBufname)
    " TODO check seq if cache hit.

    let ei_bak = &eventignore
    set eventignore=all

    let winnr = bufwinnr(a:targetBufname)
    if winnr == -1
        return
    else
        exec winnr." wincmd w"
    endif
    let new = getbufline(a:targetBufname,'^','$')
    undo
    let old = getbufline(a:targetBufname,'^','$')
    redo

    let &eventignore = ei_bak

    call self.SetFocus()
    setlocal modifiable
    call s:exec('1,$ d _')
    let tempfile1 = tempname()
    let tempfile2 = tempname()
    if writefile(old,tempfile1) == -1
        echoerr "Can not write to temp file:".tempfile1
        return
    endif
    if writefile(new,tempfile2) == -1
        echoerr "Can not write to temp file:".tempfile2
        return
    endif
    let diffresult = system('diff '.tempfile1.' '.tempfile2)
    call s:log("diffresult: ".diffresult)
    if delete(tempfile1) != 0
        echoerr "Can not delete temp file:".tempfile1
        return
    endif
    if delete(tempfile2) != 0
        echoerr "Can not delete temp file:".tempfile2
        return
    endif
    call append(0,split(diffresult,"\n"))
    call append(0,'- seq: '.a:seq.' -')

    "remove the last empty line
    call s:exec('$d _')
    setlocal nomodifiable
    call t:undotree.SetFocus()
endfunction

function! s:diffpanel.Init()
    let self.bufname = "diffpanel_".s:cntr
    " Increase to make it unique.
    let s:cntr = s:cntr + 1
endfunction

function! s:diffpanel.Toggle()
    call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
    else
        call self.Show()
    endif
endfunction

function! s:diffpanel.Show()
    call s:log("diffpanel.Show()")
    if self.IsVisible()
        return
    endif
    " Create diffpanel window.
    call t:undotree.SetFocus() "can not exist without undotree

    let sb_bak = &splitbelow
    let ei_bak= &eventignore
    set splitbelow
    set eventignore=all

    let cmd = g:undotree_diffpanelHeight.'new '.self.bufname
    exec cmd

    setlocal winfixwidth
    setlocal winfixheight
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nonumber
    setlocal nocursorline
    setlocal nomodifiable

    let &eventignore = ei_bak
    let &splitbelow = sb_bak

    " syntax need filetype autocommand
    setfiletype diff
    call self.BindAu()
    call t:undotree.SetFocus()
endfunction

function! s:diffpanel.BindAu()
    " Auto exit if it's the last window or undotree closed.
    au WinEnter <buffer> if !t:undotree.IsTargetVisible() |
                \call t:undotree.Hide() | call t:diffpanel.Hide() | endif
endfunction
"=================================================
" It will set the target of undotree window to the current editing buffer.
function! s:undotreeAction(action)
    call s:log("undotreeAction()")
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        echoerr "Fatal: t:undotree does not exists!"
        return
    endif
    call t:undotree.Action(a:action)
endfunction

function! UndotreeUpdate()
    call s:log(">>>>>>> UndotreeUpdate()")
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        return
    endif
    if &bt != '' "it's nor a normal buffer, could be help, quickfix, etc.
        return
    endif
    if &modifiable == 0 "no modifiable buffer.
        return
    endif
    if mode() != 'n' "not in normal mode, return.
        return
    endif
    if !t:undotree.IsVisible()
        return
    endif
    call s:log(">>> UndotreeUpdate()")
    call t:undotree.UpdateTarget()
    call t:undotree.SetFocus()
    call t:undotree.Update()
    call t:undotree.SetTargetFocus()
    call s:log("<<< UndotreeUpdate() leave")
endfunction

function! UndotreeToggle()
    call s:log(">>> UndotreeToggle()")
    if type(gettabvar(tabpagenr(),'undotree')) != type(s:undotree)
        let t:undotree = s:new(s:undotree)
        let t:diffpanel = s:new(s:diffpanel)
    endif
    call t:undotree.Toggle()
    call s:log("<<< UndotreeToggle() leave")
endfunction


"let s:auEvents = "InsertEnter,InsertLeave,WinEnter,WinLeave,CursorMoved"
let s:auEvents = "InsertLeave,CursorMoved"
exec "au ".s:auEvents." * call UndotreeUpdate()"

"=================================================
" User commands.
command! -n=0 -bar UndotreeToggle   :call UndotreeToggle()

" vim: set et fdm=marker sts=4 sw=4:
