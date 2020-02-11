# vim-fg

vim find and grep support plugin

## status

- work grepprg get
- work search cmd list
- work filelist cmd list
- not work ripgrep (regex opt need last do not work)

## Installation

```vim
```

## Concept

- grep like program option handling
- grepprg, grep command, filelistup command support with option
  tunnable
- core search command code import/fork from [yegappan/grep](https://github.com/yegappan/grep)

## ToDo

- [ ] `grepprg` format support
- [ ] toml config read support
- [ ] default use priority config support
- [ ] search command and format support

## Note

- toml config load lazy VimEnter
- setup greprg and other value then load
- toml config read, option (use regex, find hidden...) build
- command `Fg` with high priority, found execuable command.
- command `FgXxx` each find command
- inner func deriv, grepprg format,find format,filelist format generating
