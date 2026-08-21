# Tự động cài phần mềm cho Ubuntu 26.04 LTS

Bộ script cài sẵn các phần mềm cần thiết ngay khi cài Ubuntu, không phải bấm gì thêm.

## Phần mềm được cài

| Phần mềm | Nguồn |
|---|---|
| Google Chrome | Kho apt chính chủ của Google |
| VLC | Kho Ubuntu |
| LibreOffice (+ gói tiếng Việt) | Kho Ubuntu |
| Codec đa phương tiện | `ubuntu-restricted-extras`, `libavcodec-extra`, GStreamer good/bad/ugly/libav |
| Discord | `.deb` chính chủ, dự phòng snap |
| Telegram Desktop | Snap của Telegram FZ-LLC *(Ubuntu 26.04 đã bỏ gói apt `telegram-desktop`)* |
| ibus-bamboo (bộ gõ tiếng Việt) | PPA `bamboo-engine/ibus-bamboo` |
| LocalSend | `.deb` từ GitHub Releases, dự phòng flatpak/snap |
| RustDesk | `.deb` bản ổn định từ GitHub Releases |

Ngoài ra script còn:

- Đặt **ibus + Bamboo** làm nguồn nhập mặc định cho mọi user (qua dconf system database — bạn vẫn đổi lại được trong Settings).
- Mở cổng **53317** trên `ufw` cho LocalSend, nếu tường lửa đang bật.
- Tự trả lời EULA của `ttf-mscorefonts-installer` để không bị treo giữa chừng.

## Cấu trúc

```
.
├── build.sh                    # sinh autoinstall/user-data từ 2 file nguồn
├── serve.sh                    # host file autoinstall qua HTTP cho trình cài tải về
├── scripts/
│   └── post-install.sh         # NGUỒN DUY NHẤT của toàn bộ logic cài đặt
└── autoinstall/
    ├── user-data.tmpl          # khung cấu hình autoinstall
    ├── user-data               # FILE SINH RA — đừng sửa tay
    └── meta-data               # file rỗng, cloud-init bắt buộc phải có
```

> Sửa `scripts/post-install.sh` hoặc `autoinstall/user-data.tmpl`, rồi chạy `./build.sh`.
> `build.sh` sẽ nhúng script vào YAML, kiểm tra cú pháp bash và tính hợp lệ của YAML.

---

## Cách 1 — Điền URL vào trình cài (dễ nhất)

Trình cài Ubuntu Desktop có sẵn màn hình **"Automated installation"** để dán link file cấu hình. Cách này không cần USB thứ hai, không cần sửa dòng lệnh GRUB.

### Bước 1. Trên máy hiện tại, bật server chia sẻ file

```bash
./serve.sh
```

Script sẽ build lại cấu hình, dò IP LAN và in ra đúng cái link cần dán, ví dụ:

```
http://192.168.100.64:3003/autoinstall.yaml
```

Cứ để cửa sổ đó chạy trong suốt quá trình cài. Nếu `ufw` đang bật thì mở cổng:

```bash
sudo ufw allow 3003/tcp
```

### Bước 2. Trên máy sắp cài

1. Boot vào USB cài Ubuntu, chọn **Try or Install Ubuntu**.
2. **Kết nối mạng trước** (Wi-Fi hoặc cắm dây) — trình cài phải tải được file, chưa có mạng thì ô nhập link vô dụng.
3. Đi tới màn hình hỏi kiểu cài đặt, chọn **Automated installation**.
4. Dán link mà `serve.sh` in ra, rồi tiếp tục như bình thường.

> Hai máy phải **cùng mạng LAN**. Máy sắp cài phải ping được IP kia.

### Không muốn dựng server?

Đẩy file `autoinstall/user-data` lên GitHub rồi lấy link **raw**:

```
https://raw.githubusercontent.com/<user>/<repo>/main/autoinstall/user-data
```

> ⚠️ Link raw phải trả về **file thô**, không phải trang HTML — dán nhầm link trang web GitHub là hỏng.
> Và đừng đẩy lên repo/gist công khai nếu bạn đã điền hash mật khẩu vào phần `identity:`.

---

## Cách 2 — USB `CIDATA` (không cần mạng lúc cài)

Dùng khi máy sắp cài không có mạng, hoặc bạn muốn cắm là chạy.

### Bước 1. Build

```bash
./build.sh
```

