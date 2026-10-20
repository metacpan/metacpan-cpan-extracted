package oEdtk::Field;

use strict;
use warnings;
our $VERSION = 2.1129;

sub new {
	my ( $class, $name, $len ) = @_;
	my $field = {
		name => $name,
		len  => $len,
	};

	bless $field, $class;
	return $field;
}

sub process {
	my ( $self, $data ) = @_;

	return $data;
}

sub get_name {
	my ($self) = @_;

	return $self->{'name'};
}

sub set_name {
	my ( $self, $name ) = @_;

	$self->{'name'} = $name;
}

sub get_len {
	my ($self) = @_;

	return $self->{'len'};
}

1;

=head1 NAME

oEdtk::Field - abstract base class for fixed-width record fields

=head1 SYNOPSIS

    use base 'oEdtk::Field';

    my $field = oEdtk::Field->new('NAME', 10);
    print $field->get_name, "\n";
    print $field->process('value'), "\n";

=head1 DESCRIPTION

The root of the field hierarchy used to describe the fixed-width records of an
Infinite flux. A field carries a name and a byte length and knows how to turn
the raw slice handed to it by C<oEdtk::Record> into a display value. The base
class returns the slice unchanged; subclasses (C<oEdtk::AddrField>,
C<oEdtk::DateField>, C<oEdtk::FPField>, C<oEdtk::SignedField>) override
L</process>.

=head1 METHODS

=head2 new

    my $field = oEdtk::Field->new($name, $len);

Construct a field of name C<$name> and byte length C<$len>.

=head2 process

    my $value = $field->process($data);

Return the display value for the raw slice C<$data>. The base implementation is
the identity; subclasses override it.

=head2 get_name

    my $name = $field->get_name;

Return the field name.

=head2 set_name

    $field->set_name($name);

Set the field name.

=head2 get_len

    my $len = $field->get_len;

Return the field byte length.

=head1 AUTHOR

The oEdtk team.

=cut
