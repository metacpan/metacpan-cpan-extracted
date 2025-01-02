package Wikibase::Datatype::Print::Value::Property;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.18;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Property')) {
		err "Object isn't 'Wikibase::Datatype::Value::Property'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache')) {
		err "Option 'cb' must be a instance of Wikibase::Cache.";
	}

	my $property;
	if (exists $opts_hr->{'cb'}) {
		$property = $opts_hr->{'cb'}->get('label', $obj->value);
	}
	if (! defined $property) {
		$property = $obj->value;
	}

	return $property;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::Property - Wikibase property value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::Property qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Property>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::Property'.
         Option 'cb' must be a instance of Wikibase::Cache.

=head1 EXAMPLE

=for comment filename=create_and_print_value_property.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Property;
 use Wikibase::Datatype::Value::Property;

 # Object.
 my $obj = Wikibase::Datatype::Value::Property->new(
         'value' => 'P31',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Property::print($obj)."\n";

 # Output:
 # P31

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Property>

Wikibase property value datatype.

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

0.18

=cut
