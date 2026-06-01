---
name: ui-tokens
description: >
  Skill for checking, fixing, and validating UI token usage in the project.
  Use whenever the user mentions UI tokens, hardcoded colors, visual regressions,
  frozen components, or wants to audit/fix styling. Triggers on:
  "проверь токены", "хардкод в ui", "fix ui tokens", "проверь frozen",
  "audit colors", "rgba в компонентах", "ui-tokens", "визуальная проверка",
  "токены нарушены", "check ui", "fix styling".
---

# ui-tokens

Проверка, фиксация и валидация UI токенов в проекте.

## Правило

**Все** визуальные свойства — цвета, blur, shadow, радиусы, размеры — только через `UI_TOKENS`:
```ts
import { UI_TOKENS } from 'src/styles/uiTokens'
```

Никогда не хардкодить: `rgba(...)`, `#hex`, `blur(Npx)`, числовые значения цветов прямо в компонентах.

Нет нужного токена → добавить в `uiTokens.ts`, затем использовать.

---

## FROZEN — никогда не трогать

| Что | Где |
|-----|-----|
| `positionCardAwayFromConnections()` | `ScoreCanvas.tsx`, `ComposerOverlay.tsx` |
| `MobileConnectionGraph` (Medusa) | — |
| Mobile `SelectedCard` (~строки 370-490) | `ComposerOverlay.tsx` |
| `UI_TOKENS.card.mobile` | `uiTokens.ts` |
| `UI_TOKENS.parchment` | Canvas API, не CSS |

---

## Режимы

### `/ui-tokens check` — аудит хардкода

Найти хардкод в UI-компонентах (не в `uiTokens.ts`):

```bash
grep -rn "rgba(\|blur(\|#[0-9a-fA-F]\{3,6\}" src/components/ src/hooks/ src/pages/
```

Нормально: только в `src/styles/uiTokens.ts`.
Нарушение: любой `rgba`/`#hex` прямо в `.tsx`-компонентах.

Проверить FROZEN не тронут:
```bash
git diff HEAD -- src/ | grep -i "positionCardAwayFromConnections\|MobileConnectionGraph\|card\.mobile\|parchment"
```
Ожидается: пусто.

Вывод:
```
🎨 UI Token Audit

✅ Чисто: src/components/Card.tsx
⚠️ Нарушение: src/components/Overlay.tsx:42 — rgba(0,0,0,0.5)
🔒 FROZEN: не задет

Итого: N нарушений в M файлах
```

---

### `/ui-tokens fix` — исправить хардкод

1. Прочитать `src/styles/uiTokens.ts` — найти подходящий токен
2. Если токена нет — добавить в `uiTokens.ts` в нужную группу
3. Заменить хардкод на токен в компоненте
4. Проверить что замена не сломала визуал (логически — по группе токена)

Формат отчёта:
```
🔧 Fixed: src/components/Overlay.tsx
  rgba(0,0,0,0.5) → UI_TOKENS.overlay.background
  [новый токен] overlay.background = 'rgba(0,0,0,0.5)' добавлен в uiTokens.ts
```

---

### `/ui-tokens verify` — верификация после изменений

Запускается после `brain-run` для UI-шагов. Проверяет:

```bash
# Хардкод в изменённых файлах
git diff HEAD --name-only | xargs grep -ln "rgba(\|blur(\|#[0-9a-fA-F]\{3,6\}" 2>/dev/null

# FROZEN не задет
git diff HEAD | grep -i "positionCardAwayFromConnections\|MobileConnectionGraph\|card\.mobile\|parchment"
```

Если хардкод найден → шаг brain-run получает `[~]` вместо `[x]`, не засчитывается до исправления.

---

### `/ui-tokens diff` — показать изменения токенов

```bash
git diff HEAD -- src/styles/uiTokens.ts
```

Показать что изменилось, какие компоненты импортируют изменённые токены:
```bash
grep -rn "UI_TOKENS\.<изменённый токен>" src/components/
```

---

## Группы токенов (справка)

| Группа | Область |
|--------|---------|
| `UI_TOKENS.glass.*` | Стеклянные эффекты, backdrop-filter |
| `UI_TOKENS.card.*` | Карточки композиторов |
| `UI_TOKENS.card.mobile` | 🔒 FROZEN |
| `UI_TOKENS.overlay.*` | Оверлеи и модальные окна |
| `UI_TOKENS.text.*` | Цвета текста |
| `UI_TOKENS.parchment` | 🔒 FROZEN — Canvas API |
| `UI_TOKENS.connection.*` | Линии связей |
| `UI_TOKENS.era.*` | Цвета эпох |

---

## Интеграция с brain-run

brain-run автоматически вызывает верификацию токенов после каждого шага с пометкой `⚠️ UI`.
Вызывай `/ui-tokens fix` если шаг получил `[~] UI-токен нарушен`.
