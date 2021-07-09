syn match batchy    /\([│#].*\|←\)/ contains=batchyDir
syn match batchyDir /[│#]\s*\zsd/

hi batchy    guifg=#aaaaaa ctermfg=grey
hi batchyDir guifg=#0000ff ctermfg=blue
