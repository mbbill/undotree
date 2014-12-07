"=================================================
" File: undotree.vim
" Description: Manage your undo history in a graph.
" Author: Ming Bai <mbbill@gmail.com>
" License: BSD

" Avoid installing twice.
if exists('g:loaded_undotree')
    finish
endif
let g:loaded_undotree = 0

" At least version 7.3 with 005 patch is needed for undo branches.
" Refer to https://github.com/mbbill/undotree/issues/4 for details.
" Thanks kien
if v:version < 703
    command! -n=0 -bar UndotreeToggle :echoerr "undotree.vim needs Vim version >= 7.3"
    finish
endif
if (v:version == 703 && !has("patch005"))
    command! -n=0 -bar UndotreeToggle :echoerr "undotree.vim needs vim7.3 with patch005 applied."
    finish
endif
let g:loaded_undotree = 1   " Signal plugin availability with a value of 1.

"=================================================
"Options:

" Window layout
" style 1
" +----------+------------------------+
" |          |                        |
" |          |                        |
" | undotree |                        |
" |          |                        |
" |          |                        |
" +----------+                        |
" |          |                        |
" |   diff   |                        |
" |          |                        |
" +----------+------------------------+
" Style 2
" +----------+------------------------+
" |          |                        |
" |          |                        |
" | undotree |                        |
" |          |                        |
" |          |                        |
" +----------+------------------------+
" |                                   |
" |   diff                            |
" |                                   |
" +-----------------------------------+
" Style 3
" +------------------------+----------+
" |                        |          |
" |                        |          |
" |                        | undotree |
" |                        |          |
" |                        |          |
" |                        +----------+
" |                        |          |
" |                        |   diff   |
" |                        |          |
" +------------------------+----------+
" Style 4
" +-----------------------++----------+
" |                        |          |
" |                        |          |
" |                        | undotree |
" |                        |          |
" |                        |          |
" +------------------------+----------+
" |                                   |
" |                            diff   |
" |                                   |
" +-----------------------------------+
if !exists('g:undotree_WindowLayout')
    let g:undotree_WindowLayout = 1
endif

" undotree window width
if !exists('g:undotree_SplitWidth')
    let g:undotree_SplitWidth = 30
endif

" diff window height
if !exists('g:undotree_DiffpanelHeight')
    let g:undotree_DiffpanelHeight = 10
endif

" auto open diff window
if !exists('g:undotree_DiffAutoOpen')
    let g:undotree_DiffAutoOpen = 1
endif

" if set, let undotree window get focus after being opened, otherwise
" focus will stay in current window.
if !exists('g:undotree_SetFocusWhenToggle')
    let g:undotree_SetFocusWhenToggle = 0
endif

" tree node shape.
if !exists('g:undotree_TreeNodeShape')
    let g:undotree_TreeNodeShape = '*'
endif

if !exists('g:undotree_DiffCommand')
    let g:undotree_DiffCommand = "diff"
endif

" relative timestamp
if !exists('g:undotree_RelativeTimestamp')
    let g:undotree_RelativeTimestamp = 1
endif

" Highlight changed text
if !exists('g:undotree_HighlightChangedText')
    let g:undotree_HighlightChangedText = 1
endif

" Highlight linked syntax type.
" You may chose your favorite through ":hi" command
if !exists('g:undotree_HighlightSyntaxAdd')
    let g:undotree_HighlightSyntaxAdd = "DiffAdd"
endif
if !exists('g:undotree_HighlightSyntaxChange')
    let g:undotree_HighlightSyntaxChange = "DiffChange"
endif

" Deprecates the old style configuration.
if exists('g:undotree_SplitLocation')
    echo "g:undotree_SplitLocation is deprecated,
                \ please use g:undotree_WindowLayout instead."
endif

"Custom key mappings: add this function to your vimrc.
"You can define whatever mapping as you like, this is a hook function which
"will be called after undotree window initialized.
"
"function g:undotree_CustomMap()
"    map <buffer> <c-n> J
"    map <buffer> <c-p> K
"endfunction

"=================================================
" Help text
let s:helpmore = ['"    ===== Marks ===== ',
            \'" >num< : current change',
            \'" {num} : change to redo',
            \'" [num] : the last change',
            \'"   s   : saved changes',
            \'"   S   : last saved change',
            \'"   ===== Hotkeys =====']
