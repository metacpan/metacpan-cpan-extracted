package oEdtk::AddrField;

use strict;
use warnings;

use oEdtk::Main qw(oe_uc_sans_accents);
use base 'oEdtk::Field';
our $VERSION = 2.1126;

sub process {
	my ( $self, $data ) = @_;

	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	oe_uc_sans_accents($data);
	return uc($data);
}

1;

=head1 NAME

oEdtk::AddrField - address field: trim, drop accents, uppercase

=head1 SYNOPSIS

    use oEdtk::AddrField;

    my $field = oEdtk::AddrField->new('ADDR', 38);
    print $field->process('  12 rue de la gare  '), "\n";   # '12 RUE DE LA GARE'

=head1 DESCRIPTION

An C<oEdtk::Field> subclass for address lines. It trims the leading and
trailing whitespace, strips the accents and uppercases the result. The field
name and byte length are carried by the inherited constructor.

=head1 METHODS

=head2 process

    my $value = $field->process($data);

Trim C<$data>, drop its accents (via C<oe_uc_sans_accents>, imported from
C<oEdtk::Main>) and return it uppercased.

=head1 AUTHOR

The oEdtk team.

=cut
