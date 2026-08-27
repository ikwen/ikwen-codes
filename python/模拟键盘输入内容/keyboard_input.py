#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import sys
import pyautogui

def type_text_directly(text):
    """
    直接模拟键盘输入（逐字符输入，不使用剪贴板）
    """
    print("\n开始模拟键盘输入...")
    print("请勿移动鼠标或按键盘！")
    
    # 设置输入参数
    pyautogui.PAUSE = 0.02
    pyautogui.FAILSAFE = True  # 鼠标移动到左上角可中断
    
    # 分块输入
    chunk_size = 100
    total = len(text)
    
    for i in range(0, total, chunk_size):
        chunk = text[i:i+chunk_size]
        pyautogui.typewrite(chunk, interval=0.01)
        
        # 显示进度
        progress = min(100, int((i + chunk_size) / total * 100))
        print(f"\r输入进度: {progress}%", end='')
    
    print("\n✅ 键盘输入完成！")

def main():
    print("="*60)
    print("键盘模拟输入工具")
    print("="*60)
    
    # 提示用户输入要模拟的文字
    print("\n请输入要模拟输入的文字（支持多行，输入完成后按 Enter）：")
    print("提示：如果要输入多行，请先复制好，然后粘贴到这里")
    print("-"*60)
    
    # 读取用户输入（支持多行）
    lines = []
    while True:
        try:
            line = input()
            if line.strip() == "":  # 如果输入空行
                # 检查是否真的想结束
                confirm = input("\n是否结束输入？(y/n): ").strip().lower()
                if confirm == 'y':
                    break
                else:
                    print("继续输入（输入空行结束）：")
                    continue
            lines.append(line)
        except KeyboardInterrupt:
            print("\n\n输入被取消")
            sys.exit(0)
        except EOFError:
            break
    
    # 如果没有输入内容
    if not lines:
        print("错误：没有输入任何内容")
        return
    
    # 组合所有行
    content = '\n'.join(lines)
    
    # 显示输入的内容信息
    print("\n" + "="*60)
    print(f"已接收 {len(content)} 个字符，{len(lines)} 行")
    print("\n内容预览（前200个字符）：")
    preview = content[:200]
    if len(content) > 200:
        preview += "..."
    print(preview)
    print("="*60)
    
    # 倒计时
    print("\n⚠️  请在5秒内将焦点切换到目标终端窗口！")
    print("倒计时开始...")
    
    for i in range(5, 0, -1):
        print(f"{i}...")
        time.sleep(1)
    
    # 开始输入
    type_text_directly(content)
    
    print("\n✅ 全部完成！")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n发生错误：{e}")
        input("按 Enter 键退出...")
