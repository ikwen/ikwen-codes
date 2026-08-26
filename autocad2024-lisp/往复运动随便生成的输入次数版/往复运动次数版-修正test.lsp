(defun c:CreateLaserPath (/ ssRects ssLines rectList lineObj i rect rectPoints rectMinX rectMaxX rectMinY rectMaxY inRect lastInRect rectStartParam rectEndParam beyondDistance oscillationCount step newPoints totalLength param currentPoint p)
    (vl-load-com)
    
    (setq oscillationCount (getint "\n请输入往返次数: "))
    (if (not oscillationCount) (setq oscillationCount 1))
    
    (princ "\n选择所有长方形框: ")
    (setq ssRects (ssget '((0 . "LWPOLYLINE"))))
    
    (princ "\n选择需要添加往复运动的线条: ")
    (setq ssLines (ssget '((0 . "LWPOLYLINE"))))
    
    (if (and ssRects ssLines)
        (progn
            (setq rectList '())
            (setq i 0)
            (repeat (sslength ssRects)
                (setq rect (ssname ssRects i))
                (setq rectPoints (getPolylinePoints rect))
                (setq rectMinX (apply 'min (mapcar 'car rectPoints)))
                (setq rectMaxX (apply 'max (mapcar 'car rectPoints)))
                (setq rectMinY (apply 'min (mapcar 'cadr rectPoints)))
                (setq rectMaxY (apply 'max (mapcar 'cadr rectPoints)))
                (setq rectList (cons (list rectMinX rectMaxX rectMinY rectMaxY) rectList))
                (setq i (1+ i))
            )
            
            (setq i 0)
            (repeat (sslength ssLines)
                (setq line (ssname ssLines i))
                (setq lineObj (vlax-ename->vla-object line))
                (setq newPoints '())
                (setq beyondDistance 5.0) 
                (setq step 1.0) ; 采样步进（毫米）
                
                (setq totalLength (vlax-get lineObj 'Length))
                (setq param 0.0)
                (setq lastInRect nil)

                (while (<= param totalLength)
                    (setq currentPoint (vlax-curve-getPointAtDist lineObj param))
                    (setq inRect (isPointInRects currentPoint rectList))

                    ;; 1. 记录进入/离开状态
                    (if (and inRect (not lastInRect)) (setq rectStartParam param))
                    
                    ;; 2. 只有在矩形内才记录点
                    (if inRect (setq newPoints (addPointUnique currentPoint newPoints)))

                    ;; 3. 处理往复运动（高密度采样区）
                    (if (and (not inRect) lastInRect)
                        (progn
                            (setq rectEndParam (- param step))
                            (repeat oscillationCount
                                ;; 向前超出
                                (setq p rectEndParam)
                                (while (<= p (min totalLength (+ rectEndParam beyondDistance)))
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p))
                                    (if (isPointInRects testPt rectList) (setq newPoints (addPointUnique testPt newPoints)))
                                    (setq p (+ p step)))
                                ;; 往回退
                                (setq p (min totalLength (+ rectEndParam beyondDistance)))
                                (while (>= p (max 0.0 (- rectStartParam beyondDistance)))
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p))
                                    (if (isPointInRects testPt rectList) (setq newPoints (addPointUnique testPt newPoints)))
                                    (setq p (- p step)))
                                ;; 回到终点
                                (setq p (max 0.0 (- rectStartParam beyondDistance)))
                                (while (<= p rectEndParam)
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p))
                                    (if (isPointInRects testPt rectList) (setq newPoints (addPointUnique testPt newPoints)))
                                    (setq p (+ p step)))
                            )
                        )
                    )
                    
                    (setq lastInRect inRect)
                    
                    ;; --- 智能步进优化 ---
                    ;; 如果当前点和下一个“关键点”（转角）之间是直线，直接跳过去
                    (setq nextParam (min totalLength (+ param step)))
                    (setq param nextParam)
                )
                
                ;; 4. 关键：对生成后的点进行直线去重过滤
                (createRedPolylineFromPoints (optimizePoints (reverse newPoints)))
                (setq i (1+ i))
            )
            (princ "\n优化完成！线条已极简化，不再卡顿。")
        )
    )
    (princ)
)

;; 优化点集：删除共线的中间点
(defun optimizePoints (pts / a b c result)
  (if (< (length pts) 3)
    pts
    (progn
      (setq result (list (car pts)))
      (setq i 1)
      (while (< i (- (length pts) 1))
        (setq a (nth (- i 1) pts)
              b (nth i pts)
              c (nth (+ i 1) pts))
        ;; 如果 a-b-c 不共线，则保留 b 点
        (if (not (isCollinear a b c 0.01))
            (setq result (cons b result))
        )
        (setq i (1+ i))
      )
      (setq result (cons (last pts) result))
      (reverse result)
    )
  )
)

;; 检查三点是否共线
(defun isCollinear (p1 p2 p3 tol / area)
  (setq area (abs (+ (* (car p1) (- (cadr p2) (cadr p3)))
                     (* (car p2) (- (cadr p3) (cadr p1)))
                     (* (car p3) (- (cadr p1) (cadr p2))))))
  (< area tol)
)

;; 确保不添加重复的点
(defun addPointUnique (pt pts / )
  (if (or (not pts) (> (distance pt (car pts)) 0.001))
      (cons pt pts)
      pts
  )
)

(defun isPointInRects (pt rList / found)
  (setq found nil)
  (if pt
    (foreach r rList
      (if (and (>= (car pt) (car r)) (<= (car pt) (cadr r))
               (>= (cadr pt) (caddr r)) (<= (cadr pt) (cadddr r)))
          (setq found T)
      )
    )
  )
  found
)

(defun getPolylinePoints (ent / i pts obj)
  (setq i 0 obj (vlax-ename->vla-object ent))
  (setq pts '())
  (while (<= i (vlax-curve-getEndParam obj))
    (setq pts (cons (vlax-curve-getPointAtParam obj i) pts))
    (setq i (1+ i))
  )
  (reverse pts)
)

(defun createRedPolylineFromPoints (points)
    (if (> (length points) 1)
        (entmakex
            (append
                (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") '(62 . 1) '(100 . "AcDbPolyline")
                      (cons 90 (length points)) '(70 . 0))
                (mapcar '(lambda (pt) (cons 10 (list (car pt) (cadr pt)))) points)
            )
        )
    )
)
