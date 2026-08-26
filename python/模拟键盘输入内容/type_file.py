#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import pyautogui

def read_file_content(file_path):
    """读取文件内容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        return content
    except FileNotFoundError:
        print(f"错误：文件 '{file_path}' 不存在")
        sys.exit(1)
    except Exception as e:
        print(f"读取文件时出错：{e}")
        sys.exit(1)

def type_text_directly(text):
    """
    直接模拟键盘输入（逐字符输入，不使用剪贴板）
    """
    print("开始模拟键盘输入...")
    
    # 设置输入参数
    pyautogui.PAUSE = 0.02  # 每个字符之间的间隔
    pyautogui.FAILSAFE = True  # 鼠标移动到左上角可中断
    
    # 分块输入，避免一次性输入太多导致问题
    chunk_size = 100  # 每块100个字符
    total_chunks = (len(text) + chunk_size - 1) // chunk_size
    
    for i in range(0, len(text), chunk_size):
        chunk = text[i:i+chunk_size]
        # 使用typewrite逐字符输入
        pyautogui.typewrite(chunk, interval=0.01)
        
        # 显示进度
        progress = min(100, int((i + chunk_size) / len(text) * 100))
        print(f"\r输入进度: {progress}%", end='')
    
    print("\n✅ 键盘输入完成！")

def main():
    # 检查命令行参数
    if len(sys.argv) != 2:
        print("使用方法：python script.py <文件路径>")
        print("示例：python script.py my_text.txt")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    print(f"正在读取文件: {file_path}")
    content = read_file_content(file_path)
    
    if not content:
        print("警告：文件内容为空")
        return
    
    # 显示内容信息
    content_lines = content.split('\n')
    print(f"文件内容长度: {len(content)} 字符, {len(content_lines)} 行")
    print("\n准备输入以下内容（前100个字符）：")
    preview = content[:100]
    if len(content) > 100:
        preview += "..."
    print(preview)
    
    print("\n⚠️  请在5秒内将焦点切换到目标终端窗口！")
    print("倒计时开始...")
    
    # 倒计时
    for i in range(5, 0, -1):
        print(f"{i}...")
        time.sleep(1)
    
    print("\n开始输入！请勿移动鼠标或按键盘...")
    
    # 直接模拟键盘输入
    type_text_directly(content)
    
    print("\n✅ 全部完成！")

if __name__ == "__main__":
    main()
