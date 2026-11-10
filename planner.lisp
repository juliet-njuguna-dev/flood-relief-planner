
;;; ==========================================
;;; FLOOD RELIEF PLANNER
;;; Planning Foundations
;;; ==========================================

;;; ==========================================
;;; BFS PERFORMANCE COUNTERS
;;; ==========================================

(defparameter *bfs-expanded* 0)
(defparameter *bfs-generated* 0)


;;; ==========================================
;;; A* PERFORMANCE COUNTERS
;;; ==========================================

(defparameter *astar-expanded* 0)
(defparameter *astar-generated* 0)


;;; Check whether all village requirements are satisfied

(defun goal-p (state)
  (notany
   (lambda (fact)
     (eq (first fact) 'needs))
   state))


;;; Create a consistent representation of a state.
;;; This prevents identical states with different fact
;;; ordering from being treated as different states.

(defun state-key (state)
  (sort
   (mapcar #'prin1-to-string state)
   #'string<))


;;; Generate all possible actions from the current state


(defun generate-actions (state)
  (let ((actions '()))

    ;; Possible loading actions
    (dolist (fact state)
      (when (and (eq (first fact) 'needs)
                 (member (list 'at (third fact) 'depot)
                         state
                         :test #'equal))
        (push (list 'load (third fact)) actions)))

    ;; Possible driving actions
    (dolist (fact state)
      (when (eq (first fact) 'road)
        (let ((from (second fact))
              (to (third fact)))
          (when (member (list 'at 'truck from)
                        state
                        :test #'equal)
            (push (list 'drive from to) actions)))))

    ;; Possible unloading actions
    (dolist (fact state)
      (when (eq (first fact) 'needs)
        (let ((village (second fact))
              (supply (third fact)))
          (when (and
                 (member (list 'at 'truck village)
                         state
                         :test #'equal)
                 (member (list 'loaded supply)
                         state
                         :test #'equal))
            (push (list 'unload supply village) actions)))))

    (nreverse actions)))



;;; ==========================================
;;; BREADTH-FIRST SEARCH (BFS)
;;; ==========================================

(defun bfs (initial-state)
  (let ((queue (list (list initial-state nil)))
        (visited (make-hash-table :test #'equal)))

    ;; Reset performance counters
    (setf *bfs-expanded* 0)
    (setf *bfs-generated* 1)

    ;; Mark initial state as visited
    (setf (gethash (state-key initial-state) visited) t)

    ;; Explore states while queue is not empty
    (loop while queue do
      (let* ((node (pop queue))
             (current-state (first node))
             (current-plan (second node)))

        ;; Count expanded states
        (incf *bfs-expanded*)

        ;; Check whether goal has been reached
        (when (goal-p current-state)
          (return-from bfs (reverse current-plan)))

        ;; Generate possible actions
        (dolist (action (generate-actions current-state))
          (when (applicable-p action current-state)
            (let* ((new-state (apply-action action current-state))
                   (key (state-key new-state)))

              ;; Avoid revisiting states
              (unless (gethash key visited)
                (setf (gethash key visited) t)

                ;; Count newly generated states
                (incf *bfs-generated*)

                ;; Add new state to queue
                (setf queue
                      (append queue
                              (list
                               (list new-state
                                     (cons action current-plan)))))))))))

    ;; No solution found
    nil))


;;; ==========================================
;;; A* SEARCH
;;; ==========================================

;;; Count outstanding delivery requirements.
;;; This is an admissible lower-bound heuristic because
;;; each outstanding delivery requires at least one
;;; unloading action, which costs 1.

(defun heuristic (state)
  (count-if
   (lambda (fact)
     (eq (first fact) 'needs))
   state))


;;; A* search algorithm

(defun astar (initial-state)
  (let ((open-list
         (list (list initial-state nil 0
                     (heuristic initial-state))))
        (best-cost (make-hash-table :test #'equal)))

    ;; Reset performance counters
    (setf *astar-expanded* 0)
    (setf *astar-generated* 1)

    ;; Initial state has a cost of zero
    (setf (gethash (state-key initial-state) best-cost) 0)

    ;; Continue until a solution is found or the list is empty
    (loop while open-list do

      ;; Select the state with the lowest f(n)
      (setf open-list
            (stable-sort open-list #'< :key #'fourth))

      (let* ((node (pop open-list))
             (current-state (first node))
             (current-plan (second node))
             (current-cost (third node))
             (key (state-key current-state)))

        ;; Ignore outdated search entries
        (when (= current-cost (gethash key best-cost))

          ;; Count expanded states
          (incf *astar-expanded*)

          ;; Check for a completed delivery
          (when (goal-p current-state)
            (return-from astar (reverse current-plan)))

          ;; Explore available actions
          (dolist (action (generate-actions current-state))

            (when (applicable-p action current-state)

              (let* ((new-state
                      (apply-action action current-state))

                     ;; Use the actual cost of the action
                     (new-cost
                      (+ current-cost
                         (action-cost action current-state)))

                     (new-key (state-key new-state))
                     (old-cost (gethash new-key best-cost)))

                ;; Check whether this is a cheaper route
                (when (or (null old-cost)
                          (< new-cost old-cost))

                  (setf (gethash new-key best-cost) new-cost)

                  ;; Count newly generated states
                  (incf *astar-generated*)

                  (let ((estimated-cost
                         (+ new-cost (heuristic new-state))))

                    (push
                     (list new-state
                           (cons action current-plan)
                           new-cost
                           estimated-cost)
                     open-list)))))))))

    ;; No solution found
    nil))


;;; ==========================================
;;; PLAN VERIFICATION
;;; ==========================================

(defun verify-plan (initial-state plan)
  (let ((current-state initial-state))

    ;; Execute each action in the plan
    (dolist (action plan)

      ;; Check whether the action is valid
      (unless (applicable-p action current-state)
        (return-from verify-plan nil))

      ;; Apply the action
      (setf current-state
            (apply-action action current-state)))

    ;; Confirm that the final state satisfies the goal
    (goal-p current-state)))


;;; ==========================================
;;; CALCULATE TOTAL PLAN COST
;;; ==========================================

(defun plan-cost (initial-state plan)
  (let ((current-state initial-state)
        (total-cost 0))

    (dolist (action plan)
      (incf total-cost
            (action-cost action current-state))

      (setf current-state
            (apply-action action current-state)))

    total-cost))


;;; ==========================================
;;; EXECUTION TIME MEASUREMENT
;;; ==========================================

(defun measure-time (function)
  (let ((start-time (get-internal-real-time)))
    (funcall function)
    (/ (- (get-internal-real-time) start-time)
       internal-time-units-per-second)))
