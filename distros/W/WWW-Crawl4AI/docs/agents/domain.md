# Domain Docs

Wie die Engineering-Skills die Domänen-Doku dieses Repos lesen sollen, wenn sie den
Code erkunden.

## Vor dem Erkunden lesen

- **`CONTEXT.md`** im Repo-Root — das Glossar / die Domänensprache.
- **`docs/adr/`** — die ADRs, die den Bereich berühren, an dem gerade gearbeitet wird.

Dies ist ein **Single-context**-Repo: ein `CONTEXT.md` plus `docs/adr/` im Root.

Wenn eine dieser Dateien nicht existiert, **stillschweigend fortfahren**. Ihr Fehlen
nicht melden und nicht vorab vorschlagen, sie anzulegen. Die Producer-Skills legen
sie erst dann an, wenn Begriffe oder Entscheidungen tatsächlich fixiert werden.

## Dateistruktur

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-….md
│   └── 0002-….md
└── lib/
```

## Das Glossar-Vokabular verwenden

Wenn die Ausgabe ein Domänenkonzept benennt (Issue-Titel, Refactor-Vorschlag,
Hypothese, Testname), den in `CONTEXT.md` definierten Begriff verwenden. Nicht zu
Synonymen abdriften, die das Glossar bewusst vermeidet.

Fehlt das benötigte Konzept noch im Glossar, ist das ein Signal — entweder wird
Sprache erfunden, die das Projekt nicht nutzt (überdenken), oder es gibt eine echte
Lücke (für die Doku-Producer notieren).

## ADR-Konflikte melden

Widerspricht die Ausgabe einem bestehenden ADR, das explizit ansprechen statt
stillschweigend zu übergehen:

> _Widerspricht ADR-0007 (…) — aber einen erneuten Blick wert, weil …_
