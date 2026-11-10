
;;; ==========================================
;;; FLOOD RELIEF PLANNER
;;; AUTOMATED TESTS
;;; ==========================================

(defun run-tests ()

  (format t "~%========== RUNNING TESTS ==========~%")

  ;; Test 1: Loading available food
  (format t "~%Test 1: Loading available food... ")
  (assert (applicable-p '(load food) *initial-state*))
  (format t "PASSED~%")

  ;; Test 2: Rejecting unavailable supplies
  (format t "Test 2: Rejecting unavailable supplies... ")
  (assert (not (applicable-p '(load water) *initial-state*)))
  (format t "PASSED~%")

  ;; Test 3: Enforcing truck capacity
  (format t "Test 3: Enforcing truck capacity... ")
  (let* ((state (apply-action '(load food) *initial-state*))
         (state (apply-action '(load medicine) state)))
    (assert (= (loaded-count state) 2))
    (assert (not (applicable-p '(load food) state))))
  (format t "PASSED~%")

  ;; Test 4: Rejecting invalid roads
  (format t "Test 4: Rejecting invalid roads... ")
  (assert (not (applicable-p '(drive depot village-b)
                             *initial-state*)))
  (format t "PASSED~%")

  ;; Test 5: BFS finds a valid plan
  (format t "Test 5: BFS finds a valid plan... ")
  (assert (verify-plan *scenario-1*
                       (bfs *scenario-1*)))
  (format t "PASSED~%")

  ;; Test 6: A* finds a valid plan
  (format t "Test 6: A* finds a valid plan... ")
  (assert (verify-plan *scenario-1*
                       (astar *scenario-1*)))
  (format t "PASSED~%")

  ;; Test 7: BFS and A* return equal plan lengths
  (format t "Test 7: Comparing BFS and A* plan lengths... ")
  (assert (= (length (bfs *scenario-1*))
             (length (astar *scenario-1*))))
  (format t "PASSED~%")

  ;; Test 8: Capacity scenario
  (format t "Test 8: Testing multiple truckloads... ")
  (assert (verify-plan *scenario-2*
                       (bfs *scenario-2*)))
  (format t "PASSED~%")

  ;; Test 9: Blocked-road detour
  (format t "Test 9: Testing alternative route... ")
  (assert (verify-plan *scenario-3*
                       (bfs *scenario-3*)))
  (format t "PASSED~%")

  ;; Test 10: Larger delivery scenario
  (format t "Test 10: Testing larger scenario... ")
  (assert (verify-plan *scenario-4*
                       (bfs *scenario-4*)))
  (format t "PASSED~%")

  ;; Test 11: Unreachable destination
  (format t "Test 11: Testing unreachable destination... ")
  (assert (null (bfs *scenario-5*)))
  (assert (null (astar *scenario-5*)))
  (format t "PASSED~%")

  ;; Test 12: Old roads retain their default cost
  (format t "Test 12: Testing default road cost... ")
  (assert (= (road-cost 'depot 'village-a *scenario-1*) 1))
  (format t "PASSED~%")

  ;; Test 13: Both algorithms find valid weighted-road plans
  (format t "Test 13: Testing weighted-road plans... ")
  (assert (verify-plan *scenario-6*
                       (bfs *scenario-6*)))
  (assert (verify-plan *scenario-6*
                       (astar *scenario-6*)))
  (format t "PASSED~%")

  ;; Test 14: A* finds the cheaper weighted route
  (format t "Test 14: Comparing weighted route costs... ")
  (let ((bfs-plan (bfs *scenario-6*))
        (astar-plan (astar *scenario-6*)))
    (assert (member '(drive depot village-b)
                    bfs-plan
                    :test #'equal))
    (assert (not (member '(drive depot village-b)
                         astar-plan
                         :test #'equal)))
    (assert (< (plan-cost *scenario-6* astar-plan)
               (plan-cost *scenario-6* bfs-plan))))
  (format t "PASSED~%")

  (format t "~%========== ALL TESTS PASSED ==========~%")

  t)
