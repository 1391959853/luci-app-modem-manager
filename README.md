
```markdown
# luci-app-modem-manager
OpenWrt/LEDE 下的一款功能全面的 4G/5G 模块管理插件，支持移远（Quectel）和广和通（Fibocom）等多款模块，提供状态监控、AT 命令调试、短信收发等一站式管理功能。
---
## ✨ 特性
- **📊 模块状态看板**  
  实时显示模块厂商、型号、IMEI、IMSI、固件版本、信号强度（带动态条和颜色分级）、运营商名称及图标（移动/联通/电信/广电）、SIM 卡状态、NAT 模式、模块温度等，一目了然。
- **⌨️ AT 命令调试**  
  通过 Web 界面直接发送 AT 命令，查看原始响应，方便调试和配置模块。
- **✉️ 短信管理**  
  支持发送短信、查看收件箱、删除短信（可扩展），满足基本短信收发需求。
- **🔌 多模块适配**  
  自动识别移远 EC20/EC25/RG200U-CN/724UG 及广和通 L720/L724 等模块，统一界面管理，无需额外配置。
- **🚀 驱动自动加载**  
  开机时自动检测模块并加载必要的内核驱动（usb-serial-option、qmi_wwan、cdc_ncm 等），无需联网即可使用。
- **🌐 顶级菜单**  
  插件独立置于 LuCI 顶级菜单“4/5G 模块”，与“系统”“网络”并列，操作便捷。
---
## 📦 支持的模块

| 厂商   | 型号                    | 协议支持       |
|--------|-------------------------|----------------|
| 移远   | EC20, EC25              | QMI / ECM      |
| 移远   | RG200U-CN               | NCM / RNDIS    |
| 移远   | 724UG                   | QMI / ECM      |
| 广和通 | L720, L724              | QMI / ECM      |

> 若你的模块不在列表中，可通过 ATI 命令或 USB ID 自动识别，一般也能正常工作。
---
## 🔧 依赖
安装本插件前，请确保 OpenWrt 系统已包含以下内核模块和用户态工具（插件会自动依赖并安装）：
- `kmod-usb-core`, `kmod-usb-serial`, `kmod-usb-serial-option`
- `kmod-usb-net`, `kmod-usb-net-cdc-ncm`, `kmod-usb-net-qmi-wwan`
- `comgt`, `comgt-ncm`, `sms-tool`, `picocom`
- `luci-lib-nixio`, `luci-lib-jsonc`
> 如果使用官方 OpenWrt 或 LEDE 固件，通常已包含上述大部分依赖。安装时会自动拉取缺失部分。
---

```
1. 刷新 LuCI 页面（或重启 uhttpd）。
方法二：从源码编译
1. 将本项目克隆到 OpenWrt 的 package/ 目录下：
   ```bash
   cd package/
   git clone https://github.com/1391959853/luci-app-modem-manager.git
   ```
2. 进入 OpenWrt 顶层目录，运行 make menuconfig，选中 LuCI → Applications → luci-app-modem-manager。
3. 编译固件或单独生成 IPK：
   ```bash
   make package/luci-app-modem-manager/compile V=s
   ```
4. 生成的 IPK 位于 bin/packages/...，安装即可。

---

🚀 使用方法
1. 模块连接
将 4G/5G 模块通过 USB 接口（如 Mini PCIe 转 USB 或直接板载）连接到路由器，并插入有效 SIM 卡，插上天线。
2. 进入管理界面
登录 LuCI，在顶部菜单找到 “4/5G 模块”，默认进入状态页。
📊 状态页
· 自动刷新（10 秒）模块状态，信号强度以彩色条和数值显示。
· 运营商名称旁会显示对应的图标（需提前放置图片）。
· 若检测到缺失驱动，会提示一键加载。
⌨️ AT 命令页
· 输入 AT 命令（如 ATI、AT+CSQ、AT+QCFG="nat"?），选择串口端口，点击执行。
· 下方输出区显示模块返回的原始响应。
✉️ 短信页
· 发送短信：填写号码和内容，点击发送。
· 收件箱：自动读取并展示短信列表，支持定时刷新（30 秒）。
---
❓ 常见问题
1. 安装后看不到菜单？
· 确保已安装 luci-compat（部分旧版本 LuCI 需要）。
· 尝试清除浏览器缓存或执行 rm -rf /tmp/luci-* 后刷新。
2. 状态页显示“加载失败”或无法获取信息？
· 检查模块是否已正确连接：执行 ls /dev/ttyUSB* 看是否有 ttyUSB 设备。
· 确认 AT 命令端口是否为 /dev/ttyUSB2（可通过 dmesg | grep ttyUSB 查看）。
· 若驱动缺失，点击“一键加载”按钮。
3. 信号强度始终为 0？
· 确保天线已接好。
· 检查 SIM 卡是否注册：在 AT 命令页发送 AT+CEREG?，应返回 1 或 5。
4. 温度显示“N/A”？
· 部分模块不支持 AT+QTEMP 命令，此为正常现象，不影响使用。
5. 短信无法发送或接收？
· 确保模块已设置短信文本模式（插件会自动设置）。
· 检查 SIM 卡短信中心号码是否正确。
---
📚 参考资料
· LuCI 官方文档
· 移远 AT 命令手册
· 广和通产品中心
---
🤝 贡献
欢迎提交 Issue 和 Pull Request！若有新模块适配或功能增强，请附上模块的 lsusb 输出和 ATI 响应。
---

---

Enjoy your 4G/5G connection! 🚀

```
