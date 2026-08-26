(defun c:BCC (/ ssTargets ssSource sourceObj targetObj i targetCenter sourceMin sourceMax sourceCenter offset)
    (vl-load-com)
    (princ "\n--- 谢思瑶的批量中心复制工具 ---")

    ;; 1. 谢思瑶，请先选中你已经选好的那一堆图形
    (princ "\n请选择所有的目标图形（要把东西拷贝到这些图形的中心）: ")
    (setq ssTargets (ssget))

    (if (and ssTargets (> (sslength ssTargets) 0))
        (progn
            ;; 2. 让谢思瑶选择要复制的那个“源图形”
            (princ "\n请选择要被复制的那个源图形: ")
            (setq ssSource (ssget ":S")) ;; :S 只允许选一个

            (if ssSource
                (progn
                    (setq sourceObj (ssname ssSource 0))
                    
                    ;; 计算源图形的中心点
                    (setq sourceCenter (getObjCenter sourceObj))

                    (setq i 0)
                    (repeat (sslength ssTargets)
                        (setq targetObj (ssname ssTargets i))
                        
                        ;; 计算当前目标图形的中心点
                        (setq targetCenter (getObjCenter targetObj))

                        ;; 执行复制并移动
                        ;; 谢思瑶，这里我们先拷贝一份，再把拷贝件从源中心移到目标中心
                        (command "_copy" sourceObj "" sourceCenter targetCenter)
                        
                        (setq i (1+ i))
                    )
                    (princ (strcat "\n谢思瑶，完成啦！已成功复制到 " (itoa (sslength ssTargets)) " 个位置。"))
                )
                (princ "\n谢思瑶，你没有选中源图形哦。")
            )
        )
        (princ "\n谢思瑶，目标图形选择集为空。")
    )
    (princ)
)

;; --- 辅助函数：万能中心点计算 (支持圆、方框、多段线) ---
(defun getObjCenter (ent / minp maxp)
    (vla-getboundingbox (vlax-ename->vla-object ent) 'minp 'maxp)
    (setq minp (vlax-safearray->list minp)
          maxp (vlax-safearray->list maxp))
    (list 
        (/ (+ (car minp) (car maxp)) 2.0)
        (/ (+ (cadr minp) (cadr maxp)) 2.0)
        0.0
    )
)

;; --- 加载提示 ---
(princ "\n>>> 批量对齐工具已加载。谢思瑶，请输入命令: BCC 来运行 <<<")
(princ)
