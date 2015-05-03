" ============================================================================
" File:        molly.vim
" Description: Speed is key!
" Maintainer:  William Estoque <william.estoque at gmail dot com>
" License:     MIT
"
" ============================================================================

command -nargs=? -complete=dir Molly call <SID>MollyController()
silent! nmap <unique> <silent> <Leader>g :Molly<CR>

let s:Molly_version = "0.0.3"
let s:query = ""
let s:bufferName = '\[Go\ To\ File\]'
let s:windowHeight = 10 
let s:promt = "/"
let s:filesCache = {}
let s:options = {}

function! s:MollyController()
	let number = bufwinnr(s:bufferName)
	if (number == -1)
		call OpenWindow()
	else
		call CloseWindow()
	endif
endfunction

"
" Window function!
"
function! CloseWindow()
	let pluginWinNumber = bufwinnr(s:bufferName)

	if (pluginWinNumber != -1)
		let currentWinNumber = winnr()
		execute pluginWinNumber . "wincmd w"
		silent! close
		if (currentWinNumber != pluginWinNumber)
			execute currentWinNumber . "wincmd w"
			redraw | echo ""
		endif
	endif
endfunction

function! OpenWindow()
	if (bufnr(s:bufferName) != -1)
		" Don't at once (:sp bufferName) because 'sp' with arg set 'buflisted'
		silent! execute ":bo " . s:windowHeight . "sp"
		silent! execute ":b " . s:bufferName
	else
		silent! execute ":bo " . s:windowHeight . "sp " . s:bufferName
		call SetBufferLocals()
		call SetBufferKeyBindings()
		call RefreshCache()
		call RefreshWindow()
	endif
endfunction

function! SetBufferLocals()
	setlocal winfixwidth
	setlocal bufhidden=hide
	setlocal buftype=nofile
	setlocal hidden
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap
	setlocal nonumber
	setlocal nolist
	setlocal cursorline
	setlocal filetype=qf
	highlight! link CursorLine Search

	" This options can't be 'local', need restore after leave buffer
	call AddGlobalOption("timeout", 1)
	call AddGlobalOption("timeoutlen", 0)

	autocmd BufEnter <buffer> call SetGlobalOptions("local")
	autocmd BufLeave <buffer> call SetGlobalOptions("global")
	call SetGlobalOptions("local")
endfunction

function! AddGlobalOption(name, value)
	let s:options[a:name] = {}
	execute "let value=&" . a:name
	let s:options[a:name]["global"] = value
	let s:options[a:name]["local"] = a:value
endfunction

function! SetGlobalOptions(type)
	for key in keys(s:options)
		execute "let &" . key . "=" . s:options[key][a:type]
	endfor
endfunction

function! SetBufferKeyBindings()
	let asciilist = range(97,122)
	let asciilist = extend(asciilist, range(32,47))
	let asciilist = extend(asciilist, range(60,90))
	let asciilist = extend(asciilist, [91,92,93,95,96,123,125,126])

	let specialChars = {
				\  '<BS>'    : 'Backspace',
				\  '<C-h>'   : 'Backspace',
				\  '<C-u>'   : 'Clear',
				\  '<C-r>'   : 'Refresh',
				\  '<C-c>'   : 'Cancel',
				\  '<C-e>'   : 'Cancel',
				\  '<Esc>'   : 'Cancel',
				\  '<Tab>'   : 'Cancel',
				\  '<CR>'    : 'AcceptSelection',
				\  '<C-y>'   : 'AcceptSelection',
				\  '<C-n>'   : 'SelectNext',
				\  '<C-j>'   : 'SelectNext',
				\  '<Down>'  : 'SelectNext',
				\  '<C-k>'   : 'SelectPrev',
				\  '<C-p>'   : 'SelectPrev',
				\  '<Up>'    : 'SelectPrev',
				\}

	for n in asciilist
		execute "noremap <buffer> <silent>" . "<Char-" . n . "> :call HandleKey('" . nr2char(n) . "')<CR>"
	endfor

	for key in keys(specialChars)
		execute "noremap <buffer> <silent>" . key  . " :call HandleKey" . specialChars[key] . "()<CR>"
	endfor
endfunction

function! HandleKey(key)
	let s:query = s:query . a:key
	call RefreshWindow()
endfunction

function! HandleKeyClear()
	let s:query = ""
	call RefreshWindow()
endfunction

function! HandleKeySelectNext()
	call setpos(".", [0, line(".") + 1, 1, 0])
endfunction

function! HandleKeySelectPrev()
	call setpos(".", [0, line(".") - 1, 1, 0])
endfunction

function! HandleKeyBackspace()
	let querylen = strlen(s:query)
	if (querylen > 0)
		let s:query = strpart(s:query, 0, querylen - 1)
		call RefreshWindow()
	else
		let s:query = ""
		call CloseWindow()
	endif
endfunction

function! HandleKeyCancel()
	let s:query = ""
	call CloseWindow()
endfunction

function! HandleKeyAcceptSelection()
	let s:query = ""
	let selectedFile = getline(".")
	execute 'wincmd p'
	if filereadable(selectedFile)
		execute ":e " . selectedFile
	endif
	call CloseWindow()
endfunction

function! HandleKeyRefresh()
	call RefreshCache()
	call RefreshWindow()
endfunction

"
" Refresh
"
function! RefreshCache()
	echo "Search files (^c to abort)"

	let s:filesCache = {}
	let filepaths = FileFinder(".")

	for filepath in filepaths
		let filesplit = split(filepath, '/')
		let filename = get(filesplit, len(filesplit) - 1)
		let s:filesCache[filepath] = filename
	endfor

	redraw | echo ""
endfunction

function! RefreshWindow()
	let number = bufwinnr(s:bufferName)
	if (number != -1)
		let files = AbbrFilter(s:filesCache, s:query)
		execute number . 'wincmd w'
		execute ":1,$d" 
		call setline(".", files)
		echo s:promt . s:query
	endif
endfunction

"
" Utilites
"
function! FileFinder(path)
	let found = globpath(a:path, "**")
	let files = split(found, "\n")
	" globpath() return dirs too, remove it
	call filter(files, 'filereadable(v:val)')
	return files
endfunction

function! AbbrFilter(files, query)
	" Basic parts of queries
	let fuzzychars = '\.\*'
	let abbrsplit = split(a:query, '\%(\u\|\<\)\l*\zs') 
	let abbrquery = join(abbrsplit, fuzzychars)

	" Query
	let query = len(abbrsplit) == 1
		\ ? '\V\c' . fuzzychars . get(abbrsplit, 0) . fuzzychars
		\ : '\V\C' . join(abbrsplit, fuzzychars)

	let result = []

	" Files tests
	for filepath in keys(a:files)
		if (a:files[filepath] =~ query)
			call add(result, filepath)
		endif
	endfor

	" End result
	return result 
endfunction
