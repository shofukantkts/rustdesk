# RustDesk 构建缓存（Dropbox / dbxcli 共享）

> 跨机器共享编译缓存，加速新设备上的 RustDesk 构建。

## 资产清单（Dropbox 路径 `/rustdesk-build-cache/`）

| 文件 | 大小 | 内容 | 跨机器可用性 |
|---|---|---|---|
| `vcpkg-installed-x64-linux.tar.gz` | 50 MB | vcpkg C 依赖静态库（libaom / libavcodec / libvpx / libyuv / libjpeg / libopus 等，含头文件） | ✅ 完全可复用（C 静态库无指纹问题） |
| `rustdesk-unattended-wayland-1.5.1.deb` | 25 MB | 修复 uinput 光标瞬移/居中的发布包（Wayland） | ✅ 直接安装 |

## 从 Dropbox 获取（dbxcli）

```bash
# vcpkg 依赖缓存
dbxcli get /rustdesk-build-cache/vcpkg-installed-x64-linux.tar.gz .

# 发布包
dbxcli get /rustdesk-build-cache/rustdesk-unattended-wayland-1.5.1.deb .
```

`dbxcli` 安装与登录：

```bash
# 下载 dbxcli（GitHub release），或直接安装二进制
curl -L -o dbxcli https://github.com/dropbox/dbxcli/releases/latest/download/dbxcli-linux-amd64
chmod +x dbxcli && sudo mv dbxcli /usr/local/bin/
dbxcli login   # 浏览器授权
```

## 使用 vcpkg 缓存

```bash
tar xzf vcpkg-installed-x64-linux.tar.gz -C ~/vcpkg/installed/
# 包内为 x64-linux/ 目录，与 vcpkg 布局一致（include/ lib/ share/ ...）
export VCPKG_ROOT=~/vcpkg
```

之后编译 RustDesk 时 C 依赖直接复用，不再重新编译：

```bash
cd rustdesk-src
cargo build --locked --release --features drm,drm-wake   # 或 build.py --flutter --drm
```

## 更新缓存（源机器内容变化后）

```bash
# 压缩
tar czf vcpkg-installed-x64-linux.tar.gz -C ~/vcpkg/installed x64-linux
# 上传覆盖
dbxcli put vcpkg-installed-x64-linux.tar.gz /rustdesk-build-cache/
```

## 为什么只共享 vcpkg（而不是整个 target/）

- `target/release/deps`（4.3 GB / 1395 个 rlib）的缓存命中依赖 **Cargo fingerprint**：`rustc` 版本、`features`、`target` 三元组、`profile`（lto / codegen-units）、**checkout 路径**、`rustflags` 哈希。两台机器任一不同 → 缓存不命中 → 白下载。
- vcpkg 的 C 静态库是**内容无关**的产物，跨机器、跨路径直接可用，安全可共享。
- 想进一步共享 Rust 依赖层：装 **sccache**（`cargo install sccache`），把缓存目录指向共享位置：

```bash
export SCCACHE_DIR=/home/sfk/Dropbox/sccache   # 或 NAS 挂载目录
# ~/.cargo/config.toml
# [build]
# rustc-wrapper = "sccache"
```

注意：RustDesk 主 crate（librustdesk，14.6 万行，`codegen-units=1` + `lto=true`）无法被 sccache 缓存，每次改代码仍需全量重编约 2-5 分钟；sccache 只加速 1395 个依赖 crate。

## 注意事项

- RustDesk 编译依赖系统包：`libvpx-dev` 等可用 vcpkg 替代；若使用 vcpkg 之外的系统依赖，请先 `apt install` 对应开发包。
- 上传/下载大文件时如遇超时，dbxcli 支持断点续传（upload session），可重试。
- 更新 vcpkg 版本（`vcpkg update` / 换 triplet）后缓存可能不再匹配，重新上传即可。
