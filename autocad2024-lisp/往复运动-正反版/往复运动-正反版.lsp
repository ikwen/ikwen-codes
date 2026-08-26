(defun c:CreateLaserPath (/ ssRects ssLines rectList lineObj i rect rectPoints rectMinX rectMaxX rectMinY rectMaxY inRect lastInRect oscillationCount step newPoints totalLength param currentPoint dirChoice segmentPoints)
    (vl-load-com)
    
    (setq oscillationCount (getint "\n请输入往返次数: "))
    (if (not oscillationCount) (setq oscillationCount 1))

    (initget "Forward Backward")
    (setq dirChoice (getkword "\n起始方向 [正向(F)/反向(B)] <正向>: "))
    (if (not dirChoice) (setq dirChoice "Forward"))
    
    (princ "\n选择方框(确定往复区域): ")
    (setq ssRects (ssget '((0 . "LWPOLYLINE,POLYLINE,CIRCLE"))))
    
    (princ "\n选择绿色线条: ")
    (setq ssLines (ssget '((0 . "LWPOLYLINE,LINE"))))
    
    (if (and ssRects ssLines)
        (progn
            ;; 1. 提取所有区域(支持矩形和圆)
            (setq rectList '())
            (setq i 0)
            (repeat (sslength ssRects)
                (setq rect (ssname ssRects i))
                (setq rectList (cons rect rectList))
                (setq i (1+ i))
            )
            
            (setq i 0)
            (repeat (sslength ssLines)
                (setq line (ssname ssLines i))
                (setq lineObj (vlax-ename->vla-object line))
                (setq totalLength (vlax-get lineObj 'Length))
                (setq newPoints '())
                (setq step 0.5) ;; 谢思瑶，调小步长让曲线更平滑
                
                ;; 根据方向设定初始参数
                (if (= dirChoice "Forward")
                    (setq param 0.0)
                    (setq param totalLength)
                )

                (setq segmentPoints '())
                
                ;; 2. 沿线扫描（核心逻辑：不再因出框而停止）
                (setq count 0)
                (while (if (= dirChoice "Forward") (<= param totalLength) (>= param 0.0))
                    (setq currentPoint (vlax-curve-getPointAtDist lineObj param))
                    
                    ;; 检查当前点是否在任何一个方框/圆内
                    (setq inArea nil)
                    (foreach r rectList
                        (if (isPointInsideEntity currentPoint r) (setq inArea T))
                    )

                    (if inArea
                        ;; 如果在区域内，收集点准备做往复
                        (setq segmentPoints (cons currentPoint segmentPoints))
                        (progn
                            ;; 如果不在区域内，且之前有收集到往复点，先处理往复
                            (if (> (length segmentPoints) 1)
                                (progn
                                    (setq seg (reverse segmentPoints))
                                    (setq newPoints (append newPoints seg))
                                    (repeat oscillationCount
                                        (setq newPoints (append newPoints (reverse seg) seg))
                                    )
                                    (setq segmentPoints '())
                                )
                            )
                            ;; 普通路段，直接加点
                            (setq newPoints (append newPoints (list currentPoint)))
                        )
                    )

                    (if (= dirChoice "Forward")
                        (setq param (+ param step))
                        (setq param (- param step))
                    )
                )
                
                ;; 处理线末尾可能残留的往复段
                (if (> (length segmentPoints) 1)
                    (progn
                        (setq seg (reverse segmentPoints))
                        (setq newPoints (append newPoints seg))
                        (repeat oscillationCount
                            (setq newPoints (append newPoints (reverse seg) seg))
                        )
                    )
                )

                (createRedPolylineFromPoints newPoints)
                (setq i (1+ i))
            )
            (princ "\n处理完成！谢思瑶，红线现在会跟着绿线走完全程了。")
        )
    )
    (princ)
)

;; 判定点是否在实体(矩形或圆)内部
(defun isPointInsideEntity (pt ent / minp maxp)
    (vla-getboundingbox (vlax-ename->vla-object ent) 'minp 'maxp)
    (setq minp (vlax-safearray->list minp)
          maxp (vlax-safearray->list maxp))
    (and (>= (car pt) (car minp)) (<= (car pt) (car maxp))
         (>= (cadr pt) (cadr minp)) (<= (cadr pt) (cadr maxp)))
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
