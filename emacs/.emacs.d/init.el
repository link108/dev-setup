;; inhibit-startup-echo-area-message MUST be set to a hardcoded
;; string of your login name
;;(setq inhibit-startup-echo-area-message "username")
(setq inhibit-startup-message t)

(require 'package)
(setq package-enable-at-startup nil) ;; ????
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/"))

(package-initialize)
;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
(package-refresh-contents)
(package-install 'use-package))

(use-package try
	     :ensure t)

(use-package company
  :ensure t
  :init (global-company-mode))

(defconst cameron-savefile-dir (expand-file-name "savefile" user-emacs-directory))

;; Map the window manipulation keys to meta 0, 1, 2, o
(global-set-key (kbd "M-3") 'split-window-horizontally)
(global-set-key (kbd "M-2") 'split-window-vertically)
(global-set-key (kbd "M-1") 'delete-other-windows)
(global-set-key (kbd "M-0") 'delete-window)
(global-set-key (kbd "M-o") 'other-window)


(ido-mode 1)
(use-package ido-vertical-mode
  :config
  (setq ido-vertical-define-keys 'C-n-and-C-p-only)
  (ido-vertical-mode t))


(global-set-key (kbd "C-x C-b") 'ibuffer)


;; TODO (cmotevasselani): Look into this code block
;; Helm added
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (flymd company-go exec-path-from-shell go-mode gradle-mode groovy-mode markdown-mode ido-vertical-mode counsel-projectile flx-ido smex counsel ivy projectile helm which-key use-package try))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package projectile
  :ensure t
  :config
  ;;(define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (projectile-mode +1))

;; End helm added


(use-package ivy :demand
  :config
  (setq ivy-use-virtual-buffers t
        ivy-count-format "%d/%d ")
  (ivy-mode t))


(use-package smex
  :ensure t
  :bind
  (([remap execute-extended-command] . smex)
   ("M-X" . smex-major-mode-commands)))


;; (use-package ido                        ; Better minibuffer completion
;;   :init (progn
;;           (ido-mode)
;;           (ido-everywhere))
;;   :config
;;   (setq ido-enable-flex-matching t      ; Match characters if string doesn't
;;                                         ; match
;;         ido-create-new-buffer 'always   ; Create a new buffer if nothing matches
;;         ido-use-filename-at-point 'guess
;;         ;; Visit buffers and files in the selected window
;;         ido-default-file-method 'selected-window
;;         ido-default-buffer-method 'selected-window
;;         ido-use-faces nil))             ; Prefer flx ido faces

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode))


(use-package flx-ido                    ; Flex matching for IDO
  :ensure t
  :init (flx-ido-mode t)
  ;; disable flx highlights
  (setq flx-ido-use-faces nil
	ido-enable-flex-matching t
	ido-use-faces nil)
  (setq ivy-re-builders-alist
        '((t . ivy--regex-fuzzy))))

;; Do not use tabs for indentation
;;(setq-default indent-tabs-mode nil)

;; tab length

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq indent-line-function 'insert-tab)

(global-set-key (kbd "TAB") 'tab-to-tab-stop)

;;(setq-default tab-width 2)
;;(setq tab-width 2) ; or any other preferred value
;;(defvaralias 'c-basic-offset 'tab-width)
;;(defvaralias 'cperl-indent-level 'tab-width)



(use-package recentf
  :config
  (setq recentf-save-file (expand-file-name "recentf" cameron-savefile-dir)
        recentf-max-saved-items 500
        recentf-max-menu-items 15
        ;; disable recentf-cleanup on Emacs start, because it can cause
        ;; problems with remote files
        recentf-auto-cleanup 'never)
;;  (global-set-key (kbd 'C-x C-r') 'recentf-open-files)
  (recentf-mode +1))

(defun ido-recentf-open ()
  "Use `ido-completing-read' to \\[find-file] a recent file"
  (interactive)
  (if (find-file (ido-completing-read "Find recent file: " recentf-list))
      (message "Opening file...")
    (message "Aborting")))

(global-set-key (kbd "C-x C-r") 'ivy-recentf)
;;(global-set-key (kbd "C-x C-r") 'ido-recentf-open)

(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :bind
  (("C-c l" . markdown-follow-link-at-point))
  :init (setq markdown-command "/usr/local/bin/pandoc"))


;; Remove trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)



(use-package groovy-mode
  :ensure t
  :mode (("\\.groovy\\'" . groovy-mode)
         ("\\.gradle\\'" . groovy-mode)))

;;(use-package gradle-mode
;;  :ensure t
;;  :mode (("\\.gradle\\'" . gradle-mode)))

(setq compilation-scroll-output t)
;;(setq compilation-scroll-output 'first-error)

;; Close the current buffer with one keycombo
(global-set-key (kbd "M-k") 'kill-this-buffer)
;; Toggle maximize buffer view
(global-set-key (kbd "M-RET") 'toggle-maximize-buffer)


(global-linum-mode 1)
;;(global-visual-line-mode 1)
(setq linum-format "%d ")


;; Split windows with a single keycombo
;; (defun vsplit-last-buffer ()
;;   (interactive)
;;   (split-window-vertically)
;;   (other-window 1 nil)
;;   (projectile-find-file)
;;   (switch-to-next-buffer)
;;   )
;; (defun hsplit-last-buffer ()
;;   (interactive)
;;   (split-window-horizontally)
;;   (other-window 1 nil)
;;   (projectile-find-file)
;;   (switch-to-buffer (other-buffer))
;;   )

;; Maximize buffer
(defun toggle-maximize-buffer ()
  (interactive)
  (if (= 1 (length (window-list)))
      (jump-to-register '_)
    (progn
      (window-configuration-to-register '_)
      (delete-other-windows))))


;; Golang
(use-package go-mode
  :ensure t)

(use-package company-go
  :ensure t)


;; Set exec-path from shell
;; https://github.com/purcell/exec-path-from-shell
;; Unsure if this is needed if we store env vars in .zshenv
(use-package exec-path-from-shell
  :ensure t
  :init
  (exec-path-from-shell-initialize))

(defun my-go-mode-hook ()
  ; Call Gofmt before saving
  (add-hook 'before-save-hook 'gofmt-before-save)
  ; Godef jump key binding
  (local-set-key (kbd "M-.") 'godef-jump)
  (local-set-key (kbd "M-*") 'pop-tag-mark)
  )

(add-hook 'go-mode-hook 'my-go-mode-hook)
(add-hook 'go-mode-hook
      (lambda ()
        (set (make-local-variable 'company-backends) '(company-go))
        (company-mode)))
;;(add-hook 'before-save-hook 'gofmt-before-save)


;; enable rectangle selection
(cua-selection-mode t)
(global-set-key (kbd "C-c SPC") 'cua-rectangle-mark-mode)
