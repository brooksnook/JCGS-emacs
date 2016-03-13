;;; config-packages.el --- set up my packages downloads  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  John Sturdy

;; Author: John Sturdy <john.sturdy@arm.com>
;; Keywords: 

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

;; See:
;; - https://www.emacswiki.org/emacs/ELPA
;; - http://www.gnu.org/software/emacs/manual/html_node/emacs/Packages.html
;; - http://www.gnu.org/software/emacs/manual/html_node/elisp/Packaging.html

;;; Code:

(setq package-user-dir (substitute-in-file-name "$EHOME/emacs-packages"))
(unless (file-directory-p package-user-dir)
  (make-directory package-user-dir))
(add-to-list 'package-archives (cons "marmalade" "https://marmalade-repo.org/packages/"))
(add-to-list 'package-archives (cons "melpa" "https://melpa.org/packages/"))

(provide 'config-packages)

;;; config-packages.el ends here
