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
| `*(text)*` at the end of an option | note, right or wrong option; shown under the option only after answering, in a highlight colour (yellowish on dark, bluish on light) – e.g. `*(a teszt ezt is elfogadja, de nem helyes)*`, `*(1860 + 22 = 1882)*`. Both `*` are needed: without the closing one the text stays in the option, visible before answering (warning) |
| blank lines, `---` | ignored |
| a level-1 heading **after** the questions (`# Trivia`) | starts the trivia part – see below |

- During the quiz all emphasis is removed and the options are shuffled; the feedback view shows the correct option with its emphasis.
- Text is kept exactly as written, including the source's typos.
- Any other line inside a question is a validation error.

## Trivia (D-016)

After the last question, a level-1 heading (`# Trivia`) starts the **trivia** part: short „Tudtad?” items that pop up in the app after an answer – right or wrong – whose **correct option** contains one of the item's keywords.

```markdown
---

# Trivia

## EB helyezések

Ezt figyeld! EB-ken
- ***Kovács János*** **1961-ben Milánóban** II. helyezést ért el.
- ***első*** magyar ***felnőtt Európa-bajnok Tuncsik József*** volt, **1976**-ban Kievben.

[európa bajnok], [európa-bajnok]
```

| Element | Meaning |
|---|---|
| `## Title` | starts an item; the title is shown in the pop-up |
| text lines, `- ` bullets | the item's text, with `***subject***` and `**bold**` as in the answers |
| `[a, b]` or `[a], [b]` (a line of its own, one or more) | the keywords, separated by commas |

- **Matching:** a keyword matches when the correct option's plain text **contains** it, ignoring upper/lower case and extra spaces. It is plain text matching, so word endings matter: `olimpia` matches „olimpiai” but not „Olimpián”; `olimpi` matches both.
- Several items may match one answer; they are shown together, in file order.
- An item without a keyword line uses its title as the keyword (warning). Text between `# Trivia` and the first `##` is ignored (warning).
- Re-importing a file replaces the set's trivia.

## Question key

`key` = the first 16 hex characters of the SHA-256 of the correct option's plain text (emphasis markers removed, whitespace collapsed, trimmed). Changing only emphasis keeps the key; changing the text gives a new key.

When an existing set is updated and a question with a new key has **the same number** as a question that disappears, it is taken to be that question with its text fixed: it remembers the old key (`previousKeys`), and everyone's progress recorded under the old key is carried over (D-017). So fixing typos in the correct answers keeps progress as long as the numbers stay; renumbering and changing an answer in the same import does not.

## Validation

The validator reports:

- questions with no ✔ or more than one ✔
- questions with fewer than 2 options
- duplicate keys (two questions with the same correct text)
- identical options within one question
- lines that could not be parsed

The import is blocked while there are errors; warnings (e.g. a question with 3 or 5 options) are shown in the preview.
