;;; yatt-mode.el -- Major mode to edit yatt templates.

;;; Copyright (C) 2010 KOBAYASI Hiroaki

;; Author: KOBAYASI Hiroaki <hkoba@cpan.org>

;;
;; To use yatt-mode, add followings to your .emacs:
;;
;; (autoload 'yatt-mode "yatt-mode")
;; (add-to-list 'auto-mode-alist '("\\.\\(yatt\\|ytmpl\\)\\'" . yatt-mode))
;; (add-to-list 'auto-mode-alist '("\\.ydo\\'" . perl-mode))
;;

(require 'advice)
(require 'mmm-mode)
(require 'mmm-sample)
(require 'derived)
(require 'sgml-mode)
(require 'cperl-mode)

(require 'yatt-lint-any-mode)

(defvar yatt-mode-hook nil
  "yatt で書かれたテンプレートを編集するためのモード")

(defvar yatt-mode-YATT-dir
  (if load-file-name
      (file-name-directory
       (directory-file-name
	(file-name-directory
	 (file-truename load-file-name)))))
  "Where YATT is installed. This is used to locate ``yatt.lint''.")

(defvar yatt-mode-default-mmm-classes
  (let ((css-class (find-if
                    (lambda (k) 
                      (assoc k mmm-classes-alist))
                    '(html-css embedded-css))))
    `(yatt-declaration
      yatt-pi-perl-raw-output
      yatt-pi-perl-escaped-output
      yatt-pi-perl-code
      html-js ,css-class))
  "Default mmm-classes for *.yatt files.")

;;========================================
;; 通常の html 部分
(define-derived-mode yatt-mode html-mode "YATT"
  "yatt:* タグのある html ファイルを編集するためのモード"
  ;; To avoid duplicate call from mmm-mode-on (mmm-update-mode-info)
  (unless (yatt-mode-called-from-p 'mmm-mode-on)
    ;;
    (setq mmm-classes yatt-mode-default-mmm-classes)
    (when (and (member 'html-js mmm-classes)
	       (require 'js)
	       (fboundp 'js--update-quick-match-re))
      (js--update-quick-match-re))
    (setq mmm-submode-decoration-level 2)
    (make-variable-buffer-local 'process-environment)
    (yatt-lint-any-mode 1)
    (yatt-mode-ensure-file-coding)
    (ad-activate 'mmm-refontify-maybe)
    (mmm-mode-on)
    (mmm-refontify-maybe)
    ;; cperl-mode にする中で、 buffer-modified-p が立ってる... かと思いきや...
    ;; 分からん！
    ;; [after idle] 的な処理が必要なんでは?
    ;; (yatt-mode-multipart-refontify)
    (run-hooks 'yatt-mode-hook)))

(define-derived-mode yatt-declaration-mode html-mode "YATT decl"
  "yatt:* タグの、宣言部分")

;;----------------------------------------
(defface yatt-declaration-submode-face
  '((t (:background "#d2d4f1")))
  "Face used for yatt declaration block (<!yatt:...>)")

(defface yatt-action-submode-face
  '((t (:background "#f4f2f5")))
  "Face used for yatt action part (<!yatt:...>)")

(defface yatt-pi-perl-raw-output-submode-face
  '((t (:background "Plum")))
  "Face used for <?perl=== ?>")
(defface yatt-pi-perl-escaped-output-submode-face
  '((t (:background "#f4f2f5")))
  "Face used for <?perl= ?>")
(defface yatt-pi-perl-code-submode-face
  '((t (:background "LightGray")))
  "Face used for <?perl ?>")

;; html の中の、 <!yatt:...> を識別して yatt-declaration-mode へ。
(mmm-add-classes
 '((yatt-declaration
    :submode yatt-declaration-mode
    :face yatt-declaration-submode-face
    :include-front t :include-back t
    :front "^<!\\sw+:"
    :back ">\n")))

(mmm-add-classes
 '((yatt-pi-perl-raw-output
    :submode cperl-mode
    :face yatt-pi-perl-raw-output-submode-face
    :front "<\\?perl==="
    :back "\\?>")
   (yatt-pi-perl-escaped-output
    :submode cperl-mode
    :face yatt-pi-perl-escaped-output-submode-face
    :front "<\\?perl="
    :back "\\?>")
   (yatt-pi-perl-code
    :submode cperl-mode
    :face yatt-pi-perl-code-submode-face
    :front "<\\?perl"
    :back "\\?>")
   ))

;; patch js-inline from mmm-samples.el
;; setf doesn't work for assoc, assoc*
(let ((js (assoc 'js-inline mmm-classes-alist)))
  (if js
      (setcdr js
	      '(:submode javascript
			 :face mmm-code-submode-face
			 :delimiter-mode nil
			 :front "\\'on\\w+=\""
			 :back "\""))))

;;========================================
;;
(defadvice mmm-refontify-maybe (before yatt-mode-refontify-multipart)
  "This adds submode to yatt:action"
  (interactive)
  (let ((modified (buffer-modified-p))
	(fn (buffer-file-name))
	sym start finish)
    (dolist (part (yatt-mode-multipart-list))
      (setq sym (caar part) start (cadr part) finish (caddr part))
      (case sym
	(widget)
	(action
	 ;; XXX: mmm-ify-region は良くないかも。 interactive だと。
	 (mmm-make-region 'cperl-mode start finish
			  :face 'yatt-action-submode-face)
	 (mmm-enable-font-lock 'cperl-mode)
	 (when (and (not modified)
		    (eq (file-locked-p fn) t))
	   (message "removing unwanted file lock from %s" fn)
	   (restore-buffer-modified-p t)
	   (unlock-buffer)
	   (restore-buffer-modified-p nil)))))))

(defun yatt-mode-multipart-list ()
  (do* (result
	(regions (mmm-regions-in (point-min) (point-max))
		 next)
	(reg (car regions) (car regions))
	(next (cdr regions) (cdr regions))
	(section `((default) ,(cadr (car regions))))
	reg)
      ;; 次が無いなら、最後の section を詰めて返す
      ((not next)
       (reverse (cons (append section (list (caddr reg))) result)))
    (when (eq (car reg) 'yatt-declaration-mode)
      (setq begin (cadr reg) end (caddr reg)
	    ;; ここまでを登録しつつ、
	    result (cons (append section (list begin))
			 result)
	    ;; 新しい section を始める
	    section (list (yatt-mode-decltype reg) end)))))

(defun yatt-mode-decltype (region)
  (let* ((min (cadr region)) (max (caddr region))
	 (start (next-single-property-change min 'face (current-buffer) max))
	 (end (next-single-property-change start 'face (current-buffer) max))
	 (decl (buffer-substring-no-properties start end))
	 pos
	 )
    ;; XXX: !yatt: で始まらなかったら?
    (save-match-data
      (cond ((setq pos (string-match ":" decl))
	     (list
	      (intern (substring decl (1+ pos)))
	      (substring decl 1 pos)
	      ))
	    (t
	     (list nil nil decl))))))

;;========================================

(defun yatt-mode-ensure-file-coding (&optional new-coding)
  (let ((modified (buffer-modified-p))
	(old-coding buffer-file-coding-system))
    (setq new-coding (or new-coding yatt-mode-file-coding))
    (when (and new-coding
	       (not (eq old-coding new-coding)))
      (set-buffer-file-coding-system new-coding nil)
      (set-buffer-modified-p modified)
      (message "coding is changed from %s to %s, modified is now %s"
	       old-coding new-coding modified))))

;;========================================
;; Debugging aid.

(defun yatt-mode-called-from-p (fsym)
  (do* ((i 0 (1+ i))
	(frame (backtrace-frame i) (backtrace-frame i)))
      ((not frame))
    (when (eq (cadr frame) fsym)
      (return t))))

(defun yatt-mode-from-hook-p (hooksym)
  (do* ((i 0 (1+ i))
	(frame (backtrace-frame i) (backtrace-frame i)))
      ((not frame))
    (when (and (eq (cadr frame) 'run-hooks)
	       (eq (caddr frame) hooksym))
      (return t))))

(defun yatt-mode-backtrace (msg &rest args)
  (let ((standard-output (get-buffer-create "*yatt-debug*")))
    (princ "---------------\n")
    (princ (apply 'format msg args))
    (princ "\n---------------\n")
    (backtrace)
    (princ "\n\n")))
