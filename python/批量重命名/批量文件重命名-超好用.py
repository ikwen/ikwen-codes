# -*- coding: utf-8 -*-
import os

def rename_files_in_directory():
    # 输入目录路径，直接回车则使用当前目录
    directory = input("Enter the directory path (press Enter for current directory-请输入目录路径，按回车直接使用当前目录！): ").strip()
    if not directory:
        directory = os.getcwd()
    
    if not os.path.isdir(directory):
        print("Error: Invalid directory path")
        return

    # 输入要替换的字符
    old_str = input("Enter the text to be replaced:-请输入要替换的字符： ")
    new_str = input("Enter the new text:-请输入新字符： ")

    # 遍历目录中的文件
    for filename in os.listdir(directory):
        old_path = os.path.join(directory, filename)
        
        if os.path.isfile(old_path):
            # 替换文件名中的指定字符串
            if old_str in filename:
                new_name = filename.replace(old_str, new_str)
                new_path = os.path.join(directory, new_name)
                
                try:
                    os.rename(old_path, new_path)
                    print(f"Renamed: {filename} -> {new_name}")
                except Exception as e:
                    print(f"Error renaming {filename}: {str(e)}")
            else:
                print(f"Skipped: {filename} (no '{old_str}' found)")

if __name__ == "__main__":
    rename_files_in_directory()
