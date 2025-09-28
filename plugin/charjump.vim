if has('nvim')
  finish
endif

noremap <expr> <Plug>(charjump-inclusive-forward)  charjump#Jump(v:true, v:false)
noremap <expr> <Plug>(charjump-inclusive-backward)  charjump#Jump(v:false, v:false)
noremap <expr> <Plug>(charjump-exclusive-forward)  charjump#Jump(v:true, v:true)
noremap <expr> <Plug>(charjump-exclusive-backward)  charjump#Jump(v:false, v:true)
noremap <Plug>(charjump-repeat-obverse) <Cmd>call charjump#Repeat(v:true)<CR>
noremap <Plug>(charjump-repeat-reverse) <Cmd>call charjump#Repeat(v:false)<CR>
