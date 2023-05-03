package Wikibase::Datatype::Print::Value::Quantity;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.13;

sub print {
	my ($obj, $opts_hr) = @_;

	# Default options.
	if (! defined $opts_hr) {
		$opts_hr = {};
	}
	if (! exists $opts_hr->{'print_name'}) {
		$opts_hr->{'print_name'} = 1;
	}

	if (! $obj->isa('Wikibase::Datatype::Value::Quantity')) {
		err "Object isn't 'Wikibase::Datatype::Value::Quantity'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache')) {
		err "Option 'cb' must be a instance of Wikibase::Cache.";
	}

	# Unit.
	my $unit;
	if ($obj->unit) {
		if ($opts_hr->{'print_name'} && exists $opts_hr->{'cb'}) {
			$unit = $opts_hr->{'cb'}->get('label', $obj->unit) || $obj->unit;
		} else {
			$unit = $obj->unit;
		}
	}

	# Output.
	my $ret = $obj->value;
	if ($unit) {
		$ret .= ' ('.$unit.')';
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::Quantity - Wikibase quantity value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::Quantity qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Quantity>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::Quantity'.
         Option 'cb' must be a instance of Wikibase::Cache.

=head1 EXAMPLE1

=for comment filename=create_and_print_value_quantity.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Quantity;
 use Wikibase::Datatype::Value::Quantity;

 # Object.
 my $obj = Wikibase::Datatype::Value::Quantity->new(
         'unit' => 'Q190900',
         'value' => 10,
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Quantity::print($obj)."\n";

 # Output:
 # 10 (Q190900)

=head1 EXAMPLE2

=for comment filename=create_and_print_value_quantity_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Value::Quantity;
 use Wikibase::Datatype::Value::Quantity;

 # Object.
 my $obj = Wikibase::Datatype::Value::Quantity->new(
         'unit' => 'Q11573',
         'value' => 10,
 );

 # Cache object.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Quantity::print($obj, {
         'cb' => $cache,
 })."\n";

 # Output:
 # 10 (metre)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Quantity>

Wikibase quantity value datatype.

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
