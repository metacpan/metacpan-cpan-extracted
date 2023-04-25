package Wikibase::Datatype::Print::MediainfoSnak;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.12;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::MediainfoSnak')) {
		err "Object isn't 'Wikibase::Datatype::MediainfoSnak'.";
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

Wikibase::Datatype::Print::MediainfoSnak - Wikibase mediainfo snak pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::MediainfoSnak qw(print);

 my $pretty_print_string = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::MediainfoSnak>
object.

Returns string.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::MediainfoSnak'.
         Bad snaktype.
                 snaktype: %s

=head1 EXAMPLE1

=for comment filename=create_and_print_mediainfo_snak.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::MediainfoSnak;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::MediainfoSnak->new(
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q5',
         ),
         'property' => 'P31',
 );

 # Print.
 print Wikibase::Datatype::Print::MediainfoSnak::print($obj)."\n";

 # Output:
 # P31: Q5

=head1 EXAMPLE2

=for comment filename=create_and_print_mediainfo_snak_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::MediainfoSnak;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::MediainfoSnak->new(
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
 print Wikibase::Datatype::Print::MediainfoSnak::print($obj, {
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

=item L<Wikibase::Datatype::MediainfoSnak>

Wikibase mediainfo snak datatype.

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

0.12

=cut

