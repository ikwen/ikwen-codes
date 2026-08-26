(defun c:C2A (/ ss i en obj new_obj p1 p2 old_osmode)
  (vl-load-com)
  ;; 1. 谢思瑶，先保存你当前的捕捉设置 (OSMODE)
  (setq old_osmode (getvar "OSMODE"))
  
  (setq i 0)
  (if (setq ss (ssget '((0 . "LWPOLYLINE") (-4 . "&") (70 . 1))))
    (progn
      ;; 2. 暂时关闭捕捉，确保 0.01mm 剪切精确
      (setvar "OSMODE" 0)
      
      (repeat (sslength ss)
        (setq en (ssname ss i))
        (setq obj (vlax-ename->vla-object en))
        
        ;; 缩放偏移量：向内缩小 0.1mm
        (vla-offset obj -0.1)
        (setq new_obj (entlast))
        
        ;; 获取剪切点：起点和距离起点 0.01mm 处的点
        (setq p1 (vlax-curve-getStartPoint new_obj))
        (setq p2 (vlax-curve-getPointAtDist new_obj 0.01))
        
        ;; 执行打断
        (command "_break" new_obj p1 p2)
        
        ;; 删除原图
        (vla-delete obj)
        (setq i (1+ i))
      )
      
      ;; 3. 谢思瑶，这里是关键！脚本跑完了，把捕捉设置还原回去
      (setvar "OSMODE" old_osmode)
      
      (princ (strcat "\n处理完成，谢思瑶，共修改了 " (itoa i) " 个图形，并已恢复你的捕捉设置。"))
    )
    (progn
      ;; 如果没选中东西，也要记得还原捕捉，否则谢思瑶下次画图会发现没捕捉了
      (setvar "OSMODE" old_osmode)
      (princ "\n谢思瑶，未选中任何闭合的多段线。")
    )
  )
  (princ)
)
