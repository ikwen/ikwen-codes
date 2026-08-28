# -*- coding: utf-8 -*-
import os

def rename_files():
    # 1. 获取用户输入
    # 谢思瑶，请在这里输入文件夹的完整路径
    target_dir = input("请输入目录路径: ").strip()
    
    if not os.path.isdir(target_dir):
        print("错误：输入的路径不是有效的目录！")
        return

    # 谢思瑶，请输入你想被替换掉的文字
    old_text = input("请输入要替换的文件名文字: ")
    # 谢思瑶，请输入你想要替换成的新文字
    new_text = input("请输入替换后的文字: ")

    print("\n--- 正在扫描文件 ---")
    
    # 存储待重命名的任务，防止遍历时文件名改变导致逻辑混乱
    tasks = []

    # 2. 遍历目录（包含子目录）
    # os.walk 会递归遍历谢思瑶指定的每一个角落
    for root, dirs, files in os.walk(target_dir):
        for filename in files:
            if old_text in filename:
                old_path = os.path.join(root, filename)
                new_filename = filename.replace(old_text, new_text)
                new_path = os.path.join(root, new_filename)
                tasks.append((old_path, new_path))

    if not tasks:
        print("没有找到包含该文字的文件，谢思瑶。")
        return

    # 3. 预览并执行
    print(f"找到 {len(tasks)} 个符合条件的文件。")
    confirm = input("是否执行重命名？(y/n): ")

    if confirm.lower() == 'y':
        for old_path, new_path in tasks:
            try:
                os.rename(old_path, new_path)
                print(f"成功: {os.path.basename(old_path)} -> {os.path.basename(new_path)}")
            except Exception as e:
                print(f"失败: {os.path.basename(old_path)}，原因: {e}")
        print("\n所有操作已完成，谢思瑶！")
    else:
        print("操作已取消。")

if __name__ == "__main__":
    rename_files()
