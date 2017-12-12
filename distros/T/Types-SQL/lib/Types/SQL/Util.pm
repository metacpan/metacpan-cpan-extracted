package Types::SQL::Util;

use strict;
use warnings;

use Exporter qw/ import /;

use PerlX::Maybe;

our $VERSION = 'v0.1.2';

# RECOMMEND PREREQ: PerlX::Maybe::XS

=head1 NAME

Types::SQL::Util - Extract DBIx::Class column_info from types

=head1 SYNOPSIS

  use Types::SQL -types;
  use Types::Standard -types;

  use Types::SQL::Util;

  my $type = Maybe[ Varchar[64] ];

  my %info = column_info_from_type( $type );

=head1 DESCRIPTION

This module provides a utility function that translates types into
column information.

=head1 EXPORTS

=head2 C<column_info_from_type>

  my %info = column_info_from_type( $type );

This function returns a hash of column information for the
C<add_column> method of L<DBIx::Class::ResultSource>, based on the
type.

Besides the types from L<Types::SQL>, it also supports the following
types from L<Types::Standard>:

=head3 C<Maybe>

This treats the type in the parameter as nullable.

=head3 C<Enum>

This is treated as an C<enum> type, which can be used with
L<DBIx::Class::InflateColumn::Object::Enum>.

=head3 C<Int>

This is treated as an C<integer> without a precision.

=head3 C<Str>

This is treated as a C<text> value without a size.

=head3 C<InstanceOf>

For L<DateTime>, L<Time::Moment> and L<Time::Piece> objects, this is
treated as a C<datetime>.

=cut

our @EXPORT    = qw/ column_info_from_type /;
our @EXPORT_OK = @EXPORT;

my %CLASS_TYPES = (
    'DateTime'     => 'datetime',
    'Time::Moment' => 'datetime',
    'Time::Piece'  => 'datetime',
);

sub column_info_from_type {
    my ($type) = @_;

    my $name    = $type->name;
    my $methods = $type->my_methods;

    if ( $type->is_anon && $type->has_parent ) {
        $name    = $type->parent->name;
        $methods = $type->parent->my_methods;
    }

    if ( $methods && $methods->{dbic_column_info} ) {
        return $methods->{dbic_column_info}->($type);
    }

    if ( $type->isa('Type::Tiny::Enum') ) {
        return (
            data_type  => 'enum',
            is_enum    => 1,
            is_numeric => 0,
            extra      => {
                list => $type->values,
            },
        );
    }

    if ( $name eq 'Maybe' ) {
        return (
            is_nullable => 1,
            column_info_from_type( $type->type_parameter )
        );
    }

    if (   $name eq 'Object'
        && $type->display_name =~ /^InstanceOf\[['"](.+)['"]\]$/ )
    {
        if ( my $data_type = $CLASS_TYPES{$1} ) {
            return ( data_type => $data_type );
        }

    }

    if ( $name eq 'Str' ) {
        return ( data_type => 'text', is_numeric => 0 );
    }

    if ( $name eq 'Int' ) {
        return ( data_type => 'integer', is_numeric => 1 );
    }

    if ( $type->has_parent ) {
        my @info = eval { column_info_from_type( $type->parent ) };
        return @info if @info;
    }

    die "Unsupported type: " . $type->display_name;
}

=head1 CUSTOM TYPES

You can declare custom types from these types and still extract column
information from them:

  use Type::Library
    -base,
    -declare => qw/ CustomStr /;

  use Type::Utils qw/ -all /;
  use Types::SQL -types;
  use Types::SQL::Util;

  declare CustomStr, as Varchar [64];

  ...

  my $type = CustomStr;
  my %info = column_info_from_type($type);

=head1 SEE ALSO

L<Types::SQL>.

=head1 AUTHOR

Robert Rothenberg, C<rrwo@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
