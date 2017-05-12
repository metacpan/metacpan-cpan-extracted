(defalias 'obo-term
  (read-kbd-macro "C-a C-k [term] RET id: SPC C-y 2*RET"))

(defalias 'obo-isa (read-kbd-macro
"C-s id: <right> C-k C-y C-s [term] C-a 2*RET 2*<up> [term] RET id: SPC RET relationship: SPC is_a SPC C-y <up>"))

(defalias 'obo-xp (read-kbd-macro
"C-s id: <right> C-k C-y C-s [term] C-a 2*RET 2*<up> [term] RET id: SPC RET cross_product: SPC C-y SPC ( ) <up>"))
