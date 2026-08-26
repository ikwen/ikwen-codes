(defun c:ExtendLines (/ ss extensionType extensionAmount i ent objType entData vertices firstVertex lastVertex firstPt lastPt startVec endVec newFirstPt newLastPt pickPt)
    (vl-load-com)
    
    ; 如果已经选择了对象，使用之前的选择集，否则让用户选择
    (if (or (not (setq ss (ssget "_I")))
            (= (sslength ss) 0))
        (progn
            (princ "\n选择要延伸的线条: ")
            (setq ss (ssget '((0 . "LINE,LWPOLYLINE"))))
        )
        (princ "\n使用当前选择集...")
    )
    
    (if ss
        (progn
            (setq extensionAmount (getreal "\n输入延伸长度(毫米): "))
            
            ; 让用户点击要延伸的端点
            (princ "\n请点击要延伸的端点: ")
            (setq pickPt (getpoint))
            
            (setq i 0)
            (repeat (sslength ss)
                (setq ent (ssname ss i))
                (setq objType (cdr (assoc 0 (entget ent))))
                (setq entData (entget ent))
                
                (cond
                    ; 处理直线
                    ((= objType "LINE")
                        (setq startPt (cdr (assoc 10 entData)))
                        (setq endPt (cdr (assoc 11 entData)))
                        (setq vec (mapcar '- endPt startPt))
                        (setq len (distance startPt endPt))
                        
                        (if (> len 1e-8)
                            (progn
                                (setq unitVec (list (/ (car vec) len) (/ (cadr vec) len)))
                                
                                ; 判断点击点靠近哪个端点
                                (setq distToStart (distance pickPt startPt))
                                (setq distToEnd (distance pickPt endPt))
                                
                                (cond
                                    ; 点击点靠近起点
                                    ((< distToStart distToEnd)
                                        (setq newStartPt (list (- (car startPt) (* (car unitVec) extensionAmount))
                                                              (- (cadr startPt) (* (cadr unitVec) extensionAmount))))
                                        (setq newEndPt endPt)
                                    )
                                    ; 点击点靠近终点
                                    (t
                                        (setq newStartPt startPt)
                                        (setq newEndPt (list (+ (car endPt) (* (car unitVec) extensionAmount))
                                                            (+ (cadr endPt) (* (cadr unitVec) extensionAmount))))
                                    )
                                )
                                
                                ; 更新直线
                                (entmod (subst (cons 10 newStartPt) (assoc 10 entData) 
                                        (subst (cons 11 newEndPt) (assoc 11 entData) entData)))
                            )
                        )
                    )
                    
                    ; 处理轻量多段线
                    ((= objType "LWPOLYLINE")
                        ; 获取所有顶点
                        (setq vertices (vl-remove-if-not '(lambda (x) (= (car x) 10)) entData))
                        
                        (if (>= (length vertices) 2)
                            (progn
                                ; 获取第一个和最后一个顶点
                                (setq firstVertex (car vertices))
                                (setq lastVertex (last vertices))
                                (setq firstPt (cdr firstVertex))
                                (setq lastPt (cdr lastVertex))
                                
                                ; 计算端点处的切线方向
                                (setq startVec (GetPolylineTangent entData t))   ; 起点切线方向
                                (setq endVec (GetPolylineTangent entData nil))   ; 终点切线方向
                                
                                ; 判断点击点靠近哪个端点
                                (setq distToStart (distance pickPt firstPt))
                                (setq distToEnd (distance pickPt lastPt))
                                
                                ; 计算新的顶点位置
                                (cond
                                    ; 点击点靠近起点
                                    ((< distToStart distToEnd)
                                        ; 延伸起点：第一个顶点沿起点切线反方向移动
                                        (setq newFirstPt (list (- (car firstPt) (* (car startVec) extensionAmount))
                                                              (- (cadr firstPt) (* (cadr startVec) extensionAmount))))
                                        (setq newLastPt lastPt)
                                    )
                                    ; 点击点靠近终点
                                    (t
                                        ; 延伸终点：最后一个顶点沿终点切线正方向移动
                                        (setq newFirstPt firstPt)
                                        (setq newLastPt (list (+ (car lastPt) (* (car endVec) extensionAmount))
                                                             (+ (cadr lastPt) (* (cadr endVec) extensionAmount))))
                                    )
                                )
                                
                                ; 更新多段线的顶点
                                (setq entData (subst (cons 10 newFirstPt) firstVertex entData))
                                (setq entData (subst (cons 10 newLastPt) lastVertex entData))
                                
                                ; 更新实体
                                (entmod entData)
                            )
                        )
                    )
                )
                (setq i (1+ i))
            )
            (princ (strcat "\n成功延伸 " (itoa (sslength ss)) " 个对象"))
        )
        (princ "\n未选择任何对象")
    )
    (princ)
)

; 获取多段线端点切线方向的函数
(defun GetPolylineTangent (entData atStart / vertices pt1 pt2 vec len)
    (setq vertices (vl-remove-if-not '(lambda (x) (= (car x) 10)) entData))
    
    (if atStart
        ; 起点切线：从第一个顶点指向第二个顶点
        (if (>= (length vertices) 2)
            (progn
                (setq pt1 (cdr (car vertices)))
                (setq pt2 (cdr (cadr vertices)))
                (setq vec (mapcar '- pt2 pt1))
                (setq len (distance pt1 pt2))
                (if (> len 1e-8)
                    (list (/ (car vec) len) (/ (cadr vec) len)
                          (if (> (length vec) 2) (/ (caddr vec) len) 0.0))
                    '(1.0 0.0 0.0) ; 默认方向
                )
            )
            '(1.0 0.0 0.0) ; 默认方向
        )
        ; 终点切线：从倒数第二个顶点指向最后一个顶点
        (if (>= (length vertices) 2)
            (progn
                (setq pt1 (cdr (nth (- (length vertices) 2) vertices)))
                (setq pt2 (cdr (last vertices)))
                (setq vec (mapcar '- pt2 pt1))
                (setq len (distance pt1 pt2))
                (if (> len 1e-8)
                    (list (/ (car vec) len) (/ (cadr vec) len)
                          (if (> (length vec) 2) (/ (caddr vec) len) 0.0))
                    '(1.0 0.0 0.0) ; 默认方向
                )
            )
            '(1.0 0.0 0.0) ; 默认方向
        )
    )
)

; 加载提示
(princ "\n延伸线条命令已加载，输入 ExtendLines 来使用")
(princ "\n使用方法1: 先选择线条，再输入 ExtendLines")
(princ "\n使用方法2: 直接输入 ExtendLines，然后选择线条")
(princ "\n注意: 程序会让你点击要延伸的端点")
(princ)
