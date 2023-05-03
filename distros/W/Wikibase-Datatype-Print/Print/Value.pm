package Wikibase::Datatype::Print::Value;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value::Globecoordinate;
use Wikibase::Datatype::Print::Value::Item;
use Wikibase::Datatype::Print::Value::Monolingual;
use Wikibase::Datatype::Print::Value::Property;
use Wikibase::Datatype::Print::Value::Quantity;
use Wikibase::Datatype::Print::Value::Sense;
use Wikibase::Datatype::Print::Value::String;
use Wikibase::Datatype::Print::Value::Time;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.13;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value')) {
		err "Object isn't 'Wikibase::Datatype::Value'.";
	}

	my $type = $obj->type;
	my $ret;
	if ($type eq 'globecoordinate') {
		$ret = Wikibase::Datatype::Print::Value::Globecoordinate::print($obj, $opts_hr);
	} elsif ($type eq 'item') {
		$ret = Wikibase::Datatype::Print::Value::Item::print($obj, $opts_hr);
	} elsif ($type eq 'monolingualtext') {
		$ret = Wikibase::Datatype::Print::Value::Monolingual::print($obj, $opts_hr);
	} elsif ($type eq 'property') {
		$ret = Wikibase::Datatype::Print::Value::Property::print($obj, $opts_hr);
	} elsif ($type eq 'quantity') {
		$ret = Wikibase::Datatype::Print::Value::Quantity::print($obj, $opts_hr);
	} elsif ($type eq 'sense') {
		$ret = Wikibase::Datatype::Print::Value::Sense::print($obj, $opts_hr);
	} elsif ($type eq 'string') {
		$ret = Wikibase::Datatype::Print::Value::String::print($obj, $opts_hr);
	} elsif ($type eq 'time') {
		$ret = Wikibase::Datatype::Print::Value::Time::print($obj, $opts_hr);
	} else {
		err "Type '$type' is unsupported.";
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value - Wikibase value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value'.
         Type '%s' is unsupported.

=head1 EXAMPLE

=for comment filename=create_and_print_value.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::Value::Item->new(
         'value' => 'Q123',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::print($obj)."\n";

 # Output:
 # Q123

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Value::Globecoordinate>,
L<Wikibase::Datatype::Print::Value::Item>,
L<Wikibase::Datatype::Print::Value::Monolingual>,
L<Wikibase::Datatype::Print::Value::Property>,
L<Wikibase::Datatype::Print::Value::Quantity>,
L<Wikibase::Datatype::Print::Value::Sense>,
L<Wikibase::Datatype::Print::Value::String>,
L<Wikibase::Datatype::Print::Value::Time>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value>

Wikibase value datatype.

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

0.13

=cut
