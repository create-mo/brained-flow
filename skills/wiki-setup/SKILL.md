---
name: wiki-setup
description: >
  Skill for setting up the brain/ ↔ claude.ai Projects sync system from scratch.
  Use this skill when the user wants to install, configure, or replicate the wiki sync
  system on a new machine, add a new project to sync, update ORG_ID or project IDs,
  set up autostart for wiki-watch, or troubleshoot the initial setup. Trigger on:
  "настрой синхронизацию", "как поставить wiki sync", "добавь новый проект в sync",
  "wiki-setup", "autostart wiki-watch", "как устроен brain", "obsidian и claude".
---

# wiki-setup

## Что такое brain/

`brain/` — персональная вики-база знаний, хранящаяся локально и синхронизируемая с облаком. Это единое место где живут:

- **projects/** — вики по каждому проекту: карта файлов, архитектура, решения, дневники работы
- **knowledge/** — личная база знаний вне конкретных проектов (паттерны, инструменты, принципы)
- **resources/** — шаблоны и сниппеты
- **journal/** — личный дневник

Все файлы — Markdown (`.md`). Это сознательный выбор: `.md` читается везде, хранится в Git, работает в Obsidian и понимается Claude.

## Зачем синхронизировать с claude.ai Projects

claude.ai Projects — это контекст который Claude видит в каждом разговоре внутри проекта. Если загрузить туда вики проекта, Claude будет знать архитектуру, решения, договорённости — без повторного объяснения.

Флоу:
```
Редактируешь brain/ на ПК
    → wiki-watch замечает изменение через 5 сек
    → wiki-push.py загружает файл в claude.ai Project
    → Claude на мобилке видит актуальный контекст

Работаешь с Claude на мобилке, он обновляет файлы в Project
    → При входе на ПК wiki-pull.py скачивает изменения в brain/
```

## Wiki как рабочая среда: планирование и выполнение

Brain — не просто база знаний для чтения. Это активная рабочая среда, встроенная в цикл разработки.

### Структура проектной вики

Каждый проект в `brain/projects/<project>/` содержит:

| Файл | Назначение |
|------|-----------|
| `README.md` | Обзор проекта, стек, ключевые ограничения |
| `map.md` | Карта файлов и модулей проекта |
| `architecture.md` | Архитектурные решения |
| `state.md` | Текущее состояние (модели, конфиг, задачи) — источник правды |
| `solutions.md` | Нетривиальные проблемы и их решения — хронология |
| `known-issues.md` | Дистиллят из solutions.md — читать перед работой |
| `.raw_nuances.md` | Архитектурные нюансы, инварианты, неочевидные паттерны |
| `journal/` | Дневник сессий по датам |

### Цикл планирование → выполнение

```
/brain-plan <задача>         → создаёт plans/<дата>_<slug>.md
       ↓
/brain-run                   → выполняет шаги через субагентов
       ↓
solutions.md + known-issues.md  → фиксируют найденные решения
       ↓
wiki-push                 → контекст доступен Claude в следующей сессии
```

### Планирование (`/brain-plan`)

Перед созданием плана `/brain-plan` вызывает `/wiki <тема>` — извлекает только релевантные