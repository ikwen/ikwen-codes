(defun c:BM (/ moveSS targetSS moveEnts targetEnts nearestPairs)
  (princ "\n=== 多线条自动对齐合并命令 ===")
  
  ; 第一步：选择要移动的多根线条
  (princ "\n第一步：选择要移动的多根线条: ")
  (setq moveSS (ssget '((0 . "LINE,ARC,LWPOLYLINE"))))
  (if (not moveSS)
    (progn (princ "未选择移动线条!") (princ) (exit))
  )
  
  ; 第二步：选择要对齐的目标线条
  (princ "\n第二步：选择要对齐的目标线条: ")
  (setq targetSS (ssget '((0 . "LINE,ARC,LWPOLYLINE"))))
  (if (not targetSS)
    (progn (princ "未选择目标线条!") (princ) (exit))
  )
  
  ; 转换为实体列表
  (setq moveEnts (ssToList moveSS))
  (setq targetEnts (ssToList targetSS))
  
  (princ (strcat "\n移动线条数量: " (itoa (length moveEnts))))
  (princ (strcat " 目标线条数量: " (itoa (length targetEnts))))
  
  ; 为每个移动线条找到最近的目标线条并对齐
  (setq nearestPairs (findAllNearestPairs moveEnts targetEnts))
  
  (if nearestPairs
    (progn
      (princ "\n正在对齐合并...")
      (alignAndJoinAll nearestPairs)
      (princ "\n=== 多线条对齐合并完成! ===")
    )
    (princ "\n没有找到可以对齐的线条!")
  )
  (princ)
)

; 将选择集转换为实体列表
(defun ssToList (ss / i ent result)
  (setq result '())
  (repeat (setq i (sslength ss))
    (setq ent (ssname ss (setq i (1- i))))
    (setq result (cons ent result))
  )
  result
)

; 为每个移动线条找到最近的目标线条
(defun findAllNearestPairs (moveEnts targetEnts / pairs usedTargets)
  (setq pairs '())
  (setq usedTargets '())
  
  (foreach moveEnt moveEnts
    (setq nearestTarget nil)
    (setq nearestDist 1e99)
    (setq movePoints nil)
    (setq targetPoints nil)
    
    ; 找到最近的目标线条
    (foreach targetEnt targetEnts
      ; 确保目标线条未被使用
      (if (not (member targetEnt usedTargets))
        (progn
          (setq movePoints (getAllPoints moveEnt))
          (setq targetPoints (getAllPoints targetEnt))
          (setq dist (getMinDistance movePoints targetPoints))
          
          (if (< dist nearestDist)
            (progn
              (setq nearestDist dist)
              (setq nearestTarget targetEnt)
              (setq bestMovePoints movePoints)
              (setq bestTargetPoints targetPoints)
            )
          )
        )
      )
    )
    
    ; 如果找到最近的目标线条，记录配对
    (if (and nearestTarget (< nearestDist 1000))  ; 限制最大距离
      (progn
        (setq nearestPoints (findNearestPoints bestMovePoints bestTargetPoints))
        (setq pairs (cons (list moveEnt nearestTarget (car nearestPoints) (cadr nearestPoints)) pairs))
        (setq usedTargets (cons nearestTarget usedTargets))  ; 标记目标线条已使用
      )
    )
  )
  pairs
)

; 获取两组点之间的最小距离
(defun getMinDistance (points1 points2 / minDist)
  (setq minDist 1e99)
  (foreach pt1 points1
    (foreach pt2 points2
      (setq dist (distance pt1 pt2))
      (if (< dist minDist)
        (setq minDist dist)
      )
    )
  )
  minDist
)

; 对齐并合并所有配对
(defun alignAndJoinAll (pairs / count)
  (setq count 0)
  (foreach pair pairs
    (setq moveEnt (car pair))
    (setq targetEnt (cadr pair))
    (setq movePoint (caddr pair))
    (setq targetPoint (cadddr pair))
    
    ; 检查实体是否还存在（可能已被之前的合并操作删除）
    (if (and (entget moveEnt) (entget targetEnt))
      (progn
        ; 移动对齐
        (command "_.move" moveEnt "" "_non" movePoint "_non" targetPoint)
        ; 合并
        (command "_.join" moveEnt targetEnt "")
        (setq count (1+ count))
      )
    )
  )
  (princ (strcat " 成功合并了 " (itoa count) " 对线条"))
)

; 获取实体的所有顶点（保持不变）
(defun getAllPoints (ent / obj points entType coords i)
  (setq obj (vlax-ename->vla-object ent))
  (setq entType (cdr (assoc 0 (entget ent))))
  (setq points '())
  
  (cond
    ((= entType "LWPOLYLINE")
     (setq coords (vlax-get obj 'Coordinates))
     (setq i 0)
     (while (< i (length coords))
       (setq points (cons (list (nth i coords) (nth (+ i 1) coords) 0.0) points))
       (setq i (+ i 2))
     )
    )
    ((= entType "LINE")
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
    )
    ((= entType "ARC")
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
     (setq midParam (/ (+ (vlax-curve-getStartParam ent) (vlax-curve-getEndParam ent)) 2.0))
     (setq points (cons (vlax-curve-getPointAtParam ent midParam) points))
    )
    (t
     (setq points (list (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent)))
    )
  )
  points
)

; 找到两组点中距离最近的一对点（保持不变）
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

(princ "\n*** 输入 BM 多线条自动对齐合并 ***")
(princ)
