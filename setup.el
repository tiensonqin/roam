;;; ~/org/roam/setup.el -*- lexical-binding: t; -*-

(require 'org)

;; prevent bunch of backup files during markdown export by ox-hugo
(setq make-backup-files nil)

(defun jk-org-kwds ()
  "parse the buffer and return a cons list of (property . value)
from lines like:
#+PROPERTY: value"
  (org-element-map (org-element-parse-buffer 'element) 'keyword
                   (lambda (keyword) (cons (org-element-property :key keyword)
                                           (org-element-property :value keyword)))))

(defun jk-org-kwd (KEYWORD)
  "get the value of a KEYWORD in the form of #+KEYWORD: value"
  (cdr (assoc KEYWORD (jk-org-kwds))))

(defun me/add-hugo-info ()
  (interactive)
  (goto-char 0)
  (let* ((setupfile (jk-org-kwd "SETUPFILE"))
         (hugo-section (jk-org-kwd "HUGO_SECTION"))
         )

  (unless  setupfile
    (message "adding setupfile")
    (goto-char 0)
    (insert "#+SETUPFILE:./hugo_setup.org\n")
  )

  (unless hugo-section
    (message "adding hugo_section")
    (goto-char 0)
    (insert "#+HUGO_SECTION: zettels\n")
  )
  (save-buffer))
)

(defun me/hugo-export (f)
  (setq buffer (find-file f))

  (unless (equal (file-name-nondirectory f) "hugo_setup.org")
    (me/add-hugo-info)
    ;; (ignore-errors (org-hugo-export-wim-to-md))
    (org-hugo-export-wim-to-md)
  ))

(defun me/export-hugo-from-dir (dir)
  "run `handler' on files matching `pattern' under `dir'"
  (interactive)

  (require 'find-lisp)
  (mapc (lambda (f)
          (message "process file: %s" f)
          (me/hugo-export f))
        (find-lisp-find-files dir "\\.org$" )))

;; all these below are needed to generate backlinds for org-roam
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/dash")
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/f")
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/s")
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/emacsql")
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/emacsql-sqlite")
(add-to-list 'load-path "~/.emacs.d/.local/straight/build/org-roam")
(require 'org-roam)
(setq org-roam-directory "~/org/roam/org")

(defun my/org-roam--backlinks-list-with-content (file)
  (with-temp-buffer
    (if-let* ((backlinks (org-roam--get-backlinks file))
              (grouped-backlinks (--group-by (nth 0 it) backlinks)))
        (progn
          (insert (format "\n\n* %d Backlinks\n"
                          (length backlinks)))
          (dolist (group grouped-backlinks)
            (let ((file-from (car group))
                  (bls (cdr group)))
              (insert (format "** [[file:%s][%s]]\n"
                              file-from
                              (org-roam--get-title-or-slug file-from)))
              (dolist (backlink bls)
                (pcase-let ((`(,file-from _ ,props) backlink))
                  (insert (s-trim (s-replace "\n" " " (plist-get props :content))))
                  (insert "\n\n")))))))
    (buffer-string)))

(defun my/org-export-preprocessor (backend)
(let ((links (my/org-roam--backlinks-list-with-content (buffer-file-name))))
    (unless (string= links "")
    (save-excursion
        (goto-char (point-max))
        (insert (concat "\n* Backlinks\n") links)))))

(require 'ox)
(add-hook 'org-export-before-processing-hook 'my/org-export-preprocessor)

(add-to-list 'load-path "~/.emacs.d/.local/straight/build/ox-hugo")
(require 'ox-hugo)
