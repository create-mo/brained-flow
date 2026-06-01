---
description: >
  Wiki для vitejs-vite-6hpxonsb: полный update-цикл или быстрый ctx-lookup.
  /wiki → полный цикл (distill + scan + apply + sync).
  /wiki <тема> или /wiki --ctx <тема> → читать wiki по теме (graph-routing, экономия контекста).
  /wiki --status → актуальность .sync без записи.
  /wiki --nuances → только обработать .raw_nuances.md без сканирования кода.
  /wiki --plan → только синхронизировать активный план с git-изменениями.
---

**WIKI_DIR:** `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb`
**MANIFEST:** `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\_manifest.json`

---

## Шаг 0 — Определить режим

Проверить `$ARGUMENTS`:

| Вызов | Режим | Переход |
|---|---|---|
| `/wiki` (пусто) | **update** — полный цикл | → [UPDATE](#update) |
| `/wiki <слово>` (не начинается с `--`) | **ctx** — lookup по теме | → [CTX](#ctx) |
| `/wiki --ctx <тема>` | **ctx** — явный lookup | → [CTX](#ctx) |
| `/wiki --status` | **status** — проверить .sync | → [STATUS](#status) |
| `/wiki --nuances` | **nuances** — только нюансы | → [NUANCES](#nuances) |
| `/wiki --plan` | **plan** — только матч плана | → [PLAN](#plan) |

---

## ══ CTX — lookup по теме ══ {#ctx}

**Цель:** экономия контекста (~60-70%) через graph-augmented retrieval — читать только 2-3 релевантных файла вместо всей wiki.

### CTX-1 — Читать манифест

```
Read: C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\_manifest.json
```

### CTX-2 — Резолвить тему → файлы

Тема = `$ARGUMENTS` без `--ctx` (trim пробелов, lowercase).
Если передано несколько слов → проверить каждое отдельно, объединить уникальные файлы.

Приоритет поиска в `manifest.topics`:
1. Exact match
2. Substring match (тема содержится в ключе или ключ содержится в теме)
3. Fallback → `manifest.default_fallback` (обычно `["map.md"]`)

Ограничение: ≤3 файла (по `routing_notes.context_budget`).
Если у найденного файла есть `reads_before` в frontmatter → предварить им (обычно `map.md`).

**Быстрая справка тема → файлы:**

| Тема | Файлы |
|---|---|
| `bugs` / `issues` / `solutions` | `known-issues.md`, `solutions.md` |
| `audio` / `synthesis` / `player` | `architecture.md`, `data.md`, `glossary.md` |
| `vexflow` / `score` / `print` | `map.md`, `glossary.md`, `known-issues.md` |
| `architecture` / `rendering` / `pixi` / `webgl` | `architecture.md`, `map.md` |
| `data` / `supabase` / `schema` / `migrations` | `data.md`, `map.md` |
| `minimax` / `wav` / `music21` | `known-issues.md` |
| `connections` / `links` / `influence` | `data.md`, `glossary.md` |
| `medusa` / `effects` / `acoustic` | `map.md`, `glossary.md` |
| `layout` / `geometry` / `coordinates` / `wheel` | `architecture.md`, `glossary.md` |
| `eras` / `colors` / `lod` | `architecture.md`, `glossary.md` |
| `typescript` / `react` / `eslint` | `known-issues.md` |

### CTX-3 — Читать файлы

```
Read: C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\<file>
```

Если суммарный объём > 10k токенов → агрессивная фильтрация: читать только первые 2 файла.

### CTX-4 — Ответить

```
**Тема:** <тема>
**Файлы:** <список прочитанных>

[Содержимое — только релевантная информация по теме]
```

Если файлов > 3 — предупредить:
```
**Внимание:** найдено <N> файлов. Читаю только <первые 2>.
Остальные: <список>. Если нужны — запроси явно.
```

---

## ══ STATUS — проверить актуальность ══ {#status}

Прочитать `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\.sync`.

```bash
git log -1 --format="%H %ci"
```

Сравнить с commit в `.sync`. Показать:
- Последний wiki-update: дата
- Коммитов с тех пор: N (`git log <sync-sha>..HEAD --oneline -- src/ | wc -l`)
- Статус: ✅ актуальна / ⚠️ устарела (>0 коммитов)

Никаких записей, только отчёт.

---

## ══ NUANCES — только нюансы ══ {#nuances}

Только обработка `.raw_nuances.md` → `nuances.md`. Без git-сканирования, без субагента.

Прочитать `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\.raw_nuances.md`.

Если пуст или не существует → вывести: `нет сырых нюансов`. Стоп.

Формат сырых записей от `/brain-run` агентов:
```markdown
## <YYYY-MM-DD> | <plans/filename.md> | Шаг N «название»

**Проблема/нюанс:** <описание>
**Контекст:** <файл/паттерн>
**Решение/наблюдение:** <что помогло>
**Файлы:** <src/path/file.ts:строка>
**Теги:** #тег1 #тег2
```

Для каждой записи → определить раздел по тегам → записать компактно в `nuances.md` → после обработки очистить `.raw_nuances.md`.

Целевые разделы: `## InMapMedusa`, `## AudioPlayerBlock`, `## VexScore`, `## Кэширование`, `## Инварианты` (или создать новый по контексту).

Компактный формат:
```markdown
### Короткое название
- **Файл:** `src/path/file.ts`
- **Нюанс:** однострочное объяснение "почему это важно"
```

Если похожая запись уже есть → смёрджить, не дублировать.

---

## ══ PLAN — только матч плана ══ {#plan}

Только синхронизация активного плана с git-изменениями. Без wiki-сканирования, без субагента.

```bash
git status --short
git diff --stat HEAD
```

`mcp__ide__getDiagnostics` — TS/ESLint ошибки в изменённых файлах.

Найти активный план: `Grep("🔄 В работе", "plans/*.md", output_mode: "files_with_matches")`.

Если найден — для каждого изменённого файла матч с полем **Файлы** в шагах плана:
- изменён + нет ошибок → `[x] Выполнено`
- изменён + есть ошибки → `[~] Ошибки: <список>`
- не тронут → `[ ]` без изменений

Обновить план-файл: чекбоксы + `## Лог выполнения`:
```
**<дата> /wiki --plan** — Шаг N: <файлы>, <итог>
```

Изменения вне плана → `внеплановые: <список>` в лог.
Если все `[x]` → `🔄 В работе` → `✅ Выполнено`.

`TaskList` → `[план]`-таски выполненных шагов → `TaskUpdate` completed.

Отчёт: какие шаги отмечены, что вне плана.

---

## ══ UPDATE — полный цикл ══ {#update}

**Цель:** синхронизировать план с кодом, дистиллировать сырые нюансы, актуализировать wiki по git delta.
**Методология:** сначала нюансы (`.raw_nuances.md` → `nuances.md`), потом delta-scan через Explore-субагент. Главный контекст не тратится на сканирование кода.

---

### UPDATE-1 — Матч прямых изменений → активный план

```bash
git status --short
git diff --stat HEAD
```

`mcp__ide__getDiagnostics` — TS/ESLint ошибки в изменённых файлах.

Найти активный план: `Grep("🔄 В работе", "plans/*.md", output_mode: "files_with_matches")`.

Если найден → матч изменённых файлов с шагами плана (поле **Файлы**):
- изменён + нет ошибок → `[x] Выполнено`
- изменён + есть ошибки → `[~] Ошибки: <список>`
- не тронут → `[ ]` без изменений

Обновить план-файл: чекбоксы + `## Лог выполнения`:
```
**<дата> /wiki** — Шаг N: <файлы>, <итог>
```

Изменения вне плана → `внеплановые: <список>`.
Если все `[x]` → `🔄 В работе` → `✅ Выполнено`.

`TaskList` → `[план]`-таски → `TaskUpdate` completed.

---

### UPDATE-2 — Вычислить дельту

Прочитать `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\.sync`:
```
commit: <sha>
date: <дата>
```

Если файл существует — дельта от снимка:
```bash
git log --oneline <sha>..HEAD -- src/ supabase/migrations/ src/types/ src/lib/
```

Если файла нет → **первый запуск**, полный скан `src/`.

Если `git log` вернул пустой список → `wiki актуальна, нет изменений с <дата>`. Стоп.

---

### UPDATE-3 — Обработка сырых нюансов

*Выполнить логику NUANCES-режима здесь (не вызывать отдельно).*

Прочитать `.raw_nuances.md`. Если пуст — пропустить.
Дистиллировать в `nuances.md`, очистить `.raw_nuances.md`.

---

### UPDATE-4 — Автономный сбор решений + спавн Explore-субагента

Перед субагентом — автономно просмотреть `git diff HEAD -- src/` на паттерны нетривиальных решений:
- workaround-комментарии (`// TODO`, `// HACK`, `// workaround`, `// fix`)
- необычные type cast (`as unknown as`, `@ts-ignore`)
- нестандартные API-вызовы с пояснением

Если найдено → дописать в `C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\solutions.md`.

Спавн `Agent tool, subagent_type=Explore`. Передать дословно:

```
Ты обновляешь wiki проекта (путь: C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\) для React 19 + TypeScript + PixiJS + Supabase проекта.

ПРИНЦИП ДИСТИЛЛЯЦИИ (Karpathy LLM-wiki):
Вопрос не "что здесь есть", а "что нужно знать через 3 месяца не читая код?":
- Архитектурные решения и ПОЧЕМУ они такие
- Паттерны, которые нигде явно не задокументированы
- Ключевые ограничения и инварианты системы
- Что можно легко сломать и почему

НЕ дистиллируй:
- Очевидные file listings — код сам это говорит
- Мелкие багфиксы без архитектурного следствия
- Boilerplate и конфиги

PROVENANCE — помечай каждое нетривиальное утверждение:
- ^[extracted] — буквально видно в коде/комменте
- ^[inferred] — вывод из паттернов кода (не написано явно)
- ^[critical] — инвариант, нарушение которого ломает систему

---

ИЗМЕНЁННЫЕ ФАЙЛЫ С ПОСЛЕДНЕГО WIKI-UPDATE:
<вставь git log из UPDATE-2>

ТЕКУЩИЙ КОНТЕНТ WIKI (путь: C:\Users\user\ВОблако\brain\projects\vitejs-vite-6hpxonsb\):
- map.md
- architecture.md
- data.md
- glossary.md

ЧТО НУЖНО НАЙТИ:
1. Файлы в src/ которых нет в map.md (новые) → прочитать первые 40 строк, определить назначение
2. Записи в map.md для файлов которых больше нет (устарели)
3. Изменения в src/types/, src/lib/supabase.ts → обновить data.md
4. Новые суперважные паттерны в src/pixi/, src/hooks/, src/utils/ (>100 строк, нетривиальные) → architecture.md
5. Новые миграции в supabase/migrations/ → data.md
6. Новые термины в коде которых нет в glossary.md

ФОРМАТ ОТЧЁТА (под 500 слов):

## DELTA

### ADD to map.md
- `src/path/file.ts`: <назначение, 1 строка> ^[extracted]

### REMOVE from map.md
- `src/path/old.ts`: больше не существует

### UPDATE map.md
- `src/path/file.ts`: <что изменилось в роли> ^[inferred]

### ADD to architecture.md
<секция: название паттерна>
<2-4 предложения: что это, почему так, что ломается если нарушить> ^[critical если применимо]

### UPDATE data.md
- table.column: <added/removed/changed>
- migration NNN_xxx.sql: <что меняет в схеме>

### ADD to glossary.md
- `Термин`: определение ^[extracted/inferred]

### НИЧЕГО НЕ МЕНЯТЬ
<список стабильных разделов — не трогать>
```

---

### UPDATE-5 — Применить правки

По отчёту субагента — `Edit` (точечные правки) или `Write` (секция полностью пересоздаётся).

Правила:
- Язык — русский, тон и структура существующих файлов сохраняются
- `^[inferred]` и `^[critical]` — оставлять в тексте wiki как есть
- Если появилась целая новая подсистема (>5 файлов одной темы) → предложить пользователю создать отдельный wiki-файл, не делать молча
- Не трогать `README.md` если структура wiki не менялась

**Обязательно: frontmatter + wikilinks**

Каждый wiki-файл должен иметь YAML-шапку:
```yaml
---
tags: [<теги через запятую>]
summary: <1-2 предложения, ≤150 символов>
updated: <YYYY-MM-DD>
---
```

⚠️ **Не писать `related:` в frontmatter** — Obsidian создаёт узлы-призраки. Связи только через `[[wikilinks]]` в теле (секция `## Связи`).

Теги из: `map` `architecture` `data` `schema` `audio` `rendering` `pixi` `react` `layout` `geometry` `glossary` `terms` `migrations` `fallback` `visual`

При обновлении файла → обновить `updated:` на текущую дату.

---

### UPDATE-5б — Обновить known-issues.md из solutions.md

Если `solutions.md` существует и имеет новые записи (после последней даты в `known-issues.md`):

Дистиллировать: сгруппировать по тегам, убрать дубли. Обновить/создать `known-issues.md`:

```markdown
---
tags: [known-issues, solutions, blockers]
summary: Дистиллированные проблемы и решения. Читается /brain-plan и агентами /brain-run.
updated: <YYYY-MM-DD>
---

# Known Issues & Solutions

> Дистиллят из `solutions.md`. Обновляется при каждом `/wiki`.
> **НЕ редактировать вручную** — источник правды: `solutions.md`.

## #typescript
...

## Связи

[[solutions]] · [[architecture]] · [[data]]
```

Правила: одна проблема = одна запись; группировать по тегам (#typescript, #pixi, #supabase, #layout, #audio, #react); только суть + файл.

---

### UPDATE-6 — Обновить .sync + CHANGELOG

```bash
git log -1 --format="%H"
git log -1 --format="%ci"
```

Перезаписать `.sync`:
```
commit: <новый HEAD sha>
date: <YYYY-MM-DD>
note: /wiki <YYYY-MM-DD>
```

Дописать в `CHANGELOG.md`:
```markdown
## <YYYY-MM-DD> /wiki

**Нюансы:** <N обработано из .raw_nuances.md>
**Изменено:** <N ADD, M UPDATE, K REMOVE wiki-файлов>
**Затронутые файлы:** map.md | architecture.md | data.md | glossary.md | nuances.md
**Триггер:** <кратко — что изменилось в src/ после прошлого /wiki>
**Distilled:** <самое важное знание этой сессии — 1 предложение>
```

---

### UPDATE-7 — Отчёт

4–5 предложений:
- Нюансы: сколько обработано из `.raw_nuances.md`
- Что добавлено в wiki (новые файлы/паттерны)
- Что обновлено (schema, роли файлов)
- Что удалено
- Главное знание которое теперь в wiki и раньше не было (distilled insight)
