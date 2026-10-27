# 🧰 Agent Skillpack (bộ skill cá nhân của meth)

Kho trung tâm chứa bộ công cụ agent để tái dùng cho **mọi project**.

## Thành phần

| Thứ | Cách cài vào project | Lý do |
|-----|----------------------|-------|
| `.agent/` | **Junction** (link) | 42MB/5718 file. Link để không nhân bản, sửa 1 chỗ mọi project xài chung. |
| `CLAUDE.md` | **Copy** | Rule agent. Copy để mỗi project chỉnh riêng được. |
| `ERRORS.template.md` → `ERRORS.md` | **Tạo mới rỗng** | Nhật ký lỗi là của RIÊNG từng project, không bê log cũ sang. |

## Cài vào 1 project mới

```powershell
cd D:\code\project-moi
& C:\Users\meth\agent-skillpack\install.ps1
```

Ghi đè `CLAUDE.md` đã có:

```powershell
& C:\Users\meth\agent-skillpack\install.ps1 -Force
```

Cài cho project ở đường dẫn khác mà không cần `cd`:

```powershell
& C:\Users\meth\agent-skillpack\install.ps1 -Project D:\code\project-moi
```

## Cập nhật bộ skill

Vì `.agent` là junction, cứ sửa trực tiếp trong `C:\Users\meth\agent-skillpack\.agent`
là mọi project đang link tới đều thấy ngay. `CLAUDE.md` thì sửa ở kho rồi chạy lại
`install.ps1 -Force` cho từng project muốn đồng bộ.

## Gỡ khỏi 1 project

```powershell
Remove-Item .\.agent -Force    # xoá junction (KHÔNG xoá file gốc trong kho)
Remove-Item .\CLAUDE.md, .\ERRORS.md
```
