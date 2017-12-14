;;; config-debuggers.el --- setup up emacs debugging   -*- lexical-binding: t; -*-

;; Copyright (C) 2017  John Sturdy

;; Author: John Sturdy <john.sturdy@grapeshot.com>
;; Keywords: tools, convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'realgud)

(defun jcgs-find-ancestral-directory-matching (dir pattern)
  "Find the nearest ancestor of DIR matching PATTERN."
  (setq dir (expand-file-name dir))
  (while (and (> (length dir) 2)
	      (not (string-match pattern (file-name-nondirectory dir))))
    (setq dir (expand-file-name ".." dir)))
  (and (string-match pattern dir)
       dir))

(defun jcgs/preload-realgud-file-remap ()
  "Preload the file name table for ‘realgud:gdb’.
Gets all the C source files in the general vicinity."
  (when realgud:gdb-track-mode
    (dolist (file (directory-files-recursively
		   (or (jcgs-find-ancestral-directory-matching default-directory "src")
		       ;; take a guess if we can't find ....../src/.......
		       (expand-file-name "../.."))
		   ".+\\.c$"))
      (puthash (file-name-nondirectory file)
	       file
	       realgud-file-remap))))

(add-hook 'realgud:gdb-track-mode-hook 'jcgs/preload-realgud-file-remap)

(provide 'config-debuggers)
;;; config-debuggers.el ends here
