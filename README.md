u4pak
=====

Unpack, pack, list, test and mount Unreal Engine 4 .pak archives.

=====

## 🔧 Enhanced Version by porhe911

This repository contains an **enhanced universal version** of u4pak tool with drag & drop support and improved UI.

✨ New Features

- **🖱️ Drag & Drop Automation** - Simply drag files/folders onto the batch tool
  - Drag `.pak` files → automatically unpacks
  - Drag folders → automatically packs to `.pak`
- **📋 Content Listing** - View `.pak` contents without extraction
- **🌍 Universal Compatibility** - Works with any UE4 game structure
- **🎯 Improved UI** - Clean English interface with proper error handling
- **⚡ Auto-detection** - Smart Python detection and UTF-8 support

### 🛠️ Usage Options

#### Method 1: Drag & Drop (Recommended)
- **Unpack**: Drag `.pak` file onto `u4pak_tool.bat`
- **Pack**: Drag folder onto `u4pak_tool.bat`

#### Method 2: Interactive Menu
Run `u4pak_tool.bat` and choose:
- `1` - Unpack `.pak` file → creates `[filename]_unpacked` folder
- `2` - Pack folder → creates `[foldername].pak`  
- `3` - List `.pak` contents (view without extracting)
- `4` - Exit

🔧 Улучшенная версия от porhe911

Этот репозиторий содержит **улучшенную универсальную версию** инструмента u4pak с поддержкой перетаскивания и улучшенным интерфейсом.

### ✨ Новые возможности

- **🖱️ Автоматическое перетаскивание** - Просто перетащите файлы/папки на батник
  - Перетащите `.pak` файл → автоматически распакуется
  - Перетащите папку → автоматически упакуется в `.pak`
- **📋 Просмотр содержимого** - Просмотр файлов в `.pak` без распаковки
- **🌍 Универсальная совместимость** - Работает с любой структурой UE4 игр
- **🎯 Улучшенный интерфейс** - Чистый английский интерфейс с обработкой ошибок
- **⚡ Автоопределение** - Умное определение Python и поддержка UTF-8

### 🛠️ Способы использования

#### Способ 1: Перетаскивание (Рекомендуется)
- **Распаковать**: Перетащите `.pak` файл на `u4pak_tool.bat`
- **Упаковать**: Перетащите папку на `u4pak_tool.bat`

#### Способ 2: Интерактивное меню
Запустите `u4pak_tool.bat` и выберите:
- `1` - Распаковать `.pak` файл → создаст папку `[имя_файла]_unpacked`
- `2` - Упаковать папку → создаст файл `[имя_папки].pak`
- `3` - Просмотр содержимого `.pak` (без распаковки)
- `4` - Выход

=====

