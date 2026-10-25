# WWW::Crawl4AI — Hausregeln

Gelten für jede Aufgabe in diesem Repo. Automatisch geladen für den
orchestrierenden Agenten; Subagenten bekommen ihr Wissen über `briefing.skills`.

## Disziplin

1. **Erst denken** — Annahmen nennen, bei Unklarheit fragen, nicht raten.
2. **Einfach zuerst** — minimaler Code, nichts Spekulatives.
3. **Chirurgisch** — nur anfassen, was die Aufgabe braucht; bestehenden Stil treffen.
4. **Laut scheitern** — „fertig" ist falsch, wenn etwas übersprungen wurde.
5. **Ein roter Test ist eine Behauptung** — erst sagen, was er behauptet, dann Code ändern.

## Delegation

- **Du kannst Subagenten starten** (Hauptagent): verhaltensrelevanten Code nicht
  selbst anfassen — delegieren. Deine Spur: koordinieren, planen, Diffs reviewen,
  Tests laufen lassen, reine Prosa-Doku.

  | Aufgabe | Agent |
  |---|---|
  | Implementieren / refactoren / debuggen / testen | `crawl4ai-worker` |
  | Commits, `Changes`, Karte → done, Release-Audit | `crawl4ai-release-manager` |
  | URL live durch die Strategy Chain, Fehlklassifikation diagnostizieren | `crawl-chain-probe` |
  | Skill / CONTEXT.md / ADRs gegen den Code auf Drift prüfen | `docs-drift-auditor` |
  | karr-Tickets triagieren und labeln | `karr-triage` |

- **Du bist ein Subagent**: die Sperre gilt nicht für dich — arbeite deine Spur.

Verhaltensrelevant = Laufzeitverhalten, öffentliche API, Chain und Detect-Logik,
Fehlerbehandlung, Tests. Reine Prosa-Doku und README nicht.

**Nur `crawl4ai-release-manager` committet.** Ein Worker hinterlässt einen
commit-fertigen Tree und gibt seine Karte nach `review`; dann schickst du
`crawl4ai-release-manager`, der committet und die Karte schließt.

## Koordination — karr

Board in `refs/karr/*`; Befehle: `docs/agents/issue-tracker.md`, voller Umfang:
Skill `kanban-issues-karr-coordination`. Du pickst, claimst und legst Karten an;
der Worker bearbeitet nur die übergebene Karte bis `review`. Board-Mutationen beim
Auffächern nacheinander, nie N gleichzeitig.

## Nie ohne Erlaubnis

`dzil release`, CPAN-Upload, `git push`, Tags — nur auf ausdrückliches Go des
Maintainers, auch wenn ein Plan „release" als nächsten Schritt nennt.
