# Contributing

This file is runnable with [markatzea][markatzea].

Run this file with `markatzea ./CONTRIBUTING.md` when setting up your dev environment.

## Documentation

Generate the README.md

```bash bash
pod2markdown ./lib/Test/QuickGen.pm > ./README.md
```

## Build

```bash bash
perl Makefile.PL
make
```

## Test

Running tests.

```bash bash
make test
```

## Git Hook

A pre-commit hook to update the docs.

```bash cat - > .git/hooks/pre-commit
#!/usr/bin/env bash

markatzea ./CONTRIBUTING.md
git add README.md
```

Make the script executable

```bash bash
chmod +x .git/hooks/pre-commit
```

[markatzea]:https://github.com/bas080/markatzea
