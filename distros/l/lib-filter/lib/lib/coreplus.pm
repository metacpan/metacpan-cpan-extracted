package lib::coreplus;

use strict;
use warnings;

use Module::CoreList;
use lib::filter ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-29'; # DATE
our $DIST = 'lib-filter'; # DIST
our $VERSION = '0.281'; # VERSION

sub import {
    my $pkg = shift;

    my $re = join('|', map {quotemeta} @_);
    $re = qr/\A($re)\z/;

    lib::filter->import(
        filter => sub {
            return 1 if Module::CoreList->is_core($_);
            return 1 if $_ =~ $re;
            0;
        },
    );
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Allow core modules plus a few others

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::coreplus - Allow core modules plus a few others

=head1 VERSION

This document describes version 0.281 of lib::coreplus (from Perl distribution lib-filter), released on 2021-08-29.

=head1 SYNOPSIS

 % perl -Mlib::coreplus=Clone,Data::Structure::Util yourscript.pl

=head1 DESCRIPTION

This pragma uses L<lib::filter>'s custom C<filter> to accomplish its function.

Rationale for this pragma: using C<lib::filter>'s C<allow_noncore=0>+C<allow>
doesn't work for non-core XS modules because C<allow_noncore=0> will remove
non-core directories from C<@INC>, while XS modules will still look for their
loadable objects in C<@INC> during loading.

So the alternative approach used by C<lib::coreplus> is to check the module
against C<< Module::CoreList->is_core >>. If the module is not a core module
according to C<is_core>, it is then checked against the list of additional
modules specified by the user. If both checks fail, the module is disallowed.
lib::coreplus does not remove directories from C<@INC> because it does not use
C<allow_noncore=0>.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-filter>.

=head1 SEE ALSO

L<lib::filter>

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
