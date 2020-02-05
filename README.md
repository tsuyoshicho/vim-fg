# vim-fg

vim find and grep support plugin

## Installation

```vim
```

## Concept

- grep like program option handling
- grepprg, grep command, filelistup command support with option
  tunnable

## ToDo

- [ ] `grepprg` format support
- [ ] yaml config read support
- [ ] default use priority config support
- [ ] search command and format support

## Note

- yaml config load lazy VimEnter
- setup greprg and other value then load
- yaml config read, option (use regex, find hidden...) build
- command `Fg` with high prio, usable find command run
- command `FgXxx` each find command
- inner func deriv, grepprg format,find format,filelist format generating
