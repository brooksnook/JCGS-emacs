;;; config-org-mode.el --- set up JCGS' org mode
;;; Time-stamp: <2016-01-20 18:19:50 johstu01>

(require 'org)

(add-to-list 'load-path (substitute-in-file-name "$GATHERED/emacs"))
(add-to-list 'load-path (substitute-in-file-name "$GATHERED/emacs/information-management"))

(add-to-list 'org-modules 'org-timer)
(add-to-list 'org-modules 'org-clock)
(add-to-list 'org-modules 'org-mobile)

(org-load-modules-maybe t)

(add-to-list 'load-path (expand-file-name "information-management" user-emacs-directory))
(require 'work-tasks)
(require 'work-log)

;; so I can exchange files with non-emacs users and still have their systems pick a text editor:
(add-to-list 'auto-mode-alist (cons "\\.org\\.txt" 'org-mode))

(setq org-todo-keywords
      '((sequence "TODO(t)" "BLOCKED(b)" "CURRENT(c)" "OPEN(o)"
		  "|"
		  "DONE(d)" "CANCELLED(x)"))
      org-clock-in-switch-to-state "CURRENT"
      org-use-fast-todo-selection nil
      org-log-done 'time
      org-log-into-drawer t
      org-agenda-include-diary t
      org-agenda-compact-blocks t
      org-agenda-start-with-follow-mode t
      org-agenda-start-with-clockreport-mode t
      org-agenda-start-on-weekday 0
      org-agenda-columns-add-appointments-to-effort-sum t
      org-agenda-default-appointment-duration 60 ; minutes
      ;; org-agenda-overriding-columns-format ; should probably set this
      org-directory (substitute-in-file-name "$ORG/")
      foo (message "org dir is %s" org-directory)
      org-default-notes-file (expand-file-name "new.org" org-directory)
      org-archive-location (substitute-in-file-name "$ORG/archive/%s::")
      org-agenda-files (append (mapcar (function
					(lambda (file)
					  (expand-file-name (format "%s.org" file) org-directory)))
				       '("general" "shopping" "eating" "research" "work"
					 "projects" "learning" "improvement" "goals"))
			       (list (substitute-in-file-name "$VEHICLES/Marmalade/Marmalade-work.org")
				     ;; (substitute-in-file-name "$VEHICLES/Marmalade/170.org")
				     )
			       (mapcar (function
					(lambda (file)
					  (expand-file-name (format "Cat-Imp-%s.org" file)
							    (substitute-in-file-name "$DROPBOX/Categorical_Imperative"))))
				       '("work" "purchasing")))
      bar (message "agenda files %s" org-agenda-files)
      org-capture-templates '(("p" "Personal todo" entry
			       (file+headline
				(substitute-in-file-name "$ORG/general.org")
				"Incoming"
				"** TODO"))
			      ("b" "Buy" entry (file+headline
						(substitute-in-file-name "$ORG/shopping.org")
						"Incoming"
						"** BUY")))
      org-refile-use-outline-path 'full-file-path
      org-outline-path-complete-in-steps t
      org-timer-default-timer 25
      org-clock-idle-time 26
      org-enforce-todo-dependencies t
      org-agenda-dim-blocked-tasks t
      org-enforce-todo-checkbox-dependencies t
      org-M-RET-may-split-line nil
      org-mobile-directory "~/Dropbox/MobileOrg"
      org-mobile-inbox-for-pull (expand-file-name "inbox.org" org-mobile-directory)
      )

(defvar jcgs/org-ssid-tag-alist
  '(("BTHomeHub2-8GHW" . "@home")
    ;; todo: add one for @office
    ("Makespace" . "@Makespace")
    )
  "Alist mapping wireless networks to tags.")

(require 'metoffice)

(defvar weather-loadable (and (file-readable-p metoffice-config-file)
			      (load-file metoffice-config-file))
  "Whether we have a chance of getting the weather data.")

(require 'calendar)

(defun jcgs/org-agenda-make-early-extra-matcher ()
  "Make some extra matcher types for my custom agenda, to go early in the list."
  (let ((result nil))
    (when (member (calendar-day-of-week
		   (calendar-gregorian-from-absolute (org-today)))
		  org-agenda-weekend-days)
      (push '(tags-todo "weekend") result))
    (let ((wifi-command "/sbin/iwgetid"))
      (when (file-executable-p wifi-command)
	(let* ((network (car (split-string
			      (shell-command-to-string
			       (concat wifi-command " --raw")))))
	       (tag (cdr (assoc network jcgs/org-ssid-tag-alist))))
	  (when (stringp tag)
	    (push `(tags-todo ,tag) result)))))
    result))

(defun jcgs/org-agenda-make-late-extra-matcher (early-matches)
  "Make some extra matcher types for my custom agenda, to go late in the list.
EARLY-MATCHES shows what we've already found to go earlier in the list."
  (let ((todo-home '(tags-todo "@home"))
	(result nil))
    (when (string-match "isaiah" (system-name))
      (push todo-home result))
    (when (and weather-loadable (or (member todo-home result)
				    (member todo-home early-matches))) ; could be there because of hostname, or ssid
      (let* ((day-weather (metoffice-get-site-period-weather nil 0 'day))
	     (temperature (metoffice-weather-aspect day-weather 'feels-like-day-maximum-temperature))
	     (rain (metoffice-weather-aspect day-weather 'precipitation-probability-day))
	     (wind (metoffice-weather-aspect day-weather 'wind-speed)))
	(when (and (>= temperature 10)
		   (<= rain 6)
		   (<= wind 6))
	  (push '(tags-todo "outdoor|@garden") result))))))

(setq jcgs/org-agenda-current-matcher
      (let* ((earlies (jcgs/org-agenda-make-early-extra-matcher))
	     (lates (jcgs/org-agenda-make-late-extra-matcher earlies)))
	`("c" "Agenda and upcoming tasks"
	  ((tags-todo "urgent")
	   (tags-todo "PRIORITY=\"A\"")
	   (tags-todo "today")
	   ,@earlies
	   (agenda "")
	   (tags-todo "next")
	   ,@lates
	   (tags-todo "soon/OPEN")
	   (tags-todo "PRIORITY=\"B\"")
	   (tags-todo "soon/TODO")
	   ))))

(add-to-list 'org-agenda-custom-commands jcgs/org-agenda-current-matcher)

(add-to-list 'org-agenda-custom-commands '("y" "mackaYs shopping" tags-todo "Mackays"))
(add-to-list 'org-agenda-custom-commands '("k" "supermarKet shopping" tags-todo "supermarket"))
(add-to-list 'org-agenda-custom-commands '("d" "Daily Bread" tags-todo "daily_bread"))
(add-to-list 'org-agenda-custom-commands '("o" "Online" tags-todo "online"))
(add-to-list 'org-agenda-custom-commands '("h" "At home" tags-todo "@home"))
(add-to-list 'org-agenda-custom-commands '("H" "Hacking" ((tags-todo "hacking")
							  (tags-todo "programming")
							  (tags-todo "@Makespace")
							  (tags-todo "soldering")
							  (tags-todo "woodwork")
							  (tags-todo "sewing")
							  (tags-todo "epoxy")
							  (tags-todo "hotglue")
							  (tags-todo "electronics"))))
(add-to-list 'org-agenda-custom-commands '("W" "Writing" tags-todo "writing"))
(add-to-list 'org-agenda-custom-commands '("w" "At work" tags-todo "@office"))
(add-to-list 'org-agenda-custom-commands '("E" "weekEnd" tags-todo "weekend"))
(add-to-list 'org-agenda-custom-commands '("u" "Urgent" ((tags-todo "urgent") (tags-todo "PRIORITY=\"A\""))))
(add-to-list 'org-agenda-custom-commands '("U" "Soon" ((tags-todo "soon") (tags-todo "PRIORITY=\"B\""))))
(add-to-list 'org-agenda-custom-commands '("p" "Phone" tags-todo "phone"))
(add-to-list 'org-agenda-custom-commands '("x" "Next" tags-todo "next"))

(when (and (boundp 'work-agenda-file)
	   (stringp work-agenda-file)
	   (file-exists-p work-agenda-file))
  (setq org-capture-templates (cons '("w" "Work todo" entry
				      (file+headline work-agenda-file "Incoming"
						     "** TODO"))
				    org-capture-templates)))

;; TODO: make this stop my pomodoro timer
;; TODO: probably it should be in the pomodoro code rather than this hook
;; (defun jcgs/org-clock-out-function ()
;;   "My customization of task clock-out."
;;   (org-timer-stop))

;; (add-hook 'org-clock-out-hook 'jcgs/org-clock-out-function)

(require 'org-mode-linked-tasks)

(global-set-key "\C-cn" 'org-capture)

(defun org-tags-view-todo-only ()
  "Call `org-tags-view' with a prefix."
  (interactive)
  (org-tags-view t))

(global-set-key "\C-cm" 'org-tags-view-todo-only)

(require 'org-mode-task-colours)
(require 'org-mode-pomodoros)
(require 'org-mode-jira)
(require 'org-mode-log-tasks)

;;;; Timer notification

(defvar jcgs/background-images-directory (substitute-in-file-name "$HOME/backgrounds")
  "My directory of background images.")

(defun jcgs/random-background-image ()
  "Pick a background image at random."
  (let ((images (directory-files jcgs/background-images-directory t "\\.jpg" t)))
    (nth (random (length images)) images)))

(defun jcgs/org-timer-notifier (notification)
  "Display NOTIFICATION in an arresting manner."
  (let ((overrun nil))
    (jcgs/org-timer-log-pomodoro-done notification)
    (require 'notify-via-browse-url)
    (notify-via-browse-url
     (format "<STYLE type=\"text/css\"> BODY { background: url(\"file:%s\") } </STYLE>"
	     (jcgs/random-background-image))
     (format "Pomodoro completed at %s" (current-time-string))
     notification)
    (save-window-excursion
      (switch-to-buffer (get-buffer-create "*Org timer notification*"))
      (erase-buffer)
      (insert notification (substitute-command-keys "\n\n\\[exit-recursive-edit] to continue\n\n"))
      (let ((start-of-overrun-keystrokes (point)))
	(recursive-edit)
	;; avoid wasting any keystrokes the user was typing at the time
	(when (> (point-max)
		 start-of-overrun-keystrokes)
	  (setq overrun  (buffer-substring start-of-overrun-keystrokes
					   (point-max)))
	  (kill-new overrun))))
    (message "%s saved in kill ring" overrun)))

(setq org-show-notification-handler 'jcgs/org-timer-notifier)

(eval-after-load "org"
  '(jcgs/org-timer-setup))

(defun jcgs/org-clock-out-on-typing-break-function ()
  "Clock out of the current task, as a typing break is starting."
  (message "jcgs/org-clock-out-on-typing-break-function: %S %S %S"
	   org-clock-goto-may-find-recent-task
	   (car org-clock-history)
	   (if (car org-clock-history)
	       (marker-buffer (car org-clock-history))
	     "<none>"))
  (when (and org-clock-goto-may-find-recent-task
	     (car org-clock-history)
	     (marker-buffer (car org-clock-history)))
    (let ((jcgs/org-clocking-out-for-type-break t))
      (org-clock-goto)
      (message "clocking out at %d in %S" (point) (current-buffer))
      (org-clock-out))
    ;; we did not actually do the typing break:
    nil))

(defvar jcgs/type-break-start-break-hook nil
  "Hooks for starting a typing break.
You may want to turn voice input off at this point; and suspend task timers.")

(eval-after-load "type-break"
  '(progn
     (defadvice type-break (before jcgs/type-break-hook-runner activate)
       (run-hooks 'jcgs/type-break-start-break-hook))
     (add-hook 'jcgs/type-break-start-break-hook 'jcgs/org-clock-out-on-typing-break-function)))

;; (defun jcgs/org-open-hierarchical-date (date)
;;   "Ensure there is a hierarchical record for DATE.
;; Return whether a new date was inserted."
;;   ;; TODO: I think there is an existing library I could use for this
;;   ;; TODO: make it find the right place in a file even if DATE is not the last date
;;   ;; TODO: make it use a common date format for the argument
;;   (let ((new-date-inserted nil))
;;     (goto-char (point-max))
;;     (beginning-of-line 1)
;;     (when (looking-at "^\\s-+$")
;;       (delete-region (point) (point-max)))
;;     (unless (save-excursion
;; 	      (beginning-of-line 0)
;; 	      (looking-at "^$"))
;;       (insert "\n")
;;       (setq new-date-inserted t))
;;     (unless (re-search-backward (concat "* Year " (substring date 0 -6) "$") (point-min) t)
;;       (goto-char (point-max))
;;       (insert "* Year " (substring date 0 -6) "\n")
;;       (setq new-date-inserted t))
;;     (goto-char (point-max))
;;     (unless (re-search-backward (concat "** Month " (substring date 0 -3) "$") (point-min) t)
;;       (goto-char (point-max))
;;       (insert "** Month " (substring date 0 -3) "\n")
;;       (setq new-date-inserted t))
;;     (goto-char (point-max))
;;     (unless (re-search-backward (concat "*** Date " date "$") (point-min) t)
;;       (goto-char (point-max))
;;       (unless (bolp)
;; 	(insert "\n"))
;;       (insert "*** Date " date "\n\n")
;;       (setq new-date-inserted t))
;;     new-date-inserted))

(when (and (boundp 'work-agenda-file)
	   (stringp work-agenda-file)
	   (file-readable-p work-agenda-file)
	   (not (member work-agenda-file org-agenda-files)))
  (push work-agenda-file org-agenda-files))

(defvar jcgs/shell-mode-accumulated-command-history-file
  (if (file-directory-p "/work/johstu01")
      "/work/johstu01/work-org/shell-command-history.org"
    (substitute-in-file-name "$ORG/shell-command-history.org"))
  "My accumulated command history.")

(require 'org-mouse-extras)
(add-hook 'org-mode-hook 'jcgs-org-mouse-stuff)

(defun planner-to-org ()
  "Convert text from planner format to org format."
  (interactive)
  (goto-char (point-min)) (replace-regexp "^#[ABC] " "")
  (goto-char (point-min)) (replace-regexp " {{Tasks:[0-9]+}}" "")
  (goto-char (point-min)) (replace-regexp " (\\[\\[[0-9.]+\\]\\])$" "")
  (goto-char (point-min)) (replace-string "pos:" "file:")
  (goto-char (point-min)) (replace-regexp "#[0-9]+" "")
  (goto-char (point-min)) (replace-regexp "^o" "CURRENT")
  (goto-char (point-min)) (replace-regexp "^_" "TODO")
  (goto-char (point-min)) (replace-regexp "^X" "DONE")
  (goto-char (point-min)) (replace-regexp "^" "** "))

(defvar source-file-names-pattern "\\(.el\\|\\.c\\|\\.h\\)$"
  "Pattern describing the files to record.")

(defun make-source-org-tree (dir &optional prefix)
  "Make an org tree for DIR, at level PREFIX."
  (interactive "DDirectory: ")
  (if (null prefix) (setq prefix "*"))
  (let ((pending nil))
    (dolist (file (directory-files dir t))
      (if (and (file-directory-p file)
	       (not (string-match "\\.$" file)))
	  (push file pending)
	(if (string-match source-file-names-pattern file)
	    (insert prefix " TODO read " (file-name-nondirectory file) "\n"))))
    (dolist (pended (nreverse pending))
      (insert prefix " " (file-name-nondirectory pended) "\n")
      (make-source-org-tree pended (concat "*" prefix)))))

(define-key org-mode-map "\C-z" 'org-todo)
(define-key org-mode-map "\C-cw" 'org-agenda-list)
(global-set-key "\C-ca" 'org-agenda)
(define-key org-agenda-mode-map "\C-z" 'org-agenda-todo)

(defun org-global-close-property-drawers ()
  "Close all property drawers in this buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-property-start-re (point-max) t)
      (org-flag-drawer t))))

;;;; Patch the table export to use vertical rules:

(defvar org-export-latex-table-column-separator "|"
  "String to put between columns in exported tables.")

(defvar org-export-latex-table-left-margin "|"
  "String to put before the first column in exported tables.")

(defvar org-export-latex-table-right-margin "|"
  "String to put after the last column in exported tables.")

(setq org-export-latex-tables-column-borders t)

(eval-after-load "org-export-latex"
  '(defun org-export-latex-tables (insert)
     "Convert tables to LaTeX and INSERT it.
This is John Sturdy's modified version."
     (goto-char (point-min))
     (while (re-search-forward "^\\([ \t]*\\)|" nil t)
       ;; FIXME really need to save-excursion?
       (save-excursion (org-table-align))
       (let* ((beg (org-table-begin))
	      (end (org-table-end))
	      (raw-table (buffer-substring beg end))
	      fnum fields line lines olines gr colgropen line-fmt align
	      caption label attr floatp longtblp)
	 (if org-export-latex-tables-verbatim
	     (let* ((tbl (concat "\\begin{verbatim}\n" raw-table
				 "\\end{verbatim}\n")))
	       (apply 'delete-region (list beg end))
	       (insert (org-export-latex-protect-string tbl)))
	   (progn
	     (setq caption (org-find-text-property-in-string
			    'org-caption raw-table)
		   attr (org-find-text-property-in-string
			 'org-attributes raw-table)
		   label (org-find-text-property-in-string
			  'org-label raw-table)
		   longtblp (and attr (stringp attr)
				 (string-match "\\<longtable\\>" attr))
		   align (and attr (stringp attr)
			      (string-match "\\<align=\\([^ \t\n\r,]+\\)" attr)
			      (match-string 1 attr))
		   floatp (or caption label))
	     (setq lines (split-string raw-table "\n" t))
	     (apply 'delete-region (list beg end))
	     (when org-export-table-remove-special-lines
	       (setq lines (org-table-clean-before-export lines 'maybe-quoted)))
	     ;; make a formatting string to reflect aligment
	     (setq olines lines)
	     (while (and (not line-fmt) (setq line (pop olines)))
	       (unless (string-match "^[ \t]*|-" line)
		 (setq fields (org-split-string line "[ \t]*|[ \t]*"))
		 (setq fnum (make-vector (length fields) 0))
		 (setq line-fmt
		       (concat
			org-export-latex-table-left-margin
			(mapconcat
			 (lambda (x)
			   (setq gr (pop org-table-colgroup-info))
			   (format "%s%%s%s"
				   (cond ((eq gr ':start)
					  (prog1 (if colgropen "|" "")
					    (setq colgropen t)))
					 ((eq gr ':startend)
					  (prog1 (if colgropen "|" "|")
					    (setq colgropen nil)))
					 (t ""))
				   (if (memq gr '(:end :startend))
				       (progn (setq colgropen nil) "|")
				     "")))
			 fnum org-export-latex-table-column-separator)
			org-export-latex-table-right-margin))))
	     ;; fix double || in line-fmt
	     (message "line-fmt raw = %S" line-fmt)
	     (setq line-fmt (replace-regexp-in-string "||" "|" line-fmt))
	     ;; maybe remove the first and last "|"
	     (when (and (not org-export-latex-tables-column-borders)
			(string-match "^\\(|\\)?\\(.+\\)|$" line-fmt))
	       (message "line-fmt chomped = %S" line-fmt)
	       (setq line-fmt (match-string 2 line-fmt)))
	     (message "line-fmt now = %S" line-fmt)
	     ;; format alignment
	     (unless align
	       (setq align (apply 'format
				  (cons line-fmt
					(mapcar (lambda (x) (if x "r" "l"))
						org-table-last-alignment)))))
	     ;; prepare the table to send to orgtbl-to-latex
	     (setq lines
		   (mapcar
		    (lambda(elem)
		      (or (and (string-match "[ \t]*|-+" elem) 'hline)
			  (split-string (org-trim elem) "|" t)))
		    lines))
	     (when insert
	       (insert (org-export-latex-protect-string
			(concat
			 (if longtblp
			     (concat "\\begin{longtable}{" align "}\n")
			   (if floatp "\\begin{table}[htb]\n"))
			 (if (or floatp longtblp)
			     (format
			      "\\caption{%s%s}"
			      (if label (concat "\\\label{" label "}") "")
			      (or caption "")))
			 (if longtblp "\\\\\n" "\n")
			 (if (not longtblp) "\\begin{center}\n")
			 (if (not longtblp) (concat "\\begin{tabular}{" align "}\n"))
			 (orgtbl-to-latex
			  lines
			  `(:tstart nil :tend nil
				    :hlend ,(if longtblp
						(format "\\\\
\\hline
\\endhead
\\hline\\multicolumn{%d}{r}{Continued on next page}\\
\\endfoot
\\endlastfoot" (length org-table-last-alignment))
					      nil)))
			 (if (not longtblp) (concat "\n\\end{tabular}"))
			 (if longtblp "\n" "\n\\end{center}\n")
			 (if longtblp
			     "\\end{longtable}"
			   (if floatp "\\end{table}"))))
		       "\n\n"))))))))

;;;; archive all individual DONE tasks:

(defun jcgs/org-archive-done-tasks-buffer ()
  "Archive all DONE entries in the current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward org-heading-regexp (point-max) t)
      (beginning-of-line 1)
      (org-map-entries (function
			(lambda ()
			  (let ((started-at (point)))
			    (org-archive-subtree)
			    (setq org-map-continue-from started-at))))
		       "/DONE|CANCELLED|BOUGHT|EATEN|KEPT|BROKEN|ALMOSTKEPT" 'file))))

(defun jcgs/org-archive-done-tasks-file (file)
  "Archive all DONE entries in FILE."
  (interactive "fArchive tasks in file: ")
  (find-file file)
  (jcgs/org-archive-done-tasks-buffer))

(defun jcgs/org-archive-done-tasks ()
  "Archive all DONE entries in variable `org-agenda-files'."
  (interactive)
  (save-window-excursion
    (mapcar 'jcgs/org-archive-done-tasks-file
	    (org-agenda-files))))

;;;; sort entries by stage

(defun jcgs/org-todo-sort-entries-by-stage ()
  "Sort entries by their stage of progress."
  (interactive)
  (org-sort-entries nil ?f
		    'jcgs/todo-keyword-sort-key
		    '<))

(defun jcgs/org-todo-keyword-sort-key ()
  "Return the sort key of the current entry.
For use with `org-sort-entries'."
  (save-excursion
    (when (looking-at org-outline-regexp) (goto-char (1- (match-end 0))))
    (if (or (looking-at (concat " +" org-todo-regexp "\\( +\\|[ \t]*$\\)"))
	    (looking-at "\\(?: *\\|[ \t]*$\\)"))
	(position (match-string-no-properties 1) org-todo-keywords-1 :test 'equal)
      999)))

;;; change task dates

(defun jcgs/org-task-today (&optional no-move offset)
  "Mark the task on the current line as to be done today.
Unless optional NO-MOVE, move to the next entry.
With optional OFFSET, add that number of days."
  (interactive "P")
  (let ((today-string (format-time-string "<%Y-%m-%d %a>"
					  (if offset
					      (time-add (current-time)
							(days-to-time offset))
					    nil)))
	(eol (line-end-position)))
    (save-excursion
      (beginning-of-line)
      ;; todo: probably some org-mode functions for positions and changes in the line
      (if (re-search-forward "<[0-9]+-[0-9]+-[0-9]+ [a-z]+>" eol t)
	  (replace-match today-string)
	(let* ((tag-start (save-excursion
			    (and (re-search-forward "[:@a-z0-9_]+:$" eol t)
				 (match-beginning 0))))
	       (text-end (and tag-start
			      (save-excursion
				(goto-char tag-start)
				(skip-syntax-backward "s")
				(point)))))
	  (goto-char (or text-end eol))
	  (just-one-space)
	  (insert today-string)
	  (unless (eolp)
	    (just-one-space)))))
    ;; todo: probably some org-mode or outline-mode command for this
    (forward-line)))

(defun jcgs/org-task-tomorrow (&optional extra-days)
  "Mark the task on the current line as to be done tomorrow.
Then move to the next entry.
An argument can change the number of days ahead, 1 being tomorrow."
  (interactive "p")
  (jcgs/org-task-today nil extra-days))

(define-key org-mode-map [ f8 ] 'jcgs/org-task-today)
(define-key org-mode-map [ f9 ] 'jcgs/org-task-tomorrow)

(defun jcgs/org-agenda-task-today (&optional no-move)
  "Like jcgs/org-task-today, but from the agenda buffer.
Unless optional NO-MOVE, move to the next entry."
  (interactive "P")
  (save-window-excursion
    (other-window 1)
    (jcgs/org-task-today t))
  (unless no-move
    (org-agenda-next-line)))

(defun jcgs/org-agenda-task-tomorrow (&optional extra-days)
  "Like jcgs/org-task-tomorrow, but from the agenda buffer.
Then move to the next entry.
An argument can change the number of days ahead, 1 being tomorrow."
  (interactive "p")
  (save-window-excursion
    (other-window 1)
    (jcgs/org-task-tomorrow extra-days))
  (org-agenda-next-line))

(define-key org-agenda-mode-map [ f8 ] 'jcgs/org-agenda-task-today)
(define-key org-agenda-mode-map [ f9 ] 'jcgs/org-agenda-task-tomorrow)

;;;;;;;;;;;;;;;;;;;;;;;;
;; separate log files ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; (make-variable-buffer-local 'tracking-org-file)

;; (defun jcgs-select-work-log ()
;;   "This function is meant to go on `find-file-hook'."
;;   (cond
;;    ((string-match (substitute-in-file-name "$COMMON/Marmalade") default-directory)
;;     (setq tracking-org-file (substitute-in-file-name "$COMMON/Marmalade/Marmalade-work.log")))))

;; (add-hook 'find-file-hook 'jcgs-select-work-log)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transfer from and to mobile ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(org-mobile-pull)

(defun jcgs/org-maybe-push-to-mobile ()
  "Offer to push the agenda to mobile."
  (when (y-or-n-p "Push to mobile? ")
    (org-mobile-push)))

(add-hook 'kill-emacs-query-functions 'jcgs/org-maybe-push-to-mobile)

;;;;;;;;;;;;;;;;;;;;;;
;; counting entries ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun jcgs/org-count-entry ()
  "Count the current entry, in the appropriate counter."
  (let* ((state (and (looking-at org-todo-line-regexp)
		     (match-end 2)
		     (match-string-no-properties 2)))
	 (pair (assoc state jcgs/org-state-counters)))
    (if pair
	(rplacd pair (1+ (cdr pair)))
      (setq jcgs/org-state-counters
	    (cons (cons state 1)
		  jcgs/org-state-counters)))))

(defun jcgs/org-count-entries (scope)
  "Count the entries in each state for SCOPE."
  (let ((jcgs/org-state-counters nil))
    (org-map-entries 'jcgs/org-count-entry nil scope)
    (with-output-to-temp-buffer "*Entry state counts*"
      (let ((fmt (format "%% %ds: %%d\n" (apply 'max (mapcar 'length (mapcar 'car jcgs/org-state-counters))))))
	(dolist (state (sort jcgs/org-state-counters (lambda (a b) (> (cdr a) (cdr b )))))
	  (when (car state)
	    (princ (format fmt (car state) (cdr state)))))))))

(defun jcgs/org-count-all-entries ()
  "Count all entries."
  (interactive)
  (jcgs/org-count-entries 'agenda))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; list entries with a given tag ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun jcgs/org-tag-list (tag)
  "Return a list of the occurrences of TAG."
  (let ((result nil))
    (org-map-entries
     (lambda ()
       (push (cons (org-get-heading t t)
		   (cons (org-get-todo-state)
			 (org-get-tags)))
	     result))
     tag			  ; maybe add "+TODO=\"TODO\"" or "/!"
     'agenda)
    result))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Most Important Three ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun jcgs/org-most-important-3 ()
  "Get the items tagged as the three most important."
  (jcgs/org-tag-list "mi3"))

(defun jcgs/org-mark-as-most-important ()
  "Mark the current item as one of three most important things to do today."
  (let ((already (jcgs/org-most-important-3)))
    (when (>= (length already) 3)
      (error "Already got 3 most important tasks"))
    (org-toggle-tag "mi3" 'on)))

;;;;;;;;;;;;;;;;;
;; Agenda loop ;;
;;;;;;;;;;;;;;;;;

(defun jcgs/org-agenda-monitor-update ()
  "Update my outgoing agenda files from incoming org file alterations."
  (interactive)				; for debugging, mostly
  (message "Starting agenda update")
  (save-excursion
    (let ((x (find-buffer-visiting org-mobile-capture-file)))
      (when x
	(kill-buffer x)))
    (find-file org-mobile-capture-file)
    (mapcar (lambda (file)
	      (set-buffer (find-buffer-visiting file))
	      (revert-buffer t t t))
	    org-agenda-files))
  (org-mobile-pull)
  (save-excursion
    (org-agenda-list)
    (write-file "/tmp/agenda-list")
    (org-agenda nil "c")
    (write-file "/tmp/agenda-current")
    (org-agenda nil "k")
    (write-file "/tmp/agenda-supermarket"))
  (org-mobile-push)
  (message "Done agenda update")
  (jcgs/org-agenda-monitor-start)	; set the next one going
  )

(setq remote-update 'remote-update)

(global-set-key [ remote-update ] 'jcgs/org-agenda-monitor-update)

(defun jcgs/org-agenda-trigger-monitor-update ()
  "Trigger an agenda update.
Doing it this means we're not running anything large in the sentinel."
  (interactive)
  (setq unread-command-events (nreverse (cons remote-update (nreverse unread-command-events)))))

(defvar jcgs/org-agenda-monitor-timer nil
  "The timer to batch updates rather than doing them on every change.")

(defvar jcgs/org-agenda-monitor-delay 20
  "How long to delay to allow other changes to come in.")

(defun jcgs/org-agenda-monitor-sentinel (process change-descr)
  "Run on each state change of the agenda monitor.
Argument PROCESS is the monitor process.
CHANGE-DESCR is the change"
  (message "agenda monitor sentinel %s" change-descr)
  (when (string= change-descr "finished")
    (message "Agenda directory has changed, waiting %d seconds in case of further changes"
	     jcgs/org-agenda-monitor-delay)
    (when (timerp jcgs/org-agenda-monitor-timer)
      (cancel-timer jcgs/org-agenda-monitor-timer)
      (setq jcgs/org-agenda-monitor-timer nil))
    (setq jcgs/org-agenda-monitor-timer
	  (run-with-idle-timer jcgs/org-agenda-monitor-delay nil 'jcgs/org-agenda-trigger-monitor-update))))

(defun jcgs/org-agenda-monitor-start ()
  "Arrange to monitor incoming alterations to my agenda files."
  (interactive)				; mostly for testing
  (message "Starting agenda monitor")
  (let* ((agenda-monitor-buffer (get-buffer-create " *agenda monitor*"))
	 (agenda-monitor-process (start-process "agenda-monitor"
						agenda-monitor-buffer
						"/usr/bin/inotifywait"
						"-e" "modify"
						"-e" "create"
						(substitute-in-file-name "$EHOME/Dropbox/org")
						)))
    (set-process-sentinel agenda-monitor-process
			  'jcgs/org-agenda-monitor-sentinel))
  )

(defun jcgs/org-agenda-monitor-stop ()
  "Arrange to stop monitoring incoming alterations to my agenda files."
  (interactive)				; mostly for testing
  (setq jcgs/org-agenda-monitor-timer nil))

;;; config-org-mode.el ends here
