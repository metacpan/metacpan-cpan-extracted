package Types::SQL::Util;

use strict;
use warnings;

use Exporter 5.57 qw/ import /;

use PerlX::Maybe qw/ maybe /;
use Safe::Isa 1.000008 qw/ $_isa $_call_if_can /;

our $VERSION = 'v0.6.1';

# RECOMMEND PREREQ: PerlX::Maybe::XS

# ABSTRACT: extract DBIx::Class column_info from types


our @EXPORT    = qw/ column_info_from_type /;
our @EXPORT_OK = @EXPORT;

my %CLASS_TYPES = (
    'Data::UUID'                 => 'uuid',
    'Data::GUID'                 => 'uuid',
    'Date'                       => 'timestamp',
    'DateTime'                   => 'timestamp',
    'DateTime::Tiny'             => 'timestamp',
    'JSON::PP::Boolean'          => 'boolean',
    'Time::Moment'               => 'timestamp',
    'Time::Piece'                => 'timestamp',
    'Types::Serialiser::Boolean' => 'boolean',
);


my %FROM_PARENT = (

    'Types::Standard' => {

        'ArrayRef' => sub {
            my %type = column_info_from_type( $_[0]->type_parameter );
            $type{data_type} .= '[]';
            return %type;
        },

        'Maybe' => sub {
            return (
                is_nullable => 1,
                column_info_from_type( $_[0]->type_parameter )
            );
        },

        'Object' => sub {
            my $class = $_[0]->$_call_if_can('class') or return;
            if ( my $data_type = $CLASS_TYPES{$class} ) {
                return ( data_type => $data_type );
            }
            return;
        },

      }

);

my %FROM_TYPE = (

    'Types::Standard' => {

        'Bool' => sub {
            return ( data_type => 'boolean' );
        },

        'Int' => sub {
            return ( data_type => 'integer', is_numeric => 1 );
        },

        'Num' => sub {
            return ( data_type => 'numeric', is_numeric => 1 );
        },


        'Str' => sub {
            return ( data_type => 'text', is_numeric => 0 );
        },

    },

    'Types::Common::Numeric' => {

        'PositiveInt' => sub {
            return (
                data_type  => 'integer',
                is_numeric => 1,
                extra      => { unsigned => 1 }
                );
        },

        'PositiveOrZeroInt' => sub {
            return (
                data_type  => 'integer',
                is_numeric => 1,
                extra      => { unsigned => 1 }
                );
        },

        'PositiveNum' => sub {
            return (
                data_type  => 'numeric',
                is_numeric => 1,
                extra      => { unsigned => 1 }
                );
        },

        'PositiveOrZeroNum' => sub {
            return (
                data_type  => 'numeric',
                is_numeric => 1,
                extra      => { unsigned => 1 }
                );
        },

        'SingleDigit' => sub {
            return (
                data_type  => 'integer',
                is_numeric => 1,
                size       => 1,
                extra      => { unsigned => 1 }
            );
        },

      },

    'Types::Common::String' => {

        'LowerCaseStr' => sub {
            return ( data_type => 'text', is_numeric => 0 );
        },

        'UpperCaseStr' => sub {
            return ( data_type => 'text', is_numeric => 0 );
        },

        'NonEmptyStr' => sub {
            return ( data_type => 'text', is_numeric => 0 );
        },

        'LowerCaseSimpleStr' => sub {
            return ( data_type => 'text', is_numeric => 0, size => 255 );
        },

        'UpperCaseSimpleStr' => sub {
            return ( data_type => 'text', is_numeric => 0, size => 255 );
        },

        'NonEmptySimpleStr' => sub {
            return ( data_type => 'text', is_numeric => 0, size => 255 );
        },

        'SimpleStr' => sub {
            return ( data_type => 'text', is_numeric => 0, size => 255 );
        },

    },

    'Types::DateTime' => {

        'DateTime' => sub {
            return ( data_type => 'timestamp' );
        },

        'DateTimeWithZone' => sub {
            return ( data_type => 'timestamp with time zone' );
        },

        'DateTimeUTC' => sub {
            return ( data_type => 'timestamp with time zone' );
        },

        'Now' => sub {
            return ( data_type => 'timestamp', default_value => \ "CURRENT_TIMESTAMP"  );
        },
    },

    'Types::UUID' => {

        'Uuid' => sub {
            return ( data_type => 'uuid' ),
        },

    },

);


