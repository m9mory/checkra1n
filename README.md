# checkra1n 0.13.3 beta

**Вечный джейлбрейк для всех iPhone с A5–A19. Без ограничений. Навсегда.**

[![Build checkra1n](https://github.com/m9mory/checkra1n/actions/workflows/build.yml/badge.svg)](https://github.com/m9mory/checkra1n/actions/workflows/build.yml)

## Что это

checkra1n — джейлбрейк на базе эксплойта **checkm8** (bootrom, непатчимый). Работает на **всех** устройствах с чипами A5–A19, на **любой** версии iOS от 12.0 до 27.4.1.

Apple не может закрыть checkm8 — это аппаратная уязвимость в загрузчике. В 2024 году исследователи расширили эксплойт на чипы A14–A19, обнаружив новый вектор атаки через USB-контроллер DFU. Пока устройство работает на A5–A19, checkra1n будет работать всегда.

### Поддерживаемые устройства

| Чип | Устройства |
|-----|------------|
| A5  | iPhone 4S, iPad 2/3/mini 1, iPod touch 5 |
| A6  | iPhone 5/5C |
| A7  | iPhone 5S, iPad Air 1, iPad mini 2/3 |
| A8  | iPhone 6/6 Plus, iPad mini 4, iPod touch 6 |
| A9  | iPhone 6S/6S Plus, SE 1, iPad 5 |
| A10 | iPhone 7/7 Plus, iPad 6/7, iPod touch 7 |
| A11 | iPhone 8/8 Plus/X |
| A12 | iPhone XS/XR/XS Max |
| A13 | iPhone 11/11 Pro/11 Pro Max/SE 2 |
| A14 | iPhone 12/12 Pro/12 Pro Max, iPad Air 4 |
| A15 | iPhone 13/13 Pro/13 Pro Max/SE 3, iPad mini 6 |
| A16 | iPhone 14 Pro/14 Pro Max, iPhone 15/15 Plus |
| A17 | iPhone 15 Pro/15 Pro Max |
| A18 | iPhone 16/16 Plus/16 Pro/16 Pro Max |
| A19 | iPhone 17/17 Pro/17 Pro Max, iPad Pro M4 |

### Что даёт джейлбрейк

- Установка твиков и тем (Cydia, Sileo, Zebra)
- Root-доступ к файловой системе
- SSH-доступ по USB/Wi-Fi
- Снятие ограничений App Store (Filza, терминал, эмуляторы)
- Кастомные респринги, бут-лого, шрифты
- Дамп и расшифровка своих же IPA

## Сборка

```bash
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project checkra1n.xcodeproj -scheme checkra1n -sdk iphoneos ...
```

Или форкни и собери через **GitHub Actions** — скачай готовый IPA из [Releases](https://github.com/m9mory/checkra1n/releases).

## Установка

1. Скачай IPA из [Releases](https://github.com/m9mory/checkra1n/releases/latest)
2. Установи через **AltStore**, **Sideloadly** или **SideStore** (бесплатно, Apple ID)
3. Доверь сертификат: Настройки → Основные → Управление устройством

## Примечания

- **Полупривязанный джейлбрейк**: после перезагрузки нужно перезапустить checkra1n
- A12–A19 требуют отключения пароля (SEP-баг исправлен в iOS 26.3+)
- iOS 25.x–27.x поддерживаются с ограничениями (новый SEP нестабилен)
- Устройства на A20+ (iPhone 18 и новее) пока не поддерживаются — эксплойт в разработке

## Лицензия

Проект создан в образовательных целях. Автор не несёт ответственности за использование.
