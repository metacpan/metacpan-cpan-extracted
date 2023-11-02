package Wikibase::Datatype::MediainfoStatement;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_isa check_required);
use Readonly;

Readonly::Array our @RANKS => qw(normal preferred deprecated);

our $VERSION = 0.33;

has id => (
	is => 'ro',
);

has property_snaks => (
	default => [],
	is => 'ro',
);

has rank => (
	is => 'ro',
	default => 'normal',
);

has references => (
	default => [],
	is => 'ro',
);

has snak => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check requirements.
	check_required($self, 'snak');

	# Check rank.
	if (defined $self->{'rank'} && none { $_ eq $self->{'rank'} } @RANKS) {
		err "Parameter 'rank' has bad value. Possible values are ".(
			join ', ', @RANKS).'.';
	}

	# Check snak.
	check_isa($self, 'snak', 'Wikibase::Datatype::MediainfoSnak');

	# Check property snaks.
	check_array_object($self, 'property_snaks', 'Wikibase::Datatype::MediainfoSnak',
		'Property mediainfo snak');

	# Check references.
	check_array_object($self, 'references', 'Wikibase::Datatype::Reference',
		'Reference');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::MediainfoStatement - Wikibase mediainfo statement datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::MediainfoStatement;

 my $obj = Wikibase::Datatype::MediainfoStatement->new(%params);
 my $id = $obj->id;
 my $property_snaks_ar = $obj->property_snaks;
 my $rank = $obj->rank;
 my $referenes_ar = $obj->references;
 my $snak = $obj->snak;

=head1 DESCRIPTION

This datatype is statement class for representing mediainfo statement.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::MediainfoStatement->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<id>

Id of statement.
Parameter is optional.

=item * C<property_snaks>

Property snaks.
Parameter is reference to hash with Wikibase::Datatype::MediainfoSnak instances.
Parameter is optional.
Default value is [].

=item * C<rank>

Rank value.
Parameter is string with these possible values: normal, preferred and deprecated
Default value is 'normal'.

=item * C<references>

List of references.
Parameter is reference to hash with Wikibase::Datatype::Reference instances.
Parameter is optional.
Default value is [].

=item * C<snak>

Main snak.
Parameter is Wikibase::Datatype::MediainfoSnak instance.
Parameter is required.

=back

=head2 C<id>

 my $id = $obj->id;

Get id of statement.

Returns string.

=head2 C<property_snaks>

 my $property_snaks_ar = $obj->property_snaks;

Get property mediainfo snaks.

Returns reference to array with Wikibase::Datatype::MediainfoSnak instances.

=head2 C<rank>

 my $rank = $obj->rank;

Get rank value.

=head2 C<references>

 my $referenes_ar = $obj->references;

Get references.

Returns reference to array with Wikibase::Datatype::Reference instance.

=head2 C<snak>

 my $snak = $obj->snak;

Get main mediainfo snak.

Returns Wikibase::Datatype::MediainfoSnak instance.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Parameter 'property_snaks' must be a array.
                 Parameter 'references' must be a array.
                 Property mediainfo snak isn't 'Wikibase::Datatype::MediainfoSnak' object.
                 Reference isn't 'Wikibase::Datatype::Reference' object.
         From Mo::utils::check_isa():
                 Parameter 'snak' must be a 'Wikibase::Datatype::MediainfoSnak' object.
         From Mo::utils::check_required():
                 Parameter 'snak' is required.
         Parameter 'rank' has bad value. Possible values are normal, preferred, deprecated.

=head1 EXAMPLE

=for comment filename=create_and_print_mediainfostatement.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::String;

 # Object.
 my $obj = Wikibase::Datatype::MediainfoStatement->new(
         'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',

         # creator (P170)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                  'property' => 'P170',
                  'snaktype' => 'novalue',
         ),
         'property_snaks' => [
                 # Wikimedia username (P4174): Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'Lviatour',
                          ),
                          'property' => 'P4174',
                 ),

                 # URL (P2699): https://commons.wikimedia.org/wiki/user:Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'https://commons.wikimedia.org/wiki/user:Lviatour',
                          ),
                          'property' => 'P2699',
                 ),

                 # author name string (P2093): Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'Lviatour',
                          ),
                          'property' => 'P2093',
                 ),

                 # object has role (P3831): photographer (Q33231)
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::Item->new(
                                  'value' => 'Q33231',
                          ),
                          'property' => 'P3831',
                 ),
         ],
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Statement: '.$obj->snak->property.' -> ';
 if ($obj->snak->snaktype eq 'value') {
         print $obj->snak->datavalue->value."\n";
 } elsif ($obj->snak->snaktype eq 'novalue') {
         print "-\n";
 } elsif ($obj->snak->snaktype eq 'somevalue') {
         print "?\n";
 }
 print "Qualifiers:\n";
 foreach my $property_snak (@{$obj->property_snaks}) {
         print "\t".$property_snak->property.' -> '.
                 $property_snak->datavalue->value."\n";
 }
 print 'Rank: '.$obj->rank."\n";

 # Output:
 # Id: M123$00C04D2A-49AF-40C2-9930-C551916887E8
 # Statement: P170 -> -
 # Qualifiers:
 #         P4174 -> Lviatour
 #         P2699 -> https://commons.wikimedia.org/wiki/user:Lviatour
 #         P2093 -> Lviatour
 #         P3831 -> Q33231
 # Rank: normal

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::MoreUtils>,
L<Mo>,
L<Mo::utils>.
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Statement>

Wikibase statement datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.33

=cut
