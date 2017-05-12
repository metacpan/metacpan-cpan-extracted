package Types::PerlVersion;

use strict;
use warnings;

=head1 NAME

Types::PerlVersion - L<Perl::Version> type constraint for L<Type::Tiny>

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

    package MyApp::Thingie;

    use Moose;
    use Types::PerlVersion qw/PerlVersion/;

    has version => (
        is       => 'ro',
        isa      => PerlVersion,
        coerce   => 1,
        required => 1,
    );

=head1 DESCRIPTION

L<Types::PerlVersion> is a type constraint suitable for use with
L<Moo>/L<Moose> attributes that need to deal with version strings as
handled by L<Perl::Version>.

=head2 Types

This module provides the single type constraint C<PerlVersion>. Coercion is
provided from C<Str> and C<Num> types.

=cut

use Type::Library -base, -declare => qw( PerlVersion );
use Type::Utils -all;
use Types::Standard qw/Num Str/;
use Perl::Version;

class_type PerlVersion, { class => "Perl::Version" };

coerce PerlVersion,
  from Num, via { "Perl::Version"->new($_) },
  from Str, via { "Perl::Version"->new($_) };

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 BUGS

Please report any bugs found to:

L<https://github.com/SysPete/p5-Types-PerlVersion/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Types::PerlVersion

You can also look for information at:

=over 4

=item * L<GitHub repository|https://github.com/SysPete/p5-Types-PerlVersion>

=item * L<meta::cpan|https://metacpan.org/pod/Types::PerlVersion>

=back

=head1 SEE ALSO

If you prefer to use L<MooseX::Types> then see L<MooseX::Types::PerlVersion>
which was the basis of this module.

=head1 ACKNOWLEDGEMENTS

Toby Inkster for his excellent L<Type::Tiny>, brian d foy for L<Perl::Version>
and Roman F. for L<MooseX::Types::PerlVersion> from which I stole most of the
code for this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut

1;    # End of Types::PerlVersion
