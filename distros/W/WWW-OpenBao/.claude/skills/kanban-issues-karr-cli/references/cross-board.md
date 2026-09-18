# Cross-board dependencies: needs, escalated-from, karr needs

`--depends-on` is board-local. When work here cannot proceed until something
is fixed in **another repository**, that link is a cross-board dependency.

```bash
# in the other repository — raise the card and record where it came from
karr create "Fix the API" --escalated-from home#5

# here — record what you are waiting for, block, release the claim, leave
karr edit 5 --add-needs other-repo#7 --block "needs other-repo#7: API change first" --release

# any time — what is this board waiting on, and is it done yet?
karr needs
karr needs 5,6                                    # only these cards
karr needs --board other-repo=/srv/other-repo     # where that board is on THIS machine (repeatable)
karr needs --fleet-config FILE                    # default ~/.config/karr-foundation/config.yml
karr needs --resolve                              # drop settled links, unblock what is free
karr needs --json
```

A reference is `BOARD#ID`: the other board's **name** and a card id. Never a
path — the card is shared state and two clones of one fleet have different
directories. karr maps the name to a directory from `--board NAME=PATH` or
from the fleet config, matching the repository's directory basename.

`--resolve` settles a link whose far card has reached one of the **far**
board's own terminal statuses, and lifts `blocked` when a card's last link
settles, printing the reason it lifted. A far card that does not exist settles
nothing. A board this machine cannot place is reported, not fatal.

Like `depends_on`, a cross-board link blocks nothing by itself: `pick` hands
the card over and says what it waits on. The `blocked` flag is what keeps the
card out of `pick` and out of karr-foundation's selection — the link is the
fact, `blocked` is the decision.

## How it is stored

The links ride in `tags` (`needs:BOARD#ID`, `escalated-from:BOARD#ID`), not
in a frontmatter field of their own: kanban-md marshals a card from its own
struct and would drop an unmodelled key the first time it writes, while `tags`
is modelled on both sides.
