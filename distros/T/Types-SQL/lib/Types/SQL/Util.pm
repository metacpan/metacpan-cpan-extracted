package Types::SQL::Util;

use strict;
use warnings;

use Exporter qw/ import /;

use PerlX::Maybe;

our $VERSION = 'v0.1.3';

# RECOMMEND PREREQ: PerlX::Maybe::XS

# ABSTRACT: extract DBIx::Class column_info from types


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

    if ( $name eq 'Bool' ) {
        return ( data_type => 'boolean' );
    }

    if ( $type->has_parent ) {
        my @info = eval { column_info_from_type( $type->parent ) };
        return @info if @info;
    }

    die "Unsupported type: " . $type->display_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::SQL::Util - extract DBIx::Class column_info from types

=head1 VERSION

version v0.1.3

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

=head2 C<Bool>

This is trated as a C<boolean> type.

=head3 C<Enum>

This is treated as an C<enum> type, which can be used with
L<DBIx::Class::InflateColumn::Object::Enum>.

=head3 C<InstanceOf>

For L<DateTime>, L<Time::Moment> and L<Time::Piece> objects, this is
treated as a C<datetime>.

=head3 C<Int>

This is treated as an C<integer> without a precision.

=head3 C<Maybe>

This treats the type in the parameter as nullable.

=head3 C<Str>

This is treated as a C<text> value without a size.

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

L<Types::Standard>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Types-SQL>
and may be cloned from L<git://github.com/robrwo/Types-SQL.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Types-SQL/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
