package lib::coreplus;

our $DATE = '2016-08-24'; # DATE
our $VERSION = '0.27'; # VERSION

use strict;
use warnings;

use Module::CoreList;
use lib::filter ();

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

This document describes version 0.27 of lib::coreplus (from Perl distribution lib-filter), released on 2016-08-24.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::filter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
