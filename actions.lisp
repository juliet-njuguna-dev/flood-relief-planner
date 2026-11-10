
;;; ==========================================
;;; FLOOD RELIEF PLANNER
;;; State Representation and Action Modelling
;;; ==========================================

;;; Initial state of the flood-relief environment

(defparameter *initial-state*
  '((at truck depot)
    (at food depot)
    (at medicine depot)
    (road depot village-a)
    (road village-a village-b)
    (capacity truck 2)
    (needs village-a food)
    (needs village-b medicine)))


;;; Display the current state

(defun show-state (state)
  (format t "~%Current State:~%")
  (dolist (fact state)
    (format t "~a~%" fact)))


;;; Count supplies currently loaded onto the truck

(defun loaded-count (state)
  (count-if
   (lambda (fact)
     (eq (first fact) 'loaded))
   state))


;;; Find a road connecting two locations

(defun find-road (from to state)
  (find-if
   (lambda (fact)
     (and
      (eq (first fact) 'road)
      (equal (second fact) from)
      (equal (third fact) to)))
   state))


;;; Retrieve the cost of travelling along a road

;;; Older road facts without a distance have a default cost of 1.

(defun road-cost (from to state)
  (let ((road (find-road from to state)))
    (if (and road
             (numberp (fourth road)))
        (fourth road)
        1)))


;;; Calculate the cost of performing an action

;;; Driving uses the distance of the road.
;;; Loading and unloading each have a cost of 1.

(defun action-cost (action state)
  (if (eq (first action) 'drive)
      (road-cost (second action)
                 (third action)
                 state)
      1))


;;; Check whether an action can be performed

(defun applicable-p (action state)
  (cond

    ;; LOAD preconditions
    ((eq (first action) 'load)
     (let ((supply (second action))
           (capacity (third (assoc 'capacity state))))
       (if (and
            (member (list 'at supply 'depot) state :test #'equal)
            (member '(at truck depot) state :test #'equal)
            capacity
            (< (loaded-count state) capacity))
           t
           nil)))

    ;; DRIVE preconditions
    ((eq (first action) 'drive)
     (let ((from (second action))
           (to (third action)))
       (if (and
            (member (list 'at 'truck from) state :test #'equal)
            (find-road from to state))
           t
           nil)))

    ;; UNLOAD preconditions
    ((eq (first action) 'unload)
     (let ((supply (second action))
           (village (third action)))
       (if (and
            (member (list 'at 'truck village) state :test #'equal)
            (member (list 'loaded supply) state :test #'equal)
            (member (list 'needs village supply) state :test #'equal))
           t
           nil)))

    ;; Unknown actions are not allowed
    (t nil)))


;;; Apply an action and produce a new state

(defun apply-action (action state)
  (cond

    ;; LOAD action
    ((and (eq (first action) 'load)
          (applicable-p action state))
     (let ((supply (second action)))
       (cons
        (list 'loaded supply)
        (remove (list 'at supply 'depot)
                state
                :test #'equal))))

    ;; DRIVE action
    ((and (eq (first action) 'drive)
          (applicable-p action state))
     (let ((from (second action))
           (to (third action)))
       (cons
        (list 'at 'truck to)
        (remove (list 'at 'truck from)
                state
                :test #'equal))))

    ;; UNLOAD action
    ((and (eq (first action) 'unload)
          (applicable-p action state))
     (let ((supply (second action))
           (village (third action)))
       (cons
        (list 'delivered supply village)
        (remove (list 'loaded supply)
                (remove (list 'needs village supply)
                        state
                        :test #'equal)
                :test #'equal))))

    ;; Invalid action
    (t
     (format t "~%Action cannot be performed: ~a~%" action)
     nil)))
