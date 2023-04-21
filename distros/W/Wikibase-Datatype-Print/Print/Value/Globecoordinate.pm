package Wikibase::Datatype::Print::Value::Globecoordinate;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.09;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Globecoordinate')) {
		err "Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.";
	}

	my $ret = '('.$obj->latitude.', '.$obj->longitude.')';

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::Globecoordinate - Wikibase globe coordinate value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::Globecoordinate qw(print);

 my $pretty_print_string = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Globecoordinate>
object.

Returns string.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.

=head1 EXAMPLE

=for comment filename=create_and_print_value_globecoordinate.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Globecoordinate;
 use Wikibase::Datatype::Value::Globecoordinate;

 # Object.
 my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
         'value' => [49.6398383, 18.1484031],
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Globecoordinate::print($obj)."\n";

 # Output:
 # (49.6398383, 18.1484031)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Globecoordinate>

Wikibase globe coordinate value datatype.

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

0.09

=cut
