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

(mapcar (lambda (c) (format "%02x" c))
        (encode-coding-char (decode-char 'ucs #x2572) 'compound-text))
;; #x2572
("1b" "24" "28" ;; GL 94^N
 "47" ;; cns11643-7
 "23" "4d") [2 times]
Esc $(G#M

;; 65509 FFE5
("1b" "24" "28" ;; GL 94^N
 "41" ;; GB2312  942 chars
 "23" "24")
Esc $(A#$

(mapcar (lambda (c) (format "%02x" c))
        (encode-coding-string
         (concat (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-1)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-2)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-3)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-4)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-7)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-6)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-8)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-5)
                 (decode-coding-string (string-make-unibyte
                                        (string #xAB)) 'iso-8859-9)
                 )
         'compound-text)
        )
# Esc [ - F


(with-temp-buffer
  (insert-file-contents "/tmp/x.utf8" nil)
  (set-buffer-file-coding-system 'compound-text-with-extensions)
  (write-file "/tmp/x.ctext"))


(with-temp-buffer
  (dotimes (i #x2FA1)
    (unless (or (< i 32)
                (and (>= i #x7F) (<= i #x9F))
                (and (>= i #xD800) (<= i #xDFFF))
                (and (>= i #xFDD0) (<= i #xFDEF))
                (and (>= i #xFFFE) (<= i #xFFFF))
                (and (>= i #x1FFFE) (<= i #x1FFFF)))
      (let* ((c   (decode-char 'ucs i))
             (str (encode-coding-char c
                                      'ctext
                                      ;; 'compound-text-with-extensions
                                      )))
        (when str
          (setq str (mapconcat (lambda (c)
                                 (format "%02X" c))
                               str " "))
          (insert (format "U+%04X = %s\n" i str))))))
  (set-buffer-file-coding-system 'compound-text-with-extensions)
  (set-buffer-file-coding-system 'utf-8)
  (write-file (format "%s%d.txt"
                      (if (featurep 'xemacs) "xemacs" "emacs")
                      emacs-major-version)))

(insert (decode-coding-string (string-make-unibyte (string #x1B #x2D #x46 #xAA))
                              'compound-text))
(insert (decode-coding-string (string-make-unibyte (string #xAA))
                              'iso-8859-7))

(insert (decode-coding-string (string #x7E)
                              'japanese-iso-8bit))~


(with-temp-buffer
  (set-buffer-file-coding-system 'ctext)
  (insert (decode-coding-string (string #x1B #x28 #x4A #x7E) 'ctext))
  (describe-char (point-min)))
(insert #x203E)



(progn
  (switch-to-buffer "x")
  (erase-buffer)
  (require 'cl)
  (loop for i from #x20 to #xFF
        do
        (let* ((str (decode-coding-string (string #x1B #x28 #x49
                                                  #x1B #x29 #x49
                                                  i) 'ctext))
               (u   (and (length str)
                         (encode-char (aref str 0) 'ucs))))
          (insert (format "%02X %s  %02X\n" i str (or u -1)))))
  (goto-char (point-min))
  (set-buffer-file-coding-system 'compound-text))