sub column_info_from_type {
    my ($type) = @_;

    return { } unless $type->$_isa('Type::Tiny');

    my $name    = $type->name;
    my $methods = $type->my_methods;
    my $parent  = $type->has_parent ? $type->parent : undef;

    if ( $type->is_anon && $parent ) {
        $name    = $parent->name;
        $methods = $parent->my_methods;
    }

    if ( $methods && $methods->{dbic_column_info} ) {
        return $methods->{dbic_column_info}->($type);
    }

    my $from = ( $type->library ? $FROM_TYPE{ $type->library } : undef ) // { };

    if ( my $code = $from->{$name} ) {
        if ( my %info = $code->($type) ) {
            return %info;
        }
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

    if ( my $parent_lib = $parent->$_call_if_can('library') ) {
        if ( my $code = $FROM_PARENT{$parent_lib}{$name} ) {
            if ( my %info = $code->($type) ) {
                return %info;
            }
        }
    }

    if ( $parent ) {
        my @info = eval { column_info_from_type( $parent ) };
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

version v0.6.1

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
types.

Unless noted, these come from L<Types::Standard>,
L<Types::Common::String> or L<Types::Common::Numeric>.

=head3 C<ArrayRef>

This treats the type as an array.

=head3 C<Bool>

This is treated as a C<boolean> type.

=head3 C<DateTime>

From L<Types::DateTime>. This is a C<timestamp>.

=head3 C<DateTimeUTC>

=head3 C<DateTimeWithZone>

From L<Types::DateTime>. These are C<timestamp with time zone>.

=head3 C<Enum>

This is treated as an C<enum> type, which can be used with
L<DBIx::Class::InflateColumn::Object::Enum>.

=head3 C<InstanceOf>

For L<Date>, L<DateTime>, L<DateTime::Tiny>, L<Time::Moment> and
L<Time::Piece> objects, this is treated as a C<timestamp>.

If you want a timestamp with a time zone, use L<Types::DateTime>
C<DateTimeWithZone> or C<DateTimeUTC> type.

L<Data::UUID> or L<Data::GUID> will be treated as C<uuid>.

=head3 C<Int>

This is treated as an C<integer> without a precision.

=head3 C<Maybe>

This treats the type in the parameter as nullable.

=head3 C<Num>

This is treated as a C<numeric> without a precision.

=head3 C<PositiveOrZeroInt>

This is treated as an C<unsigned integer> without a precision.

=head3 C<PositiveOrZeroNum>

This is treated as an C<unsigned numeric> without a precision.

=head3 C<SingleDigit>

This is treated as an C<unsigned integer> of size 1.

=head3 C<Str>

This is treated as a C<text> value without a size.

=head3 C<NonEmptyStr>

=head3 C<LowerCaseStr>

=head3 C<UpperCaseStr>

These are treated the same as L</Str>.  In the future, if
L<DBIx::Class> supports database-related constraints, this will be
added to the metadata.

=head3 C<SimpleStr>

This is treated as a C<text> value with a size of 255.

=head3 C<NonEmptySimpleStr>

=head3 C<LowerCaseSimpleStr>

=head3 C<UpperCaseSimpleStr>

These are treated the same as L</SimpleStr>. In the future, if
L<DBIx::Class> supports database-related constraints, this will be
added to the metadata.

=head3 C<Now>

From L<Types::DateTime>. This is a C<timestamp> with a default set to
the SQL C<current_timestamp> function.

=head3 C<Uuid>

From L<Types::UUID>. This is a C<uuid>.

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

This software is Copyright (c) 2016-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
