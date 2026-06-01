# ui-tokens — Claude Cowork Skill

Скилл для проверки, фиксации и валидации UI токенов в проекте.

## Режимы

| Команда | Действие |
|---------|---------|
| `ui-tokens check` | Найти хардкод (rgba, hex) в компонентах, проверить FROZEN |
| `ui-tokens fix` | Заменить хардкод на токены, добавить недостающие в uiTokens.ts |
| `ui-tokens verify` | Верификация после brain-run UI-шага |
| `ui-tokens diff` | Показать что изменилось в uiTokens.ts и где используется |

## Правило

Все визуальные свойства — только через `UI_TOKENS`. Никаких `rgba()`, `#hex`, `blur()` прямо в компонентах.

## Автор

Mahmud Salakhetdinov — MIT License
