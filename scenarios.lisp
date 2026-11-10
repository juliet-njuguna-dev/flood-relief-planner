
;;; ==========================================
;;; FLOOD RELIEF PLANNER
;;; TEST SCENARIOS
;;; ==========================================


;;; S1: Basic delivery scenario
;;; Two villages, two supplies, capacity two

(defparameter *scenario-1* *initial-state*)


;;; S2: Truck capacity scenario
;;; Three deliveries require more than one truckload.

(defparameter *scenario-2*
  '((at truck depot)
    (at food depot)
    (at medicine depot)
    (at water depot)
    (road depot village-a)
    (road village-a depot)
    (road depot village-b)
    (road village-b depot)
    (road depot village-c)
    (capacity truck 2)
    (needs village-a food)
    (needs village-b medicine)
    (needs village-c water)))


;;; S3: Blocked road scenario
;;; The truck must travel through village-a.

(defparameter *scenario-3*
  '((at truck depot)
    (at food depot)
    (road depot village-a)
    (road village-a village-b)
    (capacity truck 2)
    (needs village-b food)))


;;; S4: Larger delivery scenario
;;; Three villages connected through a road network.

(defparameter *scenario-4*
  '((at truck depot)
    (at food depot)
    (at medicine depot)
    (at water depot)
    (road depot village-a)
    (road village-a depot)
    (road village-a village-b)
    (road village-b village-a)
    (road village-b village-c)
    (road village-c village-b)
    (capacity truck 2)
    (needs village-a food)
    (needs village-b medicine)
    (needs village-c water)))


;;; S5: Unreachable village scenario
;;; Village-z has no connecting road.

(defparameter *scenario-5*
  '((at truck depot)
    (at food depot)
    (road depot village-a)
    (capacity truck 2)
    (needs village-z food)))


;;; S6: Weighted roads - shortest route is not cheapest route
(defparameter *scenario-6*
  '((at truck depot)
    (at food depot)

    ;; Direct road is short but expensive
    (road depot village-b 10)

    ;; Alternative route is longer but cheaper
    (road depot village-a 1)
    (road village-a village-c 1)
    (road village-c village-b 1)

    (capacity truck 2)
    (needs village-b food)))