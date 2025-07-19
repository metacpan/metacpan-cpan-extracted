# Contributions are welcome.

I haven't got a style file yet, but send me a PR with a note explaining
what changes are made and why you want to make them and then we'll work it out.

If you code [like this](https://tux.nl/style.html), it should be ok.
_which really means that I should create a .perltidyrc file for the module_

## Setting up you development environment

Here follows instructions on setting up your dev environment with all
the dependencies and won't pollute your main environment.
I will try to write for the perl novice.

github clone
cpanm or cpm
[local::lib](https://metacpan.org/pod/local::lib)
```
cd perl-OurWorldInData
cpanm -l local .
eval $(perl -Mlocal::lib=local)

prove -Mlocal::lib=local -lr t/
```

### On Dzil

Some devs won't work on modules that use Dist::Zilla as a build tool.
I will still accept patches as long as `prove -lr t/` passes.
