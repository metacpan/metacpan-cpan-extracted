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

(require 'cl-lib)
(require 'advice)
(require 'mmm-mode)
(require 'mmm-sample)
(require 'derived)
(require 'sgml-mode)
(require 'cperl-mode)

(require 'yatt-lint-any-mode)

(defvar yatt-mode-use-lsp t
  "Use lsp if available")

(defvar yatt-mode-use-yatt-lint-with-lsp t
  "Use yatt-lint too even if lsp is available")

(defvar yatt-mode-lsp-client 'eglot
  "LSP client mode")

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

(defun yatt-mode-ls-command ()
  "Generate the language server startup command."
  (let* ((app-dir (locate-dominating-file "." "app.psgi"))
         (yatt-lib (cond (app-dir
                          (concat app-dir "lib/YATT/"))
                         (t
                          yatt-mode-YATT-dir))))
    (list (concat yatt-lib "Lite/LanguageServer.pm") "server")))

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
    (when yatt-mode-use-lsp
      (yatt-mode-ensure-lsp))
    (when (or (not yatt-mode-use-lsp)
              yatt-mode-use-yatt-lint-with-lsp)
      (yatt-lint-any-mode 1))
    (yatt-mode-ensure-file-coding)
    (ad-activate 'mmm-refontify-maybe)

    ;; I want to set comment-start, comment-end... here,
    ;; but it doesn't take effect because it is overriden via
    ;; (get 'yatt-mode 'mmm-local-variables)
    (yatt-mode--set-local-vars
     (yatt-mode-comment-style))

    (mmm-mode-on)

    ;; So I also update the property directly.
    (yatt-mode--update-assoc
     (get 'yatt-mode 'mmm-local-variables)
     (yatt-mode-comment-style))

    (mmm-refontify-maybe)
    ;; cperl-mode にする中で、 buffer-modified-p が立ってる... かと思いきや...
    ;; 分からん！
    ;; [after idle] 的な処理が必要なんでは?
    ;; (yatt-mode-multipart-refontify)
    (run-hooks 'yatt-mode-hook)))

(defun yatt-mode-comment-style ()
  ;; XXX: get namespace from workspace config
  (list
   '(comment-start "<!--#yatt ")
   '(comment-continue " # ")
   '(comment-end " #-->")
   '(comment-style extra-line)))

(defun yatt-mode--set-local-vars (spec-assoc)
  (dolist (spec spec-assoc)
    (set (make-variable-buffer-local (car spec)) (car (cdr spec)))))

(defun yatt-mode--update-assoc (dest-assoc spec-assoc)
  (dolist (spec spec-assoc)
    (let ((k (car spec))
          (l (cdr spec))
          dest)
      (when (setq dest (assoc k dest-assoc))
            (setcdr dest l)))))


(defun yatt-mode-ensure-lsp ()
  (when (require yatt-mode-lsp-client nil t)
    (cond ((eq yatt-mode-lsp-client 'eglot)
           (dolist (m '(yatt-mode yatt-declaration-mode))
             (add-to-list 'eglot-server-programs
                          (cons m (yatt-mode-ls-command))))
           (eglot-ensure))
          ((eq yatt-mode-lsp-client 'lsp)
           (dolist (m '(yatt-mode yatt-declaration-mode))
             (add-to-list 'lsp-language-id-configuration
                          (cons m "yatt")))
           (require 'lsp-yatt)
           (lsp)
           ;; To avoid "Flycheck cannot use lsp in this buffer, type M-x flycheck-verify-setup for more details" error
           (lsp-flycheck-add-mode 'yatt-declaration-mode))
          (t
           (error "Unknown value for yatt-mode-lsp-client: %s" yatt-mode-lsp-client)
           ))))

;;; Below is stolen and modified from recent sgml-mode to revert old behavior
;;;
(eval-and-compile
  (defconst yatt-declaration-syntax-propertize-rules
    (syntax-propertize-precompile-rules
     ;; Use the `b' style of comments to avoid interference with the -- ... --
     ;; comments recognized when `sgml-specials' includes ?-.
     ;; FIXME: beware of <!--> blabla <!--> !!
     ("\\(<\\)!--" (1 "< b"))
     ("--[ \t\n]*\\(>\\)" (1 "> b"))
     ;; Double quotes outside of tags should not introduce strings.
     ;; Be careful to call `syntax-ppss' on a position before the one we're
     ;; going to change, so as not to need to flush the data we just computed.
     ("\"" (0 (if (prog1 (zerop (car (syntax-ppss (match-beginning 0))))
                    (goto-char (match-end 0)))
                  (string-to-syntax ".")))))))

(defun yatt-declaration-syntax-propertize (start end)
  (funcall
   (syntax-propertize-rules yatt-declaration-syntax-propertize-rules)
   start end))

(define-derived-mode yatt-declaration-mode sgml-mode "YATT decl"
  "yatt:* タグの、宣言部分"
    (setq-local syntax-propertize-function #'yatt-declaration-syntax-propertize)
  )

;;----------------------------------------
(defface yatt-declaration-submode-face
  '((t (:background "#d2d4f1" :extend t)))
  "Face used for yatt declaration block (<!yatt:...>)")

(defface yatt-action-submode-face
  '((t (:background "#f4f2f5" :extend t)))
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
	((action entity)
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
  (cl-do* (result
	   (regions (mmm-regions-in (point-min) (point-max))
		    next)
	   (reg (car regions) (car regions))
	   (next (cdr regions) (cdr regions))
	   (section
            (if (not (eq (car reg) 'yatt-declaration-mode))
                `((default)
                  ,(cadr (car regions)))))
           )
      ;; 次が無いなら、最後の section を詰めて返す
      ((not next)
       (reverse (cons (append section (list (caddr reg))) result)))
    (when (eq (car reg) 'yatt-declaration-mode)
      (setq begin (cadr reg) end (caddr reg)
	    ;; ここまでを登録しつつ、
	    result (if section
                       (cons (append section (list begin))
                             result))
	    ;; 新しい section を始める
	    section (list (yatt-mode-decltype reg) end)))))

;;; mmm-region is usually:
;;; (yatt-declaration-mode 1 20 #<overlay from 1 to 20 in test1_w_a.yatt>)
(defun yatt-mode-decltype (mmm-region)
  (let* ((min (cadr mmm-region)) (max (caddr mmm-region))
         ;; XXX: rewrite above with seq-let.
	 (start (next-single-property-change min 'face (current-buffer) max))
	 (end (next-single-property-change start 'face (current-buffer) max))
         decl
	 pos
	 )
    ;; XXX: !yatt: で始まらなかったら?
    (save-match-data
      (when (and (= max end)
                 (equal (char-after start) ?\n))
        ;; workaround
        (save-excursion
          (goto-char min)
          (search-forward "<")
          (setq start (point))
          (re-search-forward "[ \t]")
          (setq end (1- (point)))))
      (setq decl (buffer-substring-no-properties start end))
      ;; decl typically contains "!yatt:widget"
      ;; In this case, return value is ('widget "yatt")
      ;; XXX: rewrite below with split-string. (This changes returning structure though).
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
	       (not (eq (coding-system-base old-coding)
			(coding-system-base new-coding))))
      (set-buffer-file-coding-system new-coding nil)
      (set-buffer-modified-p modified)
      (message "coding is changed from %s to %s, modified is now %s"
	       old-coding new-coding modified))))

;;========================================
;; Debugging aid.

(defun yatt-mode-called-from-p (fsym)
  (cl-do* ((i 0 (1+ i))
	   (frame (backtrace-frame i) (backtrace-frame i)))
      ((not frame))
    (when (eq (cadr frame) fsym)
      (cl-return t))))

(defun yatt-mode-from-hook-p (hooksym)
  (cl-do* ((i 0 (1+ i))
	   (frame (backtrace-frame i) (backtrace-frame i)))
      ((not frame))
    (when (and (eq (cadr frame) 'run-hooks)
	       (eq (caddr frame) hooksym))
      (cl-return t))))

(defun yatt-mode-backtrace (msg &rest args)
  (let ((standard-output (get-buffer-create "*yatt-debug*")))
    (princ "---------------\n")
    (princ (apply 'format msg args))
    (princ "\n---------------\n")
    (backtrace)
    (princ "\n\n")))
