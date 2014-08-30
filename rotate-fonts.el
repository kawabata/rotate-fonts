;;; rotate-fonts.el --- Rotate fonts of specified charsets.  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 KAWABATA, Taichi

;; Filename: rotate-fonts.el
;; Description: Rotate Fonts in Emacs.
;; Author: KAWABATA, Taichi <kawabata.taichi@gmail.com>
;; Created: 2014-07-20
;; Version: 1.140727
;; Package-Requires: ((emacs "24") (dash "2.8") (doremi "0"))
;; Keywords: tools
;; URL: https://github.com/kawabata/rotate-fonts

;;; Commentary:

;; rotate-fonts.el
;; ===============
;;
;; This is tiny utility to rotate fonts for specific Unicode regions
;; or blocks with 'doremi' or 'helm' user interface. If you want
;; static font setting for each region, you should probably use
;; `unicode-fonts' utility.
;;
;; setup
;; -----
;;
;; Customize `rotate-fonts-specs` as a list of `((key (fonts)
;; (scripts))...)`. Following is an example.
;;
;;    (customize-set-variable
;;     'rotate-fonts-specs
;;     '((?l  ("Inconsolata"
;;             "Source Code Pro"           ; Adobe
;;             "Monaco"
;;             "Monofur"
;;             "Droid Sans Mono"
;;             "DejaVu Sans Mono"
;;             "Anonymous Pro"
;;             "Consolas"                  ; Windows
;;             "Menlo"                     ; Macintosh
;;             "IPAMonaPGothic")
;;            (latin))
;;
;; `?l` is key, "Inconsolata", etc. are font family names, and
;; `(latin)` is a list of scripts. (see characters.el for the name of
;; scripts.) `script' may also be a cons of Unicode range, e.g.
;; `(#x1800 . #x18ff)`.
;;
;; Calling function (rotate-fonts KEY) will let you toggle fonts with
;; "n" or "p" key.  For example,
;;
;;     (global-set-key (kbd "C-c r") 'rotate-fonts)
;;
;; will let you toggle the latin fonts by pressing `C-c r l`.
;;
;; You should use 'customize-set-variable' instead of 'setq' to
;; automatically check and remove non-existent fonts.

;;; Code:

(require 'dash)
(require 'doremi)
(require 'helm)

(defgroup rotate-fonts nil
  "Rotate Fonts."
  :group 'wp)

(defun rotate-fonts-init (variable specs)
  "Remove non-existent fonts in SPECS and put to VARIABLE."
  (dolist (spec specs)
    (when (listp (elt spec 1))
      (setf (elt spec 1) (--filter
                          (find-font (font-spec :family it))
                          (elt spec 1)))
      (unless (elt spec 1) (message "Font not found! %s" (elt spec 0)))))
  (set variable specs))

(defcustom rotate-fonts-specs
  '((?l  ("Inconsolata"
          "Source Code Pro"           ; Adobe
          "Monaco"
          "Monofur"
          "Droid Sans Mono"
          "DejaVu Sans Mono"
          "Anonymous Pro"
          "Consolas"                  ; Windows
          "Menlo"                     ; Macintosh
          "IPAMonaPGothic")
         (latin)))
  "Font specs with (key variable targets)."
  :group 'rotate-fonts
  :set 'rotate-fonts-init)

(defvar rotate-fonts-key nil)

;;;###autoload
(defun rotate-fonts (key)
  "Rotate Fonts specified by KEY and reset fontsets."
  (interactive "kKey=? ")
  (setq rotate-fonts-key
        (if (stringp key) (string-to-char key) key))
  (let* ((spec (assq key rotate-fonts-specs))
         (fonts (elt spec 1)))
    (doremi 'rotate-fonts-to-font
            (car fonts)
            nil nil fonts)))

(defun rotate-fonts-to-font (font)
  "rotate-font-specs を、FONTまで回転させる。"
  (message "font=%s" font)
  (let* ((spec (assq rotate-fonts-key rotate-fonts-specs))
         (fonts (elt spec 1)))
    (setf (elt spec 1)
          (progn
            (while (not (equal font (car fonts)))
              (setq fonts (-rotate 1 fonts)))
            fonts))
    (message "fonts=%s" fonts)
    (rotate-fonts-update)
    font))

(defun rotate-fonts-helm-source (key)
  (setq rotate-fonts-key key)
  `((name . "Font selection")
    (init . rotate-fonts-helm-init)
    (candidates-in-buffer)
    (mode-line . helm-mode-line-string)
    (action . (("Select" . rotate-fonts-to-font)))))

(defun rotate-fonts-helm-init ()
  (let* ((spec (assq rotate-fonts-key rotate-fonts-specs))
         (fonts (elt spec 1)))
    (with-current-buffer (helm-candidate-buffer
                          (get-buffer-create "*Fonts*"))
      (erase-buffer)
      (dolist (font fonts)
        (insert font "\n")))))

;;;###autoload
(defun rotate-fonts-helm (key)
  "Choose fonts from Helm menu."
  (interactive "kKey=? ")
  (setq rotate-fonts-key
        (if (stringp key) (string-to-char key) key))
  (helm :sources (rotate-fonts-helm-source key)
        :keymap helm-map))

(defun rotate-fonts-update ()
  (dolist (spec rotate-fonts-specs)
    (let* ((fonts    (elt spec 1))
           (fonts    (if (stringp fonts)
                         (list fonts) fonts))
           (targets  (elt spec 2))
           (first    t)
           (size (string-to-number
                  (aref (x-decompose-font-name
                         (cdr (assq 'font (frame-parameters))))
                        xlfd-regexp-pixelsize-subnum))))
      (dolist (target targets)
        (dolist (font fonts)
          (set-fontset-font nil target
                            (font-spec :family font :size size)
                            nil
                            (if (not first) 'append
                              (setq first nil))))))))

(provide 'rotate-fonts)
;;; rotate-fonts.el ends here
