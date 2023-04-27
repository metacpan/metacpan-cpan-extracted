package Wikibase::Datatype::Statement;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_isa check_required);
use Readonly;

Readonly::Array our @RANKS => qw(normal preferred deprecated);

our $VERSION = 0.31;

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
	check_isa($self, 'snak', 'Wikibase::Datatype::Snak');

	# Check property snaks.
	check_array_object($self, 'property_snaks', 'Wikibase::Datatype::Snak',
		'Property snak');

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

Wikibase::Datatype::Statement - Wikibase statement datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Statement;

 my $obj = Wikibase::Datatype::Statement->new(%params);
 my $id = $obj->id;
 my $property_snaks_ar = $obj->property_snaks;
 my $rank = $obj->rank;
 my $referenes_ar = $obj->references;
 my $snak = $obj->snak;

=head1 DESCRIPTION

This datatype is statement class for representing claim.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Statement->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<id>

Id of statement.
Parameter is optional.

=item * C<property_snaks>

Property snaks.
Parameter is reference to hash with Wikibase::Datatype::Snak instances.
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
Parameter is Wikibase::Datatype::Snak instance.
Parameter is required.

=back

=head2 C<id>

 my $id = $obj->id;

Get id of statement.

Returns string.

=head2 C<property_snaks>

 my $property_snaks_ar = $obj->property_snaks;

Get property snaks.

Returns reference to array with Wikibase::Datatype::Snak instances.

=head2 C<rank>

 my $rank = $obj->rank;

Get rank value.

=head2 C<references>

 my $referenes_ar = $obj->references;

Get references.

Returns reference to array with Wikibase::Datatype::Reference instance.

=head2 C<snak>

 my $snak = $obj->snak;

Get main snak.

Returns Wikibase::Datatype::Snak instance.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Parameter 'property_snaks' must be a array.
                 Parameter 'references' must be a array.
                 Property snak isn't 'Wikibase::Datatype::Snak' object.
                 Reference isn't 'Wikibase::Datatype::Reference' object.
         From Mo::utils::check_isa():
                 Parameter 'snak' must be a 'Wikibase::Datatype::Snak' object.
         From Mo::utils::check_required():
                 Parameter 'snak' is required.
         Parameter 'rank' has bad value. Possible values are normal, preferred, deprecated.

=head1 EXAMPLE

=for comment filename=create_and_print_statement.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Statement->new(
         'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',

         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::Snak->new(
                  'datatype' => 'wikibase-item',
                  'datavalue' => Wikibase::Datatype::Value::Item->new(
                          'value' => 'Q5',
                  ),
                  'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::Snak->new(
                          'datatype' => 'wikibase-item',
                          'datavalue' => Wikibase::Datatype::Value::Item->new(
                                  'value' => 'Q474741',
                          ),
                          'property' => 'P642',
                 ),
         ],
         'references' => [
                  Wikibase::Datatype::Reference->new(
                          'snaks' => [
                                  # stated in (P248) Virtual International Authority File (Q53919)
                                  Wikibase::Datatype::Snak->new(
                                           'datatype' => 'wikibase-item',
                                           'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                   'value' => 'Q53919',
                                           ),
                                           'property' => 'P248',
                                  ),

                                  # VIAF ID (P214) 113230702
                                  Wikibase::Datatype::Snak->new(
                                           'datatype' => 'external-id',
                                           'datavalue' => Wikibase::Datatype::Value::String->new(
                                                   'value' => '113230702',
                                           ),
                                           'property' => 'P214',
                                  ),

                                  # retrieved (P813) 7 December 2013
                                  Wikibase::Datatype::Snak->new(
                                           'datatype' => 'time',
                                           'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                   'value' => '+2013-12-07T00:00:00Z',
                                           ),
                                           'property' => 'P813',
                                  ),
                          ],
                  ),
         ],
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Claim: '.$obj->snak->property.' -> '.$obj->snak->datavalue->value."\n";
 print "Qualifiers:\n";
 foreach my $property_snak (@{$obj->property_snaks}) {
         print "\t".$property_snak->property.' -> '.
                 $property_snak->datavalue->value."\n";
 }
 print "References:\n";
 foreach my $reference (@{$obj->references}) {
         print "\tReference:\n";
         foreach my $reference_snak (@{$reference->snaks}) {
                 print "\t\t".$reference_snak->property.' -> '.
                         $reference_snak->datavalue->value."\n";
         }
 }
 print 'Rank: '.$obj->rank."\n";

 # Output:
 # Id: Q123$00C04D2A-49AF-40C2-9930-C551916887E8
 # Claim: P31 -> Q5
 # Qualifiers:
 #         P642 -> Q474741
 # References:
 #         Reference:
 #                 P248 -> Q53919
 #                 P214 -> 113230702
 #                 P813 -> +2013-12-07T00:00:00Z
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

0.31

=cut
