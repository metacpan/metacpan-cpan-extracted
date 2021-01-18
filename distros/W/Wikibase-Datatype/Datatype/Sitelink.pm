package Wikibase::Datatype::Sitelink;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_array_object check_required);

our $VERSION = 0.06;

has badges => (
	is => 'ro',
	default => [],
);

has site => (
	is => 'ro',
);

has title => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	check_required($self, 'site');
	check_required($self, 'title');

	check_array_object($self, 'badges', 'Wikibase::Datatype::Value::Item', 'Badge');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Sitelink - Wikibase sitelink datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Sitelink;

 my $obj = Wikibase::Datatype::Sitelink->new(%params);
 my $badges_ar = $obj->badges;
 my $site = $obj->site;
 my $title = $obj->title;

=head1 DESCRIPTION

This datatype is sitelink class for representing link to wikimedia projects
(e.g. Czech Wikipedia).

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Sitelink->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<badges>

Badges.
Default value is [].

=item * C<site>

Site shortcut (e.g. cswiki).
Parameter is required.

=item * C<title>

Page title (e.g. 'Main Page').
Parameter is required.

=back

=head2 C<badges>

 my $badges_ar = $obj->badges;

Get badges (Badge is link to item - regexp /^Q\d+$/).

Returns reference to array with strings.

=head2 C<site>

 my $site = $obj->site;

Get site.

Returns string.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'site' is required.
                 Parameter 'title' is required.
         From Mo::utils::check_array_object():
                 Badge isn't 'Wikibase::Datatype::Value::Item' object.
                 Parameter 'badges' must be a array.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::Sitelink->new(
         'badges' => [
                  Wikibase::Datatype::Value::Item->new(
                          'value' => 'Q123',
                  ),
         ],
         'site' => 'cswiki',
         'title' => decode_utf8('Hlavní strana'),
 );

 # Get badges.
 my $badges_ar = [map { $_->value } @{$obj->badges}];

 # Get site.
 my $site = $obj->site;

 # Get title.
 my $title = $obj->title;

 # Print out.
 print 'Badges: '.(join ', ', @{$badges_ar})."\n";
 print "Site: $site\n";
 print 'Title: '.encode_utf8($title)."\n";

 # Output:
 # Badges: Q123
 # Site: cswiki
 # Title: Hlavní strana

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.06

=cut
