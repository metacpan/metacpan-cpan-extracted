A Modern Perl module to fill in gaps in a CSV file

Creating a new file preserves the original data, which is always a good
insurance policy. A log file is created upon each run, detailing the field and the data gap which was filled. Not found data is not mentioned, only positive matches are.

Installation
------------
The best and easiest way is with [cpanm](https://metacpan.org/release/App-cpanminus):

```
cpanm Text::CSV::Merge
```

This will also install its dependencies, which include Text::CSV_XS, DBI, DBD::CSV and a few other, rather common modules.

Why
---
I needed to fill in gaps in user demographics from legacy data formats. I converted them into CSV and wrote this Perl script to automate this; The base CSV file had over 11,000 rows, with 8,000 more rows collected from various, years-old data sources.

Development
-----------
Text::CSV::Merge is built upon [Moo](https://metacpan.org/module/Moo).

Module packaging is performed by the really time-saving [Dist::Zilla](https://metacpan.org/module/Dist::Zilla).

Coding is done mostly in Vim on Windows (Console2 with the TCC/LE shell), but also in Notepad2 in a pinch.

Future Directions
-----------------
To update an existing CSV file in place, using Tie::CSV could be a decent choice (?).