let s:helpless = ['" Press ? for help.']

" Keymap
let s:keymap = []
" action, key, help.
let s:keymap += [['Help','?','Toggle quick help']]
let s:keymap += [['Close','q','Close this panel']]
let s:keymap += [['FocusTarget','<tab>','Set Focus to editor']]
let s:keymap += [['ClearHistory','C','Clear undo history']]
let s:keymap += [['TimestampToggle','T','Toggle relative timestamp']]
let s:keymap += [['DiffToggle','D','Toggle diff panel']]
let s:keymap += [['GoNext','K','Revert to next state']]
let s:keymap += [['GoPrevious','J','Revert to previous state']]
let s:keymap += [['GoNextSaved','<','Revert to next saved state']]
let s:keymap += [['GoPreviousSaved','>','Revert to previous saved state']]
let s:keymap += [['Redo','<c-r>','Redo']]
let s:keymap += [['Undo','u','Undo']]
let s:keymap += [['Enter','<2-LeftMouse>','Revert to current']]
let s:keymap += [['Enter','<cr>','Revert to current']]

function! s:new(obj)
    let newobj = deepcopy(a:obj)
    call newobj.Init()
    return newobj
endfunction

" Get formatted time
function! s:gettime(time)
    if a:time == 0
        return "Original"
    endif
    if !g:undotree_RelativeTimestamp
        let today = substitute(strftime("%c",localtime())," .*$",'','g')
        if today == substitute(strftime("%c",a:time)," .*$",'','g')
            return strftime("%H:%M:%S",a:time)
        else
            return strftime("%H:%M:%S %b%d %Y",a:time)
        endif
    else
        let sec = localtime() - a:time
        if sec < 0
            let sec = 0
        endif
        if sec < 60
            if sec == 1
                return '1 second ago'
            else
                return sec.' seconds ago'
            endif
        endif
        if sec < 3600
            if (sec/60) == 1
                return '1 minute ago'
            else
                return (sec/60).' minutes ago'
            endif
        endif
        if sec < 86400 "3600*24
            if (sec/3600) == 1
                return '1 hour ago'
            else
                return (sec/3600).' hours ago'
            endif
        endif
        return (sec/86400).' days ago'
    endif
endfunction

function! s:exec(cmd)
    call s:log("s:exec() ".a:cmd)
    silent exe a:cmd
endfunction

" Don't trigger any events(like BufEnter which could cause redundant refresh)
function! s:exec_silent(cmd)
    call s:log("s:exec_silent() ".a:cmd)
    let ei_bak= &eventignore
    set eventignore=all
    silent exe a:cmd
    let &eventignore = ei_bak
endfunction

" Return a unique id each time.
let s:cntr = 0
function! s:getUniqueID()
    let s:cntr = s:cntr + 1
    return s:cntr
endfunction

" Debug...
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
        silent echon strftime('%H:%M:%S') . ': ' . string(a:msg) . "\n"
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
    " already focused.
    if winnr == winnr()
        return
    endif
    if winnr == -1
        echoerr "Fatal: window does not exist!"
        return
    endif
    call s:log("SetFocus() winnr:".winnr." bufname:".self.bufname)
    " wincmd would cause cursor outside window.
    call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>")
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
"

" {rawtree}
"     |
"     | ConvertInput()               {seq2index}--> [seq1:index1]
"     v                                             [seq2:index2] ---+
"  {tree}                                               ...          |
"     |                                    [asciimeta]               |
"     | Render()                                |                    |
"     v                                         v                    |
" [asciitree] --> [" * | SEQ DDMMYY "] <==> [node1{seq,time,..}]     |
"                 [" |/             "]      [node2{seq,time,..}] <---+
"                         ...                       ...

let s:undotree = s:new(s:panel)

