;; =============================================
;; 多颜色选择工具 - 合并版
;; 包含 MCQ, MCQ2, GetColor 命令
;; =============================================

(defun c:MCQ (/ color-str color-list ss selection-type)
  ;; 基础版多颜色选择命令
  (vl-load-com)
  
  ;; 获取选择集
  (princ "\n选择对象或按Enter键选择所有图形: ")
  (setq ss (ssget))
  
  ;; 如果没有选择，则使用所有图形
  (if (not ss)
    (progn
      (setq ss (ssget "_X"))
      (setq selection-type "所有图形")
    )
    (setq selection-type "当前选择")
  )
  
  (if ss
    (progn
      ;; 获取颜色输入
      (setq color-str (getstring t "\n输入颜色代码(用;分号分隔，例如: 114;250;177): "))
      
      ;; 解析颜色代码
      (setq color-list (parse-colors color-str))
      
      (if color-list
        (progn
          ;; 根据颜色筛选选择集
          (setq ss (filter-by-colors ss color-list))
          
          (if (> (sslength ss) 0)
            (progn
              (princ (strcat "\n已选择 " (itoa (sslength ss)) " 个对象 (颜色: " color-str ")"))
              (sssetfirst nil ss)  ;; 高亮显示选择的对象
            )
            (princ "\n没有找到匹配颜色的对象。")
          )
        )
        (princ "\n颜色输入格式错误！")
      )
    )
    (princ "\n没有选择任何对象。")
  )
  (princ)
)

(defun c:MCQ2 (/ color-str color-list ss selection-type)
  ;; 增强版多颜色选择命令，带颜色提示
  (vl-load-com)
  
  (princ "\n=== 多颜色选择命令 ===")
  (princ "\n常用颜色代码: 1=红, 2=黄, 3=绿, 4=青, 5=蓝, 6=洋红, 7=白/黑")
  (princ "\n特殊代码: 0=ByBlock, 256=ByLayer")
  
  ;; 获取选择集
  (princ "\n\n选择对象或按Enter键选择所有图形: ")
  (setq ss (ssget))
  
  (if (not ss)
    (progn
      (setq ss (ssget "_X"))
      (setq selection-type "所有图形")
    )
    (setq selection-type "当前选择")
  )
  
  (if ss
    (progn
      ;; 获取颜色输入
      (setq color-str (getstring t "\n输入颜色代码(用;分号分隔，例如: 1;3;5 或 2;256): "))
      
      ;; 解析颜色代码
      (setq color-list (parse-colors color-str))
      
      (if color-list
        (progn
          ;; 根据颜色筛选选择集
          (setq ss (filter-by-colors ss color-list))
          
          (if (> (sslength ss) 0)
            (progn
              (princ (strcat "\n已选择 " (itoa (sslength ss)) " 个对象"))
              (princ (strcat "\n颜色: " color-str " (" selection-type ")"))
              (sssetfirst nil ss)
            )
            (princ "\n没有找到匹配颜色的对象。")
          )
        )
        (princ "\n颜色输入格式错误！请使用数字代码，如: 1;3;5")
      )
    )
    (princ "\n没有选择任何对象。")
  )
  (princ)
)

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
          ((<= 8 color 255) (princ " (索引颜色)"))
        )
        
        (setq i (1+ i))
      )
    )
    (princ "\n没有选择对象。")
  )
  (princ)
)

;; =============================================
;; 共用辅助函数
;; =============================================

(defun parse-colors (color-str / color-list temp-list code)
  ;; 解析颜色字符串，返回颜色代码列表
  (setq temp-list (split-string color-str ";"))
  (setq color-list '())
  
  (foreach code temp-list
    (setq code (trim code))
    (if (and (> (strlen code) 0) (is-number code))
      (setq color-list (cons (atoi code) color-list))
    )
  )
  
  (reverse color-list)
)

(defun filter-by-colors (ss color-list / filtered-ss i entity color)
  ;; 根据颜色列表筛选选择集
  (setq filtered-ss (ssadd))
  
  (if (> (sslength ss) 0)
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq entity (ssname ss i))
        (setq color (get-entity-color entity))
        
        ;; 检查颜色是否在目标列表中
        (if (member color color-list)
          (ssadd entity filtered-ss)
        )
        
        (setq i (1+ i))
      )
    )
  )
  
  filtered-ss
)

(defun get-entity-color (entity / obj color)
  ;; 获取对象的颜色
  (setq obj (vlax-ename->vla-object entity))
  (setq color (vla-get-color obj))
  color
)

(defun split-string (str delimiter / pos result)
  ;; 分割字符串
  (while (setq pos (vl-string-search delimiter str))
    (setq result (cons (substr str 1 pos) result))
    (setq str (substr str (+ pos 2)))
  )
  (reverse (cons str result))
)

(defun trim (str)
  ;; 去除字符串首尾空格
  (while (and (> (strlen str) 0) (= (substr str 1 1) " "))
    (setq str (substr str 2))
  )
  (while (and (> (strlen str) 0) (= (substr str (strlen str)) " "))
    (setq str (substr str 1 (1- (strlen str))))
  )
  str
)

(defun is-number (str / result i ch)
  ;; 检查字符串是否为数字
  (setq result T)
  (if (> (strlen str) 0)
    (progn
      (setq i 1)
      (while (and result (<= i (strlen str)))
        (setq ch (substr str i 1))
        (if (not (or (<= 48 (ascii ch) 57) 
                     (and (= i 1) (or (= ch "-") (= ch "+")))))
          (setq result nil)
        )
        (setq i (1+ i))
      )
    )
    (setq result nil)
  )
  result
)

;; =============================================
;; 程序加载提示
;; =============================================

(princ "\n========================================")
(princ "\n多颜色选择工具已加载成功！")
(princ "\n可用命令:")
(princ "\n  MCQ   - 基础版多颜色选择")
(princ "\n  MCQ2  - 增强版多颜色选择(带颜色提示)")
(princ "\n  GetColor - 查询对象颜色代码")
(princ "\n========================================")
(princ)
