if exists('g:loaded_batchy') | finish | endif
let g:loaded_batchy = 1
let s:save_cpo = &cpo
set cpo&vim

comm! -nargs=* Batchy :call s:batchy(<f-args>)

fun! s:batchy(...) abort
	let empty = line('$') is 1 && getline('.') =~ '^\s*$'
	if &ft is# 'batchy' && !empty
		return s:batchy_to_shell(a:000->join(' '))
	endif
	return s:batchy_new((&ft is# 'batchy' && empty) ? '.' : a:000->join(' '))
endfun

let s:map_type = #{file: 'f', dir: 'd', link: 'l', bdev: 'b', cdev: 'c',
			     \ socket: 's', fifo: 'f', other: 'o', linkd: 'L'}

fun s:batchy_new(cmd) abort
	exe len(a:cmd) > 0 ? a:cmd : get(g:, 'batchy_new', 'tabnew | setl noswapfile buftype=nofile bufhidden=hide nowrap')
	setl ft=batchy nogdefault

	let ls = readdirex('.')->sort({a, b -> a.type > b.type})
	let [l_n, l_s] = [0, 0]
	for l in ls
		let l.size = printf('  %.1fK  ', l.size / 1024.0)
		let l.type = s:map_type[l.type]
		let l_n = max([l_n, len(l.name)])
		let l_s = max([l_s, len(l.size)])
	endfor
	call setline(1, ls->map({_, v ->
				\ (v.name .. repeat(' ', l_n - len(v.name))) ..
				\ '  ←  ' ..
				\ (v.name .. repeat(' ', l_n - len(v.name))) ..
				\ '  │  ' ..
				\ v.type .. repeat(' ', l_s - len(v.size)) .. v.size ..
				\ strftime('%a %Y-%m-%d %H:%M:%S', v.time)}))
endfun

fun s:batchy_to_shell(cmd)
	silent g!/←/g!/^\s*$/s!^!# !

	let [list, cols] = [[], [0, 0]]
	for i in execute('g/←/echo line(".")')->split('\n')->filter({_, v -> v !~# '^Pattern'})
		let s = getline(i)->split('\s*[←│]\s*')
		let [src, dst, cmt] = [shellescape(s[0]), shellescape(s[1]), get(s, 2, '')]
		call add(list, [i, src, dst, cmt])
		let [cols[0], cols[1]] = [max([cols[0], len(src)+2]), max([cols[1], len(dst)+2])]
	endfor

	let cmd = len(a:cmd) > 0 ? a:cmd : 'mv -n'
	for l in list
		call setline(l[0], cmd .. ' ' ..
					\ l[2] .. repeat(' ', cols[1] - len(l[2])) ..
					\ l[1] .. repeat(' ', cols[0] - len(l[1])) ..
					\ '# ' .. l[3])
	endfor
endfun

let &cpo = s:save_cpo
unlet s:save_cpo
