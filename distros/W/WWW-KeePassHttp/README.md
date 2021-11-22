# NAME

WWW::KeePassHttp - Interface with KeePass PasswordSafe through the KeePassHttp plugin

# SYNOPSIS

    use WWW::KeePassHttp;

    my $kph = WWW::KeePassHttp->new(Key => $key);
    $kph->associate() unless $kph->test_associate();
    my @entries = @${ $kph->get_logins($search_string) };
    print $entry[0]->url;
    print $entry[0]->login;
    print $entry[0]->password;

# DESCRIPTION

Interface with KeePass PasswordSafe through the KeePassHttp plugin.  Allows reading entries based on URL or TITLE, and creating a new entry as well.

## REQUIREMENTS

You need to have KeePass (or compatible) on your system, with the KeePassHttp plugin installed.

# AUTHOR

Peter C. Jones `<petercj AT cpan DOT org>`

Please report any bugs or feature requests
thru the repository's interface at [https://github.com/pryrt/WWW-KeePassHttp/issues](https://github.com/pryrt/WWW-KeePassHttp/issues).

<div>
    <a href="https://metacpan.org/pod/WWW::KeePassHttp"><img src="https://img.shields.io/cpan/v/WWW-KeePassHttp.svg?colorB=00CC00" alt="" title="metacpan"></a>
    <a href="https://matrix.cpantesters.org/?dist=WWW-KeePassHttp"><img src="https://cpants.cpanauthors.org/dist/WWW-KeePassHttp.png" alt="" title="cpan testers"></a>
    <a href="https://github.com/pryrt/WWW-KeePassHttp/releases"><img src="https://img.shields.io/github/release/pryrt/WWW-KeePassHttp.svg" alt="" title="github release"></a>
    <a href="https://github.com/pryrt/WWW-KeePassHttp/issues"><img src="https://img.shields.io/github/issues/pryrt/WWW-KeePassHttp.svg" alt="" title="issues"></a>
    <a href="https://coveralls.io/github/pryrt/WWW-KeePassHttp?branch=main"><img src="https://coveralls.io/repos/github/pryrt/WWW-KeePassHttp/badge.svg?branch=main" alt="Coverage Status" /></a>
    <a href="https://github.com/pryrt/WWW-KeePassHttp/actions/"><img src="https://github.com/pryrt/WWW-KeePassHttp/actions/workflows/perl-ci.yml/badge.svg" alt="github perl-ci"></a>
</div>

# COPYRIGHT

Copyright (C) 2021 Peter C. Jones

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
