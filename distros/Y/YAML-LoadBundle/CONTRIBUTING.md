Contributing to p5-YAML-LoadBundle
==================================

We welcome contributions, whether they be pull requests, documentation fixes,
new issues, or even publicity.

The YAML::LoadBundle distribution is managed by [Dist::Zilla](http://dzil.org)
this provides a lot of benefits for managing releases and modules at the
expense of longer a learning curve.

## Getting Started

To get started, we recommend that you use
[App::Plenv](https://github.com/tokuhirom/plenv)
and the [perl-build](https://github.com/tokuhirom/perl-build) plugin
to install a recent version of perl to test with.

Once you have plenv and the perl-build plugin installed,
you can install a version of perl to use for development.

    plenv install 5.24.0 --as=YAML-LoadBundle

In your p5-YAML-LoadBundle checkout, you can specify to use that perl install:

    cd p5-YAML-LoadBundle/
    plenv local YAML-LoadBundle

You can then install cpanm, Dist::Zilla and the required dzil plugins:

    plenv install-cpanm
    dzil authordeps | cpanm -n

And the dependencies to use YAML::LoadBundle

    dzil listdeps | cpanm -n

You can test that it works now with:

    dzil test

From then on you can use the github contribution workflow.
Forking the repo, making commits with good commit messages and submitting
a pull request.
