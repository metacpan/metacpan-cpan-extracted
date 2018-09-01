# Test::Harness::KS
Harness the power of clover and junit in one easy to use wrapper.

## Usage
```
cpanm Test::Harness::KS
test-harness-ks --help
```

## Setting up developing environment

Test::Harness::KS uses Dist::Zilla for packaging.

```
cpanm Dist::Zilla
cpanm $(dzil authordeps)
cpanm $(dzil installdeps)
```

Dev your feature.

Then

```
dzil smoke
```

## Releasing new versions

```
dzil release
```

