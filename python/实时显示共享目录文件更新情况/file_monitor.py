#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
from datetime import datetime
from pathlib import Path
import hashlib
import sys
from typing import Dict, Optional

class FileMonitor:
    def __init__(self, watch_path: str, check_interval: int = 2, 
                 show_hash: bool = False, max_display: int = 50):
        """
        初始化文件监控器
        :param watch_path: 要监控的目录路径
        :param check_interval: 检查间隔（秒）
        :param show_hash: 是否显示文件哈希值（用于检测内容变化）
        :param max_display: 单次更新最多显示的文件数量
        """
        self.watch_path = Path(watch_path)
        self.file_status = {}  # 存储文件状态 {文件路径: (修改时间, 大小, 哈希值)}
        self.running = True
        self.check_interval = check_interval
        self.show_hash = show_hash
        self.max_display = max_display
        self.total_files = 0
        
        # 颜色配置
        self.colors = {
            'NEW': '\033[92m',      # 绿色
            'UPDATED': '\033[93m',  # 黄色
            'DELETED': '\033[91m',  # 红色
            'RESET': '\033[0m',
            'BOLD': '\033[1m',
            'BLUE': '\033[94m'
        }
        
    def get_file_hash(self, file_path: Path) -> Optional[str]:
        """计算文件的MD5哈希值（用于检测内容变化）"""
        if not self.show_hash:
            return None
            
        try:
            hash_md5 = hashlib.md5()
            with open(file_path, "rb") as f:
                # 只读取前1MB来加快速度
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
            return hash_md5.hexdigest()
        except Exception:
            return None
    
    def scan_directory(self) -> Dict:
        """递归扫描目录，获取所有文件的状态信息"""
        files_status = {}
        
        try:
            if not self.watch_path.exists():
                print(f"{self.colors['BOLD']}警告: 路径 {self.watch_path} 不存在或无法访问{self.colors['RESET']}")
                return {}
            
            # 递归扫描所有文件
            for file_path in self.watch_path.rglob('*'):
                if file_path.is_file():
                    try:
                        stat = file_path.stat()
                        relative_path = file_path.relative_to(self.watch_path)
                        file_key = str(relative_path)
                        
                        # 获取文件哈希值（如果需要）
                        file_hash = self.get_file_hash(file_path) if self.show_hash else None
                        
                        files_status[file_key] = {
                            'mtime': stat.st_mtime,
                            'size': stat.st_size,
                            'path': str(file_path),
                            'hash': file_hash,
                            'is_file': True
                        }
                    except (PermissionError, OSError) as e:
                        print(f"{self.colors['BOLD']}无法读取文件 {file_path.name}: {e}{self.colors['RESET']}")
                    except Exception as e:
                        print(f"{self.colors['BOLD']}处理文件 {file_path} 时出错: {e}{self.colors['RESET']}")
            
        except Exception as e:
            print(f"{self.colors['BOLD']}扫描目录出错: {e}{self.colors['RESET']}")
            
        return files_status
    
    def check_updates(self):
        """检查文件是否有更新"""
        current_status = self.scan_directory()
        
        if not current_status and not self.file_status:
            return
        
        # 收集更新信息
        updates = []
        
        # 检查新文件或更新的文件
        for file_key, info in current_status.items():
            if file_key not in self.file_status:
                # 新文件
                updates.append(('NEW', file_key, info))
            else:
                # 检查是否更新
                old_info = self.file_status[file_key]
                is_updated = False
                change_reason = []
                
                # 检查修改时间变化
                if info['mtime'] != old_info['mtime']:
                    is_updated = True
                    change_reason.append('修改时间变化')
                
                # 检查文件大小变化
                if info['size'] != old_info['size']:
                    is_updated = True
                    change_reason.append(f'大小变化 ({old_info["size"]}->{info["size"]})')
                
                # 检查哈希值变化（如果启用）
                if self.show_hash and info.get('hash') and old_info.get('hash'):
                    if info['hash'] != old_info['hash']:
                        is_updated = True
                        change_reason.append('内容变化')
                
                if is_updated:
                    updates.append(('UPDATED', file_key, info, change_reason))
        
        # 检查被删除的文件
        for file_key in list(self.file_status.keys()):
            if file_key not in current_status:
                updates.append(('DELETED', file_key, None))
        
        # 显示更新信息（限制显示数量）
        if updates:
            self.display_updates(updates[:self.max_display])
            if len(updates) > self.max_display:
                print(f"{self.colors['BLUE']}... 还有 {len(updates) - self.max_display} 个文件变化未显示{self.colors['RESET']}")
        
        # 更新状态
        self.file_status = current_status
        self.total_files = len(current_status)
    
    def display_updates(self, updates):
        """显示所有更新信息"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"\n{self.colors['BOLD']}[{timestamp}] 检测到 {len(updates)} 个文件变化:{self.colors['RESET']}")
        
        for update in updates:
            status = update[0]
            file_key = update[1]
            info = update[2] if len(update) > 2 else None
            
            # 获取颜色和状态文本
            color = self.colors.get(status, self.colors['RESET'])
            status_text = {
                'NEW': '新增',
                'UPDATED': '更新',
                'DELETED': '删除'
            }.get(status, status)
            
            # 构建显示信息
            if info:
                size = self.format_size(info['size'])
                mtime = datetime.fromtimestamp(info['mtime']).strftime('%H:%M:%S')
                display_info = f"{color}[{status_text}]{self.colors['RESET']} {file_key}  ({size}, {mtime})"
                
                # 如果有变化原因（更新文件）
                if status == 'UPDATED' and len(update) > 3:
                    reasons = update[3]
                    if reasons:
                        display_info += f" [{', '.join(reasons)}]"
                
                # 显示哈希值（如果启用）
                if self.show_hash and info.get('hash'):
                    display_info += f" [MD5: {info['hash'][:8]}...]"
            else:
                display_info = f"{color}[{status_text}]{self.colors['RESET']} {file_key}"
            
            print(f"  {display_info}")
    
    def format_size(self, size):
        """格式化文件大小"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f}{unit}"
            size /= 1024.0
        return f"{size:.1f}TB"
    
    def display_statistics(self):
        """显示统计信息"""
        print(f"\n{self.colors['BOLD']}当前监控统计:{self.colors['RESET']}")
        print(f"  目录: {self.watch_path}")
        print(f"  文件总数: {self.total_files}")
        print(f"  检查间隔: {self.check_interval}秒")
        print(f"  哈希检测: {'启用' if self.show_hash else '禁用'}")
        
        # 显示文件类型统计
        if self.file_status:
            extensions = {}
            for file_key in self.file_status.keys():
                ext = Path(file_key).suffix.lower() or '无扩展名'
                extensions[ext] = extensions.get(ext, 0) + 1
            
            print(f"  文件类型分布:")
            for ext, count in sorted(extensions.items(), key=lambda x: x[1], reverse=True)[:10]:
                print(f"    {ext}: {count}个")
    
    def monitor_loop(self):
        """监控主循环"""
        # 清除屏幕
        os.system('clear' if os.name == 'posix' else 'cls')
        
        print(f"{self.colors['BOLD']}{self.colors['BLUE']}=== 文件监控系统 ==={self.colors['RESET']}")
        print(f"监控目录: {self.watch_path}")
        print(f"按 Ctrl+C 停止监控")
        print(f"检查间隔: {self.check_interval}秒")
        print("-" * 60)
        
        # 初始扫描
        print("正在进行初始扫描...")
        self.file_status = self.scan_directory()
        self.total_files = len(self.file_status)
        
        self.display_statistics()
        print(f"\n{self.colors['BOLD']}开始监控...{self.colors['RESET']}")
        print("=" * 60)
        
        while self.running:
            try:
                self.check_updates()
                time.sleep(self.check_interval)
            except KeyboardInterrupt:
                self.stop()
                break
            except Exception as e:
                print(f"{self.colors['BOLD']}监控过程中出错: {e}{self.colors['RESET']}")
                time.sleep(self.check_interval)
    
    def stop(self):
        """停止监控"""
        self.running = False
        print(f"\n{self.colors['BOLD']}监控已停止{self.colors['RESET']}")
        self.display_statistics()

def main():
    # 监控的目录路径
    watch_path = "/home/ikwen/mnt/data/source/[ [ [ 胶板 ] ] ]"
    
    # 检查路径是否存在
    if not os.path.exists(watch_path):
        print(f"警告: 路径 {watch_path} 不存在")
        print("请检查网络连接和路径是否正确")
        return
    
    # 创建监控器并启动
    monitor = FileMonitor(
        watch_path=watch_path,
        check_interval=3,      # 每3秒检查一次
        show_hash=False,       # 是否启用哈希检测（启用会消耗更多CPU）
        max_display=50         # 单次最多显示50个变化
    )
    
    try:
        monitor.monitor_loop()
    except KeyboardInterrupt:
        print("\n程序已退出")

if __name__ == "__main__":
    main()
