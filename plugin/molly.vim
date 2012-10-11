" ============================================================================
" File:        molly.vim
" Description: Speed is key!
" Maintainer:  William Estoque <william.estoque at gmail dot com>
" License:     MIT
"
" ============================================================================
let s:Molly_version = '0.0.3'

command -nargs=? -complete=dir Molly call <SID>MollyController()
silent! nmap <unique> <silent> <Leader>t :Molly<CR>

let s:query = ""
let s:bufferOpen = 0

function! s:MollyController()
	if s:bufferOpen
		call ShowBuffer()
	else
		let s:bufferOpen = 1
		execute "sp molly"
		call BindKeys()
		call SetLocals()
		let s:filelist = split(globpath(".", "**"), "\n")
		call WriteToBuffer(s:filelist)
	endif
endfunction

function BindKeys()
	let asciilist = range(97,122)
	let asciilist = extend(asciilist, range(32,47))
	let asciilist = extend(asciilist, range(58,90))
	let asciilist = extend(asciilist, [91,92,93,95,96,123,125,126])

	let specialChars = {
				\  '<BS>'    : 'Backspace',
				\  '<Del>'   : 'Delete',
				\  '<CR>'    : 'AcceptSelection',
				\  '<C-t>'   : 'AcceptSelectionTab',
				\  '<C-v>'   : 'AcceptSelectionVSplit',
				\  '<C-CR>'  : 'AcceptSelectionSplit',
				\  '<C-s>'   : 'AcceptSelectionSplit',
				\  '<Tab>'   : 'ToggleFocus',
				\  '<C-c>'   : 'Cancel',
				\  '<Esc>'   : 'Cancel',
				\  '<C-u>'   : 'Clear',
				\  '<C-e>'   : 'CursorEnd',
				\  '<C-a>'   : 'CursorStart',
				\  '<C-n>'   : 'SelectNext',
				\  '<C-j>'   : 'SelectNext',
				\  '<Down>'  : 'SelectNext',
				\  '<C-k>'   : 'SelectPrev',
				\  '<C-p>'   : 'SelectPrev',
				\  '<Up>'    : 'SelectPrev',
				\  '<C-h>'   : 'CursorLeft',
				\  '<Left>'  : 'CursorLeft',
				\  '<C-l>'   : 'CursorRight',
				\  '<Right>' : 'CursorRight'
				\}

	for n in asciilist
		execute "noremap <buffer> <silent>" . "<Char-" . n . "> :call HandleKey('" . nr2char(n) . "')<CR>"
	endfor

	for key in keys(specialChars)
		execute "noremap <buffer> <silent>" . key  . " :call HandleKey" . specialChars[key] . "()<CR>"
	endfor
endfunction

function HandleKey(key)
	let s:query = s:query . a:key
	call ExecuteQuery()
endfunction

function HandleKeySelectNext()
	call setpos(".", [0, line(".") + 1, 1, 0])
endfunction

function HandleKeySelectPrev()
	call setpos(".", [0, line(".") - 1, 1, 0])
endfunction

function HandleKeyCursorLeft()
	echo "left"
endfunction

function HandleKeyCursorRight()
	echo "right"
endfunction

function HandleKeyBackspace()
	let s:query = strpart(s:query, 0, strlen(s:query) - 1)
	call ExecuteQuery()
endfunction

function HandleKeyCancel()
	let s:query = ""
	call HideBuffer()
endfunction

function HandleKeyAcceptSelection()
	let filename = getline(".")
	call HideBuffer()
	execute ":e " . filename
	unlet filename
	let s:query = ""
endfunction

function HandleKeyAcceptSelectionVSplit()
	let filename = getline(".")
	call HideBuffer()
	execute "vs " . filename
	unlet filename
	let s:query = ""
endfunction

function HandleKeyAcceptSelectionSplit()
	let filename = getline(".")
	call HideBuffer()
	execute "sp " . filename
	unlet filename
	let s:query = ""
endfunction

function HandleKeyAcceptSelectionTab()
	let filename = getline(".")
	call HideBuffer()
	execute "tabnew"
	execute "e " . filename
	unlet filename
	let s:query = ""
endfunction

function ClearBuffer()
	execute ":1,$d"
endfunction

function HideBuffer()
	execute ":hid"
endfunction

function ShowBuffer()
	execute ":sb molly"
endfunction

function SetLocals()
	setlocal bufhidden=hide
	setlocal buftype=nowrite
	setlocal noswapfile
	setlocal nowrap
	setlocal nonumber
	setlocal nolist
	setlocal foldcolumn=0
	setlocal foldlevel=99
	setlocal nospell
	setlocal nobuflisted
	setlocal textwidth=0
	setlocal cursorline
endfunction

function ExecuteQuery()
	let matches = []
	let querychars = split(s:query, '\zs')
	let fuzzychars = '\.\*'
	let fuzzyquerry = join(querychars, fuzzychars)
	let queryfirst = '\V' . '\^' . fuzzyquerry
	let queryother = '\V' . fuzzychars . fuzzyquerry

	for filepath in s:filelist
		let filesplit = split(filepath, '/')
		let filename = get(filesplit, len(filesplit) - 1)

		if filename =~? queryfirst
			call insert(matches, filepath, 0)
		elseif filename =~? queryother
			call add(matches, filepath)
		endif
	endfor

	call WriteToBuffer(matches)
	unlet matches
	unlet querychars
	echo ":" . s:query
endfunction

function WriteToBuffer(files)
	call ClearBuffer()
	call setline(".", a:files)
endfunction