function! s:undotree.Init()
    let self.bufname = "undotree_".s:getUniqueID()
    " Increase to make it unique.
    let self.width = g:undotree_SplitWidth
    let self.opendiff = g:undotree_DiffAutoOpen
    let self.targetid = -1
    let self.targetBufnr = -1
    let self.rawtree = {}  "data passed from undotree()
    let self.tree = {}     "data converted to internal format.
    let self.seq_last = -1
    let self.save_last = -1
    let self.save_last_bak = -1

    " seqs
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    let self.seq_saved = {} "{saved value -> seq} pair

    "backup, for mark
    let self.seq_cur_bak = -1
    let self.seq_curhead_bak = -1
    let self.seq_newhead_bak = -1

    let self.asciitree = []     "output data.
    let self.asciimeta = []     "meta data behind ascii tree.
    let self.seq2index = {}     "table used to convert seq to index.
    let self.showHelp = 0
endfunction

function! s:undotree.BindKey()
    if v:version > 703 || (v:version == 703 && has("patch1261"))
        let map_options = '<nowait> '
    else
        let map_options = ''
    endif
    for i in s:keymap
        silent exec 'nnoremap <silent> <script> <buffer> '
            \ .map_options
            \ .i[1].' :call <sid>undotreeAction("'.i[0].'")<cr>'
    endfor
    if exists('*g:Undotree_CustomMap')
        call g:Undotree_CustomMap()
    endif
endfunction

function! s:undotree.BindAu()
    " Auto exit if it's the last window
    augroup Undotree_Main
        au!
        au BufEnter <buffer> call s:exitIfLast()
        au BufEnter,BufLeave <buffer> if exists('t:undotree') |
                    \let t:undotree.width = winwidth(winnr()) | endif
        au BufWinLeave <buffer> if exists('t:diffpanel') |
                    \call t:diffpanel.Hide() | endif
    augroup end
endfunction

function! s:undotree.Action(action)
    call s:log("undotree.Action() ".a:action)
    if !self.IsVisible() || bufname("%") != self.bufname
        echoerr "Fatal: window does not exists."
        return
    endif
    if !has_key(self,'Action'.a:action)
        echoerr "Fatal: Action does not exists!"
        return
    endif
    silent exec 'call self.Action'.a:action.'()'
endfunction

" Helper function, do action in target window, and then update itself.
function! s:undotree.ActionInTarget(cmd)
    if !self.SetTargetFocus()
        return
    endif
    " Target should be a normal buffer.
    if (&bt == '') && (&modifiable == 1) && (mode() == 'n')
        call s:exec(a:cmd)
        call self.Update()
    endif
    " Update not always set current focus.
    call self.SetFocus()
endfunction

function! s:undotree.ActionHelp()
    let self.showHelp = !self.showHelp
    call self.Draw()
    call self.MarkSeqs()
endfunction

function! s:undotree.ActionFocusTarget()
    call self.SetTargetFocus()
endfunction

function! s:undotree.ActionEnter()
    let index = self.Screen2Index(line('.'))
    if index < 0
        return
    endif
    let seq = self.asciimeta[index].seq
    if seq == -1
        return
    endif
    if seq == 0
        call self.ActionInTarget('norm 9999u')
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

function! s:undotree.ActionGoPrevious()
    call self.ActionInTarget('earlier')
endfunction

function! s:undotree.ActionGoNext()
    call self.ActionInTarget('later')
endfunction

function! s:undotree.ActionGoPreviousSaved()
    call self.ActionInTarget('earlier 1f')
endfunction

function! s:undotree.ActionGoNextSaved()
    call self.ActionInTarget('later 1f')
endfunction

function! s:undotree.ActionDiffToggle()
    let self.opendiff = !self.opendiff
    call t:diffpanel.Toggle()
    call self.UpdateDiff()
endfunction

function! s:undotree.ActionTimestampToggle()
    if !self.SetTargetFocus()
        return
    endif
    let g:undotree_RelativeTimestamp = !g:undotree_RelativeTimestamp
    let self.targetBufnr = -1 "force update
    call self.Update()
    " Update not always set current focus.
    call self.SetFocus()
endfunction

function! s:undotree.ActionClearHistory()
    if confirm("Are you sure to clear ALL undo history?","&Yes\n&No") != 1
        return
    endif
    if !self.SetTargetFocus()
        return
    endif
    let ul_bak = &undolevels
    let &undolevels = -1
    call s:exec("norm! a \<BS>\<Esc>")
    let &undolevels = ul_bak
    unlet ul_bak
    let self.targetBufnr = -1 "force update
    call self.Update()
