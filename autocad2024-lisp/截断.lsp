(defun c:BM (/ ss gapPoints moveDir moveVector)
  (princ "\n=== 自动对齐合并命令 ===")
  
  ; 选择要处理的所有线条（缺口两侧的线条）
  (princ "\n选择缺口两侧的所有线条: ")
  (setq ss (ssget '((0 . "LINE,ARC,LWPOLYLINE"))))
  (if (not ss)
    (progn (princ "未选择线条!") (princ) (exit))
  )
  
  ; 自动分析缺口，找到两侧的最近点
  (setq gapPoints (findGapPoints ss))
  
  (if gapPoints
    (progn
      (princ (strcat "\n找到缺口，距离: " (rtos (distance (car gapPoints) (cadr gapPoints)))))
      
      ; 选择移动方向
      (initget "L R")
      (setq moveDir (getkword "\n移动哪一侧? [L(左侧)/R(右侧)]: "))
      
      (if (eq moveDir "L")
        ; 移动左侧点到右侧点
        (progn
          (setq moveVector (mapcar '- (cadr gapPoints) (car gapPoints)))
          (command "_.move" (caddr gapPoints) "" "_non" (car gapPoints) "_non" (cadr gapPoints))
        )
        ; 移动右侧点到左侧点
        (progn
          (setq moveVector (mapcar '- (car gapPoints) (cadr gapPoints)))
          (command "_.move" (cadddr gapPoints) "" "_non" (cadr gapPoints) "_non" (car gapPoints))
        )
      )
      
      ; 自动合并
      (princ "\n正在合并线条...")
      (command "_.join" (caddr gapPoints) (cadddr gapPoints) "")
      
      (princ "\n=== 对齐合并完成! ===")
    )
    (princ "\n没有检测到缺口!")
  )
  (princ)
)

; 自动找到缺口两侧的最近点
(defun findGapPoints (ss / lines allPoints i ent end1 end2 nearestDist point1 point2 line1 line2)
  (setq lines '())
  (setq allPoints '())
  
  ; 收集所有线条和端点
  (repeat (setq i (sslength ss))
    (setq ent (ssname ss (setq i (1- i))))
    (setq end1 (vlax-curve-getStartPoint ent))
    (setq end2 (vlax-curve-getEndPoint ent))
    (setq lines (cons (list ent end1 end2) lines))
    (setq allPoints (cons (list end1 ent) allPoints))
    (setq allPoints (cons (list end2 ent) allPoints))
  )
  
  ; 找到距离最近的两个点（属于不同线条）
  (setq nearestDist 1e99)
  (setq point1 nil)
  (setq point2 nil)
  (setq line1 nil)
  (setq line2 nil)
  
  (foreach pt1 allPoints
    (foreach pt2 allPoints
      (if (not (eq (cadr pt1) (cadr pt2)))  ; 确保是不同线条的点
        (progn
          (setq dist (distance (car pt1) (car pt2)))
          (if (< dist nearestDist)
            (progn
              (setq nearestDist dist)
              (setq point1 (car pt1))
              (setq point2 (car pt2))
              (setq line1 (cadr pt1))
              (setq line2 (cadr pt2))
            )
          )
        )
      )
    )
  )
  
  (if (and point1 point2 (< nearestDist 100))  ; 限制最大距离，避免误匹配
    (list point1 point2 line1 line2)
    nil
  )
)

(princ "\n*** 输入 BM 自动对齐合并缺口 ***")
(princ)
