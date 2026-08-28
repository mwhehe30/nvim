# Neovim Setup — Windows

Konfigurasi Neovim pribadi untuk development Laravel, Blade, Livewire, PHP,
React, TypeScript, Vue, Vite, Next.js, Tailwind CSS, dan Python.

## 1. Backup sebelum install ulang

Backup seluruh folder ini:

```text
%LOCALAPPDATA%\nvim
```

File yang wajib dipertahankan:

```text
init.lua
lazy-lock.json
lua\
README.md
```

Tidak perlu membackup `%LOCALAPPDATA%\nvim-data`. Folder tersebut berisi plugin,
parser, LSP, dan formatter yang dapat diunduh ulang.

Sangat disarankan menyimpan konfigurasi ini dalam repository Git private.

## 2. Install dependency Windows

### Dependency utama

- Neovim 0.12 atau lebih baru
- Git for Windows (termasuk Git Bash)
- Node.js LTS dan npm
- PHP 8.4
- Composer
- Nerd Font (`GoogleSansCode NFM`)

### Tool command-line

- **ripgrep**: fuzzy finder search (mini.pick)
- **fd**: pencarian file
- **gcc**: kompilasi parser Tree-sitter
- **tree-sitter**: instalasi parser Tree-sitter (via scoop, bukan npm!)
- **win32yank**: clipboard Windows
- **uv**: Python package manager (project Python)
- **ruff**: Python linter & formatter (via Mason)

### Install semua dependency sekaligus

```powershell
scoop install neovim git nodejs-lts ripgrep fd gcc tree-sitter win32yank uv
```

> **Penting:** Gunakan `tree-sitter` dari scoop, **bukan** dari npm.
> Versi npm sering bermasalah di Windows.

Untuk PHP, Composer, database, dan web server, Laragon dapat digunakan sebagai
pengganti instalasi paket satu per satu. Pastikan seluruh executable tersedia di
`PATH`.

### Verifikasi dependency

```powershell
nvim --version
git --version
node --version
php --version
composer --version
rg --version
fd --version
gcc --version
tree-sitter --version
win32yank.exe --version
```

## 3. Install font

Install GoogleSansCode Nerd Font, lalu pilih `GoogleSansCode NFM` pada terminal.
Neovide menggunakan:

```text
GoogleSansCode NFM:h16
```

Nerd Font diperlukan agar icon file, statusline, diagnostic, dan UI tampil
dengan benar.

## 4. Restore konfigurasi

Salin atau clone konfigurasi ke:

```text
C:\Users\<username>\AppData\Local\nvim
```

Contoh jika sudah disimpan di Git:

```powershell
git clone <repository-url> "$env:LOCALAPPDATA\nvim"
```

Pastikan struktur akhirnya seperti berikut:

```text
nvim\
├── init.lua
├── lazy-lock.json
├── README.md
└── lua\
    ├── config\
    └── plugins\
```

## 5. Install plugin & Treesitter parser

### 5a. Install semua plugin

Jalankan Neovim:

```powershell
nvim
```

`lazy.nvim` akan di-clone otomatis. Setelah Neovim terbuka, jalankan:

```vim
:Lazy sync
```

Tunggu sampai selesai, tutup Neovim, lalu buka kembali.

### 5b. Install Treesitter parser

Treesitter parser dibutuhkan untuk syntax highlighting dan indentasi.

```vim
:TreesitterInstallCore
```

Command ini menginstall parser: lua, vim, vimdoc, html, css, javascript,
typescript, tsx, json, markdown, php, blade, vue, python.

> **Catatan:** Parser `blade` adalah community parser yang di-compile dari
> source. Jika error, bisa di-skip — parser lain tetap jalan.

## 6. Install LSP dan formatter

```vim
:MasonToolsInstall
```

Periksa hasilnya:

```vim
:Mason
```

### Language server

| Server | Fungsi |
|--------|--------|
| pyright | Python |
| intelephense | PHP, Blade |
| ts_ls | TypeScript/JavaScript |
| vue_ls | Vue |
| eslint | JavaScript linting |
| html | HTML + Blade |
| cssls | CSS/SCSS/LESS + Blade |
| jsonls | JSON (schema support) |
| tailwindcss | Tailwind CSS |
| emmet_language_server | Emmet snippets |
| lua_ls | Lua (Neovim config) |

### Formatter

| Formatter | Fungsi |
|-----------|--------|
| ruff | Python formatting (via uv/ruff) |
| stylua | Lua formatting |
| prettier | JS/TS/CSS/HTML/JSON formatting |
| blade-formatter | Blade formatting |
| rustywind | Tailwind class sorting |
| Pint | PHP formatting (dari project) |

## 7. Setup project Laravel

Di setiap project Laravel:

```powershell
composer install
npm.cmd install
```

Pastikan Laravel Pint tersedia secara lokal:

```powershell
composer require laravel/pint --dev
```

Config akan mencari Pint di `vendor\bin\pint.bat`.

Pastikan extension PHP yang dibutuhkan project aktif. Umumnya:

```text
curl, dom, fileinfo, gd, intl, mbstring, openssl, pdo,
pdo_mysql, simplexml, tokenizer, xml, xmlwriter, zip
```

## 8. Setup project Python (uv)

Di setiap project Python:

```powershell
uv sync
```

### Instalasi dev dependency (opsional)

```powershell
uv add --dev ruff
```