### Bước 2. Tạo USB cấu hình

Cần **2 USB**: một chứa bộ cài Ubuntu Desktop 26.04, một chứa cấu hình này.

Format USB thứ hai với **nhãn (label) đúng là `CIDATA`**, rồi chép 2 file vào thư mục gốc:

```bash
cp autoinstall/user-data autoinstall/meta-data /media/$USER/CIDATA/
```

### Bước 3. Boot và cài

1. Boot vào USB cài Ubuntu.
2. Ở màn hình GRUB, bấm `e` để sửa dòng lệnh boot.
3. Thêm chữ `autoinstall` vào cuối dòng bắt đầu bằng `linux`.
4. Bấm `Ctrl+X` để boot.

> Cách thứ ba: nếu đang chạy `./serve.sh`, có thể bỏ USB thứ hai và thay bằng tham số kernel
> `autoinstall ds=nocloud-net;s=http://<IP>:3003/` — `serve.sh` cũng in sẵn dòng này.

---

## Cách 3 — Chạy tay sau khi đã cài Ubuntu

Không cần autoinstall, chỉ cần chạy script:

```bash
sudo ./scripts/post-install.sh
```

Script **idempotent** — chạy lại nhiều lần không sao, cái gì đã có thì bỏ qua.

---

## Sau khi cài xong (áp dụng cho mọi cách)

Máy khởi động lại. Service `ubuntu-post-install.service` chạy ở lần boot đầu và cài toàn bộ phần mềm ở nền.

Theo dõi tiến trình:

```bash
journalctl -u ubuntu-post-install.service -f
```

Xem log đầy đủ:

```bash
sudo cat /var/log/ubuntu-post-install.log
```

Chạy xong, service tạo file đánh dấu `/var/lib/ubuntu-post-install.done` và không chạy lại nữa.
Nếu lúc đầu chưa có mạng (ví dụ dùng wifi, chưa kết nối), service **tự thử lại mỗi 3 phút** cho đến khi thành công.

---

## Những chỗ nên chỉnh trước khi dùng

Mở `autoinstall/user-data.tmpl`:

| Mục | Mặc định | Ghi chú |
|---|---|---|
| `interactive-sections` | `storage`, `identity` | Bạn tự chọn ổ đĩa và đặt user/mật khẩu trong trình cài. **An toàn dữ liệu.** |
| `locale` | `en_US.UTF-8` | Đổi thành `vi_VN.UTF-8` nếu muốn giao diện tiếng Việt |
| `timezone` | `Asia/Ho_Chi_Minh` | |
| `updates` | `all` | Cập nhật hệ thống ngay trong lúc cài |

### Muốn cài hoàn toàn không bấm phím nào

Trong `user-data.tmpl`: xoá khối `interactive-sections`, bỏ comment khối `storage:` và `identity:`, sửa đường dẫn ổ đĩa và hash mật khẩu — rồi chạy lại `./build.sh`.

> ⚠️ **`storage.layout.name: direct` sẽ XOÁ SẠCH ổ đĩa được chọn, không hỏi lại.**
> Kiểm tra kỹ `path` bằng `lsblk` trước khi dùng. Đây là lý do mặc định để chế độ chọn tay.

Tạo hash mật khẩu:

```bash
mkpasswd --method=SHA-512 --rounds=4096
```

---

## Bật bộ gõ tiếng Việt

Đăng xuất rồi đăng nhập lại (hoặc khởi động lại) để ibus-bamboo có hiệu lực. Chuyển chế độ gõ bằng `Super + Space`.

Cấu hình kiểu gõ (Telex/VNI):

```bash
ibus-setup
```

## Lưu ý

- Bộ này dành cho **Ubuntu Desktop 26.04 (resolute), amd64**. Bản Ubuntu khác vẫn chạy được nhưng nên kiểm tra lại tên gói.
- Ô **"Automated installation"** có từ Ubuntu Desktop 23.04, chính thức ổn định từ 24.04 LTS.
- File `autoinstall/user-data` dùng chung được cho cả 3 cách nạp, vì nó theo định dạng Canonical khuyến nghị: `#cloud-config` + đúng **một** khoá top-level `autoinstall:`. Thêm khoá top-level khác vào là trình cài báo lỗi.
- Script gọi GitHub API không kèm token, giới hạn 60 request/giờ cho mỗi IP — quá đủ cho vài lần cài.
