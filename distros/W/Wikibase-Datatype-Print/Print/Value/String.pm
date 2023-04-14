package Wikibase::Datatype::Print::Value::String;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.04;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::String')) {
		err "Object isn't 'Wikibase::Datatype::Value::String'.";
	}

	return $obj->value;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::String - Wikibase string value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::String qw(print);

 my $pretty_print_string = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::String>
object.

Returns string.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::String'.

=head1 EXAMPLE

=for comment filename=create_and_print_value_string.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::String;
 use Wikibase::Datatype::Value::String;

 # Object.
 my $obj = Wikibase::Datatype::Value::String->new(
         'value' => 'foo',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::String::print($obj)."\n";

 # Output:
 # foo

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::String>

Wikibase string value datatype.

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

0.04

=cut
