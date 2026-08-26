(defun c:MCQ (/ color-str color-list ss selection-type default-colors input)
  (vl-load-com)
  
  ;; 1. 定义你的常用颜色
  (setq default-colors "114;44;250;177;230;242")
  
  ;; 2. 选择对象
  (princ "\n选择对象 [直接回车选择所有图形]: ")
  (setq ss (ssget))
  
  (if (not ss)
    (progn
      (setq ss (ssget "_X"))
      (setq selection-type "所有图形")
    )
  )
  
  (if ss
    (progn
      ;; 3. 使用 initget 定义关键字 A
      (initget "A")
      (setq input (getstring (strcat "\n输入颜色代码或 [使用预设(A)] <" default-colors ">: ")))
      
      ;; 4. 判断输入：如果输入 A、a 或者直接回车，都用默认值
      (if (or (= (strcase input) "A") (= input ""))
        (setq color-str default-colors)
        (setq color-str input)
      )
      
      ;; 5. 解析并筛选
      (setq color-list (parse-colors color-str))
      
      (if (and color-list (> (length color-list) 0))
        (progn
          (setq ss (filter-by-colors ss color-list))
          
          (if (> (sslength ss) 0)
            (progn
              (princ (strcat "\n已成功选中 " (itoa (sslength ss)) " 个匹配对象。"))
              (sssetfirst nil ss)
            )
            (princ (strcat "\n未找到颜色为 " color-str " 的对象。请检查颜色索引。"))
          )
        )
        (princ "\n颜色输入格式错误！")
      )
    )
    (princ "\n没有选择任何对象。")
  )
  (princ)
)

;; ======================================================
;; 下面是必不可少的工具函数，请务必全部复制到文件末尾
;; ======================================================

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
  (if (and ss (> (sslength ss) 0))
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq entity (ssname ss i))
        (setq color (get-entity-color entity))
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
  ;; 获取对象的颜色 (含随层判断)
  (setq obj (vlax-ename->vla-object entity))
  (setq color (vla-get-color obj))
  ;; 如果颜色是 256 (Bylayer)，可以根据需要在这里穿透获取图层颜色
  ;; 目前按你要求的直接颜色代码逻辑运行
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
  ;; 去除空格
  (while (and (> (strlen str) 0) (= (substr str 1 1) " "))
    (setq str (substr str 2))
  )
  (while (and (> (strlen str) 0) (= (substr str (strlen str)) " "))
    (setq str (substr str 1 (1- (strlen str))))
  )
  str
)

(defun is-number (str / result i ch)
  ;; 检查是否为数字
  (setq result T)
  (if (> (strlen str) 0)
    (progn
      (setq i 1)
      (while (and result (<= i (strlen str)))
        (setq ch (substr str i 1))
        (if (not (or (<= 48 (ascii ch) 57) (and (= i 1) (or (= ch "-") (= ch "+")))))
          (setq result nil)
        )
        (setq i (1+ i))
      )
    )
    (setq result nil)
  )
  result
)

(princ "\n全部工具函数已就绪，MCQ 现在可以正常使用了。")
(princ)
