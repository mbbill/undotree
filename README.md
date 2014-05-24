### [Link to Vim.org](http://www.vim.org/scripts/script.php?script_id=4177)

### Screenshot
![](http://files.myopera.com/mbbill/files/undotree.png)

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
 1. Monitor the changed text in diff panel which is automatically updated when undo/redo happens.
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

1. #### Toggle Undotree Window
	
	In command mode, type `:UndotreeToggle` to toggle the undo-tree panel. 
	
2. #### Use default vim hotkeys:
 
 		`u`				# undo last command
 		`<ctrl-r>`		# redo last command
 		`g+`			# Go to newer text state.  With a count repeat that many times.  {not in Vi}
 		`g-`			# Go to older text state.  With a count repeat that times.  {not in Vi}
 		`:earlier`		# Go to older text state {count} times.
 		`:later`		# Go to newer text state {count} times.
 		# For more information, refer to `:h undo`
 		# Or, Press '?' in Undotree Window
	
### Configurations

1. ### Keymap

	Map <F5> to toggle undotree view:
	
    	nnoremap <F5> :UndotreeToggle<cr>
    	
2. ### Undo History Persistency 
	(Vim 7.3 with patch005 or Vim 7.4+ required)
 
   #### Option #1: save to current directory
   By default, undo history will be saved to currently working directory under `.undo_history` directory. For example, let's say 	you're working on a `.vimrc` file, located under `~/`. Then, the following file will be created to save undo history:

        ~/.undo_history/.vimrc.undocache

    
    ![undo_persistency](https://raw.githubusercontent.com/melvkim/resource/master/screencast/undotree/undotree_persistency.gif)
    
   #### Option #2: save to custom location
    
    
    To save all undo history at your desired directory, please modify the path below and add it to your `.vimrc`: 

    	" save all undo history in this location
    	let g:persistency_DirnameToSaveUndoHistory= '/full/path/to/save/undo/history' 

	![undo_persistency_at_custom_location](https://raw.githubusercontent.com/melvkim/resource/master/screencast/undotree/undotree_persistency_at_custom_path.gif)


3. ### More options
	Refer to [this](https://github.com/mbbill/undotree/blob/master/plugin/undotree.vim#L15) link for more options:

### Example .vimrc:
	" Undo history persistency requires Vim 7.3 with patch005.
	" Or better, use Vim version 7.4 or higher.
	" Check your vim version with `vim --version`
	" save undo history at a certain location
	let g:persistency_DirnameToSaveUndoHistory = '/Users/melvkim/.vim/cache/undo_history'
	
	" Uncomment below to enable confirmation prompt when making directory
	"let g:persistency_ConfirmMkdirToSaveUndoHistory = 1
	
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
	let g:undotree_WindowLayout = 3


### Post any issue and feature request here:
https://github.com/mbbill/undotree/issues

### Debug
 1. Create a file under $HOME with the name `undotree_debug.log`
    * `$touch ~/undotree_debug.log`
 1. Run vim, and the log will automatically be appended to the file, and you may watch it using `tail`:
    * `$tail -F ~/undotree_debug.log`
 1. If you want to disable debug, just delete that file.

### Alternatives
Someone asked me about the difference with [Gundo](http://sjl.bitbucket.org/gundo.vim/), here is a list of differences, or advantages.
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
