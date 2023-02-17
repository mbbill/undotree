### [Project on Vim.org](http://www.vim.org/scripts/script.php?script_id=4177)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mbbill/undotree?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Screenshot

![](doc/_static/undotree.png)

### Table of Contents

<!-- TOC -->

- [Description](#description)
- [Download and Install](#download-and-install)
- [Usage](#usage)
    - [Configuration](#configuration)
    - [Debug](#debug)
- [License](#license)
- [Author](#author)

<!-- /TOC -->

### Description

Undotree visualizes the undo history and makes it easy to browse and switch between different undo branches. You may be wondering, _what are undo "branches" anyway?_ They're a feature of Vim that allow you to go back to a prior state even after it has been overwritten by later edits. For example: In most editors, if you make some change A, followed by change B, then go back to A and make another change C, normally you wouldn't be able to go back to change B because the undo history is linear. That's not the case with Vim, however. Vim internally stores the entire edit history for each file as a single, monolithic tree structure; this plug-in exposes that tree to you so that you can not only switch back and forth between older and more recent edits linearly but can also switch between diverging branches.

> Note: use `:help 'undolevels'` in Vim for information on configuring the size of the undo history


### Safety

Some people have questions about whether file contents change when switching between undo history states. Don't worry, *undotree* will **NEVER** save your data or write to disk. All it does is change the current buffer a little bit - just like those auto-completion plug-ins do - and will only add or remove something in the buffer temporarily. If you don't like the changes, you can go back to any prior state with just a single click. Let's say that you've made some change but didn't save it, then you use *undotree* to go back to some arbitrary previous version: your unsaved change does not get lost - it gets stored in the latest undo history node. Clicking on that node in *undotree* will bring you back instantly. Playing with undo/redo in other editors is always dangerous because if you step back and then accidentally type something, boom! You lose your edits. But don't worry, that will not happen in Vim. You might also be wondering, _what if I make some changes without saving then switch back to an older version and **exit**?_ Well, imagine what would happen if you didn't have *undotree*? You'd lose your latest edits and the file on disk would be your last saved version. This behavior **remains the same** with *undotree*. So, if you've saved the file, you will not lose anything.

> Note: use `:help persistent-undo` in Vim for instructions on how to persist the undo file


### Persisting the undo history

Undo/redo functionality is a useful feature for most editors, including Vim. However, by default, Vim's undo history is only available during the current editing session, as it is stored in memory and lost once the process exits. While tools such as undotree can aid in accessing historical states, it does not offer a permanent solution. For some users, it may be safer or more convenient to persist the undo history across editing sessions, and that's where Vim's persistent undo feature comes in.

Persistent undo saves the undo history in a file on disk, rather than in RAM. Whenever a change is made, Vim saves the edited file with its current state, while also saving the entire undo history to a separate file on disk that includes all states. This means that even after exiting Vim, the undo history is still available when you reopen the file, allowing you to continue to undo/redo changes. The undo history file is incremental and saves every change permanently, similar to Git.

If you're worried about the potential storage space used by persistent undo files, undotree provides an option to clean them up. Additionally, undotree is written in pure Vim script, making it lightweight, simple, and fast, and only runs when needed. To enable persistent undo, simply type `:h persistent-undo` in Vim, or follow the instructions provided in the documentation.

### Download and Install

Using Vim's built-in package manager:

```sh
mkdir -p ~/.vim/pack/mbbill/start
cd ~/.vim/pack/mbbill/start
git clone https://github.com/mbbill/undotree.git
vim -u NONE -c "helptags undotree/doc" -c q
```

Use whatever plug-in manager to pull the master branch. I've included 2 examples of the most used:

- *Vundle:* `Plugin 'mbbill/undotree'`
- *Vim-Plug:* `Plug 'mbbill/undotree'`

And install them with the following:

- *Vundle:* `:PluginInstall`
- *Vim-Plug:* `:PlugInstall`

### Usage

  1. Use `:UndotreeToggle` to toggle the undo-tree panel. You may want to map this command to whatever hotkey by adding the following line to your vimrc, take `F5` for example.

```vim
nnoremap <F5> :UndotreeToggle<CR>
```

  1. Markers
     * Every change has a sequence number and it is displayed before timestamps.
     * The current state is marked as `> number <`.
     * The next state which will be restored by `:redo` or `<ctrl-r>` is marked as `{ number }`.
     * The `[ number ]` marks the most recent change.
     * The undo history is sorted by timestamps.
     * Saved changes are marked as `s` and the big `S` indicates the most recent saved change.
  2. Press `?` in undotree window for quick help.
  3. Persistent undo
     * Usually, I would like to store the undo files in a separate place like below.

```vim
if has("persistent_undo")
   let target_path = expand('~/.undodir')

    " create the directory and any parent directories
    " if the location does not exist.
    if !isdirectory(target_path)
        call mkdir(target_path, "p", 0700)
    endif

    let &undodir=target_path
    set undofile
endif
```

#### Configuration

[Here](https://github.com/mbbill/undotree/blob/master/plugin/undotree.vim#L15) is a list of options.

#### Debug

  1. Create a file under $HOME with the name `undotree_debug.log`
     * `$touch ~/undotree_debug.log`
  2. Run vim, and the log will automatically be appended to the file, and you may watch it using `tail`:
     * `$tail -F ~/undotree_debug.log`
  3. If you want to disable debug, just delete that file.

### License

**BSD**

### Author

Ming Bai  &lt;mbbill AT gmail DOT COM&gt;
