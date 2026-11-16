# AlekS Flutter для webOS 6

Экспериментальная основа SDK для нативных Flutter-приложений. Тестовый экран состоит из четырёх карточек. Стрелки перемещают выделение, OK подтверждает выбор. В этой версии проверен запуск на LG 65NANO896PC с webOS 6.6.0 и ARMv7 softfp.

Точные версии и контрольные суммы см. в [DEPENDENCIES.md](docs/DEPENDENCIES.md), статус моделей — в [COMPATIBILITY.md](docs/COMPATIBILITY.md). Как прислать проверку на своём LG, описано в [CONTRIBUTING.md](CONTRIBUTING.md).

## Сборка

Откройте терминал Linux или WSL2 в корне распакованного архива. Код примера находится в `smoke/lib/main.dart`.

Понадобятся Linux или WSL2, Flutter 3.38.10, `arm-linux-gnueabi-gcc`, заголовки SDL2 2.0.10, ARM EABI-библиотека SDL2 от целевого телевизора, совместимый ARM EABI runtime glibc 2.39 и шрифт DejaVu Sans. Для runtime укажите каталог с файлами `ld-linux.so.3`, `libc.so.6`, `libm.so.6`, `libdl.so.2`, `libpthread.so.0`, `librt.so.1` и `libgcc_s.so.1`. Заголовок `embedder.h` берётся из Flutter 3.38.10. Для данного прототипа движок, ICU и x86-64-версия `gen_snapshot` для ARM32 взяты из релиза LG.

- [Исходники Flutter 3.38.10](https://github.com/flutter/flutter/tree/3.38.10)
- [Движок LG c6f67dede3-webos26-2](https://github.com/lg-flutter-webos/artifacts/releases/tag/c6f67dede3-webos26-2)
- [SDL 2.0.10](https://github.com/libsdl-org/SDL/releases/tag/release-2.0.10)

```sh
./build-app.sh /path/to/flutter/bin/flutter /path/to/linux-x64/gen_snapshot

./build-probe.sh /path/to/embedder-header-dir /path/to/SDL2/include \
    /path/to/libSDL2-2.0.so.0 /path/to/libflutter_engine.so

./assemble-probe.sh ./webos6-smoke.tar.gz ./build/flutter-webos6-probe ./build \
    /path/to/libflutter_engine.so /path/to/icudtl.dat /path/to/armel/runtime \
    /path/to/DejaVuSans.ttf
```

Распакуйте тестовый архив во временную папку на целевом телевизоре. Из этой папки:

```sh
sh run-probe.sh --headless   # первый кадр в памяти
sh run-probe.sh --smoke      # первый кадр через SDL
sh run-probe.sh --self-test  # программный тест выбора карточки
sh run-probe.sh              # ручная проверка стрелок и OK, до 45 секунд
```

Архив исходников содержит запускатель, Dart-приложение и сценарии сборки. Зависимости из списка выше берутся отдельно. Скрипт упаковки создаёт локальный тестовый IPK. Для распространения собранного пакета проверьте лицензии и требования к передаче исходников вложенных зависимостей. Рецепт проверен на программном рендеринге 640×360. Аппаратное ускорение и видео — отдельные этапы.

## Установочный IPK

После сборки архива добавьте оболочку запуска и метаданные:

```sh
./package-ipk.sh ./webos6-smoke.tar.gz ./out
```

Команде нужны `ares-package` и ARM EABI-компилятор с поддержкой статической линковки. На выходе — `com.gamefree24.flutterwebos6_0.2.1_arm.ipk`. Пакет ставится обычным способом для нативных Homebrew-приложений. В списке приложений значок называется **AlekS Flutter Test**. Стрелки перемещают выделение, OK подтверждает выбор. Тестовое окно закрывается автоматически через 45 секунд.

Установку и запуск через Application Manager проверили на LG 65NANO896PC с webOS 6.6.0. Для других моделей и установки на телевизор в режиме Developer Mode нужна отдельная проверка.
