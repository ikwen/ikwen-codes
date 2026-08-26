
(defun c:RecoverRegion (/ ss pt1 pt2 old_err)
  ; 错误处理函数
  (defun *error* (msg)
    (if old_err (setq *error* old_err))
    (princ (strcat "\n错误: " msg))
    (princ)
  )
  
  (setq old_err *error*)
  (setvar "CMDECHO" 0) ; 关闭命令回显
  
  (princ "\n★ 区域恢复工具 - 框选要恢复的区域 ★")
  
  ; 检查是否有可恢复的删除对象
  (if (not (zerop (getvar "UNDOCTL")))
    (progn
      (setq pt1 (getpoint "\n指定第一角点: "))
      (setq pt2 (getcorner pt1 "\n指定对角点: "))
      
      ; 尝试用不同选择方式获取对象
      (cond
        ((setq ss (ssget "_C" pt1 pt2)) ; 交叉选择
         (command "_.UNDO" "_BEGIN")
         (command "_.OOPS")
         (command "_.UNDO" "_END")
         (princ (strcat "\n成功恢复 " (itoa (sslength ss)) " 个对象"))
        )
        ((setq ss (ssget "_W" pt1 pt2)) ; 窗口选择
         (command "_.UNDO" "_BEGIN")
         (command "_.OOPS")
         (command "_.UNDO" "_END")
         (princ (strcat "\n成功恢复 " (itoa (sslength ss)) " 个对象"))
        )
        (t (princ "\n警告: 选定区域内未找到可恢复对象"))
      )
    )
    (princ "\n错误: 没有可撤销的操作记录")
  )
  
  (setvar "CMDECHO" 1)
  (princ)
)
