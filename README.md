# 🧰 Agent Skillpack

Bộ công cụ agent (`.agent/` + `CLAUDE.md`) đóng gói thành **package online**:
host trên GitHub, kéo về và cài vào **bất kỳ project nào, trên bất kỳ máy nào** bằng 1 lệnh.

```
https://github.com/methanol-dev/agent-skillpack
```

## Cài vào project (1 lệnh)

Đứng ở **thư mục gốc** của project rồi chạy:

**Windows (PowerShell 5.1+)**

```powershell
irm https://raw.githubusercontent.com/methanol-dev/agent-skillpack/main/install.ps1 | iex
```

**macOS / Linux / WSL**

```bash
curl -fsSL https://raw.githubusercontent.com/methanol-dev/agent-skillpack/main/install.sh | bash
```

Lệnh trên sẽ:

| Bước | Việc làm | Lý do |
|------|----------|-------|
| 1 | Clone pack về `~/.agent-skillpack` (lần đầu) hoặc `git pull` (lần sau) | 1 bản duy nhất trên máy, update 1 chỗ |
| 2 | `.agent/` → **junction/symlink** tới `~/.agent-skillpack/.agent` | 42MB / 5700 file, không nhân bản vào từng project |
| 3 | `CLAUDE.md` → **copy** vào project | Rule agent, mỗi project chỉnh riêng được |
| 4 | Thêm `.agent/`, `ERRORS.md` vào `.gitignore` | Tooling cục bộ, không commit vào repo project |

## Tuỳ chọn

| Việc | Windows | macOS / Linux |
|------|---------|---------------|
| Ghi đè `CLAUDE.md` + link lại `.agent` | `iex "& { $(irm <URL>/install.ps1) } -Force"` | `curl -fsSL <URL>/install.sh \| bash -s -- --force` |
| Cài cho project khác, không cần `cd` | `... -Project D:\code\app` | `... --project ~/code/app` |
| Chỉ update pack, không đụng project | `... -Update` | `... --update` |
| Đổi repo / thư mục pack | `-Repo`, `-PackDir` hoặc env `SKILLPACK_REPO`, `SKILLPACK_DIR` | `--repo`, `--pack-dir` hoặc env tương tự |

`<URL>` = `https://raw.githubusercontent.com/methanol-dev/agent-skillpack/main`

Env override dùng được cho cả 2 nền tảng: `SKILLPACK_PROJECT`, `SKILLPACK_FORCE=1`, `SKILLPACK_REPO`, `SKILLPACK_DIR`.

## Cập nhật bộ skill

Vì `.agent` là link, chỉ cần update pack trung tâm là **mọi project đang link đều thấy ngay**:

```powershell
iex "& { $(irm https://raw.githubusercontent.com/methanol-dev/agent-skillpack/main/install.ps1) } -Update"
# hoặc đơn giản:  git -C ~/.agent-skillpack pull
```

`CLAUDE.md` là bản copy nên muốn đồng bộ phải chạy lại installer với `-Force` / `--force` ở từng project.

## Phát triển pack (sửa skill)

```bash
git clone https://github.com/methanol-dev/agent-skillpack ~/.agent-skillpack
# sửa trong ~/.agent-skillpack/.agent/... rồi
git -C ~/.agent-skillpack commit -am "..." && git -C ~/.agent-skillpack push
```

Chạy `install.ps1` / `install.sh` **từ trong clone** sẽ dùng chính clone đó làm pack (không cần mạng).

## Gỡ khỏi 1 project

```powershell
# Windows: xoá junction, KHÔNG xoá file gốc trong pack
[IO.Directory]::Delete("$PWD\.agent"); Remove-Item .\CLAUDE.md
```

```bash
# macOS / Linux
rm .agent CLAUDE.md
```

## Ghi chú

- `ERRORS.md` (nhật ký lỗi của từng project) **không còn template**. Agent tự tạo khi cần theo
  format trong `.agent/rules/error-logging.md`.
- Yêu cầu: `git` có trong PATH. Windows dùng junction nên **không cần quyền admin**.
