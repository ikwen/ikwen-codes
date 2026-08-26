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
                (setq step 1.0)           
                
                (setq totalLength (vlax-get lineObj 'Length))
                (setq param 0.0)
                (setq lastInRect nil)

                (while (<= param totalLength)
                    (setq currentPoint (vlax-curve-getPointAtDist lineObj param))
                    (setq inRect nil)
                    ;; 检查当前点是否在矩形内
                    (foreach r rectList
                        (if (and currentPoint
                                 (>= (car currentPoint) (car r)) (<= (car currentPoint) (cadr r))
                                 (>= (cadr currentPoint) (caddr r)) (<= (cadr currentPoint) (cadddr r)))
                            (setq inRect T)
                        )
                    )

                    (if (and inRect (not lastInRect)) (setq rectStartParam param))
                    
                    ;; 关键修正：只有在矩形内的路径才保留并生成往复
                    (if inRect
                        (setq newPoints (cons currentPoint newPoints))
                    )

                    (if (and (not inRect) lastInRect)
                        (progn
                            (setq rectEndParam (- param step))
                            (repeat oscillationCount
                                ;; 往复点也必须进行矩形内检测
                                (setq p rectEndParam)
                                (while (<= p (min totalLength (+ rectEndParam beyondDistance)))
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p))
                                    (if (isPointInRects testPt rectList) (setq newPoints (cons testPt newPoints)))
                                    (setq p (+ p step))
                                )
                                (setq p (min totalLength (+ rectEndParam beyondDistance)))
                                (while (>= p (max 0.0 (- rectStartParam beyondDistance)))
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p) )
                                    (if (isPointInRects testPt rectList) (setq newPoints (cons testPt newPoints)))
                                    (setq p (- p step))
                                )
                                (setq p (max 0.0 (- rectStartParam beyondDistance)))
                                (while (<= p rectEndParam)
                                    (setq testPt (vlax-curve-getPointAtDist lineObj p))
                                    (if (isPointInRects testPt rectList) (setq newPoints (cons testPt newPoints)))
                                    (setq p (+ p step))
                                )
                            )
                        )
                    )
                    
                    (setq lastInRect inRect)
                    (setq param (+ param step))
                )
                (createRedPolylineFromPoints (reverse newPoints))
                (setq i (1+ i))
            )
            (princ "\n完美！红线已被锁定在方框内。")
        )
    )
    (princ)
)

;; 辅助函数：检查点是否在矩形列表中
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
