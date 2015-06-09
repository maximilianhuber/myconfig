(require-packages '(evil
                    evil-leader
                    evil-nerd-commenter
                    powerline
                    ;; column-marker
                    ;; column-enforce-mode
                    fill-column-indicator 
                    indent-guide
                    saveplace
                    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   EEEE V     V III L
;   E    V     V  I  L
;   EEE   V   V   I  L
;   E      V V    I  L
;   EEEE    V    III LLLL
;
; vim key bindings and modes
(require-package 'evil)
(evil-mode 1)

(setq evil-emacs-state-cursor '("red" box))
(setq evil-normal-state-cursor '("green" box))
(setq evil-visual-state-cursor '("orange" box))
(setq evil-insert-state-cursor '("red" bar))
(setq evil-replace-state-cursor '("red" bar))
(setq evil-operator-state-cursor '("red" hollow))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; modeline
(powerline-default-theme)

;; (require-package 'smart-mode-line)
;; (setq sml/show-client t)
;; (setq sml/show-eol t)
;; (setq sml/show-frame-identification t)
;; (sml/setup)

(setq-default fill-column 80)
(turn-on-auto-fill)
(add-hook 'text-mode-hook 'auto-fill-mode)
(add-hook 'latex-mode-hook 'auto-fill-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (require 'column-enforce-mode)
;; (global-column-enforce-mode t)
;; (require 'column-marker)
;; (add-hook 'foo-mode-hook (lambda () (interactive) (column-marker-1 80)))
(setq fci-rule-column 80)
(setq fci-rule-width 1)
(setq fci-rule-color "red")
(setq fci-rule-character-color nil)
(define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
(global-fci-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(indent-guide-global-mode)

;; Vim key bindings
(global-evil-leader-mode)
(evil-leader/set-leader ",")
(evil-leader/set-key
  "ci" 'evilnc-comment-or-uncomment-lines
  "cl" 'evilnc-quick-comment-or-uncomment-to-the-line
  "ll" 'evilnc-quick-comment-or-uncomment-to-the-line
  "cc" 'evilnc-copy-and-comment-lines
  "cp" 'evilnc-comment-or-uncomment-paragraphs
  "cr" 'comment-or-uncomment-region
  "cv" 'evilnc-toggle-invert-comment-line-by-line
  "\\" 'evilnc-comment-operator ; if you prefer backslash key
)

(define-key evil-motion-state-map "gcc" 'evilnc-comment-or-uncomment-lines)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq save-place-file (concat dotemacs-cache-directory "saveplace.el"))
(setq-default save-place t)
