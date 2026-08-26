(defun c:selidentical (/ ent ent_data ss tolerance ent_type ref_obj)
  ; 错误处理函数
  (defun *error* (msg)
    (if (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*"))
      (princ (strcat "\n错误: " msg))
    )
    (setvar "CMDECHO" 1)
    (princ)
  )
  
  (setvar "CMDECHO" 0)
  
  ; 让用户输入容差
  (setq tolerance (getreal "\n请输入容差值(毫米) <1.0>: "))
  (if (not tolerance) (setq tolerance 1.0))
  
  ; 提示用户选择参考对象
  (princ "\n请选择一个图形或线条作为参考: ")
  (setq ent (car (entsel)))
  
  (cond
    ((null ent)
      (princ "\n未选择对象或选择无效。")
    )
    (t
      (setq ent_data (entget ent))
      (setq ent_type (cdr (assoc 0 ent_data)))
      (setq ref_obj (vlax-ename->vla-object ent))
      
      (princ "\n正在搜索相同对象...")
      
      ; 创建空选择集
      (setq ss (ssadd))
      (ssadd ent ss)  ; 先添加参考对象自身
      
      ; 获取参考对象的关键属性
      (setq ref_layer (cdr (assoc 8 ent_data)))
      (setq ref_color (cdr (assoc 62 ent_data)))
      (setq ref_linetype (cdr (assoc 6 ent_data)))
      
      ; 获取参考对象的几何尺寸
      (setq ref_size (get_object_size ref_obj ent_type))
      
      ; 遍历整个图形数据库
      (setq all_entities (ssget "_X" (list (cons 0 ent_type))))
      
      (if all_entities
        (progn
          (repeat (setq i (sslength all_entities))
            (setq test_ent (ssname all_entities (setq i (1- i))))
            
            ; 跳过参考对象自身
            (if (not (equal test_ent ent))
              (progn
                (setq test_data (entget test_ent))
                (setq test_obj (vlax-ename->vla-object test_ent))
                
                ; 比较基本属性
                (if (and
                      (equal ref_layer (cdr (assoc 8 test_data)))
                      (or (null ref_color) (equal ref_color (cdr (assoc 62 test_data))))
                      (equal ref_linetype (cdr (assoc 6 test_data)))
                    )
                  (progn
                    ; 比较几何尺寸（带容差）
                    (setq test_size (get_object_size test_obj ent_type))
                    (if (and ref_size test_size)
                      (if (<= (abs (- ref_size test_size)) tolerance)
                        (ssadd test_ent ss)
                      )
                    )
                  )
                )
              )
            )
          )
          
          ; 显示结果
          (if (> (sslength ss) 1)
            (progn
              (sssetfirst nil ss)
              (princ (strcat "\n找到并选中了 " (itoa (sslength ss)) " 个相同的对象。"))
              (princ (strcat "\n容差值: " (rtos tolerance) " 毫米"))
            )
            (princ "\n未找到其他相同的对象。")
          )
        )
        (princ "\n未找到相同类型的对象。")
      )
    )
  )
  
  (setvar "CMDECHO" 1)
  (princ)
)

; 获取对象的主要尺寸
(defun get_object_size (obj obj_type / size)
  (cond
    ((= obj_type "CIRCLE")
      (setq size (vla-get-Radius obj))  ; 使用半径作为比较基准
    )
    ((= obj_type "LINE")
      (setq size (vla-get-Length obj))
    )
    ((= obj_type "LWPOLYLINE")
      (setq size (vla-get-Length obj))
    )
    ((= obj_type "ARC")
      (setq size (vla-get-Radius obj))
    )
    ((= obj_type "ELLIPSE")
      (setq size (vla-get-RadiusRatio obj))
    )
    (t
      ; 对于其他对象，尝试获取长度或面积
      (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-get-Length (list obj))))
        (setq size (vla-get-Length obj))
        (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-get-Area (list obj))))
          (setq size (vla-get-Area obj))
          (setq size nil)
        )
      )
    )
  )
  size
)

; 简化版本 - 只比较图层和类型
(defun c:selsimple (/ ent ent_data ss ent_type ref_layer)
  (setvar "CMDECHO" 0)
  
  (princ "\n请选择一个图形或线条作为参考: ")
  (setq ent (car (entsel)))
  
  (cond
    ((null ent)
      (princ "\n未选择对象或选择无效。")
    )
    (t
      (setq ent_data (entget ent))
      (setq ent_type (cdr (assoc 0 ent_data)))
      (setq ref_layer (cdr (assoc 8 ent_data)))
      
      ; 创建选择集 - 只比较类型和图层
      (setq ss (ssget "_X" (list (cons 0 ent_type) (cons 8 ref_layer))))
      
      (if ss
        (progn
          (sssetfirst nil ss)
          (princ (strcat "\n找到并选中了 " (itoa (sslength ss)) " 个相同类型的对象。"))
        )
        (princ "\n未找到相同类型的对象。")
      )
    )
  )
  
  (setvar "CMDECHO" 1)
  (princ)
)

(princ "\n选择相同对象命令已加载，请输入 SELIDENTICAL 或 SELSIMPLE 来运行。")
(princ)
