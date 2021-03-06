;;;; Emacs setup for task management and noticeboard only
;;; Time-stamp: <2020-04-14 21:55:22 jcgs>

(setq debug-on-error t)

(setq weather-loadable nil)

;;;;;;;;;;;;;;;;;;;;
;; Load libraries ;;
;;;;;;;;;;;;;;;;;;;;

(load-file "$MY_ELISP/basics/jcgs-common-setup.el")
(load-file "$MY_ELISP/basics/host.el")
(load-file "$MY_ELISP/basics/ediff-fix.el")
(require 'cl)

(setq user-emacs-directory (expand-file-name
			    (concat (getenv "MY_ELISP")
				    "/")))

(load-file (expand-file-name "config/config-org-mode.el" user-emacs-directory))
(message "org-agenda-files is %S" org-agenda-files)
(load-file (expand-file-name "config/config-calendar-diary.el" user-emacs-directory))

(load-file (expand-file-name "basics/use-package.el" user-emacs-directory))
(add-to-list 'load-path (substitute-in-file-name "$MY_PROJECTS/emacs-pedals"))
(unless (and (boundp 'no-versor) no-versor)
  (load-file (expand-file-name "config/use-versor.el" user-emacs-directory)))

(find-file (expand-file-name "special-setups/tasks/tasks-emacs-setup.el" user-emacs-directory))

(add-to-list 'load-path (substitute-in-file-name "$ORGLISP"))
(require 'org-jcgs-journal)
(add-hook 'jcgs/org-journal-mode-hook 'auto-fill-mode)
(add-to-list 'load-path (substitute-in-file-name "$MY_PROJECTS/JCGS-emacs/information-management"))
(require 'dated-csv)

;;;;;;;;;;;;;;;;;;;
;; For home only ;;
;;;;;;;;;;;;;;;;;;;

(when (at-home-p)
  (let ((health-dir (substitute-in-file-name "$COMMON/health")))
    (add-to-list 'auto-mode-alist (cons (concat health-dir ".+\\.csv") 'dated-csv-mode))
    (dolist (file '("peak-flow.csv" "temperature.csv" "weight.csv"))
      (find-file (expand-file-name file health-dir))
      (goto-char (point-max))
      (dated-csv-mode)))
  (dolist (file '("wiring" "switchpanel" "Marmalade-work"))
    (add-to-list 'org-agenda-files
		 (substitute-in-file-name (format "$VEHICLES/Marmalade/%s.org"
						  file))
		 t))
  (setq org-reading-files (cons (substitute-in-file-name "$ORG/guide.org")
				(let ((reading-dir (substitute-in-file-name
						    "$COMMON/noticeboard-reading")))
				  (mapcar (lambda (file)
					    (expand-file-name file reading-dir))
					  '("advices-and-queries.org"))))))

;;;;;;;;;;;;;
;; Storage ;;
;;;;;;;;;;;;;

(let ((coimealta (expand-file-name "coimealta"
                                   (substitute-in-file-name
                                    "$MY_PROJECTS"))))
  (when (file-directory-p coimealta)
    (add-to-list 'load-path (expand-file-name "inventory" coimealta))
    (autoload 'storage-locate-item "storage" "Locate ITEM." t)))

;;;;;;;;;;;;;;
;; Journals ;;
;;;;;;;;;;;;;;

(when (boundp 'jcgs/org-journals)
  (dolist (file-descr jcgs/org-journals)
    (let ((file (cdr file-descr)))
      (when (file-exists-p file)
	(find-file file)
	(jcgs/org-journal-last-day t)))))

;;;;;;;;;;;;
;; Agenda ;;
;;;;;;;;;;;;

(setq org-agenda-files (delete-if-not 'file-exists-p org-agenda-files))
(mapc (lambda (file)
	(when (file-readable-p file)
	  (find-file file)))
      org-agenda-files)
(org-mobile-pull)
;; (org-agenda-list)
(org-agenda nil "c")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pre-set system shutdown ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun jcgs/emacs-pre-shutdown-function ()
  "Function to run soon before shutdown."
  (when (fboundp 'jcgs/org-revert-agenda-files)
    (jcgs/org-revert-agenda-files))
  (save-all-buffers-no-ask)
  (org-mobile-push))

(let ((shutdown-file "/tmp/shutdowntime"))
  (when (file-readable-p shutdown-file)
    (find-file shutdown-file)
    (let* ((time-from-file (diary-entry-time (buffer-string)))
	   (now (decode-time))
	   (before-string (format-time-string 
			   "%H%M"
			   (time-subtract
			    (encode-time 0 (% time-from-file 100) (/ time-from-file 100)
					 (nth 3 now) (nth 4 now) (nth 5 now)
					 (nth 8 now))
			    (seconds-to-time 120)))))
      (kill-buffer)
      (message "Will prepare for shutdown at %s" before-string)
      (run-at-time before-string nil 'jcgs/emacs-pre-shutdown-function)
      )))

(add-hook 'kill-emacs-hook 'jcgs/emacs-pre-shutdown-function)

(setq debug-on-error nil)

;;;; tasks-emacs-setup.el ends here
