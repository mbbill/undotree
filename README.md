### [Project on Vim.org](http://www.vim.org/scripts/script.php?script_id=4177)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mbbill/undotree?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Screenshot
![](https://sites.google.com/site/mbbill/undotree_new.png)

### Description
Vim 7.0 added a new feature named **Undo branches**. Basically it's a kind of ability to go back to the text after any change, even if they were undone. Vim stores undo history in a tree which you can browse and manipulate through a bunch of commands. But that was not enough straightforward and a bit hard to use. You may use `:help new-undo-branches` or `:help undo-tree` to get more detailed help.
Now this plug-in will free you from those commands and bring back the power of undo tree.

### Features
 1. Visualize undo-tree
    * The undo history is sorted based on the changes' timestamp. The year/month/day field will not be displayed if the changes were made within the same day.
    * The change sequence number is displayed before timestamp.
    * The current position is marked as **>seq<**.
    * The next change that will be restored by `:redo` or `<ctrl-r>` is marked as **{seq}**, it's the same as *curhead* returned by *undotree()*
    * The **[seq]** marks the last change and where further changes will be added, it's the same as *newhead* returned by *undotree()*
    * Saved changes are marked as **s** and the capitalized **S** indicates the last saved change.
 1. Live updated diff panel.
 1. Highlight for added and changed text.
 1. Revert to a specific change by a single mouse click or key stroke.
 1. Customizable hotkeys and highlighting.
 1. Display changes in diff panel.

### [Download](https://github.com/mbbill/undotree/tags)

### Install
 1. Unpack all scripts into *.vim* directory and that's all. This script is written purely in Vim script with no additional dependency.
 1. It's highly recommend using **pathogen** or **Vundle** to manage your plug-ins.

### Usage
 1. Use `:UndotreeToggle` to toggle the undo-tree panel. You may want to map this command to whatever hotkey by adding the following line to your vimrc, take F5 for example.

    nnoremap    &lt;F5&gt;    :UndotreeToggle&lt;cr&gt;

 1. Then you can try to do some modification, and the undo tree will automatically updated afterwards.
 1. There are some hotkeys provided by vim to switch between the changes in history, like `u`, `<ctrl-r>`, `g+`, `g-` as well as the `:earlier` and `:later` commands.
 1. You may also switch to undotree panel and use the hotkeys to switch between history versions. Press `?` in undotree window for quick help of hotkeys.
 1. You can monitor the changed text in diff panel which is automatically updated when undo/redo happens.
 1. Persistent undo
    * It is highly recommend to enable the persistent undo. If you don't like your working directory be messed up with the undo file everywhere, you may add the following line to your *vimrc* in order to make them stored together.

// In your vimrc

    if has("persistent_undo")
        set undodir=~/.undodir/
        set undofile
    endif

### Configuration
 1. Basically, you do not need any configuration to let it work, cool?
 1. But if you still want to do some customization, there is also a couple of options provided.
    * [Here](https://github.com/mbbill/undotree/blob/master/plugin/undotree.vim#L15) is a list of these options.

### Post any issue and feature request here:
https://github.com/mbbill/undotree/issues

### Debug
 1. Create a file under $HOME with the name `undotree_debug.log`
    * `$touch ~/undotree_debug.log`
 1. Run vim, and the log will automatically be appended to the file, and you may watch it using `tail`:
    * `$tail -F ~/undotree_debug.log`
 1. If you want to disable debug, just delete that file.

### Alternatives
Someone asked me about the difference with [Gundo](https://bitbucket.org/sjl/gundo.vim/), here is a list of differences, or advantages.
 1. Pure vimscript implementation and no 3rd-party libraries(like python) is needed, don't worry about performance, it's not such a big deal for vim to handle this. The only dependency is the 'diff' tool which always shipped with vim and even without 'diff' you still can use most of the features of this script.
 1. Realtime updated undo tree. Once you make changes, the undo tree will be updated simultaneously.
 1. Several useful marks, like current changeset, next redo changeset, saved changeset, etc.
 1. Toggle between relative timestamp and absolute timestamp.
 1. Realtime updated undo window.
 1. Ability to clear undo history.
 1. More customizable.

### License
**BSD**

### Author
Ming Bai  &lt;mbbill AT gmail DOT COM&gt;
