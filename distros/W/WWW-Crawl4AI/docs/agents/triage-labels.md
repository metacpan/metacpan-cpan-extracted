# Triage Labels

Die Skills sprechen in fünf kanonischen Triage-Rollen. In diesem Repo sind sie als
**karr-Tags** mit ihren Standardnamen abgebildet.

| Rolle in mattpocock/skills | karr-Tag          | Bedeutung                                  |
| -------------------------- | ----------------- | ------------------------------------------ |
| `needs-triage`             | `needs-triage`    | Maintainer muss das Issue bewerten         |
| `needs-info`               | `needs-info`      | Wartet auf Rückmeldung des Reporters       |
| `ready-for-agent`          | `ready-for-agent` | Vollständig spezifiziert, AFK-Agent-bereit |
| `ready-for-human`          | `ready-for-human` | Braucht menschliche Implementierung        |
| `wontfix`                  | `wontfix`         | Wird nicht bearbeitet                      |

Anwenden / entfernen:

```bash
karr edit <id> --add_tag ready-for-agent
karr edit <id> --remove_tag needs-triage
karr list --tag ready-for-agent          # nach Rolle filtern
```

Wenn ein Skill eine Rolle nennt (z. B. „apply the AFK-ready triage label"), den
passenden Tag-String aus dieser Tabelle verwenden. Üblicherweise trägt ein Ticket
genau einen Rollen-Tag zur Zeit — beim Weiterreichen den alten entfernen und den
neuen setzen.

Die rechte Spalte editieren, falls ihr andere Tag-Namen verwenden wollt.