> **Catatan:** `ruff` sudah terinstall via Mason sebagai formatter/linter.
> Jika ingin versi project-specific, install juga sebagai dev dependency.

### Path Python dari uv

Jika menggunakan venv dari uv, pastikan path-nya benar:

```powershell
# Cek path Python yang aktif
uv python find
```

Neovim/pyright akan otomatis mendeteksi virtual environment dari
`pyproject.toml` atau `uv.lock` di root project.

## 9. Setup project React/Vite/Next.js

Di setiap project:

```powershell
npm.cmd install
```

Untuk project TypeScript/TSX, pastikan TypeScript tersedia secara lokal:

```powershell
npm.cmd install --save-dev typescript
```

## 10. Autentikasi AI completion

NeoCodeium memerlukan autentikasi ulang setelah reinstall. Di Neovim, ketik:

```vim
:NeoCodeium
```

Tekan `Tab` untuk melihat command yang tersedia dan pilih command autentikasi.

## 11. Pemeriksaan akhir

Jalankan:

```vim
:checkhealth
:Mason
:ConformInfo
:LspInfo
```

Tes dengan membuka beberapa jenis file:

```text
test.lua
test.php
test.blade.php
test.js
test.jsx
test.ts
test.tsx
test.vue
test.py
```

Pastikan completion, diagnostic, go-to-definition, dan format-on-save bekerja.

## Plugin yang digunakan

### Editor

| Plugin | Fungsi |
|--------|--------|
| neo-tree.nvim | File explorer (kanan) |
| mini.pick | Fuzzy finder (buffer, file, grep) |
| nvim-treesitter | Syntax highlighting & indentasi |
| flash.nvim | Navigasi cepat (jump, treesitter) |
| mini.pairs | Auto-close brackets & quotes |
| mini.comment | Comment/uncomment (gcc) |
| nvim-surround | Tambah/ganti/hapus surrounding |
| nvim-ts-autotag | Auto-close HTML/JSX tags |
| undotree | Riwayat undo visual |

### PHP & Blade

| Plugin | Fungsi |
|--------|--------|
| vim-blade | Blade syntax support |
| blade-nav.nvim | Navigasi & autocomplete Blade components |
| alpinejs.nvim | Alpine.js support (x-data, @click, $refs) |

### LSP & Completion

| Plugin | Fungsi |
|--------|--------|
| nvim-lspconfig | LSP configuration |
| blink.cmp | Completion engine (tab/S-tab, C-space) |
| LuaSnip | Snippet engine |
| mason.nvim | LSP/formatter installer |
| mason-lspconfig.nvim | Bridge mason ↔ lspconfig |
| lspsaga.nvim | LSP UI (hover, rename, code action) |

### UI

| Plugin | Fungsi |
|--------|--------|
| lualine.nvim | Statusline |
| mini.indentscope | Indent scope indicator |
| mini.icons | File icons |
| which-key.nvim | Keymap hints |

### Lainnya

| Plugin | Fungsi |
|--------|--------|
| conform.nvim | Formatting (format-on-save) |
| gitsigns.nvim | Git signs di gutter |
| render-markdown.nvim | Markdown render di buffer |
| neocodeium | AI completion (Codeium) |

## Keymap penting

| Key | Mode | Fungsi |
|-----|------|--------|
| `Space` | Normal | Leader key |
| `<C-n>` | Normal | Toggle Neo-tree |
| `s{2char}` | Normal | Flash jump |
| `S` | Normal | Flash treesitter jump |
| `K` | Normal | Hover doc (Lspsaga) |
| `gd` | Normal | Go to definition |
| `gr` | Normal | Finder (references) |
| `<leader>rn` | Normal | Rename |
| `<leader>ca` | Normal | Code action |
| `<Tab>` | Insert | Next completion / buffer switcher |
| `<S-Tab>` | Insert | Previous completion |
| `<C-Space>` | Insert | Show completion |
| `<CR>` | Insert | Accept / split bracket |
| `gcc` | Normal | Toggle comment |
| `ys{motion}{char}` | Normal | Add surrounding |
| `cs{old}{new}` | Normal | Change surrounding |
| `ds{char}` | Normal | Delete surrounding |
| `<leader>x` | Normal | Close buffer |
| `<leader>u` | Normal | Undo tree |
| `<leader>th` | Normal | Choose theme |
| `<leader>fm` | Normal | Format file |

## Troubleshooting

### Clipboard tidak bekerja

```powershell
scoop install win32yank
```

### Tree-sitter parser gagal install

Pastikan GCC dan tree-sitter (scoop) tersedia:

```powershell
gcc --version
tree-sitter --version
```

> Jangan pakai `tree-sitter` dari npm — pakai dari scoop.

### LSP tidak attach / completion tidak muncul

Buka file PHP, lalu jalankan:

```vim
:LspInfo
:LspLog
```

Pastikan `intelephense` muncul di Active Clients. Jika tidak, cek `:messages`
untuk error.

### Formatter tidak ditemukan

```vim
:ConformInfo
:MasonToolsInstall
```

Untuk PHP, pastikan `vendor\bin\pint.bat` tersedia di project Laravel.

## Command pemulihan cepat

```text
1. Buka nvim
2. :Lazy sync
3. Restart nvim
4. :MasonToolsInstall
5. :TreesitterInstallCore
6. :checkhealth
7. Login ulang NeoCodeium
```
