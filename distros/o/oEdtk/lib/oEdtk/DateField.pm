package oEdtk::DateField;

use strict;
use warnings;

use base 'oEdtk::Field';
our $VERSION = 2.1126;

sub process {
	my ( $self, $data ) = @_;

	$data =~ s/^(\d{4})(\d{2})(\d{2}).*$/$3\/$2\/$1/;
	return $data;
}

1;

=head1 NAME

oEdtk::DateField - date field: YYYYMMDD to DD/MM/YYYY

=head1 SYNOPSIS

    use oEdtk::DateField;

    my $field = oEdtk::DateField->new('DATNAI', 8);
    print $field->process('19700131'), "\n";   # '31/01/1970'

=head1 DESCRIPTION

An C<oEdtk::Field> subclass that rewrites a coded date C<YYYYMMDD> into the
display form C<DD/MM/YYYY>. Anything after the eight leading digits is dropped.

=head1 METHODS

=head2 process

    my $value = $field->process($data);

Rewrite the leading eight digits of C<$data> as C<DD/MM/YYYY>.

=head1 AUTHOR

The oEdtk team.

=cut
