### [Link to Vim.org](http://www.vim.org/scripts/script.php?script_id=4177)

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
 1. TODO: Revert to a specific change by single click.
 1. TODO: Delete a part of undo-history.
 1. TODO: Hotkey support.
 1. TODO: Diff support.

### [Download](https://github.com/mbbill/undotree/tags)

### Install
 1. Unpack all scripts into *plugin* directory and that's all. This script is written purely in Vim script with no additional dependency.

### Usage
 1. Use `:UndotreeToggle` to toggle the undo-tree panel. You may want to map this command to whatever hotkey by adding the following line to your vimrc, take F5 for example.

    nnoremap    <F5>    :UndotreeToggle<cr>

 1. Then you can try to do some modification, and the undo tree will automatically updated afterwards.
 1. There are a bunch of hotkeys provided by vim to switch between the changes in history, like `u`, `<ctrl-r>`, `g+`, `g-` as well as the `:earlier` and `:later` commands.
 1. Persistent undo
    * It is highly recommend to enable the persistent undo. If you don't like your working directory be messed up with the undo file everywhere.
Add the following line to your *vimrc* in order to make them stored together.

    if has("persistent_undo")
        set undodir = '/path/to/what/you/want/'
        set undofile
    endif

### Configuration
 1. Basically, you do not need any configuration to let it work, cool?
 1. But if you still want to do some customization, there is also a bunch of options provided. Open the *undotree.vim* to find them out since they're changed rapidly now.

### Screenshot
![](http://files.myopera.com/mbbill/files/undotree.png)

### License
**BSD**

### Author
Ming Bai <mbbill AT gmail DOT COM>
