(defconst org-wander-db--version 1)

(defconst org-wander-db--table-schemata
  '((files
     [
      (id :integer :unique :primary-key :autoincrement :not-null)
      (file :unique)
      (hash :not-null)
      (last-modified :not-null)
      ])

    (tags
     [(id :integer :unique :primary-key :autoincrement :not-null)
      (name :not-null :unique)
      ])

    (files_tags_link
     [(id :integer :unique :primary-key :autoincrement :not-null)
      (file :integer) (tag :integer)]
      (:foreign-key [tag] :references tags [id]
               :on-delete :cascade)
      (:foreign-key [file] :references files [id]
               :on-delete :cascade)
     )
    ))

(defun org-wander-db--init (db)
  "Initialize database DB with the correct schema and user version."
  (emacsql-with-transaction db
    (pcase-dolist (`(,table . ,schema) org-wander-db--table-schemata)
      (emacsql db [:create-table $i1 $S2] table schema))
    (emacsql db (format "PRAGMA user_version = %s" org-wander-db--version))))

(setq db (emacsql-sqlite "test.db"))

(org-wander-db--init db)

(emacsql db [:insert :into tags
             :values ([nil "cis"] [nil "fix-adapter"] [nil "critical"])])

(emacsql db [:insert :into files
             :values ([nil "abc.org" 123 123]  [nil "def.org" 456 456])])

(emacsql db [:insert :into files_tags_link
             :values ([nil 1 1])])

(emacsql db [:insert :into files_tags_link
             :values ([nil 1 2])])

(defun files-with-tag-ids (db given-tags)
  (message "given-tags: %s" given-tags)
    (setq query
    [:SELECT [f:id f:file (funcall GROUP_CONCAT ft:tag)] :as tags
    :FROM files f
    :LEFT :JOIN files_tags_link :as ft :ON (= f:id ft:file)
    :LEFT :JOIN tags t :ON (= t:id ft:tag) :where (in t:id $v1)
    :GROUP :BY [f:id f:file]
    :HAVING (and (>= (funcall COUNT ft:tag) (funcall COUNT t:id )) (= (funcall COUNT t:id) $s2))])

  (emacsql db query (vconcat given-tags) (length given-tags))
)

(defun files-with-tag-names (db given-tags)
    (setq query
    [:SELECT [id]
     :FROM tags
     :where (in name $v1)])

  (files-with-tag-ids db
    (emacsql db query (vconcat given-tags)))
)

(defun flatten (list-of-lists)
  (apply #'append list-of-lists))

(defun files-with-tag-names (db given-tags)
    (setq query
    [:SELECT [id]
     :FROM tags
     :where (in name $v1)])

  (files-with-tag-ids db
    (flatten (emacsql db query (vconcat given-tags))))
)

(defun org-wander/get-file-id (db file)
"return nil if no matching record from db."
    (setq query
    [:SELECT [id]
     :FROM files
     :where (= file $s1)])

    (car (flatten (emacsql db query file))))

(defun org-wander/tag-ids-from-names (db given-tags)
    (setq query
    [:SELECT [id]
     :FROM tags
     :where (in name $v1)])

   (flatten (emacsql db query (vconcat given-tags)))
)

(defun org-wander/add-tag (db tag)
  (emacsql db [:insert :into tags
                       :values ([nil $s1])] tag)
)

(defun org-wander/add-file (db file)
  (unless (org-wander/get-file-id db file)
    (setq query
        [:insert :into files
        :values ([nil $s1 123 456])])
    (emacsql db query file)
  )
)
