### [Project on Vim.org](http://www.vim.org/scripts/script.php?script_id=4177)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mbbill/undotree?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Screenshot
![](https://sites.google.com/site/mbbill/undotree_new.png)

### Description
The plug-in visualize undo history and makes it easier to browse and switch between different undo branches. Wait a second, what do you mean by undo "branches"? Well, it's vim feature added a long time ago, and it allows you to go back to a state when it is overwritten by a latest edit. For example, you made a change A, then B, then go back to A and made change C, normally you won't be able to go back to B anymore on other editors. Vim internally maintains all the undo history as a tree structure, and this plug in exposes the tree to you so that you can switch to whatever state you need.


Some people have questions about file contents being changed when switching between undo history states. Don't worry, *undotree* will **NEVER** save your data or write to disk. All it does is to change the current buffer little bit, just like those auto-completion plug-ins does - it adds or removes something in the buffer temporarily, and if you don't like you can always go back to the last state easily. Let's say, you made some change but didn't save, now you use *undotree* and go back to an old version, your last change doesn't get lost - it stores in the latest undo history node. Clicking that node will bring you back instantly. Then you might ask what if I made some change without save and switch back to an old version and then **exit**? Well, imaging what would happen if you don't have *undotree*? You lost your latest edit and the file on disk is your last saved version. This behaviour remains the same with *undotree*, and that's why I highly recommend enabling *persistent undo*. Let me explain how persistent undo works: the biggest difference is that persistent undo keeps your undo history on disk, kind of like git. Let's say you made a change A, then B, then go back to A and made change C, and now you *save* the file. Now Vim save the file with content state C, and in the mean time it saves undo history to a file with A, B and C. Next time you open the file you can still go back to B because when you save, you save **everything** you did in the past. So, be careful don't let somebody else find our your secret - you know I'm kidding.


Undotree is written in **pure Vim script** and doesn't rely on any third party tools. It's lightweight, simple and fast. It only does what it supposed to do, and it only runs when you need it.

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
        set undodir=$HOME."/.undodir"
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

### License
**BSD**

### Author
Ming Bai  &lt;mbbill AT gmail DOT COM&gt;
