Check if the result is any of the distinct expected values.

Used in the teaching materias of [Perl Maven](https://perlmaven.com/)


## Release process

* Increase version number at the top of `lib/Test/IsAny.pm` to 0.02.

```
git add  lib/Test/IsAny.pm
git commit -m "update version number to 0.02"
git push
# wait for the CI to succeed

perl Makefile.PL
make
make test
make manifest
make dist

git tag -a v0.02 -m 'release v0.02'
git push --tags

# upload to PAUSE
```

