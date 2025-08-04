package Wikibase::Datatype::Print::Value::Monolingual;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.19;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Monolingual')) {
		err "Object isn't 'Wikibase::Datatype::Value::Monolingual'.";
	}

	return $obj->value.' ('.$obj->language.')';
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::Monolingual - Wikibase monolingual value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::Monolingual qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Monolingual>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::Monolingual'.

=head1 EXAMPLE

=for comment filename=create_and_print_value_monolingual.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Monolingual;
 use Wikibase::Datatype::Value::Monolingual;

 # Object.
 my $obj = Wikibase::Datatype::Value::Monolingual->new(
         'language' => 'en',
         'value' => 'English text',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Monolingual::print($obj)."\n";

 # Output:
 # English text (en)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Monolingual>

Wikibase monolingual value datatype.

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
