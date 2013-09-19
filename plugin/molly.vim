" ============================================================================
" File:        molly.vim
" Description: Speed is key!
" Maintainer:  William Estoque <william.estoque at gmail dot com>
" License:     MIT
"
" ============================================================================

command -nargs=? -complete=dir Molly call <SID>MollyController()
silent! nmap <unique> <silent> <Leader>g :Molly<CR>

let s:Molly_version = '0.0.3'
let s:query = ""
let s:initialized = 0
let s:bufferName = '\[Go\ To\ File\]'
let s:windowHeight = 10 
let s:promt = "/"
let s:filesCache = []

function! s:MollyController()
	let number = bufwinnr(s:bufferName)
	if (number == -1)
		call OpenWindow()
	else
		call CloseWindow()
	endif
endfunction

"
" Window function
"
function CloseWindow()
	let currentWinNumber = winnr()
	let pluginWinNumber = bufwinnr(s:bufferName)
	if (pluginWinNumber >= 0)
		execute pluginWinNumber . "wincmd w" 
		execute pluginWinNumber . "wincmd c" 
		execute currentWinNumber . "wincmd w" 
		redraw | echo ""
	endif
endfunction

function OpenWindow()
	if (s:initialized == 0)
		silent! execute ":bo " . s:windowHeight . "sp " . s:bufferName
		call SetBufferLocals()
		call SetBufferKeyBindings()
		call RefreshCache()
		call RefreshWindow()
		let s:initialized = 1
	else
		" Don't at once (:sp bufferName) because 'sp' with arg set 'buflisted'
		silent! execute ":bo " . s:windowHeight . "sp"
		silent! execute ":b " . s:bufferName
	endif
endfunction

function SetBufferLocals()
	setlocal winfixwidth
	setlocal bufhidden=hide
	setlocal buftype=nofile
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap
	setlocal nonumber
	setlocal nolist
	setlocal cursorline
	highlight! link CursorLine Search
endfunction

function SetBufferKeyBindings()
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

function HandleKey(key)
	let s:query = s:query . a:key
	call RefreshWindow()
endfunction

function HandleKeyClear()
	let s:query = ""
	call RefreshWindow()
endfunction

function HandleKeySelectNext()
	call setpos(".", [0, line(".") + 1, 1, 0])
endfunction

function HandleKeySelectPrev()
	call setpos(".", [0, line(".") - 1, 1, 0])
endfunction

function HandleKeyBackspace()
	let querylen = strlen(s:query)
	if (querylen > 0)
		let s:query = strpart(s:query, 0, querylen - 1)
		call RefreshWindow()
	else
		let s:query = ""
		call CloseWindow()
	endif
endfunction

function HandleKeyCancel()
	let s:query = ""
	call CloseWindow()
endfunction

function HandleKeyAcceptSelection()
	let s:query = ""
	let selectedFile = getline(".")
	execute 'wincmd p'
	if filereadable(selectedFile)
		execute ":e " . selectedFile
	endif
	call CloseWindow()
endfunction

function HandleKeyRefresh()
	call RefreshCache()
	call RefreshWindow()
endfunction

"
" Refresh
"
function RefreshCache()
	echohl MoreMsg | echo "Building List (^c to abort)" | echohl None
	let s:filesCache = FileFinder(".")
	redraw | echo ""
endfunction

function RefreshWindow()
	let number = bufwinnr(s:bufferName)
	if (number != -1)
		let files = FuzzyFilter(s:filesCache, s:query)
		execute number . 'wincmd w'
		execute ":1,$d" 
		call setline(".", files)
		echo s:promt . s:query
	endif
endfunction

"
" Utilites
"
function FileFinder(path)
	let found = globpath(a:path, "**")
	let files = split(found, "\n")
	" globpath() return dirs too, remove it
	call filter(files, 'filereadable(v:val)')
	return files
endfunction

function FuzzyFilter(files, query)

	" Basic parts of queries
	let querychars = split(a:query, '\zs')
	let fuzzychars = '\.\*'
	let fuzzyquerry = join(querychars, fuzzychars)

	" Queries by priority (0 - is higth)
	let queries = []
	call add(queries, '\V\C' . '\^' . a:query . fuzzychars)
	call add(queries, '\V\C' . fuzzychars . a:query . fuzzychars)
	call add(queries, '\V\C' . '\^' . fuzzyquerry)
	call add(queries, '\V\c' . fuzzychars . fuzzyquerry)

	" Matches by query
	let matches = {}
	for query in queries
		let matches[query] = []
	endfor

	" Files tests
	for filepath in a:files
		let filesplit = split(filepath, '/')
		let filename = get(filesplit, len(filesplit) - 1)

		for query in queries
			if (filename =~ query)
				call add(matches[query], filepath)
				break
			endif
		endfor

	endfor

	" End result
	let result = []
	for query in queries
		let result += matches[query] 
	endfor
	return result 

endfunction
