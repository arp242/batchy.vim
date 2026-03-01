syn match batchyDivider contains=batchyDir  /←/
syn match batchyComment contains=batchyDir  /\%(│\|# [a-z]  \d\).*/
syn match batchyDir                         /[│#]\s*\zsd/

hi batchyDivider  gui=bold cterm=bold term=bold
hi batchyComment  guifg=#aaaaaa ctermfg=grey
hi default link batchyDir Directory
