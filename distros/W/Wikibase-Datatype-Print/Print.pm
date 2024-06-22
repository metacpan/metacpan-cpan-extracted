package Wikibase::Datatype::Print;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Item;
use Wikibase::Datatype::Print::Lexeme;
use Wikibase::Datatype::Print::Mediainfo;
use Wikibase::Datatype::Print::Property;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.17;

sub print {
	my ($obj, $opts_hr) = @_;

	my @ret;
	if ($obj->isa('Wikibase::Datatype::Item')) {
		@ret = Wikibase::Datatype::Print::Item::print($obj, $opts_hr);
	} elsif ($obj->isa('Wikibase::Datatype::Lexeme')) {
		@ret = Wikibase::Datatype::Print::Lexeme::print($obj, $opts_hr);
	} elsif ($obj->isa('Wikibase::Datatype::Mediainfo')) {
		@ret = Wikibase::Datatype::Print::Mediainfo::print($obj, $opts_hr);
	} elsif ($obj->isa('Wikibase::Datatype::Property')) {
		@ret = Wikibase::Datatype::Print::Property::print($obj, $opts_hr);
	} else {
		my $ref = ref $obj;
		err "Unsupported Wikibase::Datatype object.",
			defined $ref ? ('Reference', $ref) : (),
		;
	}

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print - Wikibase datatype print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Item qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 DESCRIPTION

This distributions is set of print helpers for Wikibase::Datatype objects.

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for main objects like L<Wikibase::Datatype::Item>,
L<Wikibase::Datatype::Lexeme>, L<Wikibase::Datatype::Mediainfo> and
L<Wikibase::Datatype::Property>.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Unsupported Wikibase::Datatype object.
                 Reference: %s

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Print::Form>

Wikibase form pretty print helpers.

=item L<Wikibase::Datatype::Print::Item>

Wikibase item pretty print helpers.

=item L<Wikibase::Datatype::Print::Lexeme>

Wikibase lexeme pretty print helpers.

=item L<Wikibase::Datatype::Print::Mediainfo>

Wikibase mediainfo pretty print helpers.

=item L<Wikibase::Datatype::Print::MediainfoSnak>

Wikibase mediainfo snak pretty print helpers.

=item L<Wikibase::Datatype::Print::MediainfoStatement>

Wikibase mediainfo statement pretty print helpers.

=item L<Wikibase::Datatype::Print::Property>

Wikibase property pretty print helpers.

=item L<Wikibase::Datatype::Print::Reference>

Wikibase reference pretty print helpers.

=item L<Wikibase::Datatype::Print::Sense>

Wikibase sense pretty print helpers.

=item L<Wikibase::Datatype::Print::Sitelink>

Wikibase sitelink pretty print helpers.

=item L<Wikibase::Datatype::Print::Snak>

Wikibase snak pretty print helpers.

=item L<Wikibase::Datatype::Print::Statement>

Wikibase statement pretty print helpers.

=item L<Wikibase::Datatype::Print::Utils>

Wikibase pretty print helper utils.

=item L<Wikibase::Datatype::Print::Value>

Wikibase value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Globecoordinate>

Wikibase globe coordinate item pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Item>

Wikibase item value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Lexeme>

Wikibase lexeme value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Monolingual>

Wikibase monolingual value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Property>

Wikibase property value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Quantity>

Wikibase quantity value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::String>

Wikibase string value pretty print helpers.

=item L<Wikibase::Datatype::Print::Value::Time>

Wikibase time value pretty print helpers.

=back

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Item>,
L<Wikibase::Datatype::Print::Lexeme>,
L<Wikibase::Datatype::Print::Mediainfo>,
L<Wikibase::Datatype::Print::Property>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::JSON>

Wikibase structure JSON serialization.

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.17

=cut
