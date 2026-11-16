# Зависимости первой сборки webOS 6

| Компонент | Версия или источник |
|---|---|
| Flutter | 3.38.10, framework commit `c6f67dede3d4aa1aa7a69dd56a3494a5cde6cc80` |
| Dart | 3.10.9 из комплекта Flutter 3.38.10 |
| Flutter Engine, ICU и ARM32 `gen_snapshot` для x86-64 | Релиз LG `c6f67dede3-webos26-2` |
| Заголовки SDL | 2.0.10 |
| Библиотека SDL | ARM EABI-библиотека из целевого ТВ. Совместимость проверена на LG 65NANO896PC |
| glibc в каталоге приложения | ARM EABI, Ubuntu `2.39-0ubuntu8` по версии `libc.so.6` испытанного IPK |
| ABI приложения | ARMv7 EABI softfp |
| Инструменты сборки и шрифт | `arm-linux-gnueabi-gcc`, `ares-package`, DejaVu Sans. Точные версии сборочных инструментов и шрифта в этом прогоне не зафиксированы |

Для сверки скачанных архивов LG выполните `sha256sum` для обоих файлов.

| Архив | SHA-256 |
|---|---|
| `webos-arm-release.zip` | `28fd011b3334323c1e28343f600c40f7ebabaee51fe0cafe6e9463340b5c7fb9` |
| `webos-common.zip` | `b0706807140c4792525879de30ecd0d219111f521252965cb75c01fef5a20a2e` |

Контрольные суммы библиотек из испытанного пакета.

| Файл | SHA-256 |
|---|---|
| `libflutter_engine.so` | `665b06a533920baecd1df75af4e66d69e40176e4c00577dfec348a56104ce054` |
| `icudtl.dat` | `5070de99fbd8a48378543511fb7a072f85bf36f94b4f4e1d420d54be1435d6f1` |

На проверенном LG системная glibc имеет версию 2.28, а движок LG требует символы GLIBC_2.38. Запускатель использует glibc 2.39 из каталога приложения. Сборка движка для системной glibc 2.28 ещё не проверена.
