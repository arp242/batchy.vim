syn match batchy    /\([│#].*\|←\)/ contains=batchyDir
syn match batchyDir /[│#]\s*\zsd/

hi batchy    guifg=#aaaaaa ctermfg=grey
hi default link batchyDir Directory
