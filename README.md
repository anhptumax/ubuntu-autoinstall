# Cài phần mềm cần thiết cho Ubuntu

Một script bash, chạy sau khi cài Ubuntu xong. Không cần cấu hình gì.

Viết và kiểm thử trên **Ubuntu 26.04 LTS (resolute), amd64**.

## Dùng

Tải về, xem qua rồi chạy:

```bash
curl -fsSLO https://raw.githubusercontent.com/anhptumax/ubuntu-autoinstall/main/install-apps.sh && less install-apps.sh
```

```bash
chmod +x install-apps.sh && sudo ./install-apps.sh
```

Hoặc một dòng, nếu bạn tin nội dung script:

```bash
curl -fsSL https://raw.githubusercontent.com/anhptumax/ubuntu-autoinstall/main/install-apps.sh | sudo bash
```

Chạy lại bao nhiêu lần cũng được — cái gì đã có thì bỏ qua.

## Phần mềm được cài

| Phần mềm | Nguồn |
|---|---|
| Google Chrome | Kho apt chính chủ của Google |
| VLC | Kho Ubuntu |
| Codec đa phương tiện | `ubuntu-restricted-extras`, `libavcodec-extra`, GStreamer good/bad/ugly/libav |
| Discord | `.deb` chính chủ, dự phòng snap |
| Telegram Desktop | Snap của Telegram FZ-LLC |
| ibus-bamboo (bộ gõ tiếng Việt) | PPA `bamboo-engine/ibus-bamboo` |
| LocalSend | `.deb` từ GitHub Releases, dự phòng flatpak/snap |
| RustDesk | `.deb` bản ổn định từ GitHub Releases |

Script còn tự làm mấy việc lặt vặt:

- Đặt **ibus + Bamboo** làm nguồn nhập mặc định cho mọi user (qua dconf system database — vẫn đổi lại được trong Settings).
- Mở cổng **53317** trên `ufw` cho LocalSend, nếu tường lửa đang bật.
- Trả lời sẵn EULA của `ttf-mscorefonts-installer` để không bị treo giữa chừng.
- Chờ mạng và thử lại `apt update` nếu lần đầu hỏng.
- Chờ tối đa 10 phút nếu `unattended-upgrades` đang giữ khoá dpkg.

## Chỉ cài vài thứ

```bash
sudo ./install-apps.sh chrome rustdesk
```

```bash
./install-apps.sh --list
```

```
apt          VLC, codec đa phương tiện, ibus
chrome       Google Chrome
telegram     Telegram Desktop
discord      Discord
ibus-bamboo  Bộ gõ tiếng Việt ibus-bamboo
localsend    LocalSend
rustdesk     RustDesk
```

## Sau khi chạy

Cuối script có bảng tổng kết `[OK]` / `[THIẾU]`. Log đầy đủ:

```bash
sudo less /var/log/ubuntu-post-install.log
```

Bộ gõ tiếng Việt cần **đăng xuất rồi đăng nhập lại** mới có hiệu lực. Chuyển chế độ gõ bằng `Super + Space`, chỉnh Telex/VNI bằng `ibus-setup`.

## Vài chỗ không hiển nhiên

Mấy điểm này rút ra từ việc kiểm tra dữ liệu thật, không phải đoán:

- **Telegram không còn trong kho apt Ubuntu 26.04.** Phải dùng snap của Telegram FZ-LLC (chính chủ), dự phòng flatpak.
- **LocalSend có bản phát hành chỉ chứa file Android**, không kèm `.deb`. Nên script quét 20 release gần nhất để lấy bản ổn định mới nhất *có* `.deb`, thay vì chỉ nhìn `/releases/latest`.
- **RustDesk luôn có bản `nightly` đứng đầu danh sách** và nó là pre-release. Script lọc `prerelease`/`draft` để không cài nhầm.
- **ibus-bamboo không đính kèm `.deb` nào trên GitHub Releases** — PPA là kênh duy nhất. Script tự lui về bản Ubuntu cũ hơn (`plucky` → `noble` → `jammy`) nếu PPA chưa build cho bản đang dùng.

## Phụ lục — bộ autoinstall (chưa chạy được)

Thư mục `autoinstall/` cùng `build.sh`, `serve.sh`, `set-password.sh` là nỗ lực tự động hoá luôn khâu cài Ubuntu. **Chưa dùng được** — trình cài báo lỗi và chưa tìm ra nguyên nhân cuối cùng.

Đã sửa được hai vấn đề nhưng vẫn hỏng:

- `curtin in-target` luôn thất bại trên Desktop ISO ([bug đang mở](https://github.com/canonical/ubuntu-desktop-installer/issues/2401)) — đã thay bằng tạo symlink tay.
- Thiếu `install -d` cho `/target/etc/systemd/system`.

> ⚠️ Nếu đã chạy `set-password.sh`, file `autoinstall/user-data` **chứa hash mật khẩu** và repo này đang public.
> Xoá khỏi bản hiện tại bằng `./set-password.sh --reset`, nhưng Git giữ lịch sử nên **cách duy nhất thực sự an toàn là đổi mật khẩu**.