**NOTE:** I've wrote an [alternative version](https://github.com/panzi/rust-u4pak)
of this in Rust and compiled a [self-contained binary](https://github.com/panzi/rust-u4pak/releases)
for Windows users. So there is no hassle with installing Python, plus it adds a
way to supply command line arguments via a file that you can associate with the
binary so you only need to double click that. It is also faster, mainly because
it uses multi-threading. (Note that it's command line arguments are sligthly
different.)

Basic usage:

    u4pak.py info <archive>                 - print archive summary info
    u4pak.py list <archive>                 - list contens of .pak archive
    u4pak.py test <archive>                 - test archive integrity
    u4pak.py unpack <archive>               - extract .pak archive
    u4pak.py pack <archive> <files>         - create .pak archive
    u4pak.py mount <archive> <mount-point>  - mount archive as read-only file system

For unpacking only unencryped archives of version 1, 2, 3, 4, and 7 are supported,
for packing only version 1, 2, and 3.

**NOTE:** If you know (cheap) games that use other archive versions please tell me!
Especially if its 5 or 6. There is a change in how certain offsets are handled at
some point, but since I only have an example file of version 7 I don't know if it
happened in version 5, 6, or 7.

The `mount` command depends on the [llfuse](https://code.google.com/p/python-llfuse/)
Python package. If it's not available the rest is still working.

This script is compatible with Python 3.7.

If you get errors saying anything about `'utf8' codec can't decode byte [...]` try to
use another encoding by passing `--encoding=iso-8859-1` or similar.

If you get an error message about an illegal file magic try to pass `--ignore-magic`.
If you get an error message about the archive version being 0 try to pass
`--force-version=1` (or a higher number).

File Format
-----------

Byte order is little endian and the character encoding of file names seems to be
ASCII (or ISO-8859-1/UTF-8 that coincidentally only uses ASCII compatiple
characters).

Offsets and sizes seem to be 64bit or at least unsigned 32bit integers. If
interpreted as 32bit integers all sizes (except the size of file names) and offsets
are followed by another 32bit integer of the value 0, which makes me guess these
are 64bit values. Also some values exceed the range of signed 32bit integers, so
they have to be at least unsigned 32bit integers. This information was reverse
engineered from the Elemental [Demo](https://wiki.unrealengine.com/Linux_Demos)
for Linux (which contains a 2.5 GB .pak file).

Basic layout:

* Data Records
* Index
  * Index Header
  * Index Records
* Footer

In order to parse a file you need to read the footer first. The footer contains
an offset pointer to the start of the index records. The index records then
contain offset pointers to the data records.

Some games seem to zero out parts of the file. In particular the footer, which
makes it pretty much impossible to read the file without manual analysis and
guessing. I suspect these games have the footer included somewhere in the game
binary. If it's not obfuscated one might be able to find it using the file
magic (given that the file magic is even included)?

### Record

    Offset  Size  Type         Description
         0     8  uint64_t     offset
         8     8  uint64_t     size (N)
        16     8  uint64_t     uncompressed size
        24     4  uint32_t     compression method:
                                  0x00 ... none
                                  0x01 ... zlib
                                  0x10 ... bias memory
                                  0x20 ... bias speed
    if version <= 1
        28     8  uint64_t     timestamp
    end
         ?    20  uint8_t[20]  data sha1 hash
    if version >= 3
     if compression method != 0x00
      ?+20     4  uint32_t     block count (M)
      ?+24  M*16  CB[M]        compression blocks
     end
         ?     1  uint8_t      is encrypted
       ?+1     4  uint32_t     The uncompressed size of each compression block.
    end                        The last block can be smaller, of course.

### Compression Block (CB)

Size: 16 bytes

    Offset  Size  Type         Description
         0     8  uint64_t     compressed data block start offset.
                               version <= 4: offset is absolute to the file
                               version 7: offset is relative to the offset
                                          field in the corresponding Record
         8     8  uint64_t     compressed data block end offset.
                               There may or may not be a gap between blocks.
                               version <= 4: offset is absolute to the file
                               version 7: offset is relative to the offset
                                          field in the corresponding Record

### Data Record

    Offset  Size  Type            Description
         0     ?  Record          file metadata (offset field is 0, N = compressed_size)
         ?     N  uint8_t[N]      file data

### Index Record

    Offset  Size  Type            Description
         0     4  uint32_t        file name size (S)
         4     S  char[S]         file name (includes terminating null byte)
       4+S     ?  Record          file metadata

### Index

    Offset  Size  Type            Description
         0     4  uint32_t        mount point size (S)
         4     S  char[S]         mount point (includes terminating null byte)
       S+4     4  uint32_t        record count (N)
       S+8     ?  IndexRecord[N]  records

### Footer

Size: 44 bytes

    Offset  Size  Type         Description
         0     4  uint32_t     magic: 0x5A6F12E1
         4     4  uint32_t     version: 1, 2, 3, 4, or 7
         8     8  uint64_t     index offset
        16     8  uint64_t     index size
        24    20  uint8_t[20]  index sha1 hash

Related Projects
----------------

* [fezpak](https://github.com/panzi/fezpak): pack, unpack, list and mount FEZ .pak archives
* [psypkg](https://github.com/panzi/psypkg): pack, unpack, list and mount Psychonauts .pkg archives
* [bgebf](https://github.com/panzi/bgebf): unpack, list and mount Beyond Good and Evil .bf archives
* [unvpk](https://github.com/panzi/unvpk): extract, list, check and mount Valve .vpk archives
* [rust-vpk](https://github.com/panzi/rust-vpk/): Rust rewrite of the above
* [t2fbq](https://github.com/panzi/t2fbq): unpack, list and mount Trine 2 .fbq archives
* [rust-u4pak](https://github.com/panzi/rust-u4pak): not yet finished Rust rewrite of this script

BSD License
-----------
Copyright (c) 2014-2019 Mathias Panzenböck

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
