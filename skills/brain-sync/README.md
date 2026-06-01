# brain-sync — Claude Cowork Skill

Скилл для [Claude Cowork](https://claude.ai), который учит Claude работать с двусторонней синхронизацией локальных файлов ↔ claude.ai Projects.

## Что это

Если у тебя настроена система синхронизации `brain/` ↔ claude.ai Projects (через `wiki-push.py` / `wiki-pull.py` / `wiki-watch.ps1`), этот скилл даёт Claude знание о том как она устроена — чтобы он мог помогать отлаживать, запускать скрипты и объяснять что происходит.

## Установка

1. Скопируй папку `brain-sync/` в директорию скиллов Cowork:
   ```
   %APPDATA%\Claude\skills\
   ```
2. Перезапусти Claude Cowork

## Требования

- [Claude Cowork](https://claude.ai) desktop app
- Настроенная система синхронизации (см. ниже)
- `sessionKey` от claude.ai сохранённый в `~/.claude/claude-ai-session.key`

## Настройка синхронизации

Скилл предполагает что у тебя есть эти скрипты:

| Скрипт | Назначение |
|--------|-----------|
| `wiki-push.py` | Загружает `.md` файлы из локальной папки в claude.ai Project |
| `wiki-pull.py` | Скачивает файлы из claude.ai Project локально |
| `wiki-watch.ps1` | Следит за изменениями и авто-пушит через 5 сек |

### Получение session key

1. Открой [claude.ai](https://claude.ai) в браузере
2. F12 → Application → Cookies → `claude.ai` → скопируй значение `sessionKey`
3. Сохрани в файл: `~/.claude/claude-ai-session.key`

> ⚠️ **Не коммить этот файл в Git.** Добавь в `.gitignore`:
> ```
> ~/.claude/claude-ai-session.key
> ```

## Пример использования

После установки скилла Claude будет понимать такие запросы:

- *"Почему мои изменения не появились в claude.ai?"*
- *"Запусти wiki-pull чтобы обновить brain/"*
- *"wiki-watch не работает, помоги разобраться"*

## Лицензия

MIT
