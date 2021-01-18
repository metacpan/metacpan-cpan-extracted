package Wikibase::Datatype::Struct::Sitelink;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Value::Item;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.06;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Sitelink')) {
		err "Object isn't 'Wikibase::Datatype::Sitelink'.";
	}

	my $struct_hr = {
		'badges' => [
			map { $_->value } @{$obj->badges},
		],
		'site' => $obj->site,
		'title' => $obj->title,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $obj = Wikibase::Datatype::Sitelink->new(
		'badges' => [
			map { Wikibase::Datatype::Value::Item->new('value' => $_); }
			@{$struct_hr->{'badges'}},
		],
		'site' => $struct_hr->{'site'},
		'title' => $struct_hr->{'title'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Sitelink - Wikibase sitelink structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Sitelink qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Sitelink instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of sitelink to object.

Returns Wikibase::Datatype::Sitelink instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Sitelink'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Struct::Sitelink qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Sitelink->new(
         'site' => 'enwiki',
         'title' => 'Main page',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     badges   [],
 #     site     "enwiki",
 #     title    "Main page"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Sitelink qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'badges' => [],
         'site' => 'enwiki',
         'title' => 'Main page',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get badges.
 my $badges_ar = [map { $_->value } @{$obj->badges}];

 # Get site.
 my $site = $obj->site;

 # Get title.
 my $title = $obj->title;

 # Print out.
 print 'Badges: '.(join ', ', @{$badges_ar})."\n";
 print "Site: $site\n";
 print "Title: $title\n";

 # Output:
 # Badges:
 # Site: enwiki
 # Title: Main page

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Sitelink>,
L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Sitelink>

Wikibase sitelink datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2021

BSD 2-Clause License

=head1 VERSION

0.06

=cut
