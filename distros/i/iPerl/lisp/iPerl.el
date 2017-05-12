;;; iPerl.el --- iPerl minor mode commands for Emacs

;; Copyright (C) 2000 Daniel Pfeiffer <occitan@esperanto.org>

;; Keywords: inverse Perl

;; This file is part of iPerl.

;; iPerl may be copied only under the terms of either the Artistic License or
;; the GNU General Public License, which may be found in the Perl 5.0 source
;; kit.

;; Info on iPerl and latest version are at http://beam.to/iPerl/

;;; Commentary:

;; This package is a minor mode for editing iPerl version 0.6 documents.

;;; Code:

(defgroup iPerl nil
  "Support for editing inverse Perl documents."
  :prefix "iPerl-"
  :group 'editing)



;;; 5 categories for overlays:

(defvar iPerl-categories
  '(iPerl-text iPerl-markup-open iPerl-perl iPerl-printing-perl
    iPerl-markup-close))


(defcustom iPerl-text-face nil
  "*Face that highlights plain text parts of an iPerl document or nil."
  :type 'face
  :group 'iPerl)
(setplist 'iPerl-text
	  '(invisible iPerl-text
	    evaporate t))
(if iPerl-text-face
    (put 'iPerl-text 'face iPerl-text-face))


(defcustom iPerl-markup-open-face '(background-color . "#FCDCDC")
  "*Face that highlights markup between text and Perl or nil."
  :type 'face
  :group 'iPerl)
(setplist 'iPerl-markup-open
	  '(invisible iPerl-markup-open
	    evaporate t))
(if iPerl-markup-open-face
    (put 'iPerl-markup-open 'face iPerl-markup-open-face))


