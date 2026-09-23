---

<img width="954" height="268" alt="image" src="https://github.com/user-attachments/assets/42b8e624-6502-4217-b7d8-17ff2aa164dc" />
<img width="450" height="216" alt="image" src="https://github.com/user-attachments/assets/73ec296c-9b23-416b-a324-8cac20829d30" />
<img width="653" height="685" alt="image" src="https://github.com/user-attachments/assets/b13bd3dd-d3a2-4ca8-aa43-661978d88e30" />

<!-- Theos 图片与命令部分 -->
<table style="width: 100%;">
<tr>
<td style="padding-right: 20px; width: 50%;">
    <img src="./theos.png" style="width: 100%; max-width: 400px; height: auto;" />
</td>
<td style="width: 50%; vertical-align: top;">
    <pre>

    终端执行 克隆 Theos 仓库
    git clone --recursive https://github.com/theos/theos.git

    将 Theos 的路径添加到环境变量中：
    方法一：
    终端执行 直接添加到 ~/theos

    export THEOS=~/theos
    export PATH=$THEOS/bin:$PATH

    终端执行 重新 加载配置：
    source ~/.zshrc

    另一种方法：
    终端执行 打开配置文件 .zshrc
    nano ~/.zshrc

    # Theos 配置  // theos文件夹 的本地路径
    export THEOS=/Users/pxx917144686/theos     

    之后；contron + X 是退出编辑； 按‘y’ 保存编辑退出！

    终端执行 重新 加载配置：
    source ~/.zshrc

</td>
</tr>
</table>

<hr style="border: 1px solid #ccc; margin: 30px 0;">

<!-- Theos 报错说明部分 -->
<details>
<summary> 👉  如果 theos 报错:ld: warning: -multiply_defined is obsolete </summary>

| **theos报错** | **解释** |
|----------|----------|
| **报错** | ld: warning: -multiply_defined is obsolete |
| **解释** | 为什么会出现这个问题？ |
| **原因** | 新版本的 Apple 链接器 (ld64) 不再推荐使用 `-multiply_defined`；Theos 为了兼容旧版本 iOS，才默认加入该选项。 |
| **解决** | 在文件 `theos/makefiles/targets/_common/darwin_tail.mk` 打开文件，搜索找到并删除 `-multiply_defined suppress` |

</details>

<hr style="border: 1px solid #ccc; margin: 30px 0;">
