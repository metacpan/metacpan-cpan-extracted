Contributing to Grant Street Group Open Source Projects
=======================================================

Grant Street Group welcomes contributions, whether they be pull requests,
documentation fixes, new issues, or even publicity.

Our Open Source code lives on GitHub at https://github.com/GrantStreetGroup

The Grant Street code on GitHub follows the standard [GitHub Flow](https://help.github.com/en/articles/github-flow).  This means forking the repo, creating a branch, making commits, and creating a Pull Request.  We also welcome new GitHub Issues for any of our projects.

If you have any questions about things that aren't covered here, we can hopefully provide more help if you email <developers@grantstreet.com>.

## Getting Started

If you have carton available you should just be able to
clone this repo, change to the directory, and run `make test`.

### Installing dependencies

The dependencies for this project are listed in its `cpanfile`,
this file is usually handled by [Carton](https://metacpan.org/pod/Carton).

Installing Carton can be done with any CPAN client into whichever version of perl you want to use.

If you don't have permission, or just don't want to install things into your system perl, you can use [App::Plenv](https://github.com/tokuhirom/plenv) and the [perl-build](https://github.com/tokuhirom/perl-build) plugin, or [Perlbrew](https://perlbrew.pl/) to install different versions of perl.

Once you have a version of perl to use for testing this, if you don't have a preference for a CPAN client, we recommend you use [cpanminus](https://metacpan.org/pod/App::cpanminus#Installing-to-system-perl).

With `plenv` you are able to get cpanminus with `plenv install-cpanm`.

Otherwise, quoting the cpanminus quickstart instructions:

> Quickstart: Run the following command and it will install itself for you.
> You might want to run it as a root with sudo if you want to
> install to places like /usr/local/bin.
>
>   `% curl -L https://cpanmin.us | perl - App::cpanminus`
>
> If you don't have curl but wget, replace `curl -L` with `wget -O -`.

Once you have cpanminus, you can install Carton with:

    cpanm Carton

With `carton` available, you can run `make test` and make sure tests pass.  If they do, you're ready to start making changes and get ready to create a Pull Request.

### Using Dist::Zilla

The release of this distribution is managed by [Dist::Zilla](http://dzil.org) which provides a lot of benefits for managing releases and modules at the expense of longer a learning curve.

However, you probably don't need it unless you want to build a release or run author tests.

In order to work with Dist::Zilla's `dzil` you will need to run `carton install` manually as the Makefile uses `--without develop` to avoid unnecessary dependencies.

Once those dependencies are installed, you need to use `carton exec dzil` so it can find them.

