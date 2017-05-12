# WebService::HabitRPG - Perl interface to the HabitRPG API

## To install (stable version)

    cpanm WebService::HabitRPG

You'll probably find it useful to have a `~/.habitrpgrc` file that
looks like the following:

    [auth]
    user_id   = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    api_token = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

You can get these values by going to Settings -> API in HabitRPG.

Use `hrpg` without any arguments to see command line help.

You can find documention of the stable release on the CPAN:

* https://metacpan.org/module/WebService::HabitRPG
* https://metacpan.org/module/hrpg

## Using a Mac?

If you've got a weird error that Data::Alias fails to install
on your Mac or other dtrace-friendly system, there's a patched version you can
install with:

    cpanm https://dl.dropbox.com/u/9702672/cpan/Data-Alias-1.16-dtrace-patched.tar.gz

Which contains the patches in [RT #75156](https://rt.cpan.org/Public/Bug/Display.html?id=75156).  Upgrading to Perl 5.14 or above should also work. 

## To develop / contribute

* Fork this repository
* Install Dist::Zilla (`cpanm Dist::Zilla`)
* `dzil build`

You can install the built module with `cpanm WebService-HabitRPG-*.tar.gz`
