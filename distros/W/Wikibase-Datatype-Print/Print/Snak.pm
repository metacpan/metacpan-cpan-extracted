package Wikibase::Datatype::Print::Snak;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.08;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Snak')) {
		err "Object isn't 'Wikibase::Datatype::Snak'.";
	}

	my $property_name = '';
	if (exists $opts_hr->{'cache'}) {
		$property_name = $opts_hr->{'cache'}->get('label', $obj->property);
		if (defined $property_name) {
			$property_name = " ($property_name)";
		} else {
			$property_name = '';
		}
	}

	my $ret = $obj->property.$property_name.': ';
	if ($obj->snaktype eq 'value') {
		$ret .= Wikibase::Datatype::Print::Value::print($obj->datavalue, $opts_hr);
	} elsif ($obj->snaktype eq 'novalue') {
		$ret .= 'no value';
	} elsif ($obj->snaktype eq 'somevalue') {
		$ret .= 'unknown value';
	} else {
		err 'Bad snaktype.',
			'snaktype', $obj->snaktype,
		;
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Snak - Wikibase snak pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Snak qw(print);

 my $pretty_print_string = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Snak>
object.

Returns string.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Snak'.
         Bad snaktype.
                 snaktype: %s

=head1 EXAMPLE1

=for comment filename=create_and_print_snak.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Snak;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::Snak->new(
         'datatype' => 'wikibase-item',
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q5',
         ),
         'property' => 'P31',
 );

 # Print.
 print Wikibase::Datatype::Print::Snak::print($obj)."\n";

 # Output:
 # P31: Q5

=head1 EXAMPLE2

=for comment filename=create_and_print_snak_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Snak;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::Snak->new(
         'datatype' => 'wikibase-item',
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q5',
         ),
         'property' => 'P31',
 );

 # Cache.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::Snak::print($obj, {
         'cache' => $cache,
 })."\n";

 # Output:
 # P31 (instance of): Q5

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Snak>

Wikibase snak datatype.

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

0.08

=cut

