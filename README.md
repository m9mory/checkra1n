# checkra1n — iOS Jailbreak Simulator (пранк)

Выглядит как настоящий инструмент джейлбрейка, но после «взлома» показывает погоду в твоём городе.

## Как собрать

1. Форкни/залей этот репозиторий на GitHub
2. Перейди во вкладку **Actions** → выбери **Build checkra1n** → **Run workflow**
3. Через ~5 минут скачай `checkra1n.ipa` из артефактов

## Как установить на iPhone

IPA подписан фейковым сертификатом. Чтобы установить, используй:
- **[AltStore](https://altstore.io)** (рекомендую)
- **[Sideloadly](https://sideloadly.io)**
- **[SideStore](https://sidestore.io)**

Они переподпишут IPA твоим Apple ID (бесплатно, работает без джейлбрейка).

## Иконка

Положи `icon.png` в папку `icons/` — любой размер (хоть 256×256, хоть 1024×1024). CI сам растянет до 1024 и нарежет все размеры. Если не положишь — сгенерируется фоллбэк-иконка в стиле checkra1n.

## Структура

```
├── .github/workflows/build.yml   — GitHub Actions билд
├── Sources/                       — SwiftUI код
│   ├── Checkra1nApp.swift
│   ├── ContentView.swift
│   └── JailbreakViewModel.swift
├── Resources/
│   ├── Info.plist
│   └── Assets.xcassets/           — иконки, цвета
├── project.yml                    — XcodeGen спека
├── scripts/generate_icons.sh      — генератор иконок
└── icons/                         — исходная иконка (положи сюда)
```

## Что внутри

- Чёрный фон, зелёный моноширинный лог как в терминале
- Случайные логи: `Patching kernel...`, `Exploiting checkm8...`, panic'и, SIGBUS'ы
- Через ~5 секунд: город по IP (ipapi.co) + погода (Open-Meteo)
- Кнопка **Начать джейлбрейк** — перезапускает анимацию
