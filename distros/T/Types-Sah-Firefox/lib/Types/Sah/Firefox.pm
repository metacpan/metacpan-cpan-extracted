package Types::Sah::Firefox;

use strict;
use warnings;

# to let scan_prereqs know
use Sah::Schema::firefox::profile_name;
use Sah::Schema::firefox::local_profile_name;

use Type::FromSah qw(sah2type);
use Type::Library -base;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-05'; # DATE
our $DIST = 'Types-Sah-Firefox'; # DIST
our $VERSION = '0.003'; # VERSION

__PACKAGE__->add_type(
    sah2type("firefox::profile_name*", name => 'FirefoxProfileName'),
);
__PACKAGE__->add_type(
    sah2type("firefox::local_profile_name*", name => 'FirefoxLocalProfileName'),
);

1;
# ABSTRACT: Type constraints related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Sah::Firefox - Type constraints related to Firefox

=head1 VERSION

This document describes version 0.003 of Types::Sah::Firefox (from Perl distribution Types-Sah-Firefox), released on 2022-10-05.

=head1 SYNOPSIS

 package MyApp;
 use Moose;
 use Types::Sah::Firefox -all;

 has firefox_profile_name => (
     is => 'rw',
     isa => FirefoxProfileName,
 );

=head1 DESCRIPTION

This module provides type constraints from L<Sah::Schemas::Firefox>:

=over

=item * FirefoxProfileName

From L<Sah::Schema::firefox::profile_name>. Firefox profile name.

=item * FirefoxLocalProfileName

From L<Sah::Schema::firefox::profile_name>. Firefox profile name, must exist in
local Firefox installation.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Types-Sah-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Types-Sah-Firefox>.

=head1 SEE ALSO

L<Type::Tiny>, L<Sah>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Types-Sah-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
