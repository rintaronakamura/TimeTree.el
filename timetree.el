;;; timetree.el --- TimeTree frontend for Emacs -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 rintaronakamura
;;
;; Author: rintaronakamura <n.queue.r@gmail.com>
;; Maintainer: rintaronakamura <n.queue.r@gmail.com>
;; Created: 4月 18, 2023
;; Modified: 4月 18, 2023
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/rnakamura/timetree
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar timetree-access-token (getenv "TIMETREE_ACCESS_TOKEN"))
(defvar timetree-base-url "https://timetreeapis.com/")

;; TODO
;; ・不正値が入力されたときの処理もちゃんと書く
;; ・任意項目(説明、場所、URL、予定参加者のユーザー)を入力できるようにする
;; ・処理を分ける
(defun timetree-new-event ()
  (interactive)

  (setq calendar-alist
        (timetree-success-callback
         (timetree-request-get (concat timetree-base-url "calendars"))))

  (setq selected-calendar-id
        (let ((calendar-name-list (mapcar #'car calendar-alist)))
          (let ((selected-calendar-name (completing-read "カレンダーを選択して下さい: " calendar-name-list)))
            (cdr (assoc selected-calendar-name calendar-alist)))))

  (setq title (read-string "タイトルを入力してください: "))

  (setq start-date
        (read-string "開始日を入力してください (例 2023-04-05): "))

  (setq start-time
        (read-string "開始時間を入力してください (例 12:15:00)\n＊終日予定の場合は時刻を 00:00:00 にしてください: "))

  (setq start-at (concat start-date "T" start-time))

  ;; TODO 開始日と等しい場合は省略する
  (setq end-date (read-string "終了日を入力してください (例 2023-04-05): "))

  ;; TODO 開始時間が 00:00:00 なら省略する
  (setq end-time
        (read-string "終了時間を入力してください (例 12:15:00)\n＊終日予定の場合は時刻を 00:00:00 にしてください: "))

  (setq end-at (concat end-date "T" end-time))

  (setq all-day
        (if (and (string= start-time "00:00:00") (string= end-time "00:00:00"))
            "true"
          "false"))

  (setq label-alist
        (timetree-success-callback
         (timetree-request-get (concat timetree-base-url "calendars/" selected-calendar-id "/labels"))))

  (setq selected-label-id
        (let ((label-name-list (mapcar #'car label-alist)))
          (let ((selected-label-name (completing-read "ラベルを選択して下さい: " label-name-list)))
            (cdr (assoc selected-label-name label-alist)))))

  (setq new-calendar-data `(
    (data . (
      (attributes . (
        (category . "schedule")
        (title . ,title)
        (all_day . ,all-day)
        (start_at . ,start-at)
        (start_timezone . "Asia/Tokyo")
        (end_at . ,end-at)
        (end_timezone . "Asia/Tokyo")
      ))
      (relationships . (
        (label . (
          (data . (
            (id . ,selected-label-id)
            (type . "label")
          ))
        ))
      ))
    ))
  ))

  (request
    (concat timetree-base-url "calendars/" selected-calendar-id "/events")
    :type "POST"
    :headers `(("Content-Type" . "application/json")
               ("Accept" . "application/vnd.timetree.v1+json")
               ("Authorization" . ,(concat "Bearer " timetree-access-token)))
    :data (json-encode new-calendar-data)
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "予定を登録しました")))
    :error #'timetree-error-callback))

(defun timetree-extract-name-id-pair (item)
  (let ((attributes (assoc-default 'attributes item)))
    (cons (assoc-default 'name attributes) (assoc-default 'id item))))

(defun timetree-success-callback (response)
  (let ((data (request-response-data response)))
    (let ((alist (assoc-default 'data data)))
      (mapcar #'timetree-extract-name-id-pair alist))))

(defun timetree-error-callback ()
  (cl-function
   (lambda (&rest args &key error-thrown &allow-other-keys)
     (message "Got error: %S" error-thrown))))

;; FIXME: エラー処理が拾えていない
(defun timetree-request-get (url)
  (request url
    :headers `(("Accept" . "application/vnd.timetree.v1+json")
               ("Authorization" . ,(concat "Bearer " timetree-access-token)))
    :parser 'json-read
    :sync t
    :error #'timetree-error-callback))

(provide 'timetree)
;;; timetree.el ends here
