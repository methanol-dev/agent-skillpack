# Nhật Ký Theo Dõi Lỗi & Khắc Phục (ERRORS.md)

> File này là nhật ký lỗi RIÊNG của từng project. Mỗi khi gặp bug và fix xong,
> ghi lại theo mẫu bên dưới để agent tự học và tránh lặp lỗi cũ.

---

<!-- MẪU GHI LOG — copy khối dưới cho mỗi lỗi mới, mới nhất lên trên -->

## [YYYY-MM-DD HH:MM] - <Tiêu đề ngắn gọn của lỗi>

- **Type**: <Agent / Logic / UI / Infra / Security / ...>
- **Severity**: <Low / Medium / High / Critical>
- **File**: `path/to/file.py:line`
- **Agent**: <người/agent xử lý>
- **Root Cause**:
  1. <nguyên nhân gốc>
- **Error Message**:
  ```text
  <log lỗi thực tế>
  ```
- **Fix Applied**:
  1. <cách khắc phục>
- **Prevention**:
  1. <biện pháp phòng tái diễn: test, guard, lint...>
