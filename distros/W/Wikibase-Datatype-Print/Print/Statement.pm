package Wikibase::Datatype::Print::Statement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Reference;
use Wikibase::Datatype::Print::Snak;
use Wikibase::Datatype::Print::Utils qw(print_references);

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.16;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Statement')) {
		err "Object isn't 'Wikibase::Datatype::Statement'.";
	}

	my @ret = (
		Wikibase::Datatype::Print::Snak::print($obj->snak, $opts_hr).' ('.$obj->rank.')',
	);
	foreach my $property_snak (@{$obj->property_snaks}) {
		push @ret, ' '.Wikibase::Datatype::Print::Snak::print($property_snak, $opts_hr);
	}

	# References.
	if (! exists $opts_hr->{'no_print_references'} || ! $opts_hr->{'no_print_references'}) {
		push @ret, print_references($obj, $opts_hr,
			\&Wikibase::Datatype::Print::Reference::print);
	}

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Statement - Wikibase statement pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Statement qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Statement>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Statement'.

=head1 EXAMPLE1

=for comment filename=create_and_print_statement.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Statement;
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

 # Print.
 print Wikibase::Datatype::Print::Statement::print($obj)."\n";

 # Output:
 # P31: Q5 (normal)
 #  P642: Q474741
 # References:
 #   {
 #     P248: Q53919
 #     P214: 113230702
 #     P813: 7 December 2013 (Q1985727)
 #   }

=head1 EXAMPLE2

=for comment filename=create_and_print_statement_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Statement;
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

 # Cache.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::Statement::print($obj, {
         'cache' => $cache,
 })."\n";

 # Output:
 # P31 (instance of): Q5 (normal)
 #  P642: Q474741
 # References:
 #   {
 #     P248 (stated in): Q53919
 #     P214 (VIAF ID): 113230702
 #     P813 (retrieved): 7 December 2013 (Q1985727)
 #   }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Reference>,
L<Wikibase::Datatype::Print::Snak>,
L<Wikibase::Datatype::Print::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Statement>

Wikibase statement datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.16

=cut

