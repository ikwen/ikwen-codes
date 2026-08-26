(defun c:GetColor (/ ss i entity obj color)
  ;; 查询选择对象的颜色代码
  (princ "\n选择要查询颜色的对象: ")
  (setq ss (ssget))
  
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq entity (ssname ss i))
        (setq obj (vlax-ename->vla-object entity))
        (setq color (vla-get-color obj))
        
        (princ (strcat "\n对象 " (itoa (1+ i)) " 的颜色代码: " (itoa color)))
        
        ;; 显示颜色含义
        (cond
          ((= color 0) (princ " (ByBlock)"))
          ((= color 256) (princ " (ByLayer)"))
          ((= color 1) (princ " (红色)"))
          ((= color 2) (princ " (黄色)"))
          ((= color 3) (princ " (绿色)"))
          ((= color 4) (princ " (青色)"))
          ((= color 5) (princ " (蓝色)"))
          ((= color 6) (princ " (洋红)"))
          ((= color 7) (princ " (白色/黑色)"))
        )
        
        (setq i (1+ i))
      )
    )
    (princ "\n没有选择对象。")
  )
  (princ)
)
