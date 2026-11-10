
;;; ==========================================
;;; FLOOD RELIEF PLANNER
;;; MAIN PROGRAM
;;; ==========================================


;;; Load all project modules

(load "actions.lisp")
(load "planner.lisp")
(load "scenarios.lisp")
(load "tests.lisp")


;;; Display the result of one search algorithm


(defun display-result (algorithm plan expanded generated runtime state)

  (format t "~%~a RESULTS~%" algorithm)
  (format t "------------------------------~%")

  (if plan
      (progn
        (format t "Plan: ~a~%" plan)
        (format t "Plan length: ~a actions~%" (length plan))
        (format t "Total plan cost: ~a~%"
                (plan-cost state plan))
        (format t "Plan verified: ~a~%"
                (verify-plan state plan)))
      (format t "No solution found.~%"))

  (format t "Nodes expanded: ~a~%" expanded)
  (format t "Nodes generated: ~a~%" generated)
  (format t "Average runtime: ~,9f seconds~%" runtime))



;;; Run BFS and A* on one scenario

(defun run-scenario (scenario-name state)

  (format t "~%========================================~%")
  (format t "SCENARIO: ~a~%" scenario-name)
  (format t "========================================~%")

  ;; Run BFS and save its results
  (let* ((bfs-plan (bfs state))
         (bfs-expanded *bfs-expanded*)
         (bfs-generated *bfs-generated*)

         ;; Run A* and save its results
         (astar-plan (astar state))
         (astar-expanded *astar-expanded*)
         (astar-generated *astar-generated*)

         ;; Measure average runtime over 1000 searches
         (bfs-time
          (/ (measure-time
              (lambda ()
                (dotimes (i 1000)
                  (bfs state))))
             1000))

         (astar-time
          (/ (measure-time
              (lambda ()
                (dotimes (i 1000)
                  (astar state))))
             1000)))

    ;; Display BFS results
    (display-result
     "BFS"
     bfs-plan
     bfs-expanded
     bfs-generated
     bfs-time
     state)

    ;; Display A* results
    (display-result
     "A*"
     astar-plan
     astar-expanded
     astar-generated
     astar-time
     state)))


;;; Run all five scenarios


(defun run-all-scenarios ()

  (run-scenario "S1 - Basic Delivery" *scenario-1*)

  (run-scenario "S2 - Truck Capacity" *scenario-2*)

  (run-scenario "S3 - Blocked Road Detour" *scenario-3*)

  (run-scenario "S4 - Larger Delivery Network" *scenario-4*)

  (run-scenario "S5 - Unreachable Destination" *scenario-5*)

  (run-scenario "S6 - Weighted Road Distances" *scenario-6*)

  (format t "~%========================================~%")
  (format t "ALL SCENARIOS COMPLETED~%")
  (format t "========================================~%"))



;;; Main project execution

(defun run-project ()

  (format t "~%FLOOD RELIEF PLANNER~%")
  (format t "Running automated tests...~%")

  ;; Run automated tests first
  (run-tests)

  ;; Run all scenarios
  (run-all-scenarios)

  (format t "~%PROJECT EXECUTION COMPLETE.~%")

  t)
