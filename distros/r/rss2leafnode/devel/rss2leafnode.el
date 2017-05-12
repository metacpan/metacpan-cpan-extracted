;;; rss2leafnode.el --- helpers for rss2leafnode program

;; Copyright 2010, 2014 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Version: 0
;; Keywords: files
;; URL: http://user42.tuxfamily.org/rss2leafnode/index.html
;; EmacsWiki: FindFileAtPoint

;; This file is part of RSS2Leafnode.
;;
;; RSS2Leafnode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; RSS2Leafnode is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; http://www.gnu.org/licenses.

;;; Code:

(add-to-list 'auto-mode-alist '("/\\.rss2leafnode\\.conf\\'" . perl-mode))

(add-to-list 'auto-mode-alist '("/\\.rss2leafnode\\.status\\'" . perl-mode))
(add-to-list 'completion-ignored-extensions ".rss2leafnode.status")

(provide 'rss2leafnode)

;;; rss2leafnode.el ends here
