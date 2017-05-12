(require 'htmlize)
(require 'cl)

(defun Text::EmacsColor-htmlize (filename &optional desired-major-mode)
  "Uses htmlize to format FILENAME (as MAJOR-MODE)"
  (with-temp-buffer
    (flet ((message (&rest args) nil))
      (insert-file-contents filename)
      (setq buffer-file-name filename) ; cperl-mode requires this for some reason
      (set-buffer-modified-p nil)
      (when desired-major-mode
        (funcall (intern (format "%s-mode" desired-major-mode))))
      (font-lock-fontify-buffer)
      (htmlize-ensure-fontified)
      (with-current-buffer (htmlize-buffer-1)
        (prog1
            (buffer-substring-no-properties (point-min) (point-max))
          (kill-buffer (current-buffer)))))))
