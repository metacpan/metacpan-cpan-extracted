(provide 'plist-bind)

(defmacro plist-bind (vars form &rest body)
  "Extract specified VARS from FORM result
and evaluate BODY.

\(plist-bind (file line err) (somecode...)
	    body)

is expanded into:

\(let* ((result (somecode...))
       (file (plist-get result 'file))
       (line (plist-get result 'line))
       (err  (plist-get result 'err)))
  body)"

  (declare (debug ((&rest symbolp) form &rest form)))

  ;; This code is heavily borrowed from cl-macs.el:multiple-value-bind
  (let ((temp (make-symbol "--plist-bind-var--")))
    (list* 'let* (cons (list temp form)
		       (mapcar (function
				(lambda (v)
				  (list v (list 'plist-get temp `(quote ,v)))))
			       vars))
	   body)))

(unless (get 'plist-bind 'edebug-form-spec)
  (put 'plist-bind 'edebug-form-spec '((&rest symbolp) form &rest form)))

(put 'plist-bind 'lisp-indent-function 2)

;; (macroexpand
;;  '(plist-bind (file line err) (list 'file "foo" 'line 3 'err "ERR")
;; 	      (message "file: %s line: %s err: %s" file line err)))