endfunction

function! s:undotree.ActionClose()
    call self.Toggle()
endfunction

function! s:undotree.UpdateDiff()
    call s:log("undotree.UpdateDiff()")
    if !t:diffpanel.IsVisible()
        return
    endif
    call t:diffpanel.Update(self.seq_cur,self.targetBufnr,self.targetid)
endfunction

" May fail due to target window closed.
function! s:undotree.SetTargetFocus()
    for winnr in range(1, winnr('$')) "winnr starts from 1
        if getwinvar(winnr,'undotree_id') == self.targetid
            if winnr() != winnr
                call s:exec("norm! ".winnr."\<c-w>\<c-w>")
                return 1
            endif
        endif
    endfor
    return 0
endfunction

function! s:undotree.Toggle()
    call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
        call t:diffpanel.Hide()
        call self.SetTargetFocus()
    else
        call self.Show()
        if !g:undotree_SetFocusWhenToggle
            call self.SetTargetFocus()
        endif
    endif
endfunction

function! s:undotree.GetStatusLine()
    if self.seq_cur != -1
        let seq_cur = self.seq_cur
    else
        let seq_cur = 'None'
    endif
    if self.seq_curhead != -1
        let seq_curhead = self.seq_curhead
    else
        let seq_curhead = 'None'
    endif
    return 'current: '.seq_cur.' redo: '.seq_curhead
endfunction

function! s:undotree.Show()
    call s:log("undotree.Show()")
    if self.IsVisible()
        return
    endif

    let self.targetid = w:undotree_id

    " Create undotree window.
    if g:undotree_WindowLayout == 1 || g:undotree_WindowLayout == 2
        let cmd = "topleft vertical" .
                    \self.width . ' new ' . self.bufname
    else
        let cmd = "botright vertical" .
                    \self.width . ' new ' . self.bufname
    endif
    call s:exec("silent keepalt ".cmd)
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
    setlocal statusline=%!t:undotree.GetStatusLine()
    setfiletype undotree

    call self.BindKey()
    call self.BindAu()

    let ei_bak= &eventignore
    set eventignore=all

    call self.SetTargetFocus()
    let self.targetBufnr = -1 "force update
    call self.Update()

    let &eventignore = ei_bak

    if self.opendiff
        call t:diffpanel.Show()
        call self.UpdateDiff()
    endif
endfunction

" called outside undotree window
function! s:undotree.Update()
    if !self.IsVisible()
        return
    endif
    " do nothing if we're in the undotree or diff panel
    let bufname = bufname('%')
    if bufname == self.bufname || bufname == t:diffpanel.bufname
        return
    endif
    if (&bt != '') || (&modifiable == 0) || (mode() != 'n')
        if self.targetBufnr == bufnr('%') && self.targetid == w:undotree_id
            call s:log("undotree.Update() invalid buffer NOupdate")
            return
        endif
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
        call s:log("undotree.Update() invalid buffer update")
    else
        let emptybuf = 0
        "update undotree,set focus
        if self.targetBufnr == bufnr('%')
            let self.targetid = w:undotree_id
            let newrawtree = undotree()
            if self.rawtree == newrawtree
                return
            endif

            " same buffer, but seq changed.
            if newrawtree.seq_last == self.seq_last
                call s:log("undotree.Update() update seqs")
                let self.rawtree = newrawtree
                call self.ConvertInput(0) "only update seqs.
                if (self.seq_cur == self.seq_cur_bak) &&
                            \(self.seq_curhead == self.seq_curhead_bak)&&
                            \(self.seq_newhead == self.seq_newhead_bak)&&
                            \(self.save_last == self.save_last_bak)
                    return
                endif
                call self.SetFocus()
                call self.MarkSeqs()
                call self.UpdateDiff()
                return
            endif
        endif
    endif
    call s:log("undotree.Update() update whole tree")

    let self.targetBufnr = bufnr('%')
    let self.targetid = w:undotree_id
    if emptybuf " Show an empty undo tree instead of do nothing.
        let self.rawtree = {'seq_last':0,'entries':[],'time_cur':0,'save_last':0,'synced':1,'save_cur':0,'seq_cur':0}
    else
        let self.rawtree = undotree()
    endif
    let self.seq_last = self.rawtree.seq_last
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    call self.ConvertInput(1) "update all.
    call self.Render()
    call self.SetFocus()
    call self.Draw()
    call self.MarkSeqs()
    call self.UpdateDiff()
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
    " index starts from zero and lineNr starts from 1
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
    let savedview = winsaveview()

    setlocal modifiable
    " Delete text into blackhole register.
    call s:exec('1,$ d _')
    call append(0,self.asciitree)

    call self.AppendHelp()

    "remove the last empty line
    call s:exec('$d _')

    " restore previous cursor position.
    call winrestview(savedview)

    setlocal nomodifiable
