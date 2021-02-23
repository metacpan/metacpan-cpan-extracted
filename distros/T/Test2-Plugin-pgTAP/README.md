# NAME

App::Yath::Plugin::pgTAP - Plugin to allow testing pgTAP files.

# SYNOPSIS

\# Use it with yath to execute your pgTAP tests:

    $ yath test --plugin pgTAP --pgtap-suffix .pg \
                --pgtap-dbname=try \
                --pgtap-username=postgres

# DESCRIPTION

This module set invocation support for executing pgTAP PostgreSQL tests under [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness) and yath.

# SOURCE

The source code repository for Test2-Harness can be found at
[http://github.com/Test-More/Test2-Harness/](http://github.com/Test-More/Test2-Harness/).

# SEE ALSO

- [http://pgtap.org](http://pgtap.org)
- [Test2::Harness](https://metacpan.org/pod/Test2%3A%3AHarness)

# MAINTAINERS

- Yves Lavoie <ylavoie@cpan.org>

# AUTHORS

- Yves Lavoie <ylavoie@cpan.org>

# COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