(defcustom iPerl-perl-face '(background-color . "#ECFCEC")
  "*Face that highlights bits of Perl in an iPerl document or nil."
  :type 'face
  :group 'iPerl)
(setplist 'iPerl-perl
	  `(local-map ,(if (featurep 'cperl-mode)
			   cperl-mode-map
			 (require 'perl-mode)
			 perl-mode-map)
	    syntax-table ,(if (featurep 'cperl-mode)
			      cperl-mode-syntax-table
			    perl-mode-syntax-table)
	    ;; point-entered iPerl-menu-bar-update
	    ;; point-left iPerl-menu-bar-update
	    invisible iPerl-perl
	    evaporate t))
(if iPerl-perl-face
    (put 'iPerl-perl 'face iPerl-perl-face))


(defcustom iPerl-printing-perl-face '(background-color . "#ECECFC")
  "*Face that highlights printing bits of Perl in an iPerl document or nil."
  :type 'face
  :group 'iPerl)
(setplist 'iPerl-printing-perl
	  (copy-sequence (symbol-plist 'iPerl-perl)))
(if iPerl-printing-perl-face
    (put 'iPerl-printing-perl 'face iPerl-printing-perl-face))


(defcustom iPerl-markup-close-face iPerl-markup-open-face
  "*Face that highlights markup between Perl and text or nil."
  :type 'face
  :group 'iPerl)
(setplist 'iPerl-markup-close
	  '(invisible iPerl-markup-close
	    evaporate t))
(if iPerl-markup-close-face
    (put 'iPerl-markup-close 'face iPerl-markup-close-face))


(defcustom iPerl-intangible-when-hidden t
  "*When non-nil point can't enter hidden parts."
  :type 'boolean
  :group 'iPerl)



;;; keymaps:

;;;###autoload
(defcustom iPerl-map-prefix "\C-c!"
  "*Prefix key to use for iPerl commands in iPerl minor mode.
You might set this to something like [f12] for a function key.
The value of this variable is checked as part of loading iPerl mode.
After that, changing the prefix key requires manipulating keymaps."
  :type '(choice string (vector symbol))
  :group 'iPerl)

;;;###autoload
(let ((map (make-sparse-keymap)))
  (define-key map "\C-m" 'iPerl-mode)
  (global-set-key iPerl-map-prefix map))

(defvar iPerl-mode-map nil)
(if iPerl-mode-map
    nil
  (setq iPerl-mode-map (make-sparse-keymap))
  (define-key iPerl-mode-map "\C-\M-x" 'iPerl-on-region)

  (let ((map (make-sparse-keymap)))
    (define-key iPerl-mode-map iPerl-map-prefix map)
    (mapcar
     (lambda (item) (define-key map (car item) (cdr item)))
     '(([right] . iPerl-forward)
       ("\C-f" . iPerl-forward)
       ([left] . iPerl-backward)
       ("\C-b" . iPerl-backward)
       ("\C-p" . iPerl-hide-perl)
       ("\C-\M-p" . iPerl-hide-perl-and-markup)
       ("\M-p" . iPerl-hide-markup)
       ("\M-m" . iPerl-hide-markup)
       ("\C-t" . iPerl-hide-text)
       ("\C-s" . iPerl-show-all)
       ("b" . iPerl-bit)
       ("B" . iPerl-long-bit)
       ("l" . iPerl-line)
       ("p" . iPerl-printing-bit))))

  (let ((map (make-sparse-keymap "iPerl")))
    (define-key iPerl-mode-map [menu-bar iPerl] (cons "iPerl" map))
    (mapcar
     (lambda (item) (define-key map (vector (cdr item)) item))
     (reverse '(("Backward Bit" . iPerl-backward)
		("Forward Bit" . iPerl-forward)
		("Hide/Show Perl" . iPerl-hide-perl)
		("Hide/Show Perl & Markup" . iPerl-hide-perl-and-markup)
		("Hide/Show Markup" . iPerl-hide-markup)
		("Hide/Show Text" . iPerl-hide-text)
		("Show All" . iPerl-show-all)
		("--")
		("Bit of Perl" . iPerl-bit)
		("Long Bit of Perl" . iPerl-long-bit)
		("Line of Perl" . iPerl-line)
		("Printing Bit of Perl" . iPerl-printing-bit)
		("--" . 1)
		("iperl on Region" . iPerl-on-region)
		("Set Style" . iPerl-set-style)
		("Toggle iPerl Mode" . iPerl-mode))))))

(or (assq 'iPerl-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (cons (cons 'iPerl-mode iPerl-mode-map)
		minor-mode-map-alist)))



;;; miscellaneous variables:

(defvar iPerl-mode nil)
(or (assq 'iPerl-mode minor-mode-alist)
    (setq minor-mode-alist
	  (cons '(iPerl-mode " iPerl") minor-mode-alist)))

(defvar iPerl-style nil
  "*Name of the iPerl style used in current document.
When given in a file's local variables section must be a literal string,
since that is what the iPerl interpreter understands, but as a lisp-variable
this gets transformed to a symbol as soon as it is used.")
(put 'iPerl-style 'permanent-local t)


(defcustom iPerl-style-equiv
  '((xml . xml-script)
    (sgml . xml-script)
    (unix . bang))
  "*Alternate style to search for when car is not found in some alist."
  :type 'list
  :group 'iPerl)


(defcustom iPerl-markup-matcher
  '((bang	"!{"		"}!"
		"!}!"		1
		"!<"		'">!"
		"^!"		"\n\\|\\'")
    (control	""		""
		""		'""
		"^"		"\n\\|\\'")
    (m4		"perl({"	"})"
		"perl(})"	5
		"perl(<"	'">)")
    (pod	"P<{"		"}>"
		"P<}>"		2
		"P<"		'">"
		"^=begin perl"	"^=end perl"
		"^=for perl"	"\n\n\\|\\'")
    (xml	"<perl>"	"</perl>"
		"<script[^>]*\\s +runat\\s *=\\s *server[^>]*>" "</script>"
		"<server>"	"</server>"
		"<{"		"}>"
		"<}>"		1
		"&<"		'">;"
		"`"		'"`")
    (cpp	"^#"		"\\([^\\]\\)\\(\n\\|\\'\\)"))
  "*Style alist of regexp lists to find markup.
Every alist value is a list of pairs of regexps for the beginning and end of
individual markup elements recognized by that style.  If an end-regexp is an
integer, that position in the marked text is a bit of Perl (usually }).  If an
end-regexp matches a parenthesized grouping, everything up to the end of that
grouping is considered to be part of the intervening Perl code.  If the
end-regexp is quoted, the pair surrounds a printing bit of Perl."
  :type 'list
  :group 'iPerl)


(defvar iPerl-view-change-hook nil
  "Normal hook to be run after iPerl visibility changes.")

(defcustom iPerl-skeleton-space nil
  "*Whether to space-pad around cursor in skeletons."
  :type 'boolean
  :group 'iPerl)


(defvar iPerl-header-marker nil
  "When non-`nil' is the end of header for prepending by \\[iPerl-on-region].
That command is also used for setting this variable.")


(defvar iPerl-skeleton-filter)



;;;###autoload
(defun iPerl-mode (&optional arg)
  "Toggle iPerl minor mode.
With arg, turn iPerl minor mode on if arg is positive, off otherwise.

This mode tries to handle two different modes in the same buffer
simultaneously.  There is CPerl-mode if it is loaded or Perl-mode, for the
parts that are in Perl.  This is currently limited to switching the keymap,
since things such as local variables or font-locking cannot be defined for
single regions.

And then for the rest there is the mode usually used by that document.  These
parts, as well as the markup between them can be hidden, so as to allow
concentrating on only one aspect or the other.  They are also graphically set
apart with the faces `iPerl-text-face', `iPerl-markup-open-face',
`iPerl-perl-face', `iPerl-printing-perl-face' and `iPerl-markup-close-face' to
be distinguishable at a glance.

All standard styles are supported, and the markup between text and Perl can be
automatically inserted in the syntax of the current style.  When you add
markup, however, it is not yet recognized.  You have to turn iPerl-mode off
and on again to get it straight.

The cumbersome key prefix follows Emacs' conventions for minor mode keymaps,
but can be changed with `iPerl-map-prefix', for example to a function key.

Starting this mode can be partly automatised with `iPerl-mode-if-style'.

\\{iPerl-mode-map}

Info on iPerl and latest version are at http://beam.to/iPerl/"
  (interactive "P")
  (make-local-variable 'iPerl-mode)
  (setq iPerl-mode
	(if (null arg) (not iPerl-mode)
	  (> (prefix-numeric-value arg) 0)))
  (if iPerl-mode
      (progn
	(make-local-hook 'change-major-mode-hook)
	;; Turn off this mode if we change major modes.
	(add-hook 'change-major-mode-hook
		  '(lambda () (iPerl-mode -1))
		  nil t)
	(make-local-variable 'line-move-ignore-invisible)
	(make-local-variable 'skeleton-further-elements)
	(make-local-variable 'iPerl-style)
	(make-local-variable 'iPerl-header-marker)
	(setq line-move-ignore-invisible t
	      skeleton-further-elements
	        '((space '(if iPerl-skeleton-space ?\ ))))
	;; (buffer-local-variables &optional BUFFER)
	(if (local-variable-p 'skeleton-filter)
	    (progn
	      (make-local-variable 'iPerl-skeleton-filter)
	      (setq iPerl-skeleton-filter skeleton-filter
		    skeleton-filter
		      (lambda (alist)
			(or (iPerl-by-style alist t)
			    (funcall iPerl-skeleton-filter alist)))))
	  (make-local-variable 'skeleton-filter)
	  (setq skeleton-filter
		  (lambda (alist)
		    (or (iPerl-by-style alist t)
			alist))))
	(if iPerl-style
	    (iPerl-set-style iPerl-style)
	  (call-interactively 'iPerl-set-style))
	(if (eq buffer-invisibility-spec t)
	    (setq buffer-invisibility-spec))
	(run-hooks 'iPerl-minor-mode-hook))
    (save-restriction
      (widen)
      (and ;; (= emacs-major-version 20)
	   ;; (< emacs-minor-version 7)
	   (let ((modified (buffer-modified-p)))
	     (put-text-property (point-min) (point-max) 'point-entered nil)
	     (put-text-property (point-min) (point-max) 'point-left nil)
	     (or modified
		 (set-buffer-modified-p nil))))
      (mapcar
       (lambda (o)
	 (if (memq (overlay-get o 'category) iPerl-categories)
	     (delete-overlay o)))
       (overlays-in (point-min) (point-max))))
    (setq line-move-ignore-invisible nil)
    (remove-from-invisibility-spec iPerl-categories)
    (force-mode-line-update)))

;;;###autoload
(defun iPerl-mode-if-style ()
  "Turn on iPerl-mode if `iPerl-style' is set.
This can be added to `hack-local-variables-hook' for files that have this in
their local variables section."
  (and (boundp 'iPerl-style)
       iPerl-style
       (iPerl-mode 1)))


(defun iPerl-set-style (style)
  ""
  (interactive
   (let ((style (completing-read "Style: (default bang) "
				 '(("bang") ("control") ("cpp") ("m4")
				   ("pod") ("sgml") ("xml") ("unix"))
				 nil t)))
     (if (string= style "") '("bang") (list style))))
  (mapcar
   (lambda (o)
     (if (memq (overlay-get o 'category) iPerl-categories)
	 (delete-overlay o)))
   (overlays-in (point-min) (point-max)))
  (setq iPerl-style style)
  (iPerl-add-overlays))

(defun iPerl-by-style (alist &optional noerr)
  ;; choose from ALIST by iPerl-style, possibly helped by iPerl-style-equiv
  (if (stringp iPerl-style)
      (setq iPerl-style (intern iPerl-style)))
  (or (assq iPerl-style alist)
      (if (assq iPerl-style iPerl-style-equiv)
	  (assq (cdr (assq iPerl-style iPerl-style-equiv)) alist))
      (if noerr
	  ()
	(error "Not defined for style \"%s\"." iPerl-style))))



(defun iPerl-markup-matcher (list)
  (let (s m)
    (while list
      (setq s (concat s
	       (if s "\\|")
	       "\\(" (car list) "\\)")
	    m (nconc m (list (cadr list)))
	    list (cddr list)))
    (cons s m)))

(defun iPerl-menu-bar-update (&rest list)
  ;; this also changes the menu bar between the major mode and Perl
  (force-mode-line-update))

(defsubst iPerl-overlay (start end category &optional extend)
  (when (> end start)
    (and (memq category '(iPerl-perl iPerl-printing-perl))
	 ;; (= emacs-major-version 20)
	 ;; (< emacs-minor-version 7)
	 (progn
	   (put-text-property start end 'point-entered 'iPerl-menu-bar-update)
	   (put-text-property start end 'point-left 'iPerl-menu-bar-update)))
    (overlay-put (make-overlay start end nil (not extend) extend)
		 'category category)))

(defun iPerl-add-overlays ()
  (save-excursion
    (goto-char (point-min))
    (let ((p (point)) i perl
	  (modified (buffer-modified-p))
	  (m (iPerl-markup-matcher
	      (cdr (iPerl-by-style iPerl-markup-matcher)))))
      (while (re-search-forward (car m) nil t)
	(iPerl-overlay p (match-beginning 0) 'iPerl-text t)
	(setq i 1
	      p (match-end 0))
	(while (not (match-beginning i))
	  (setq i (1+ i)))
	(setq i (nth i m))
	(if (integerp i)
	    (progn
	      (setq perl (+ (match-beginning 0) i))
	      (iPerl-overlay (match-beginning 0) perl
			     'iPerl-markup-open)
	      (iPerl-overlay perl (1+ perl) 'iPerl-perl t)
	      (iPerl-overlay (1+ perl) (match-end 0)
			     'iPerl-markup-close))
	  (iPerl-overlay (match-beginning 0) (match-end 0) 'iPerl-markup-open)
	  (if (consp i)
	      (setq i (cadr i)
		    perl 'iPerl-printing-perl)
	    (setq perl 'iPerl-perl))
	  (when (re-search-forward i nil t)
	    (if (match-beginning 1)
		(progn
		  (iPerl-overlay p (match-end 1) perl t)
		  (iPerl-overlay (match-end 1) (match-end 0)
				 'iPerl-markup-close))
	      (iPerl-overlay p (match-beginning 0) perl t)
	      (iPerl-overlay (match-beginning 0) (match-end 0)
			     'iPerl-markup-close))
	    (setq p (match-end 0)))))
      (iPerl-overlay p (point-max) 'iPerl-text t)
      (or modified
	  (set-buffer-modified-p nil)))
    (run-hooks 'iPerl-view-change-hook))
  (force-mode-line-update))



(defun iPerl-backward (&optional arg)
  "Move point backward ARG bits of text or Perl.
On reaching beginning of buffer, stop and signal error."
  (interactive "p")
  (while (>= (setq arg (1- (or arg 1))) 0)
    (backward-char)
    (let ((list (overlays-at (point))))
      (while (and list
		  (not (memq (overlay-get (car list) 'category)
			     iPerl-categories)))
	(setq list (cdr list)))
      (if (or (not list)
	      (<= (overlay-start (car list)) (point-min)))
	  (error "Beginning of buffer"))
      (goto-char (overlay-start (car list)))
      (if (memq (overlay-get (car list) 'category)
		'(iPerl-markup-open iPerl-markup-close))
	  (iPerl-backward)))))

(defun iPerl-forward (&optional arg)
  "Move point forward ARG bits of text or Perl.
On reaching end of buffer, stop and signal error."
  (interactive "p")
  (while (>= (setq arg (1- (or arg 1))) 0)
    (let ((list (overlays-at (point))))
      (while (and list
		  (not (memq (overlay-get (car list) 'category)
			     iPerl-categories)))
	(setq list (cdr list)))
      (if (or (not list)
	      (>= (overlay-end (car list)) (point-max)))
	  (error "End of buffer"))
      (goto-char (overlay-end (car list)))
      (if (memq (overlay-get (car list) 'category)
		'(iPerl-markup-open iPerl-markup-close))
	  (iPerl-forward)))))



(defun iPerl-hide (symbol arg &optional ellipsis)
  (set symbol
       (if (null arg) (not (symbol-value symbol))
	 (> (prefix-numeric-value arg) 0)))
  (if (symbol-value symbol)
      (progn
	(add-to-invisibility-spec symbol)
	(if ellipsis
	    (put symbol 'after-string "..."))
	(if iPerl-intangible-when-hidden
	    (put symbol 'intangible (if (eq symbol 'iPerl-text) 1 2))))
    (remove-from-invisibility-spec symbol)
    (put symbol 'after-string nil)
    (if iPerl-intangible-when-hidden
	(put symbol 'intangible nil))))

(defvar iPerl-markup-open nil)
(defvar iPerl-markup-close nil)
(defun iPerl-hide-markup (&optional arg)
  "Hides the bits of Perl and surrounding markup in the buffer.
Ideally you don't need to see markup in iPerl-mode.  There is however one
exception for an empty printing bit of Perl which can then not be seen.
See `iPerl-intangible-when-hidden'."
  (interactive "P")
  (iPerl-hide 'iPerl-markup-open arg)
  (iPerl-hide 'iPerl-markup-close iPerl-markup-open)
  (force-mode-line-update))

(defvar iPerl-perl nil)
(defun iPerl-hide-perl (&optional arg)
  "Hides the bits of Perl in the buffer.
See `iPerl-intangible-when-hidden'."
  (interactive "P")
  (iPerl-hide 'iPerl-perl arg t)
  (iPerl-hide 'iPerl-printing-perl iPerl-perl t)
  (force-mode-line-update))

(defun iPerl-hide-perl-and-markup (&optional arg)
  "Hides the bits of Perl and surrounding markup in the buffer.
See `iPerl-intangible-when-hidden'."
  (interactive "P")
  (iPerl-hide 'iPerl-perl arg t)
  (iPerl-hide 'iPerl-printing-perl iPerl-perl t)
  (iPerl-hide 'iPerl-markup-open iPerl-perl)
  (iPerl-hide 'iPerl-markup-close iPerl-perl)
  (force-mode-line-update))

(defvar iPerl-text nil)
(defun iPerl-hide-text (&optional arg)
  "Hides the bits of text in the buffer.
See `iPerl-intangible-when-hidden'."
  (interactive "P")
  (iPerl-hide 'iPerl-text arg t)
  (force-mode-line-update))

(defun iPerl-show-all ()
  "Shows the hidden bits of text in the buffer again."
  (interactive)
  (mapcar (lambda (c) (iPerl-hide c 0)) iPerl-categories)
  (force-mode-line-update))



(defun iPerl-on-region (start end &optional flag)
  "Pass optional header and region to iperl interpreter.
The header feature is for adding defines, includes and such to the region.
With a positive prefix ARG, instead of sending region, define header from
beginning of buffer to point.  With a negative prefix ARG, instead of sending
region, clear header."
  (interactive "r\nP")
  (if flag
      (setq iPerl-header-marker (if (> (prefix-numeric-value flag) 0)
				    (point-marker)))
    (if (and iPerl-header-marker (< iPerl-header-marker start))
	(save-excursion
	  (let (buffer-undo-list
		(modified (buffer-modified-p)))
	    (goto-char iPerl-header-marker)
	    (append-to-buffer (current-buffer) start end)
	    (shell-command-on-region (point-min)
				     (setq end (+ iPerl-header-marker
						  (- end start)))
				     (format "iperl --%s" iPerl-style))
	    (delete-region iPerl-header-marker end)
	    (or modified
		(set-buffer-modified-p nil))))
      (if iPerl-header-marker
	  (setq start (point-min)))
      (shell-command-on-region start end (format "iperl --%s" iPerl-style)))))



;; Function to be set as an iPerl-isearch-open-invisible' property
;; to the overlay that makes the iPerl invisible.
(defun iPerl-isearch-open-invisible (overlay)
  (save-excursion
    (goto-char (overlay-start overlay))
    (iPerl-hide (overlay-get overlay 'category) 0)))



;;; skeletons

(define-skeleton iPerl-bit
  "Insert markup for a bit of Perl.
There are four variations of xml, `xml-perl', `xml-script', `xml-server'
and `xml-short' one of which gets chosen via `iPerl-style-equiv'.
See `iPerl-skeleton-space'."
  (bang () "!{" space _ space "}!")
  (control () ? space _  space ?)
  (m4 () "perl({" space _ space "})")
  (pod () "P<{" space _ space "}>")
  (xml-perl () "<perl>" space _ space "</perl>")
  (xml-script () "<script runat=server>" space _ space "</script>")
  (xml-server () "<server>" space _ space "</server>")
  (xml-short () "<{" space _ space "}>"))

(define-skeleton iPerl-long-bit
  "Insert markup for a multiline bit of Perl.
See `iPerl-bit' for xml possiblities and `iPerl-skeleton-space'."
  (bang () "!{\n" _ "\n}!")
  (control () "\n" _ "\n")
  (m4 () "perl({\n" _ "\n})")
  (pod () '(if (bolp) ?\n "\n\n")
       "=begin perl\n" _ "\n\n=end perl"
       '(if (eolp) ?\n "\n\n"))
  (xml-perl () "<perl>\n" _ "\n</perl>")
  (xml-script () "<script runat=server>\n" _ "\n</script>")
  (xml-server () "<server>\n" _ "\n</server>")
  (xml-short () "<{\n" _ "\n}>"))

(define-skeleton iPerl-printing-bit
  "Insert markup for a printing bit of Perl.
See `iPerl-skeleton-space'."
  (bang () "!<" space _ space ">!")
  (control () ? space _  space ?)
  (m4 () "perl(<" space _ space ">)")
  (pod () "P<" space _ space ?>)
  (xml () "&<" space _ space ">;"))

(define-skeleton iPerl-line
  "Insert markup for a line of Perl.
See `iPerl-skeleton-space'."
  (bang () ?! space)
  (control () ? space)
  (cpp () ?# space)
  (pod () "=for perl" space))

(provide 'iPerl)



[					; lisp half ignores POD this way

=head1 NAME

iPerl.el - Edit iPerl documents
with comfortable support in Emacs


=head1 DESCRIPTION

This library allows editing iPerl documents in two modes simultaneously.
There is the major mode for the host document.  And then there is iPerl minor
mode, which will enhance the current major mode.  The bits of markup and
Perl in your document are edited in Perl or CPerl mode.  The menus and
keybindings change automatically when the cursor is on a bit of Perl.

And, so you see what you are doing, markup, plain bits and printing bits of
Perl are each highlighted in a different color, and you can make markup and/or
Perl or the rest of the text invisible so as to concentrate on one aspect of
your document or the other.

The documentation for this is all in the Emacs help system.  As a good entry
point (if the minor mode is active) click Describe Buffer Modes from the Help
menu.  Or use Describe Function... and type in C<iPerl-mode>.



=head1 INSTALLATION

Click Describe Variable... from the Help menu and type in C<load-path>.  You
get a list of directories where Emacs looks for libraries.  You should copy
F<lisp/iPerl.elc> and optionally the source file F<lisp/iPerl.el> to one of
them.  Emacs foresees the directory containing F<site-lisp> for this.

In your file F<~/.emacs> add the following:

  (setq iPerl-map-prefix "\C-c!")
  (setq iPerl-map-prefix [f12])

  (let ((map (make-sparse-keymap)))
    (define-key map "\C-m" 'iPerl-mode)
    (global-set-key iPerl-map-prefix map))

  (autoload 'iPerl-mode "iPerl" "Toggle iPerl minor mode." t nil)

Of the first two lines you can chose one or the other.  The first one means,
along the guidelines for minor-mode keybindings, that the key sequence C<C-c !
C-m> (that's C<control-C ! control-M>) will activate and deactivate iPerl
minor mode.  The second more conveniently means that C<f12 C-m> (that's C<F12
control-M>) will do it.  This is then also the keybinding prefix for all
commands of iPerl minor mode.


=head1 SEE ALSO

L<Text::iPerl>, L<iperl>, L<web-iPerl>, L<emacs>, L<perl>, http://beam.to/iPerl/

=cut ]