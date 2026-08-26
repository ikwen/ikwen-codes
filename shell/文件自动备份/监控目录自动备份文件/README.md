# rsync3.sh  运行后会自动监控目录： /home/ikwen/mnt/data/source
当此目录有文件“修改”，“删除”，“新增”后，都会自动备份到 /home/ikwen/mnt/data/backup/
，如果是删除文件，可以到：/home/ikwen/mnt/data/history 文件夹用：
find /home/ikwen/mnt/data/backup -type f -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2- > /home/ikwen/shared/newest_files.txt


查找 。
找到后的内容会在这： /home/ikwen/shared/newest_files.txt


接下来建议你从以下几个方向紧急抢救一下：
检查其他备份源或客户端缓存：

看看操作这台文件的同事电脑上（比如回收站、微信/聊天发送的临时文件、或者本地临时缓存目录），有没有在修改之前留下的原始文件副本。

如果你们平时有别的电脑或服务器也做过转存或快照，可以去那边碰碰运气。

立刻给现有的同步脚本加上历史版本机制：
吸取这次的教训，为了防止以后再发生这种“错误覆盖无法找回”的情况，我们一定要把前面提到的 rsync 归档参数加上。

你可以把同步脚本调整为带有 --backup-dir 的版本：

这样做了之后，以后只要文件发生变动或被覆盖，被替换掉的旧文件都会自动备份到 history/时间戳/ 目录下。哪怕有人把花样改错了，你也能去历史文件夹里翻出修改前的“原版”，不会再出现无路可退的情况。


![运行效果](运行效果.bmp)