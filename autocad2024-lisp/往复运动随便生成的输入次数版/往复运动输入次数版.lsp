(defun c:CreateLaserPath (/ ssRects ssLines rectList lineObj linePoints newPoints i rect rectPoints rectMinX rectMaxX rectMinY rectMaxY
                         inRect lastInRect rectStartParam rectEndParam beyondDistance oscillationCount step)
    ; 加载VL函数
    (vl-load-com)
    
    ; 获取用户输入的往返次数
    (setq oscillationCount (getint "\n请输入往返次数: "))
    (if (not oscillationCount)
        (setq oscillationCount 1) ; 默认1次
    )
    
    ; 选择所有长方形
    (princ "\n选择所有长方形框: ")
    (setq ssRects (ssget '((0 . "LWPOLYLINE"))))
    
    ; 选择要处理的线条
    (princ "\n选择需要添加往复运动的线条: ")
    (setq ssLines (ssget '((0 . "LWPOLYLINE"))))
    
    (if (and ssRects ssLines)
        (progn
            ; 收集所有矩形的边界
            (setq rectList '())
            (setq i 0)
            (repeat (sslength ssRects)
                (setq rect (ssname ssRects i))
                (setq rectPoints (getPolylinePoints rect))
                (if (>= (length rectPoints) 4)
                    (progn
                        (setq rectMinX (apply 'min (mapcar 'car rectPoints)))
                        (setq rectMaxX (apply 'max (mapcar 'car rectPoints)))
                        (setq rectMinY (apply 'min (mapcar 'cadr rectPoints)))
                        (setq rectMaxY (apply 'max (mapcar 'cadr rectPoints)))
                        (setq rectList (cons (list rectMinX rectMaxX rectMinY rectMaxY) rectList))
                    )
                )
                (setq i (1+ i))
            )
            
            ; 处理每条线
            (setq i 0)
            (repeat (sslength ssLines)
                (setq line (ssname ssLines i))
                (setq lineObj (vlax-ename->vla-object line))
                (setq linePoints (getPolylinePoints line))
                (setq newPoints '())
                (setq lastInRect nil)
                (setq rectStartParam nil)
                (setq rectEndParam nil)
                (setq beyondDistance 5.0)
                (setq step 1.0) ; 每1mm采样一个点
                
                ; 沿着多段线按参数采样点
                (setq totalLength (vlax-get lineObj 'Length))
                (setq param 0.0)
                
                (while (<= param totalLength)
                    (setq currentPoint (vlax-curve-getPointAtDist lineObj param))
                    
                    ; 检查当前点是否在任何矩形内
                    (setq inRect nil)
                    (foreach rect rectList
                        (setq rectMinX (car rect))
                        (setq rectMaxX (cadr rect))
                        (setq rectMinY (caddr rect))
                        (setq rectMaxY (cadddr rect))
                        
                        (if (and currentPoint
                                 (>= (car currentPoint) rectMinX) (<= (car currentPoint) rectMaxX)
                                 (>= (cadr currentPoint) rectMinY) (<= (cadr currentPoint) rectMaxY))
                            (setq inRect T)
                        )
                    )
                    
                    (cond
                        ; 进入矩形区域
                        ((and inRect (not lastInRect))
                            (setq rectStartParam param)
                            (setq lastInRect T)
                            (setq newPoints (cons currentPoint newPoints))
                        )
                        
                        ; 在矩形区域内
                        ((and inRect lastInRect)
                            (setq rectEndParam param)
                            (setq newPoints (cons currentPoint newPoints))
                        )
                        
                        ; 离开矩形区域
                        ((and (not inRect) lastInRect)
                            ; 在矩形结束处添加往复运动
                            (if (and rectStartParam rectEndParam)
                                (progn
                                    ; 获取矩形区域的起点和终点
                                    (setq rectStartPoint (vlax-curve-getPointAtDist lineObj rectStartParam))
                                    (setq rectEndPoint (vlax-curve-getPointAtDist lineObj rectEndParam))
                                    
                                    ; 创建多次往复
                                    (setq oscCount 0)
                                    (while (< oscCount oscillationCount)
                                        ; 沿着原始路径向前超出5mm
                                        (setq beyondEndParam (+ rectEndParam beyondDistance))
                                        (if (<= beyondEndParam totalLength)
                                            (setq beyondEndPoint (vlax-curve-getPointAtDist lineObj beyondEndParam))
                                            (setq beyondEndPoint rectEndPoint)
                                        )
                                        
                                        ; 添加向前超出段
                                        (setq newPoints (cons beyondEndPoint newPoints))
                                        
                                        ; 从超出点沿着原始路径返回到起点再超出5mm
                                        (setq reverseParam beyondEndParam)
                                        (while (>= reverseParam (- rectStartParam beyondDistance))
                                            (setq reversePoint (vlax-curve-getPointAtDist lineObj reverseParam))
                                            (setq newPoints (cons reversePoint newPoints))
                                            (setq reverseParam (- reverseParam step))
                                        )
                                        
                                        ; 从起点再向前走到终点（完成一次往复）
                                        (setq forwardParam rectStartParam)
                                        (while (<= forwardParam rectEndParam)
                                            (setq forwardPoint (vlax-curve-getPointAtDist lineObj forwardParam))
                                            (setq newPoints (cons forwardPoint newPoints))
                                            (setq forwardParam (+ forwardParam step))
                                        )
                                        
                                        (setq oscCount (1+ oscCount))
                                    )
                                )
                            )
                            (setq lastInRect nil)
                            (setq rectStartParam nil)
                            (setq rectEndParam nil)
                            (setq newPoints (cons currentPoint newPoints))
                        )
                        
                        ; 不在矩形内
                        (T
                            (setq newPoints (cons currentPoint newPoints))
                        )
                    )
                    
                    (setq param (+ param step))
                )
                
                ; 如果线条在矩形区域内结束，也要添加往复
                (if lastInRect
                    (if (and rectStartParam rectEndParam)
                        (progn
                            ; 创建多次往复
                            (setq oscCount 0)
                            (while (< oscCount oscillationCount)
                                ; 沿着原始路径向前超出5mm
                                (setq beyondEndParam (+ rectEndParam beyondDistance))
                                (if (<= beyondEndParam totalLength)
                                    (setq beyondEndPoint (vlax-curve-getPointAtDist lineObj beyondEndParam))
                                    (setq beyondEndPoint rectEndPoint)
                                )
                                
                                ; 添加向前超出段
                                (setq newPoints (cons beyondEndPoint newPoints))
                                
                                ; 从超出点沿着原始路径返回到起点再超出5mm
                                (setq reverseParam beyondEndParam)
                                (while (>= reverseParam (- rectStartParam beyondDistance))
                                    (setq reversePoint (vlax-curve-getPointAtDist lineObj reverseParam))
                                    (setq newPoints (cons reversePoint newPoints))
                                    (setq reverseParam (- reverseParam step))
                                )
                                
                                ; 从起点再向前走到终点（完成一次往复）
                                (setq forwardParam rectStartParam)
                                (while (<= forwardParam rectEndParam)
                                    (setq forwardPoint (vlax-curve-getPointAtDist lineObj forwardParam))
                                    (setq newPoints (cons forwardPoint newPoints))
                                    (setq forwardParam (+ forwardParam step))
                                )
                                
                                (setq oscCount (1+ oscCount))
                            )
                        )
                    )
                )
                
                ; 创建新的红色多段线
                (createRedPolylineFromPoints (reverse newPoints))
                (setq i (1+ i))
            )
            (princ (strcat "\n激光路径创建完成！红色线条为往复路径，往返次数: " (itoa oscillationCount)))
        )
        (princ "\n选择无效！")
    )
    (princ)
)

; 获取多段线的所有点
(defun getPolylinePoints (ent / obj points param)
    (setq obj (vlax-ename->vla-object ent))
    (setq points '())
    (setq param 0)
    (while (setq point (vlax-curve-getPointAtParam obj param))
        (setq points (cons point points))
        (setq param (1+ param))
    )
    (reverse points)
)

; 从点列表创建红色多段线
(defun createRedPolylineFromPoints (points)
    (if (> (length points) 1)
        (entmakex
            (append
                (list
                    '(0 . "LWPOLYLINE")
                    '(100 . "AcDbEntity")
                    '(8 . "0")          ; 图层0
                    '(62 . 1)           ; 颜色：红色
                    '(100 . "AcDbPolyline")
                    (cons 90 (length points))
                    '(70 . 0)
                )
                (mapcar '(lambda (pt) (cons 10 pt)) points)
            )
        )
    )
)

(princ "\n激光路径生成器已加载，输入 CreateLaserPath 开始使用。")
(princ)
