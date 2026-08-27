import pandas as pd
import os
import sys
from pathlib import Path
from tkinter import Tk, filedialog
import re

class ExcelFilter:
    def __init__(self):
        self.df = None
        self.file_path = None
        self.filters = []  # 存储筛选条件 [(列名, 关键字), ...]
        self.output_columns = []
        
    def get_file_path(self):
        """获取文件路径 - 支持拖拽"""
        print("\n" + "="*60)
        print("请将Excel文件拖入此窗口，然后按Enter键")
        print("(或者直接输入文件路径)")
        print("="*60)
        
        while True:
            file_input = input("\n文件路径: ").strip().strip('"').strip("'")
            
            if not file_input:
                print("❌ 未输入文件路径，请重新输入")
                continue
                
            # 检查文件是否存在
            if os.path.exists(file_input):
                self.file_path = file_input
                return True
            else:
                print(f"❌ 文件不存在: {file_input}")
                print("请重新输入正确的文件路径")
    
    def load_excel(self):
        """加载Excel文件"""
        try:
            print(f"\n📂 正在加载文件: {self.file_path}")
            self.df = pd.read_excel(self.file_path)
            print(f"✅ 加载成功! 共 {len(self.df)} 行, {len(self.df.columns)} 列")
            print(f"\n📋 可用的列:")
            for i, col in enumerate(self.df.columns, 1):
                print(f"  {i}. {col}")
            return True
        except Exception as e:
            print(f"❌ 加载文件失败: {e}")
            return False
    
    def add_filter(self):
        """添加筛选条件"""
        print("\n" + "-"*40)
        print("添加筛选条件")
        print("-"*40)
        
        # 显示可用的列
        print("\n可用的列:")
        for i, col in enumerate(self.df.columns, 1):
            print(f"  {i}. {col}")
        
        # 输入列序号或列名
        while True:
            col_input = input("\n请输入列序号或列名 (或输入 '完成' 结束): ").strip()
            
            if col_input.lower() == '完成':
                return False
            
            # 尝试作为序号
            try:
                idx = int(col_input) - 1
                if 0 <= idx < len(self.df.columns):
                    col_name = self.df.columns[idx]
                    print(f"✓ 已选择列: {col_name}")
                    break
                else:
                    print(f"❌ 序号超出范围 (1-{len(self.df.columns)})")
                    continue
            except ValueError:
                # 作为列名
                if col_input in self.df.columns:
                    col_name = col_input
                    break
                else:
                    print(f"❌ 列 '{col_input}' 不存在，请重新输入")
                    print("提示: 可以使用列序号 (1, 2, 3...)")
        
        # 输入关键字
        keyword = input("请输入包含的关键字: ").strip()
        if not keyword:
            print("❌ 关键字不能为空")
            return True
        
        # 添加到筛选条件列表
        self.filters.append((col_name, keyword))
        print(f"✅ 已添加筛选条件: {col_name} 包含 '{keyword}'")
        
        # 显示当前筛选条件
        self.show_filters()
        return True
    
    def show_filters(self):
        """显示当前所有筛选条件"""
        if not self.filters:
            print("\n📌 当前没有筛选条件")
            return
        
        print("\n📌 当前筛选条件:")
        for i, (col, keyword) in enumerate(self.filters, 1):
            print(f"  {i}. {col} 包含 '{keyword}'")
    
    def apply_filters(self):
        """应用所有筛选条件"""
        if not self.filters:
            print("⚠️ 没有筛选条件，将导出全部数据")
            return self.df.copy()
        
        filtered_df = self.df.copy()
        
        for col, keyword in self.filters:
            # 将列转换为字符串类型进行筛选
            filtered_df = filtered_df[filtered_df[col].astype(str).str.contains(keyword, case=False, na=False)]
            
            if len(filtered_df) == 0:
                print(f"⚠️ 筛选条件 '{col} 包含 {keyword}' 没有匹配结果")
                break
        
        print(f"\n📊 筛选结果: {len(filtered_df)} 行 (原始 {len(self.df)} 行)")
        return filtered_df
    
    def select_output_columns(self):
        """选择要输出的列"""
        print("\n" + "-"*40)
        print("选择要导出的列")
        print("-"*40)
        print("\n可用的列:")
        for i, col in enumerate(self.df.columns, 1):
            print(f"  {i}. {col}")
        
        print("\n💡 提示: 使用英文逗号分隔，例如: 1,3,15")
        print("输入要导出的列序号 (用英文逗号分隔，例如: 1,3,15)")
        print("或输入 'all' 导出所有列")
        print("或输入列名 (用英文逗号分隔，例如: 设备资产编码,设备类型,位置)")
        
        while True:
            col_input = input("\n请输入: ").strip()
            
            # 检查是否包含中文逗号，提醒用户
            if '，' in col_input:
                print("⚠️ 检测到中文逗号 '，' ，请使用英文逗号 ','")
                continue
            
            if col_input.lower() == 'all':
                self.output_columns = list(self.df.columns)
                print(f"✅ 将导出所有列")
                return True
            
            # 尝试解析
            selected_cols = []
            parts = [p.strip() for p in col_input.split(',')]
            
            for part in parts:
                # 尝试作为序号
                try:
                    idx = int(part) - 1
                    if 0 <= idx < len(self.df.columns):
                        selected_cols.append(self.df.columns[idx])
                        print(f"  ✓ 序号 {part} -> {self.df.columns[idx]}")
                    else:
                        print(f"❌ 序号 {part} 超出范围 (1-{len(self.df.columns)})")
                        continue
                except ValueError:
                    # 作为列名
                    if part in self.df.columns:
                        selected_cols.append(part)
                        print(f"  ✓ 列名: {part}")
                    else:
                        print(f"❌ 列 '{part}' 不存在")
            
            if selected_cols:
                self.output_columns = selected_cols
                print(f"\n✅ 已选择 {len(self.output_columns)} 列:")
                for i, col in enumerate(self.output_columns, 1):
                    print(f"  {i}. {col}")
                return True
            else:
                print("❌ 未选择任何有效的列，请重新输入")
    
    def sort_data(self, df):
        """排序数据"""
        print("\n" + "-"*40)
        print("排序设置")
        print("-"*40)
        
        sort_choice = input("\n是否需要进行排序? (y/n): ").strip().lower()
        if sort_choice != 'y':
            return df
        
        # 显示当前数据的所有列（已经筛选过的列）
        print("\n可用的列:")
        for i, col in enumerate(df.columns, 1):
            print(f"  {i}. {col}")
        
        # 选择排序列
        while True:
            col_input = input("\n请输入排序依据的列序号或列名: ").strip()
            
            # 尝试作为序号
            try:
                idx = int(col_input) - 1
                if 0 <= idx < len(df.columns):
                    sort_col = df.columns[idx]
                    print(f"✓ 已选择排序列: {sort_col}")
                    break
                else:
                    print(f"❌ 序号超出范围 (1-{len(df.columns)})")
                    continue
            except ValueError:
                # 作为列名
                if col_input in df.columns:
                    sort_col = col_input
                    break
                else:
                    print(f"❌ 列 '{col_input}' 不存在，请重新输入")
        
        # 选择排序顺序
        while True:
            order = input("排序顺序 (a: 升序, d: 降序): ").strip().lower()
            if order in ['a', 'd', '升序', '降序']:
                break
            else:
                print("❌ 请输入 'a' (升序) 或 'd' (降序)")
        
        ascending = order in ['a', '升序']
        
        # 执行排序
        try:
            # 对数值列特殊处理
            if pd.api.types.is_numeric_dtype(df[sort_col]):
                sorted_df = df.sort_values(by=sort_col, ascending=ascending)
            else:
                # 字符串列排序
                sorted_df = df.sort_values(by=sort_col, ascending=ascending, na_position='last')
            
            print(f"✅ 排序完成! 按 '{sort_col}' {'升序' if ascending else '降序'} 排序")
            return sorted_df
        except Exception as e:
            print(f"❌ 排序失败: {e}")
            return df
    
    def save_file(self):
        """保存文件"""
        print("\n" + "-"*40)
        print("选择保存位置")
        print("-"*40)
        
        # 生成默认文件名
        original_name = Path(self.file_path).stem
        default_name = f"{original_name}_筛选结果.xlsx"
        
        print(f"\n默认文件名: {default_name}")
        print("请选择保存位置...")
        
        # 使用tkinter选择保存位置
        try:
            root = Tk()
            root.withdraw()  # 隐藏主窗口
            
            # 打开保存对话框
            save_path = filedialog.asksaveasfilename(
                title="保存Excel文件",
                defaultextension=".xlsx",
                filetypes=[("Excel files", "*.xlsx"), ("All files", "*.*")],
                initialfile=default_name
            )
            
            root.destroy()
            
            if not save_path:  # 用户取消
                print("❌ 已取消保存")
                return False
            
            return save_path
            
        except Exception as e:
            print(f"⚠️ 无法打开图形界面，使用命令行方式")
            # 备用方案：使用当前目录
            save_path = os.path.join(os.getcwd(), default_name)
            print(f"将保存到: {save_path}")
            return save_path
    
    def export_excel(self, filtered_df, save_path):
        """导出Excel文件"""
        try:
            # 筛选要导出的列
            if self.output_columns:
                # 确保选择的列都存在
                available_cols = [col for col in self.output_columns if col in filtered_df.columns]
                if available_cols:
                    export_df = filtered_df[available_cols]
                    print(f"\n📋 将导出以下列:")
                    for i, col in enumerate(available_cols, 1):
                        print(f"  {i}. {col}")
                else:
                    print("⚠️ 选择的列都不存在，将导出所有列")
                    export_df = filtered_df
            else:
                export_df = filtered_df
            
            # 保存文件
            export_df.to_excel(save_path, index=False)
            print(f"\n✅ 导出成功!")
            print(f"📁 文件保存至: {save_path}")
            print(f"📊 共 {len(export_df)} 行, {len(export_df.columns)} 列")
            return True
            
        except Exception as e:
            print(f"❌ 导出失败: {e}")
            return False
    
    def run(self):
        """主程序流程"""
        print("\n" + "="*60)
        print("     Excel 筛选工具")
        print("="*60)
        
        # 1. 获取文件
        if not self.get_file_path():
            return
        
        # 2. 加载Excel
        if not self.load_excel():
            return
        
        # 3. 添加筛选条件
        print("\n" + "="*60)
        print("添加筛选条件 (输入 '完成' 结束添加)")
        print("="*60)
        
        while True:
            if not self.add_filter():
                break
        
        # 4. 应用筛选
        print("\n" + "="*60)
        print("正在应用筛选...")
        print("="*60)
        
        filtered_df = self.apply_filters()
        
        if len(filtered_df) == 0:
            print("\n⚠️ 筛选结果为空，是否继续导出?")
            choice = input("继续? (y/n): ").strip().lower()
            if choice != 'y':
                print("已取消操作")
                return
        
        # 5. 选择要导出的列（提前到排序之前）
        self.select_output_columns()
        
        # 6. 排序
        filtered_df = self.sort_data(filtered_df)
        
        # 7. 选择保存位置并导出
        save_path = self.save_file()
        if save_path:
            self.export_excel(filtered_df, save_path)
        
        print("\n" + "="*60)
        print("程序结束")
        print("="*60)

def main():
    try:
        app = ExcelFilter()
        app.run()
    except KeyboardInterrupt:
        print("\n\n⚠️ 用户中断程序")
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")
    finally:
        input("\n按 Enter 键退出...")

if __name__ == "__main__":
    main()
