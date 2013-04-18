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
let s:bufferName = '[GoToFile]'
let s:windowHeight = 7
let s:promt = "/"
let s:filesCache = []

function! s:MollyController()
	call ShowWindow()
endfunction

"
" KeyBindings
"
function SetBufferKeyBindings()
	let asciilist = range(97,122)
	let asciilist = extend(asciilist, range(32,47))
	let asciilist = extend(asciilist, range(58,90))
	let asciilist = extend(asciilist, [91,92,93,95,96,123,125,126])

	let specialChars = {
				\  '<BS>'    : 'Backspace',
				\  '<C-h>'   : 'Backspace',
				\  '<C-u>'   : 'Clear',
				\  '<C-r>'   : 'Refresh',
				\  '<C-c>'   : 'Cancel',
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
	if querylen > 0
		let s:query = strpart(s:query, 0, querylen - 1)
		call RefreshWindow()
	else
		let s:query = ""
		call HideWindow()
	endif
endfunction

function HandleKeyCancel()
	let s:query = ""
	call HideWindow()
endfunction

function HandleKeyAcceptSelection()
	let s:query = ""
	let selectedFile = getline(".")
	call HideWindow()
	execute ":e " . selectedFile
endfunction

function HandleKeyRefresh()
	call RefreshCache()
	call RefreshWindow()
endfunction

"
" Window function
"
function ShowWindow()
	if s:initialized == 0
		silent! execute ":bo " . s:windowHeight . "new" . s:bufferName
		call SetBufferLocals()
		call SetBufferKeyBindings()
		let s:initialized = 1
	else
		silent! execute ":bo " . s:windowHeight . "sp" 
		silent! execute ":b ". s:bufferName
	endif

	call RefreshCache()
	call RefreshWindow()

endfunction

function HideWindow()
	let number = bufwinnr(s:bufferName)
	if (number >= 0)
		execute number . 'wincmd q'
	endif
endfunction

function SetBufferLocals()
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

"
" Refresh
"
function RefreshCache()
	echohl MoreMsg | echo "Building List (^c to abort)" | echohl None
	let s:filesCache = FileFinder(".")
	redraw | echo ""
endfunction

function RefreshWindow()
	let files = FuzzyFilter(s:filesCache, s:query)
	let number = bufwinnr(s:bufferName)
	execute number . 'wincmd w'
	execute ":1,$d" 
	call setline(".", files)
	echo s:promt . s:query
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
	let matches = []
	let querychars = split(a:query, '\zs')
	let fuzzychars = '\.\*'
	let fuzzyquerry = join(querychars, fuzzychars)
	let queryfirst = '\V\c' . '\^' . fuzzyquerry
	let queryother = '\V\c' . fuzzychars . fuzzyquerry

	for filepath in a:files
		let filesplit = split(filepath, '/')
		let filename = get(filesplit, len(filesplit) - 1)

		if filename =~ queryfirst
			call insert(matches, filepath, 0)
		elseif filename =~ queryother
			call add(matches, filepath)
		endif
	endfor

	return matches
endfunction
