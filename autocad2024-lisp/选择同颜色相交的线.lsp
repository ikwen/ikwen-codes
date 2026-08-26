(defun c:AutoSelectIntersectingLines (/ entA colorA colorB ssAllLines ssResult 
                                      objA intersections count entB objB)
    (vl-load-com)
    
    ; 选择多段线（线A）
    (setq entA (car (entsel "\n请选择多段线（线A）: ")))
    (if (null entA)
        (progn
            (princ "\n未选择对象或选择无效。")
            (exit)
        )
    )
    
    ; 获取线A的颜色
    (initget 7)
    (setq colorA (getint "\n请输入线A的颜色代码 (例如 44): "))
    
    ; 获取线B的颜色
    (initget 7)
    (setq colorB (getint "\n请输入线B的颜色代码 (例如 114): "))
    
    ; 设置线A的颜色
    (setq objA (vlax-ename->vla-object entA))
    (vla-put-Color objA colorA)
    (princ (strcat "\n已设置线A颜色为: " (itoa colorA)))
    
    ; 选择所有指定颜色的线B
    (setq ssAllLines (ssget "X" (list (cons 0 "LINE,*POLYLINE,ARC,CIRCLE") (cons 62 colorB))))
    
    (if (null ssAllLines)
        (progn
            (princ (strcat "\n未找到颜色为 " (itoa colorB) " 的线对象。"))
            (exit)
        )
    )
    
    ; 创建结果选择集
    (setq ssResult (ssadd))
    (setq count 0)
    
    ; 遍历所有符合条件的线B
    (vlax-for objB (vla-get-ActiveSelectionSet (vla-get-ActiveDocument (vlax-get-acad-object)))
        (if (= (vla-get-Color objB) colorB)
            (progn
                ; 检测与线A是否相交
                (setq intersections (vlax-invoke objA 'IntersectWith objB acExtendNone))
                
                ; 如果相交，添加到结果选择集
                (if (> (length intersections) 0)
                    (progn
                        (ssadd (vlax-vla-object->ename objB) ssResult)
                        (setq count (1+ count))
                    )
                )
            )
        )
    )
    
    ; 清理选择集
    (if (setq ssAllLines (ssget "_X" (list (cons 0 "LINE,*POLYLINE,ARC,CIRCLE") (cons 62 colorB))))
        (sssetfirst nil ssAllLines)
    )
    
    ; 显示结果并选择相交的线
    (if (> count 0)
        (progn
            (princ (strcat "\n找到 " (itoa count) " 条颜色为 " (itoa colorB) " 且与线A相交的线。"))
            (sssetfirst nil ssResult)
            (princ "\n已自动选择所有相交的线B。")
        )
        (princ (strcat "\n未找到颜色为 " (itoa colorB) " 且与线A相交的线。")))
    
    (princ)
)

; 另一个版本：不改变线A颜色，只检测现有颜色
(defun c:FindIntersectingByColor (/ entA colorA colorB ssAllLines ssResult 
                                  objA intersections count entB objB entColor)
    (vl-load-com)
    
    ; 选择多段线（线A）
    (setq entA (car (entsel "\n请选择多段线（线A）: ")))
    (if (null entA)
        (progn
            (princ "\n未选择对象或选择无效。")
            (exit)
        )
    )
    
    ; 获取线A的当前颜色
    (setq objA (vlax-ename->vla-object entA))
    (setq colorA (vla-get-Color objA))
    
    ; 让用户确认或输入线A颜色
    (initget 7)
    (setq colorA (getint (strcat "\n请输入线A的颜色代码 (当前为 " (itoa colorA) "): ")))
    
    ; 获取线B的颜色
    (initget 7)
    (setq colorB (getint "\n请输入线B的颜色代码 (例如 114): "))
    
    ; 选择所有指定颜色的线B
    (setq ssAllLines (ssget "X" (list (cons 0 "LINE,*POLYLINE,ARC,CIRCLE") (cons 62 colorB))))
    
    (if (null ssAllLines)
        (progn
            (princ (strcat "\n未找到颜色为 " (itoa colorB) " 的线对象。"))
            (exit)
        )
    )
    
    ; 创建结果选择集
    (setq ssResult (ssadd))
    (setq count 0)
    
    ; 遍历所有符合条件的线B
    (repeat (setq i (sslength ssAllLines))
        (setq entB (ssname ssAllLines (setq i (1- i))))
        (setq objB (vlax-ename->vla-object entB))
        
        ; 检查颜色是否匹配
        (if (= (vla-get-Color objB) colorB)
            (progn
                ; 检测与线A是否相交
                (setq intersections (vlax-invoke objA 'IntersectWith objB acExtendNone))
                
                ; 如果相交，添加到结果选择集
                (if (> (length intersections) 0)
                    (progn
                        (ssadd entB ssResult)
                        (setq count (1+ count))
                    )
                )
            )
        )
    )
    
    ; 显示结果并选择相交的线
    (if (> count 0)
        (progn
            (princ (strcat "\n找到 " (itoa count) " 条颜色为 " (itoa colorB) " 且与线A相交的线。"))
            (sssetfirst nil ssResult)
            (princ "\n已自动选择所有相交的线B。")
            
            ; 显示相交点信息
            (princ "\n相交点信息:")
            (repeat (setq i (sslength ssResult))
                (setq entB (ssname ssResult (setq i (1- i))))
                (setq objB (vlax-ename->vla-object entB))
                (setq intersections (vlax-invoke objA 'IntersectWith objB acExtendNone))
                (princ (strcat "\n线" (itoa (- (sslength ssResult) i)) ": " 
                             (itoa (/ (length intersections) 3)) " 个相交点"))
            )
        )
        (princ (strcat "\n未找到颜色为 " (itoa colorB) " 且与线A相交的线。")))
    
    (princ)
)

; 加载提示
(princ "\n输入 AUTOSELECTINTERSECTINGLINES 自动选择相交线")
(princ "\n输入 FINDINTERSECTINGBYCOLOR 按颜色查找相交线")
(princ)
