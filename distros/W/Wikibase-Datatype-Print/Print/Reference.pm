package Wikibase::Datatype::Print::Reference;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Snak;
use Wikibase::Datatype::Print::Utils qw(defaults);

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.18;

sub print {
	my ($obj, $opts_hr) = @_;

	$opts_hr = defaults($obj, $opts_hr);

	if (! $obj->isa('Wikibase::Datatype::Reference')) {
		err "Object isn't 'Wikibase::Datatype::Reference'.";
	}

	my @ret = '{';
	foreach my $snak (@{$obj->snaks}) {
		push @ret, map { '  '.$_ } Wikibase::Datatype::Print::Snak::print($snak, $opts_hr);
	}
	push @ret, '}';

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Reference - Wikibase reference pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Reference qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Reference>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         From Wikibase::Datatype::Print::Utils::defaults():
                 Defined text keys are bad.
         Object isn't 'Wikibase::Datatype::Reference'.

=head1 EXAMPLE1

=for comment filename=create_and_print_reference.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Reference;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Reference->new(
         'snaks' => [
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'url',
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'https://skim.cz',
                         ),
                         'property' => 'P854',
                 ),
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'time',
                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                 'value' => '+2013-12-07T00:00:00Z',
                         ),
                         'property' => 'P813',
                 ),
         ],
 );

 # Print.
 print Wikibase::Datatype::Print::Reference::print($obj)."\n";

 # Output:
 # {
 #   P854: https://skim.cz
 #   P813: 7 December 2013 (Q1985727)
 # }

=head1 EXAMPLE2

=for comment filename=create_and_print_reference_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Reference;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Reference->new(
         'snaks' => [
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'url',
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'https://skim.cz',
                         ),
                         'property' => 'P854',
                 ),
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'time',
                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                 'value' => '+2013-12-07T00:00:00Z',
                         ),
                         'property' => 'P813',
                 ),
         ],
 );

 # Cache.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::Reference::print($obj, {
         'cache' => $cache,
 })."\n";

 # Output:
 # {
 #   P854 (reference URL): https://skim.cz
 #   P813 (retrieved): 7 December 2013 (Q1985727)
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Snak>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Reference>

Wikibase reference datatype.

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
