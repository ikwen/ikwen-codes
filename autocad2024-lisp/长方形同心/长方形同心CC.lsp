(defun c:CC (/ ss1 ss2 en1 en2 p1 p2 minpt maxpt obj1 obj2)
  (vl-load-com)
  
  ;; 1. 谢思瑶，请选择要移动的对象
  (setq ss1 (entsel "\n[1] 谢思瑶，请选择要移动的长方形: "))
  (if ss1
    (progn
      (setq en1 (car ss1))
      (setq obj1 (vlax-ename->vla-object en1))
      ;; 计算第一个中心
      (vla-getboundingbox obj1 'minpt 'maxpt)
      (setq p1 (mapcar '(lambda (a b) (/ (+ a b) 2.0)) 
                       (vlax-safearray->list minpt) 
                       (vlax-safearray->list maxpt)))
      
      ;; 2. 谢思瑶，请选择目标对象
      (setq ss2 (entsel "\n[2] 谢思瑶，请选择目标长方形: "))
      (if ss2
        (progn
          (setq en2 (car ss2))
          (setq obj2 (vlax-ename->vla-object en2))
          ;; 计算第二个中心
          (vla-getboundingbox obj2 'minpt 'maxpt)
          (setq p2 (mapcar '(lambda (a b) (/ (+ a b) 2.0)) 
                           (vlax-safearray->list minpt) 
                           (vlax-safearray->list maxpt)))
          
          ;; 3. 执行移动
          (command "_.move" en1 "" "_non" p1 "_non" p2)
          (princ "\n谢思瑶，中心已经完美重合了！")
        )
        (princ "\n谢思瑶，你没有选中第二个对象哦。")
      )
    )
    (princ "\n谢思瑶，你没有选中第一个对象哦。")
  )
  (princ)
)
