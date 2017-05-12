# NAME

Test::Requires::Scanner - retrieve modules specified by Test::Requires

# SYNOPSIS

    use Test::Requires::Scanner;
    my $modules2version_hashref = Test::Requires::Scanner->scan_files('t/hoge.t', 't/fuga.t');

# DESCRIPTION

App::TestRequires::Scanner is to retrieve modules specified by [Test::Requires](https://metacpan.org/pod/Test::Requires) in
test files. It is useful for CPAN module maintainer.

## METHODS

- `$hashref = Test::Requires::Scanner->scan_string($str)`
- `$hashref = Test::Requires::Scanner->scan_file($file)`
- `$hashref = Test::Requires::Scanner->scan_files(@files)`

    A key of `$hashref` is module name and a value is version.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
