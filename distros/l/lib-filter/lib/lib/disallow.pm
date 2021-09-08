package lib::disallow;

use strict;
use warnings;

require lib::filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-29'; # DATE
our $DIST = 'lib-filter'; # DIST
our $VERSION = '0.281'; # VERSION

sub import {
    my $pkg = shift;

    lib::filter->import(disallow=>join(';',@_));
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Disallow a list of modules from being locateable/loadable

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::disallow - Disallow a list of modules from being locateable/loadable

=head1 VERSION

This document describes version 0.281 of lib::disallow (from Perl distribution lib-filter), released on 2021-08-29.

=head1 SYNOPSIS

 % perl -Mlib::disallow=YAML,YAML::Syck,YAML::XS yourscript.pl

=head1 DESCRIPTION

This pragma is a shortcut for L<lib::filter>. This:

 use lib::disallow qw(YAML YAML::Syck YAML::XS);

is equivalent to:

 use lib::filter disallow=>'YAML;YAML::Syck;YAML::XS';

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-filter>.

=head1 SEE ALSO

L<lib::filter>

If an application checks the availability of modules by using L<Module::Path> or
L<Module::Path::More> instead of trying to load them, you can try:
L<Module::Path::Patch::Hide> or L<Module::Path::More::Patch::Hide>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