endfunction

function! s:undotree.MarkSeqs()
    call s:log("bak(cur,curhead,newhead): ".
                \self.seq_cur_bak.' '.
                \self.seq_curhead_bak.' '.
                \self.seq_newhead_bak)
    call s:log("(cur,curhead,newhead): ".
                \self.seq_cur.' '.
                \self.seq_curhead.' '.
                \self.seq_newhead)
    setlocal modifiable
    " reset bak seq lines.
    if self.seq_cur_bak != -1
        let index = self.seq2index[self.seq_cur_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    endif
    if self.seq_curhead_bak != -1
        let index = self.seq2index[self.seq_curhead_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    endif
    if self.seq_newhead_bak != -1
        let index = self.seq2index[self.seq_newhead_bak]
        call setline(self.Index2Screen(index),self.asciitree[index])
    endif
    " mark save seqs
    for i in keys(self.seq_saved)
        let index = self.seq2index[self.seq_saved[i]]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(self.asciitree[index],
                    \' \d\+  \zs \ze','s',''))
    endfor
    let max_saved_num = max(keys(self.seq_saved))
    if max_saved_num > 0
        let lineNr = self.Index2Screen(self.seq2index[self.seq_saved[max_saved_num]])
        call setline(lineNr,substitute(getline(lineNr),'s','S',''))
    endif
    " mark new seqs.
    if self.seq_cur != -1
        let index = self.seq2index[self.seq_cur]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','>\1<',''))
        " move cursor to that line.
        call s:exec("normal! " . lineNr . "G")
    endif
    if self.seq_curhead != -1
        let index = self.seq2index[self.seq_curhead]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','{\1}',''))
    endif
    if self.seq_newhead != -1
        let index = self.seq2index[self.seq_newhead]
        let lineNr = self.Index2Screen(index)
        call setline(lineNr,substitute(getline(lineNr),
                    \'\zs \(\d\+\) \ze [sS ] ','[\1]',''))
    endif
    setlocal nomodifiable
endfunction

" tree node class
let s:node = {}

function! s:node.Init()
    let self.seq = -1
    let self.p = []
    let self.time = -1
endfunction

function! s:undotree._parseNode(in,out)
    " type(in) == type([]) && type(out) == type({})
    if empty(a:in) "empty
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
            let self.seq_newhead = i.seq
        endif
        if has_key(i,'curhead')
            let self.seq_curhead = i.seq
            let self.seq_cur = curnode.seq
        endif
        if has_key(i,'save')
            let self.seq_saved[i.save] = i.seq
        endif
        call extend(curnode.p,[newnode])
        let curnode = newnode
    endfor
endfunction

"Sample:
"let s:test={'seq_last': 4, 'entries': [{'seq': 3, 'alt': [{'seq': 1, 'time': 1345131443}, {'seq': 2, 'time': 1345131445}], 'time': 1345131490}, {'seq': 4, 'time': 1345131492, 'newhead': 1}], 'time_cur': 1345131493, 'save_last': 0, 'synced': 0, 'save_cur': 0, 'seq_cur': 4}

" updatetree: 0: no update, just assign seqs;  1: update and assign seqs.
function! s:undotree.ConvertInput(updatetree)
    "reset seqs
    let self.seq_cur_bak = self.seq_cur
    let self.seq_curhead_bak = self.seq_curhead
    let self.seq_newhead_bak = self.seq_newhead
    let self.save_last_bak = self.save_last

    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    let self.seq_saved = {}

    "Generate root node
    let root = s:new(s:node)
    let root.seq = 0
    let root.time = 0

    call self._parseNode(self.rawtree.entries,root)

    let self.save_last = self.rawtree.save_last
    " Note: Normally, the current node should be the one that seq_cur points to,
    " but in fact it's not. May be bug, bug anyway I found a workaround:
    " first try to find the parent node of 'curhead', if not found, then use
    " seq_cur.
    if self.seq_cur == -1
        let self.seq_cur = self.rawtree.seq_cur
    endif
    " undo history is cleared
    if empty(self.rawtree.entries)
        let self.seq_cur = 0
    endif
    if a:updatetree
        let self.tree = root
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
    let out = []
    let outmeta = []
    let seq2index = {}
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
        let minseq = 99999999
        let minnode = {}
        if foundx == 0
            "assume undo level isn't more than this... of course
            for i in range(len(slots))
                if type(slots[i]) == TYPE_E
                    if slots[i].seq < minseq
                        let minseq = slots[i].seq
                        let index = i
                        let minnode = slots[i]
                        continue
                    endif
                endif
                if type(slots[i]) == TYPE_P
                    for j in slots[i]
                        if j.seq < minseq
                            let minseq = j.seq
                            let index = i
                            let minnode = j
                            continue
                        endif
                    endfor
                endif
            endfor
        endif

        " output.
        let onespace = " "
        let newline = onespace
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
            let seq2index[node.seq]=len(out)
            for i in range(len(slots))
                if index == i
                    let newline = newline.g:undotree_TreeNodeShape.' '
                else
                    let newline = newline.'| '
                endif
            endfor
            let newline = newline.'   '.(node.seq).'    '.
                        \'('.s:gettime(node.time).')'
            " update the printed slot to its child.
            if empty(node.p)
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
                    call insert(slots,node[1],index)
                    call insert(slots,node[0],index)
                else
                    call insert(slots,node[0],index)
                    call insert(slots,node[1],index)
                endif
            endif
            " split P to E+P if elements in p > 2
            if len(node) > 2
                call remove(node,index(node,minnode))
                call insert(slots,minnode,index)
                call insert(slots,node,index)
            endif
        endif
        unlet node
        if newline != onespace
            let newline = substitute(newline,'\s*$','','g') "remove trailing space.
            call insert(out,newline,0)
            call insert(outmeta,newmeta,0)
        endif
    endwhile
    let self.asciitree = out
    let self.asciimeta = outmeta
    " revert index.
    let totallen = len(out)
    for i in keys(seq2index)
        let seq2index[i] = totallen - 1 - seq2index[i]
    endfor
    let self.seq2index = seq2index
endfunction

"=================================================
"diff panel
let s:diffpanel = s:new(s:panel)

function! s:diffpanel.Update(seq,targetBufnr,targetid)
    call s:log('diffpanel.Update(),seq:'.a:seq.' bufname:'.bufname(a:targetBufnr))
    if !self.diffexecutable
        return
    endif
    let diffresult = []
    let self.changes.add = 0
    let self.changes.del = 0

    if a:seq == 0
        let diffresult = []
    else
        if has_key(self.cache,a:targetBufnr.'_'.a:seq)
            call s:log("diff cache hit.")
            let diffresult = self.cache[a:targetBufnr.'_'.a:seq]
        else
            let ei_bak = &eventignore
            set eventignore=all
            let targetWinnr = -1

            " Double check the target winnr and bufnr
            for winnr in range(1, winnr('$')) "winnr starts from 1
                if (getwinvar(winnr,'undotree_id') == a:targetid)
                            \&& winbufnr(winnr) == a:targetBufnr
                    let targetWinnr = winnr
                endif
            endfor
            if targetWinnr == -1
                return
            endif
            call s:exec_silent(targetWinnr." wincmd w")

            " remember and restore cursor and window position.
            let savedview = winsaveview()

            let new = getbufline(a:targetBufnr,'^','$')
            silent undo
            let old = getbufline(a:targetBufnr,'^','$')
            silent redo

            call winrestview(savedview)

            " diff files.
            let tempfile1 = tempname()
            let tempfile2 = tempname()
            if writefile(old,tempfile1) == -1
                echoerr "Can not write to temp file:".tempfile1
            endif
            if writefile(new,tempfile2) == -1
                echoerr "Can not write to temp file:".tempfile2
            endif
            let diffresult = split(system(g:undotree_DiffCommand.' '.tempfile1.' '.tempfile2),"\n")
            call s:log("diffresult: ".string(diffresult))
            if delete(tempfile1) != 0
                echoerr "Can not delete temp file:".tempfile1
            endif
            if delete(tempfile2) != 0
                echoerr "Can not delete temp file:".tempfile2
            endif
            let &eventignore = ei_bak
            "Update cache
            let self.cache[a:targetBufnr.'_'.a:seq] = diffresult
        endif
    endif

    call self.ParseDiff(diffresult)

    call self.SetFocus()

    setlocal modifiable
    call s:exec('1,$ d _')

    call append(0,diffresult)
    call append(0,'- seq: '.a:seq.' -')

    "remove the last empty line
    if getline("$") == ""
        call s:exec('$d _')
    endif
    call s:exec('norm! gg') "move cursor to line 1.
    setlocal nomodifiable
    call t:undotree.SetFocus()
endfunction

function! s:diffpanel.ParseDiff(diffresult)
    " set target focus first.
    call t:undotree.SetTargetFocus()

    if empty(a:diffresult)
        return
    endif
    " clear previous highlighted syntax
    " matchadd associates with windows.
    if exists("w:undotree_diffmatches")
        for i in w:undotree_diffmatches
            call matchdelete(i)
        endfor
    endif
    let w:undotree_diffmatches = []
    let lineNr = 0
    for line in a:diffresult
        let matchnum = matchstr(line,'^[0-9,\,]*[ac]\zs\d*\ze')
        if !empty(matchnum)
            let lineNr = str2nr(matchnum)
            let matchwhat = matchstr(line,'^[0-9,\,]*\zs[ac]\ze\d*')
            continue
        endif
        if matchstr(line,'^<.*$') != ''
            let self.changes.del += 1
        endif
        let matchtext = matchstr(line,'^>\zs .*$')
        if empty(matchtext)
            continue
        endif
        let self.changes.add += 1
        if g:undotree_HighlightChangedText
            if matchtext != ' '
                let matchtext = '\%'.lineNr.'l\V'.escape(matchtext[1:],'"\') "remove beginning space.
                call s:log("matchadd(".matchwhat.") ->  ".matchtext)
                call add(w:undotree_diffmatches,matchadd((matchwhat ==# 'a' ? g:undotree_HighlightSyntaxAdd : g:undotree_HighlightSyntaxChange),matchtext))
            endif
        endif

        let lineNr = lineNr+1
    endfor
endfunction

function! s:diffpanel.GetStatusLine()
    let max = winwidth(0) - 4
    let sum = self.changes.add + self.changes.del
    if sum > max
        let add = self.changes.add * max / sum + 1
        let del = self.changes.del * max / sum + 1
    else
        let add = self.changes.add
        let del = self.changes.del
    endif
    return string(sum).' '.repeat('+',add).repeat('-',del)
endfunction

function! s:diffpanel.Init()
    let self.bufname = "diffpanel_".s:getUniqueID()
    let self.cache = {}
    let self.changes = {'add':0, 'del':0}
    let self.diffexecutable = executable('diff')
    if !self.diffexecutable
        echoerr '"diff" is not executable.'
    endif
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
    " remember and restore cursor and window position.
    let savedview = winsaveview()

    let ei_bak= &eventignore
    set eventignore=all

    if g:undotree_WindowLayout == 1 || g:undotree_WindowLayout == 3
        let cmd = 'belowright '.g:undotree_DiffpanelHeight.'new '.self.bufname
    else
        let cmd = 'botright '.g:undotree_DiffpanelHeight.'new '.self.bufname
    endif
    call s:exec_silent(cmd)

    setlocal winfixwidth
    setlocal winfixheight
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal nobuflisted
    setlocal nospell
    setlocal nonumber
    setlocal nocursorline
    setlocal nomodifiable
    setlocal statusline=%!t:diffpanel.GetStatusLine()

    let &eventignore = ei_bak

    " syntax need filetype autocommand
    setfiletype diff
    setlocal foldcolumn=0
    setlocal nofoldenable

    call self.BindAu()
    call t:undotree.SetFocus()
    call winrestview(savedview)
endfunction

function! s:diffpanel.BindAu()
    " Auto exit if it's the last window or undotree closed.
    augroup Undotree_Diff
        au!
        au BufEnter <buffer> call s:exitIfLast()
        au BufEnter <buffer> if !t:undotree.IsVisible()
                    \|call t:diffpanel.Hide() |endif
    augroup end
endfunction

function! s:diffpanel.CleanUpHighlight()
    call s:log("CleanUpHighlight()")
    " save current position
    let curwinnr = winnr()
    let savedview = winsaveview()

    " clear w:undotree_diffmatches in all windows.
    let winnum = winnr('$')
    for i in range(1,winnum)
        call s:exec_silent("norm! ".i."\<c-w>\<c-w>")
        if exists("w:undotree_diffmatches")
            for j in w:undotree_diffmatches
                call matchdelete(j)
            endfor
            let w:undotree_diffmatches = []
        endif
    endfor

    "restore position
    call s:exec_silent("norm! ".curwinnr."\<c-w>\<c-w>")
    call winrestview(savedview)
endfunction

function! s:diffpanel.Hide()
    call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
    call self.CleanUpHighlight()
endfunction

"=================================================
" It will set the target of undotree window to the current editing buffer.
function! s:undotreeAction(action)
    call s:log("undotreeAction()")
    if !exists('t:undotree')
        echoerr "Fatal: t:undotree does not exists!"
        return
    endif
    call t:undotree.Action(a:action)
endfunction

function! s:exitIfLast()
    let num = 0
    if t:undotree.IsVisible()
        let num = num + 1
    endif
    if t:diffpanel.IsVisible()
        let num = num + 1
    endif
    if winnr('$') == num
        call t:undotree.Hide()
        call t:diffpanel.Hide()
    endif
endfunction

"=================================================
"called outside undotree window
function! UndotreeUpdate()
    if !exists('t:undotree')
        return
    endif
    if !exists('w:undotree_id')
        let w:undotree_id = 'id_'.s:getUniqueID()
        call s:log("Unique window id assigned: ".w:undotree_id)
    endif
    " assume window layout won't change during updating.
    let thiswinnr = winnr()
    call t:undotree.Update()
    " focus moved
    if winnr() != thiswinnr
        call s:exec("norm! ".thiswinnr."\<c-w>\<c-w>")
    endif
endfunction

function! UndotreeToggle()
    call s:log(">>> UndotreeToggle()")
    if !exists('w:undotree_id')
        let w:undotree_id = 'id_'.s:getUniqueID()
        call s:log("Unique window id assigned: ".w:undotree_id)
    endif

    if !exists('t:undotree')
        let t:undotree = s:new(s:undotree)
        let t:diffpanel = s:new(s:diffpanel)
    endif
    call t:undotree.Toggle()
    call s:log("<<< UndotreeToggle() leave")
endfunction

function! UndotreeIsVisible()
    return (exists('t:undotree') && t:undotree.IsVisible())
endfunction

function! UndotreeHide()
    if UndotreeIsVisible()
        call UndotreeToggle()
    endif
endfunction

function! UndotreeShow()
    if ! UndotreeIsVisible()
        call UndotreeToggle()
    else
        call t:undotree.SetFocus()
    endif
endfunction

function! UndotreeFocus()
    if UndotreeIsVisible()
        call t:undotree.SetFocus()
    endif
endfunction


"let s:auEvents = "InsertEnter,InsertLeave,WinEnter,WinLeave,CursorMoved"
let s:auEvents = "BufEnter,InsertLeave,CursorMoved,BufWritePost"
augroup Undotree
    exec "au! ".s:auEvents." * call UndotreeUpdate()"
augroup END

"=================================================
" User commands.
command! -n=0 -bar UndotreeToggle   :call UndotreeToggle()
command! -n=0 -bar UndotreeHide     :call UndotreeHide()
command! -n=0 -bar UndotreeShow     :call UndotreeShow()
command! -n=0 -bar UndotreeFocus    :call UndotreeFocus()

" vim: set et fdm=marker sts=4 sw=4:
