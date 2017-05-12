package lib::disallow;

our $DATE = '2016-08-24'; # DATE
our $VERSION = '0.27'; # VERSION

use strict;
use warnings;

require lib::filter;

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

This document describes version 0.27 of lib::disallow (from Perl distribution lib-filter), released on 2016-08-24.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::filter>

If an application checks the availability of modules by using L<Module::Path> or
L<Module::Path::More> instead of trying to load them, you can try:
L<Module::Path::Patch::Hide> or L<Module::Path::More::Patch::Hide>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
