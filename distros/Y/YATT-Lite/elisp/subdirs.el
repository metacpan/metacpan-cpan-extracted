(if (fboundp 'normal-top-level-add-subdirs-to-load-path)
    (let ((default-directory 
            (or (and load-file-name (file-name-directory load-file-name))
                default-directory)))
      (normal-top-level-add-to-load-path (list default-directory))
      (normal-top-level-add-subdirs-to-load-path)
      ;;
      (load (concat default-directory "yatt-autoload.el"))))

