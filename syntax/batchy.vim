syn match batchy    /\([│#].*\|←\)/ contains=batchyDir
syn match batchyDir /[│#]\s*\zsd/

hi default link batchy Comment
hi default link batchyDir SpecialComment
