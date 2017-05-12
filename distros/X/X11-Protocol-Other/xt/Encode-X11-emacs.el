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


(defun my-try-decode ()
  (unless (coding-system-p 'utf-8)
    (require 'un-define))

  (let (ustr ubuf cstr cbuf)
    (let ((coding-system-for-read 'utf-8))
      (find-file "../tempfile.utf8")
      (setq ubuf (current-buffer))
      (setq ustr (buffer-string)))

    (let ((coding-system-for-read 'ctext))
      (find-file "tempfile.ctext")
      (setq cbuf (current-buffer))
      (setq cstr (buffer-string)))

    (let ((pos (compare-strings ustr nil nil
                                cstr nil nil)))
      (unless (eq pos t)
        (error "different at %S" pos)

        (with-current-buffer ubuf
          (goto-char (+ (point-min) (pos))))
        (with-current-buffer cbuf
          (goto-char (+ (point-min) (pos))))))))



