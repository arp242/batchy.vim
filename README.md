Batchy.vim is a little plugin to perform batch operations on files.

The general idea is to keep it as simple as possible; batch operations such as
batch renames are 1) potentially very dangerous if you do it wrong, and 2) not
something people usually do very often.

Run `:Batchy` to display a list of files in the current directory that you can
edit, run `:Batchy` again to convert it to a shell script that you can examine
for correctness, maybe modify, and run with `:%!sh`.

You can run this directly from the shell with an alias:

    alias batchy='vim +":Batchy echo" +"setl noswapfile buftype=nofile bufhidden=hide nowrap"'

Usage
-----
When you use `:Batchy` you get a new buffer filled with the contents of the
current directory:

    ftplugin         ←  ftplugin         │  d  0.0K  Thu 2021-06-17 00:44:20
    plugin           ←  plugin           │  d  0.0K  Thu 2021-06-17 00:50:21
    LICENSE          ←  LICENSE          │  f  1.1K  Thu 2021-06-17 00:21:12
    README.markdown  ←  README.markdown  │  f  2.3K  Thu 2021-06-17 00:45:46

There are three columns, separated by `←` and `│` characters; the first column
is the *destination* filename and the second the *source*: this is the reverse
of most commandline tools, but makes it a lot easier to edit the destination
filenames in Vim with `:s` (more on that later). The left pointing arrow is
there as a reminder that it's the reverse.

Everything after the `│` is a comment and lists the file type, size, and
modification date. You can put anything you want there when editing. Note this
is U+2502 ("box drawings light vertical") and not the regular `|` (U+007C,
vertical line).

Now, let's say you modify the buffer to prefix every file with `xx-`:

    xx-ftplugin         ←  ftplugin         │  d  0.0K  Thu 2021-06-17 00:44:20
    xx-plugin           ←  plugin           │  d  0.0K  Thu 2021-06-17 00:50:21
    xx-LICENSE          ←  LICENSE          │  f  1.1K  Thu 2021-06-17 00:21:12
    xx-README.markdown  ←  README.markdown  │  f  2.3K  Thu 2021-06-17 00:45:46

Run `:Batchy` again and it will replace the buffer with a shell script:

    mv -n 'ftplugin'         'xx-ftplugin'         # d  0.0K  Thu 2021-06-17 00:44:20
    mv -n 'plugin'           'xx-plugin'           # d  0.0K  Thu 2021-06-17 00:51:16
    mv -n 'LICENSE'          'xx-LICENSE'          # f  1.1K  Thu 2021-06-17 00:21:12
    mv -n 'README.markdown'  'xx-README.markdown'  # f  2.5K  Thu 2021-06-17 00:51:06

*Nothing gets run automatically*. Write it to a file or use `:%!sh` to run it.

Whitespace surrounding the `←` and `│` markers is removed; if you want filenames
with spaces (or other special shell characters) then you can just type them
without escaping. For example this:

    the "README" file  ←  README.markdown  │  f  3.0K  Thu 2021-06-17 01:01:02

Becomes:

    mv -n 'README.markdown'  'the "README" file'  # f  3.0K  Thu 2021-06-17 01:01:02

You can't have a file with leading or trailing whitespace, and there is no way
to escape the `←` and `│` marker; they're chosen because it's extremely unlikely
that you want to put those in a filename. If you want either of those things
then, well, tough 🙃

Batchy command
---------------
On the first `:Batchy` invocation it will create a new `batchy` buffer:

- Any arguments will be run as commands before we do anything, this is used to
  create a new buffer and maybe set some options for this if you want. This
  defaults to `g:batchy_new`; the default is:

      tabnew | setl noswapfile buftype=nofile bufhidden=hide nowrap

  For example, to re-use the current buffer without setting anything:

      :Batchy echo

  The `echo` just functions as a no-op here to prevent batchy from using the
  default. It's a bit of a hack 😅

  Note that the defaults are overwritten, so if you want to keep that `setl`
  you'll need to add it again (or create a wrapper command). I have a little
  `:S` command, which is useful in general:

      " Convert buffer to and from scratch.
      command! S
          \  if &buftype is# 'nofile' | setl swapfile buftype= bufhidden=
          \| else                     | setl noswapfile buftype=nofile bufhidden=hide | endif
          \| echo printf('swapfile=%s buftype=%s bufhidden=%s', &swapfile, &buftype, &bufhidden)

- It always reads the current directory; you can `lcd` if you want a different
  one:

      :Batchy tabnew | lcd /

  `:lcd` is like `:cd`, but only changes the directory for the current buffer.

If the current `filetype` is `batchy` then it will try to convert the buffer to
a shell script:

- Any arguments to `:Batchy` will be taken as the command to use; e.g. `:Batchy
  cp`, `:Batchy ln -s`. This defaults to `mv -n` if not given.
- Only lines with `←` are processed.
- All other lines are commented out with `# `.

There is one exception to this: if the filetype is already `batchy` *and* the
buffer is empty, then it will populate the buffer as like the first `:Batchy`
invocation.

Options
-------
`g:batchy_new` gets run just before batchy inserts anything; you can put
anything in here, usually you want a command to open a new buffer: `new`,
`vnew`, `tabnew`, etc. The default value is:

    tabnew | setl noswapfile buftype=nofile bufhidden=hide nowrap

It highlights comments and the `d` to indicate directories with:

    hi batchy    guifg=#aaaaaa ctermfg=grey
    hi default link batchyDir Directory

Which you can change if you want.


Editing
-------
Some tips to edit filenames:

    :%s/^/prefix-/    add a prefix
    :%s/^prefix-//    remove a prefix

    :%s/ /-suffix/    add a suffix
    :%s/-suffix //    remove a suffix

    :%s/word/NEW/     replace word; because only the first match is
                      replaced this leaves the source filename alone.

This is why the source and destination are reversed: it's just so much easier.
If it would keep the `src dst` order all of the above would require a lot more
complex patterns.

*NOTE*: the `gdefault` option is reset for batchy buffers, as many of these
patterns won't work with it enabled (you can add the `/g` flag to disable it,
but it's annoying and you never really want this setting for batchy really).

If you use spaces in your filename or want to be absolutely sure it will only
operate on the destination name, then you can use a more specific match:

    :%s/\ze *←/-suffix/     add a suffix
    :%s/-asd\ze *←//        remove a suffix

    :%s/word\ze.\{-}←/X/    replace word only in the "destination" column.

This matches "← preceded by any space"; the `\ze` sets the "end of match"
location at the start, and whatever matches after that doesn't get replaced.

You can also use block visual mode (`<C-v>`), or any command really. Using `:g`
to filter out lines can also be useful:

    :g/foo/s!foo!bar!

If it turns out that you made a mistake after running `:Batchy` to generate a
shell script you can just use `u` to go back and try again.
