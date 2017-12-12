package Types::SQL;

use strict;
use warnings;

use Type::Library
  -base,
  -declare => qw/ Char Integer Numeric Serial Text Varchar /;

use Ref::Util qw/ is_arrayref /;
use Type::Utils 0.44 -all;
use Types::Standard -types;
use PerlX::Maybe;

# RECOMMEND PREREQ: PerlX::Maybe::XS
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

our $VERSION = 'v0.1.2';

=head1 NAME

Types::SQL - A library of SQL types

=head1 SYNOPSIS

  use Types::SQL -types;

  my $type = Varchar[16];

=head1 DESCRIPTION

This module provides a type library of SQL types.  These are
L<Type::Tiny> objects that are augmented with a C<dbic_column_info>
method that returns column information for use with
L<DBIx::Class>.

=for readme stop

The following types are provided:

=head2 C<Blob>

  my $type = Blob;

Returns a C<blob> data type.

=cut

our $Blob = _generate_type(
    name             => 'Blob',
    parent           => Str,
    dbic_column_info => sub {
        my ($self) = @_;
        return (
            is_numeric => 0,
            data_type  => 'blob',
        );
    },
);

=head2 C<Text>

  my $type = Text;

Returns a C<text> data type.

=cut

our $Text = _generate_type(
    name             => 'Text',
    parent           => Str,
    dbic_column_info => sub {
        my ($self) = @_;
        return (
            is_numeric => 0,
            data_type  => 'text',
        );
    },
);

=head2 C<Varchar>

  my $type = Varchar[ $size ];

Returns a C<varchar> data type, with an optional size parameter.

=cut

our $Varchar = _generate_type(
    name                 => 'Varchar',
    parent               => $Text,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type => 'varchar',
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Char>

  my $type = Char[ $size ];

Returns a C<char> data type, with an optional size parameter.

=cut

our $Char = _generate_type(
    name                 => 'Char',
    parent               => $Text,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type => 'char',
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Integer>

  my $type = Integer[ $precision ];

Returns a C<integer> data type, with an optional precision parameter.

=cut

our $Integer = _generate_type(
    name                 => 'Integer',
    parent               => Int,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        return (
            data_type  => 'integer',
            is_numeric => 1,
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Serial>

  my $type = Serial[ $precision ];

Returns a C<serial> data type, with an optional precision parameter.

=cut

our $Serial = _generate_type(
    name                 => 'Serial',
    parent               => $Integer,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type         => 'serial',
            is_auto_increment => 1,
        );
    },
);

=head2 C<Numeric>

  my $type = Numeric[ $precision, $scale ];

Returns a C<integer> data type, with optional precision and scale parameters.

If C<$scale> is omitted, then it is assumed to be C<0>.

=cut

our $Numeric = _generate_type(
    name                 => 'Numeric',
    parent               => Num,
    constraint_generator => \&_size_range_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        return (
            data_type  => 'numeric',
            is_numeric => 1,
            maybe size => $size || $self->parameters,
        );
    },
);

sub _size_constraint_generator {
    if (@_) {
        my ($size) = @_;
        die "Size must be a positive integer" unless $size =~ /^[1-9]\d*$/;
        my $re = qr/^0*\d{1,$size}$/;
        return sub { $_ =~ $re };
    }
    else {
        return sub { $_ =~ /^\d+$/ };
    }
}

sub _size_range_constraint_generator {
    if (@_) {
        my ( $prec, $scale ) = @_;
        $scale ||= 0;

        die "Precision must be a positive integer" unless $prec =~ /^[1-9]\d*$/;
        die "Scale must be a positive integer"     unless $scale =~ /^\d+$/;

        my $left = $prec - $scale;
        die "Scale must be less than the precision" if ( $left < 0 );

        my $re = qr/^0*\d{0,$left}([.]\d{0,$scale}0*)?$/;
        return sub { $_ =~ $re };
    }
    else {
        return sub { $_ =~ /^\d+$/ };
    }
}

sub _generate_type {
    my %args = @_;

    $args{my_methods} =
      { maybe dbic_column_info => delete $args{dbic_column_info}, };

    my $type = Type::Tiny->new(%args);
    __PACKAGE__->meta->add_type($type);
    return $type;
}

=head1 CUSTOM TYPES

Any type that has these types as a parent can have column information
extracted using L<Types::SQL::Util>.

Alternatively, you can specify a custom C<dbic_column_info> method in
a type, e.g.:

  my $type = Type::Tiny->new(
    name       => 'MyType',
    my_methods => {
      dbic_column_info => sub {
        my ($self) = @_;
        return (
           data_type    => 'custom',
           parameter    => 1234,
        );
      },
    },
    ...
  );

The method should return a hash of values that are passed to the
C<add_column> method of L<DBIx::Class::ResultSource>.

=for readme continue

=head1 SEE ALSO

L<Type::Tiny>.

L<Types::SQL::Util>, which provides a utility function for translating
these types and other types from L<Types::Standard> into column
information for L<DBIx::Class::ResultSource>.

=head1 AUTHOR

Robert Rothenberg, C<rrwo@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

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

=for readme continue

=cut

1;
