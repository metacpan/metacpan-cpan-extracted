;;; lsp-yatt --- YATT::Lite support for lsp-mode -*- lexical-binding: t -*-

;;; Copyright (C) 2019 KOBAYASI Hiroaki

;; Author: KOBAYASI Hiroaki <hkoba@cpan.org>


;;; Commentary:

;;; Code:

(require 'lsp-mode)
(require 'yatt-lint-any-mode)

(defun lsp-yatt--ls-command (&rest args)
  "Generate the language server startup command."
  (let* ((app-dir (locate-dominating-file "." "app.psgi"))
         (yatt-lib (cond (app-dir
                          (concat (file-local-name app-dir) "lib/YATT/"))
                         (t
                          yatt-lint-any-YATT-dir))))
    `(,(concat yatt-lib "Lite/LanguageServer.pm")
      "server"
      ,@ args)))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection 'lsp-yatt--ls-command)
                  :major-modes '(yatt-mode yatt-declaration-mode)
                  :server-id 'yatt))

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-tramp-connection (lambda () (lsp-yatt--ls-command "--quiet")))
                  :major-modes '(yatt-mode yatt-declaration-mode)
                  :remote? t
                  :server-id 'yatt-remote))


(provide 'lsp-yatt)
;;; lsp-yatt.el ends here
