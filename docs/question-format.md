# Question file format

The importer reads a UTF-8 Markdown file. Example (from `gyakorlo_teszt_osszes_valasz.md`):

```markdown
# Gyakorló teszt – összes válasz

Forrás: judo.maze.hu, Gyakorló teszt (próbálkozás 8986, 2026-11-21).

## 3.

1. ✔ A ***„Yoshi”*** jelentése, **fojtasd.**
2. A „Yoshi” jelentése, állj.
3. A „Yoshi” jelentése, rajta.
4. A „Yoshi” jelentése, ne mozdulj.
```

## Rules

| Element | Meaning |
|---|---|
| `# Title` (first level-1 heading) | set title |
| other text before the first question | description (shown on the set page only) |
| `## <number>.` | starts a question; the number is the display order. Text after it (`## 3. Válassza ki a helyes választ`) is an optional prompt |
| `1. …`, `2. …` under the heading | the options, normally 4 |
| `✔ ` right after the list number | the correct option – exactly one per question |
| `***text***` in the correct option | subject |
| `**text**` in the correct option | words that distinguish it from the wrong options |
| `*(text)*` at the end of an option | note, shown only in feedback (e.g. `*(a teszt ezt is elfogadja, de nem helyes)*`) |
| blank lines | ignored |

- During the quiz all emphasis is removed and the options are shuffled; the feedback view shows the correct option with its emphasis.
- Text is kept exactly as written, including the source's typos.
- Any other line inside a question is a validation error.

## Question key

`key` = the first 16 hex characters of the SHA-256 of the correct option's plain text (emphasis markers removed, whitespace collapsed, trimmed). Changing only emphasis keeps the key; changing the text gives a new key, and progress for that question starts again.

## Validation

The validator reports:

- questions with no ✔ or more than one ✔
- questions with fewer than 2 options
- duplicate keys (two questions with the same correct text)
- identical options within one question
- lines that could not be parsed

The import is blocked while there are errors; warnings (e.g. a question with 3 or 5 options) are shown in the preview.
