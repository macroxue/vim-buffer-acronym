Switching buffer by acronym
===========================

This plugin enables quick switching to a buffer by its acronym.

Usage
-----

The switching function is invoked by `-` (minus) key. Additionally, `_`
(underscore) key lists all buffers before switching. It's OK to enter
either target buffer's acronym or number. There are a few rules
in matching acronyms.
 * All paths are ignored.
 * Only characters `-`, `_` and `.` are considered word separators.
 * An acronyms must start from the first word.

For example, you have the following files opened in Vim.
```
awesome-program.cc
awesome-program.h
awesome_test.cc
```
Then
 * `-apc<cr>` switches to `awesome_program.cc`
 * `-aph<cr>` switches to `awesome_program.h`
 * `-at<cr>` or `-atc<cr>` switches to `awesome_test.cc`
 * `-ap<tab>` cycles between `awesome_program.cc` and `awesome_program.h`
 * `-a<tab>` cycles through all three files.

When there are multiple matches, the first one is picked.  So either `-a<cr>`
or `-ap<cr>` switches to `awesome_program.cc`.


Installation
------------

### Vim

If you don't have a preferred installation method, I recommend using [Vundle][].
Assuming you have Vundle installed and configured, the following steps will
install the plugin:

Add the following line to your `~/.vimrc` file

``` vim
Plugin 'macroxue/buffer-acronym'
```

Then run

```
:PluginInstall
```

[Vundle]: https://github.com/gmarik/vundle
