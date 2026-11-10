;;; ==========================================
;;; FLOOD RELIEF PLANNER - WEB SERVER
;;; ==========================================
;;; Start with:  sbcl --load server.lisp --eval "(start-server)"
;;; Then open:   http://localhost:8080/

;;; Load Quicklisp if it is installed in the user's home folder
;;; (works on any computer, not only one user's account).
(let ((setup (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file setup)
    (load setup)))

;;; Load Hunchentoot (through Quicklisp if available, otherwise ASDF).
(if (find-package "QL")
    (funcall (intern "QUICKLOAD" "QL") :hunchentoot)
    (asdf:load-system :hunchentoot))

;;; Folder that holds this file, so the project works from any directory.
(defparameter *base-dir*
  (make-pathname :name nil :type nil
                 :defaults (or *load-truename* *default-pathname-defaults*)))

;;; Load the existing AI planning system
(load (merge-pathnames "actions.lisp" *base-dir*))
(load (merge-pathnames "planner.lisp" *base-dir*))
(load (merge-pathnames "scenarios.lisp" *base-dir*))

;;; Find a web file in public/ (or next to this file if there is no public/).
(defun web-file (name)
  (let ((in-public (merge-pathnames (concatenate 'string "public/" name) *base-dir*)))
    (if (probe-file in-public)
        in-public
        (merge-pathnames name *base-dir*))))

;;; ==========================================
;;; CREATE SERVER
;;; ==========================================

(defparameter *web-server*
  (make-instance 'hunchentoot:easy-acceptor
                 :port 8080))

;;; ==========================================
;;; JSON STRING HELPER
;;; ==========================================

(defun json-quote (value)
  (with-output-to-string (stream)
    (write-char #\" stream)
    (loop for character across value do
      (case character
        (#\" (write-string "\\\"" stream))
        (#\\ (write-string "\\\\" stream))
        (#\Newline (write-string "\\n" stream))
        (#\Return (write-string "\\r" stream))
        (otherwise (write-char character stream))))
    (write-char #\" stream)))

;;; ==========================================
;;; SCENARIO SELECTION
;;; ==========================================

(defun select-scenario (number)
  (case number
    (1 *scenario-1*)
    (2 *scenario-2*)
    (3 *scenario-3*)
    (4 *scenario-4*)
    (5 *scenario-5*)
    (6 *scenario-6*)
    (otherwise nil)))

;;; ==========================================
;;; RUN ONE ALGORITHM
;;; ==========================================

(defparameter *timing-runs* 200)

(defun run-algorithm (initial-state algorithm)
  (cond
    ((equal algorithm "bfs") (bfs initial-state))
    ((equal algorithm "astar") (astar initial-state))
    (t nil)))

(defun run-one-algorithm (initial-state algorithm)
  ;; Run once for the plan and the node counts.
  (let* ((plan (run-algorithm initial-state algorithm))
         (expanded
           (if (equal algorithm "bfs")
               *bfs-expanded*
               *astar-expanded*))
         (generated
           (if (equal algorithm "bfs")
               *bfs-generated*
               *astar-generated*))
         ;; One run is too fast for the computer clock to measure, so the
         ;; time is the average over many runs (in milliseconds).
         (runtime
           (* 1000
              (/ (measure-time
                  (lambda ()
                    (dotimes (i *timing-runs*)
                      (run-algorithm initial-state algorithm))))
                 *timing-runs*)))
         (verified
           (and plan (verify-plan initial-state plan)))
         (total-cost
           (if plan
               (plan-cost initial-state plan)
               0)))

    (format nil
      "{\"algorithm\":~a,\"found\":~a,\"plan\":~a,\"plan_length\":~a,\"total_cost\":~a,\"expanded\":~a,\"generated\":~a,\"time_ms\":~,6f,\"verified\":~a}"
      (json-quote algorithm)
      (if plan "true" "false")
      (if plan
          (format nil "[~{~a~^,~}]"
            (mapcar
              (lambda (action)
                (json-quote (prin1-to-string action)))
              plan))
          "[]")
      (if plan (length plan) 0)
      total-cost
      expanded
      generated
      (float runtime)
      (if verified "true" "false"))))

;;; ==========================================
;;; WEB PAGES (served from public/)
;;; ==========================================

(hunchentoot:define-easy-handler (home :uri "/") ()
  (hunchentoot:handle-static-file (web-file "index.html") "text/html"))

(hunchentoot:define-easy-handler (css-file :uri "/style.css") ()
  (hunchentoot:handle-static-file (web-file "style.css") "text/css"))

(hunchentoot:define-easy-handler (js-file :uri "/script.js") ()
  (hunchentoot:handle-static-file (web-file "script.js") "application/javascript"))

;;; ==========================================
;;; PLANNER API
;;; ==========================================

(hunchentoot:define-easy-handler (run-planner :uri "/run")
    (scenario algorithm)

  (setf (hunchentoot:content-type*) "application/json")

  (let* ((scenario-number
           (ignore-errors (parse-integer scenario)))
         (initial-state
           (and scenario-number
                (select-scenario scenario-number))))

    (cond
      ((null initial-state)
       "{\"error\":\"Invalid scenario selected.\"}")

      ((equal algorithm "both")
       (format nil
         "{\"results\":[~a,~a]}"
         (run-one-algorithm initial-state "bfs")
         (run-one-algorithm initial-state "astar")))

      ((member algorithm '("bfs" "astar") :test #'equal)
       (format nil
         "{\"results\":[~a]}"
         (run-one-algorithm initial-state algorithm)))

      (t
       "{\"error\":\"Invalid algorithm selected.\"}"))))

;;; ==========================================
;;; START AND STOP SERVER
;;; ==========================================

(defun start-server ()
  (hunchentoot:start *web-server*)
  (format t "~%Server running at http://localhost:8080/~%"))

(defun stop-server ()
  (hunchentoot:stop *web-server*)
  (format t "~%Server stopped.~%"))
