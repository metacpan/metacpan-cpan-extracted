package Wikibase::Datatype::Print::MediainfoStatement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Reference;
use Wikibase::Datatype::Print::MediainfoSnak;
use Wikibase::Datatype::Print::Utils qw(defaults print_references);

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.19;

sub print {
	my ($obj, $opts_hr) = @_;

	$opts_hr = defaults($obj, $opts_hr);

	if (! $obj->isa('Wikibase::Datatype::MediainfoStatement')) {
		err "Object isn't 'Wikibase::Datatype::MediainfoStatement'.";
	}

	my $text_rank = $opts_hr->{'texts'}->{'rank_'.$obj->rank};
	my @ret = (
		Wikibase::Datatype::Print::MediainfoSnak::print($obj->snak, $opts_hr).' ('.$text_rank.')',
	);
	foreach my $property_snak (@{$obj->property_snaks}) {
		push @ret, ' '.Wikibase::Datatype::Print::MediainfoSnak::print($property_snak, $opts_hr);
	}

	# References.
	push @ret, print_references($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Reference::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::MediainfoStatement - Wikibase mediainfo statement pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::MediainfoStatement qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::MediainfoStatement>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         From Wikibase::Datatype::Print::Utils::defaults():
                 Defined text keys are bad.
         Object isn't 'Wikibase::Datatype::MediainfoStatement'.

=head1 EXAMPLE1

=for comment filename=create_and_print_mediainfo_statement.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Print::MediainfoStatement;
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

 # Print.
 print Wikibase::Datatype::Print::MediainfoStatement::print($obj)."\n";

 # Output:
 # P170: no value (normal)
 #  P4174: Lviatour
 #  P2699: https://commons.wikimedia.org/wiki/user:Lviatour
 #  P2093: Lviatour
 #  P3831: Q33231

=head1 EXAMPLE2

=for comment filename=create_and_print_mediainfo_statement_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Print::MediainfoStatement;
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

 # Cache.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::MediainfoStatement::print($obj, {
         'cache' => $cache,
 })."\n";

 # Output:
 # P170: no value (normal)
 #  P4174: Lviatour
 #  P2699: https://commons.wikimedia.org/wiki/user:Lviatour
 #  P2093: Lviatour
 #  P3831: Q33231

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Reference>,
L<Wikibase::Datatype::Print::MediainfoSnak>,
L<Wikibase::Datatype::Print::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::MediainfoStatement>

Wikibase statement datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.19

=cut
