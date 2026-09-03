import json
import os
import sys
import time
import urllib.request


def sync_time():
    print(">>> 脚本启动成功，正在获取网络时间...", flush=True)

    # 1. 优先使用苏宁 HTTP 时间接口 (80/443端口，穿透性强)
    try:
        url = "https://quan.suning.com/getSysTime.do"
        req = urllib.request.Request(
            url, headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            # 返回格式类似: "2026-09-03 22:50:00"
            sys_time_str = data["sysTime2"]

            # 解析日期和时间
            dt_date, dt_time = sys_time_str.split(" ")
            print(f"成功获取网络时间: {sys_time_str}", flush=True)

            # 更新系统时间
            os.system(f"date {dt_date}")
            os.system(f"time {dt_time}")
            print(">>> 系统时间同步完成！", flush=True)
            return
    except Exception as e:
        print(f"苏宁 API 同步失败 ({e})，尝试备用方案...", flush=True)

    # 2. 备用：腾讯云 HTTP 时间接口
    try:
        url = "https://vv.video.qq.com/checktime?otype=json"
        req = urllib.request.Request(
            url, headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            content = resp.read().decode("utf-8")
            # 截取 json 字符串
            json_str = content[content.find("{") : content.rfind("}") + 1]
            data = json.loads(json_str)
            timestamp = int(data["t"])

            dt = time.localtime(timestamp)
            date_str = time.strftime("%Y-%m-%d", dt)
            time_str = time.strftime("%H:%M:%S", dt)

            print(
                f"成功获取网络时间: {date_str} {time_str}", flush=True
            )
            os.system(f"date {date_str}")
            os.system(f"time {time_str}")
            print(">>> 系统时间同步完成！", flush=True)
            return
    except Exception as e:
        print(f"腾讯云 API 同步失败: {e}", flush=True)


if __name__ == "__main__":
    sync_time()
