(defun c:BM (/ moveEnt targetEnt movePoints targetPoints nearestPair)
  (princ "\n=== 自动对齐合并命令 ===")
  
  ; 第一步：选择要移动的线条
  (princ "\n第一步：选择要移动的线条: ")
  (setq moveEnt (car (entsel)))
  (if (not moveEnt)
    (progn (princ "未选择移动线条!") (princ) (exit))
  )
  
  ; 第二步：选择要对齐的目标线条
  (princ "\n第二步：选择要对齐的目标线条: ")
  (setq targetEnt (car (entsel)))
  (if (not targetEnt)
    (progn (princ "未选择目标线条!") (princ) (exit))
  )
  
  ; 获取两条线的所有顶点
  (setq movePoints (getAllPoints moveEnt))
  (setq targetPoints (getAllPoints targetEnt))
  
  ; 找到最近的顶点对
  (setq nearestPair (findNearestPoints movePoints targetPoints))
  
  (if nearestPair
    (progn
      (princ (strcat "\n找到最近顶点，距离: " (rtos (distance (car nearestPair) (cadr nearestPair)))))
      
      ; 移动对齐
      (princ "\n正在移动对齐...")
      (command "_.move" moveEnt "" "_non" (car nearestPair) "_non" (cadr nearestPair))
      
      ; 自动合并
      (princ "\n正在合并线条...")
      (command "_.join" moveEnt targetEnt "")
      
      (princ "\n=== 对齐合并完成! ===")
    )
    (princ "\n没有找到可以对齐的顶点!")
  )
  (princ)
)

; 获取实体的所有顶点（包括端点和中间顶点）
(defun getAllPoints (ent / obj points entType coords i)
  (setq obj (vlax-ename->vla-object ent))
  (setq entType (cdr (assoc 0 (entget ent))))
  (setq points '())
  
  (cond
    ((= entType "LWPOLYLINE")
     ; 多段线：获取所有顶点
     (setq coords (vlax-get obj 'Coordinates))
     (setq i 0)
     (while (< i (length coords))
       (setq points (cons (list (nth i coords) (nth (+ i 1) coords) 0.0) points))
       (setq i (+ i 2))
     )
    )
    ((= entType "LINE")
     ; 直线：只有起点和终点
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
    )
    ((= entType "ARC")
     ; 圆弧：起点、终点和中间点
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
     ; 添加中间点以提高对齐精度
     (setq midParam (/ (+ (vlax-curve-getStartParam ent) (vlax-curve-getEndParam ent)) 2.0))
     (setq points (cons (vlax-curve-getPointAtParam ent midParam) points))
    )
    (t
     ; 其他类型：只获取端点
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
    )
  )
  points
)

; 找到两组点中距离最近的一对点
(defun findNearestPoints (points1 points2 / nearestDist point1 point2)
  (setq nearestDist 1e99)
  (setq point1 nil)
  (setq point2 nil)
  
  (foreach pt1 points1
    (foreach pt2 points2
      (setq dist (distance pt1 pt2))
      (if (< dist nearestDist)
        (progn
          (setq nearestDist dist)
          (setq point1 pt1)
          (setq point2 pt2)
        )
      )
    )
  )
  
  (if (and point1 point2)
    (list point1 point2)
    nil
  )
)

(princ "\n*** 输入 BM 自动对齐合并 ***")
(princ)
