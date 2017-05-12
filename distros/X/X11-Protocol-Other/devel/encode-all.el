;; Copyright 2011 Kevin Ryde
;;
;; This file is part of X11-Protocol-Other.
;;
;; X11-Protocol-Other is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your option) any
;; later version.
;;
;; X11-Protocol-Other is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


;; ctext-non-standard-encodings
;; ctext-non-standard-encodings-alist

(defun my-ctext ()
  (my-ctext-1 'ctext "")
  (when (coding-system-p 'compound-text-with-extensions)
    (my-ctext-1 'compound-text-with-extensions "-ext")))

(defun my-ctext-1 (coding ext)
  (unless (coding-system-p 'utf-8)
    (require 'un-define))

  (let ((ctext-non-standard-encodings-alist nil)
        (ctext-non-standard-encodings nil))

    (with-temp-buffer
      (dotimes (i #x2FA1D)
        (unless (or (< i 32)
                    (and (>= i #x7F) (<= i #x9F))
                    (and (>= i #xD800) (<= i #xDFFF))
                    (and (>= i #xFDD0) (<= i #xFDEF))
                    (and (>= i #xFFFE) (<= i #xFFFF))
                    (and (>= i #x1FFFE) (<= i #x1FFFF)))
          (let ((c (decode-char 'ucs i)))
            (if c
                (if (encode-coding-char c coding)
                    (insert c))))))

      (let ((str (buffer-string))
            (basename (format "encode-%s%d"
                              (if (featurep 'xemacs) "xemacs" "emacs")
                              emacs-major-version))
            (backup-inhibited t))

        (find-file (format "%s%s.ctext" basename ext))
        (erase-buffer)
        (insert str)
        (set-buffer-file-coding-system coding)
        (save-buffer)
        (kill-buffer nil)

        (find-file (format "%s%s.utf8" basename ext))
        (erase-buffer)
        (insert str)
        (set-buffer-file-coding-system 'utf-8)
        (save-buffer)
        (kill-buffer nil)))))







      ;;   (find-file (format "encode-%s%d-ext.ctext"
      ;;                      (if (featurep 'xemacs) "xemacs" "emacs")
      ;;                      emacs-major-version))
      ;;   (erase-buffer)
      ;;   (insert str)
      ;;   (set-buffer-file-coding-system 'ctext)
      ;;   (save-buffer)
      ;;   (kill-buffer nil))))



      ;; (let ((want-len 192954)
      ;;       (got-len (length str)))
      ;;   (unless (= want-len got-len)
      ;;     (error "want-len %S got-len %S" want-len got-len)))


    ;; (let ((coding-system-for-read 'utf-8))
    ;;   (find-file "encode-all.utf8"))
    ;; (message "coding used %S" last-coding-system-used)
    ;; (message "buffer coding %S" buffer-file-coding-system)

;;    (let ((coding-system-for-write )
;;          (write-file ))
;; 
;;        (let ((coding-system-for-write 'compound-text-with-extensions)
;;              (backup-inhibited t))
;;          (write-file (format "encode-%s%d-ext.ctext"
;;                              (if (featurep 'xemacs) "xemacs" "emacs")
;;                              emacs-major-version))))))
;; 
;; 
;; ;; (dotimes (i #x2FA1)
;; ;;   (unless (or (< i 32)
;; ;;               (and (>= i #x80) (<= i #x9F))
;; ;;               (and (>= i #xD800) (<= i #xDFFF))
;; ;;               (and (>= i #xFDD0) (<= i #xFDEF))
;; ;;               (and (>= i #xFFFE) (<= i #xFFFF))
;; ;;               (and (>= i #x1FFFE) (<= i #x1FFFF)))
;; ;;     (insert (decode-char 'ucs i))))

