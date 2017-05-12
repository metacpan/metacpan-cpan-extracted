package WWW::Newzbin::Constants;

use 5.005;
use strict;
use warnings;

use base qw(Exporter);

our $VERSION = '0.07';

#=============================================================================#
# constant groups
#=============================================================================#

my @categories = qw(
	NEWZBIN_CAT_UNKNOWN
	NEWZBIN_CAT_ANIME
	NEWZBIN_CAT_APPS
	NEWZBIN_CAT_BOOKS
	NEWZBIN_CAT_CONSOLES
	NEWZBIN_CAT_EMULATION
	NEWZBIN_CAT_GAMES
	NEWZBIN_CAT_MISC
	NEWZBIN_CAT_MOVIES
	NEWZBIN_CAT_MUSIC
	NEWZBIN_CAT_PDA
	NEWZBIN_CAT_RESOURCES
	NEWZBIN_CAT_TV
);

my @sortfields = qw(
	NEWZBIN_SORTFIELD_DATE
	NEWZBIN_SORTFIELD_SUBJECT
	NEWZBIN_SORTFIELD_FILESIZE
);

my @sortorder = qw(
	NEWZBIN_SORTORDER_ASC
	NEWZBIN_SORTORDER_DESC
);

#=============================================================================#
# export lists
#=============================================================================#

our @EXPORT_OK = (
	@categories,
	@sortfields,	
	@sortorder
);

our %EXPORT_TAGS = (
	all => [ @categories, @sortfields, @sortorder ],
	categories => \@categories,
	sort => [ @sortfields, @sortorder ],
);

#=============================================================================#
# constant definitions
#=============================================================================#

sub NEWZBIN_CAT_UNKNOWN()		{ return "Unknown"; }
sub NEWZBIN_CAT_ANIME()			{ return "Anime"; }
sub NEWZBIN_CAT_APPS()			{ return "Apps"; }
sub NEWZBIN_CAT_BOOKS()			{ return "Books"; }
sub NEWZBIN_CAT_CONSOLES()		{ return "Consoles"; }
sub NEWZBIN_CAT_EMULATION()		{ return "Emulation"; }
sub NEWZBIN_CAT_GAMES()			{ return "Games"; }
sub NEWZBIN_CAT_MISC()			{ return "Misc"; }
sub NEWZBIN_CAT_MOVIES()		{ return "Movies"; }
sub NEWZBIN_CAT_MUSIC()			{ return "Music"; }
sub NEWZBIN_CAT_PDA()			{ return "PDA"; }
sub NEWZBIN_CAT_RESOURCES()		{ return "Resources"; }
sub NEWZBIN_CAT_TV()			{ return "TV"; }

sub NEWZBIN_SORTFIELD_DATE()		{ return "DATE"; }
sub NEWZBIN_SORTFIELD_SUBJECT()		{ return "SUBJECT"; }
sub NEWZBIN_SORTFIELD_FILESIZE()	{ return "BYTES"; }

sub NEWZBIN_SORTORDER_ASC()		{ return "ASC"; }
sub NEWZBIN_SORTORDER_DESC()		{ return "DESC"; }

#=============================================================================#

1;

__END__

#=============================================================================#

=pod

=head1 NAME

WWW::Newzbin::Constants - Exportable constants for use with L<WWW::Newzbin>

=head1 SYNOPSIS

	use WWW::Newzbin::Constants qw(:all); # exports everything
	
	use WWW::Newzbin::Constants qw(:categories); # just exports categories
	
	use WWW::Newzbin::Constants qw(:sort); # just exports sorting-related constants

=head1 DESCRIPTION

This module contains exportable constants that can be used in conjunction with its parent module, L<WWW::Newzbin>. The constants exported by this module are otherwise not very useful.

=head2 EXPORT GROUPS

Nothing is exported by default (this means that adding C<use WWW::Newzbin::Constants;> or C<use WWW::Newzbin::Constants ();> to your code will export no constants). One or more of the following export groups must be explicitly stated.

=head3 all

	use WWW::Newzbin::Constants qw(:all);

Exports constants from all export groups.

=head3 categories

	use WWW::Newzbin::Constants qw(:categories);

Exports constants relating to Newzbin categories:

=over

=item * C<NEWZBIN_CAT_UNKNOWN> - "Unknown" category

=item * C<NEWZBIN_CAT_ANIME> - "Anime" category

=item * C<NEWZBIN_CAT_APPS> - "Apps" category

=item * C<NEWZBIN_CAT_BOOKS> - "Books" category

=item * C<NEWZBIN_CAT_CONSOLES> - "Consoles" category

=item * C<NEWZBIN_CAT_EMULATION> - "Emulation" category

=item * C<NEWZBIN_CAT_GAMES> - "Games" category

=item * C<NEWZBIN_CAT_MISC> - "Misc" category

=item * C<NEWZBIN_CAT_MOVIES> - "Movies" category

=item * C<NEWZBIN_CAT_MUSIC> - "Music" category

=item * C<NEWZBIN_CAT_PDA> - "PDA" category

=item * C<NEWZBIN_CAT_RESOURCES> - "Resources" category

=item * C<NEWZBIN_CAT_TV> - "TV" category

=back

=head3 sort

Exports constants related to searching Newzbin (particularly via L<WWW::Newzbin>'s L<search_files|WWW::Newzbin/"search_files"> method):

=over

=item * C<NEWZBIN_SORTFIELD_DATE> - Sort search results by date posted

=item * C<NEWZBIN_SORTFIELD_SUBJECT> - Sort search results alphabetically by subject

=item * C<NEWZBIN_SORTFIELD_FILESIZE> - Sort search results by file size

=item * C<NEWZBIN_SORTORDER_ASC> - Sort search results in ascending order

=item * C<NEWZBIN_SORTORDER_DESC> - Sort search results in descending order

=back

=head1 DEPENDENCIES

L<Exporter>

=head1 SEE ALSO

L<WWW::Newzbin>

L<http://v3.newzbin.com> - Newzbin v3 home page

=head1 AUTHOR

Chris Novakovic <chrisn@cpan.org>

=head1 COPYRIGHT

Copyright 2007-8 Chris Novakovic.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
