;; 
;; You can evaluate this file with:
;;    ./eval-lisp -v -f eg.lisp
;;


(defun sum (a b &optional c)
  (write a b c)
  (+ a b))

(setq a 100)
(setq b (sum 4 5))
(write (print (list a b)))

(write (ord "a"))
(write (chr ?a))

(write "Yesterday was:" (localtime (- (time) (* 24 60 60))))
(setq pid (perl-eval "$$"))

(setq a 10)
(while (not (zerop a))
  (write a)
  (setq a (1- a)))

(list "Good bye")
