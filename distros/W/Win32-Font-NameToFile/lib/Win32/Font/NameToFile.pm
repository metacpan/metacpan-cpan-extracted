package Win32::Font::NameToFile;

=pod

=head1 NAME

Win32::Font::NameToFile - Return the name of a TrueType font file from a description

=head1 SYNOPSIS

	use Win32::Font::NameToFile qw(get_ttf_abs_path get_ttf_filename get_ttf_matching);
	use GD;
	use GD::Text::Wrap;

	#
	#	using a simple, absolute path font description
	#
	my $img = GD::image->new();
	my $gdtext = GD::Text::Wrap->new($img);
	$gdtext->set_font(get_ttf_abs_path('Palatino Linotype Bold Italic'), 12);
	#
	#	using a simple font description with point size
	#
	$gdtext->font_path("$ENV{SYSTEMROOT}\\Fonts");
	$gdtext->set_font(get_ttf_filename('Palatino Linotype Bold Italic 12');
	#
	#	using a font description from a Perl/Tk Tk::Font object
	#
	my $img = GD::image->new();
	my $gdtext = GD::Text::Wrap->new($img);
	$gdtext->set_font(get_ttf_abs_path($tkfont));
	#
	#	using a partial font description
	#
	$gdtext->font_path("$ENV{SYSTEMROOT}\\Fonts");
	my @fonts = get_ttf_matching('Palatino');
	$gdtext->set_font($fonts[1], 12)
		if @fonts;

=head1 DESCRIPTION

Returns filenames for a TrueType font on Win32 platforms,
using either a descriptive name, or a Perl/Tk Font object.

If the name string does not end with a number, then
returns a scalar string for either the absolute path (I<for get_abs_path()>),
or only the filename without any file qualifier (I<for get_filename()>).

Otherwise, for descriptive text names that end with a number, or for
Perl/Tk L<Tk::Font> objects, returns a list of the
absolute path (I<for get_abs_path()>),
or the filename without any file qualifier (I<for get_filename()>),
and the point size of the font (useful to simplify calls to L<GD::Text>::set_font()).

Note that all methods are static I<(i.e., class)> methods, and are exported.

=head1 METHODS

=over 4

=item B<get_ttf_abs_path(> I<font-description> | I<Tk::Font object> B<)>

Returns the full path to the font file, as described above.

=item B<get_ttf_filename(> I<font-description> | I<Tk::Font object> B<)>

Returns the font filename, with any file qualifier removed,
as described above.

=item B<get_ttf_bold(> I<font-description> | I<Tk::Font object> B<)>

=item B<get_ttf_italic(> I<font-description> | I<Tk::Font object> B<)>

=item B<get_ttf_bold_italic(> I<font-description> | I<Tk::Font object> B<)>

Returns true (as the absolute filename) if there is a version of the font that is bold,
italic, or both.

=item I<@allfonts> = B<get_ttf_list()>

Returns a list of all available font descriptions.
NOTE: the returned descriptions have been normalized to
all lower case.

=item I<%allfonts> = B<get_ttf_map()>

Returns a list of all available (font description, filename) pairs
(suitable for storing in a hash).
NOTE: the returned descriptions have been normalized to
all lower case, and the filenames are all upper case, and do B<not>
include the full path prefix.

=item I<%fonts> = B<get_ttf_matching(>C<$string>B<)>

Returns a list of all available (font description, filename) pairs
(suitable for storing in a hash) that begin with C<$string>.
NOTE: the returned descriptions have been normalized to
all lower case, and the filenames are all upper case, and do B<not>
include the full path prefix.

=back

=head1 NOTES

=over 4

=item *

The font registry information is read once when the module is loaded,
and the information is stored in a package variable. Therefore,
any changes to the font registry after the package is loaded will not
be reflected by the module until the application is restarted.

=item *

Descriptive font naming can vary significantly, though in most cases the name is followed
by the weight (if any) and then the slant (if any). As ever, YMMV.

=item *

This module treats B<"Oblique"> slant the same as italic.

=item *

In order to normalize lookups, font names are stored internally
in all lower case, and the file names are stored in all upper case.

=item *

Some fonts do not have explicit fontfiles for their bold or italic versions,
but are manipulated by other packages (e.g., Perl/Tk) to implement the
weight or slant programmatically.

=item *

Some fonts are hidden files, and thus may not show up in either the registry, or
in the values return by this module.

=item *

When using Perl/Tk Font objects, be aware that the returned size value
depends on the C<-size> value supplied when the font was created. If a positive
C<-size> was specified, then the size is in B<pixels>; if negative, the size
is in B<points>. This module detects and negates the latter C<-size>'s when
returning the results. I<Alas, there is no simple/perfect method for deriving
points from pixels, so caution is advised.>

=item *

The test suite assumes the usual Arial font types are available.

=back

=head1 PREREQUISITES

L<Win32::TieRegistry>

=head1 AUTHOR and COPYRIGHT

Copyright(C) 2006, Dean Arnold, Presicient Corp., USA. All rights reserved.

L<mailto:darnold@presicient.com>

You may use this software under the same terms as Perl itself. See the
L<Perl Artistic|perlartistic> license for details.

=cut

use Win32::TieRegistry;
use Exporter;

use base qw(Exporter);

@EXPORT = qw( );
@EXPORT_OK = qw (get_ttf_abs_path get_ttf_filename get_ttf_bold get_ttf_italic get_ttf_bold_italic
	get_ttf_list get_ttf_map get_ttf_matching);

use vars qw(%fontkeys @fontnames %bold_fonts %italic_fonts %bold_italic_fonts);

use strict;
use warnings;

our $VERSION = 0.10;

BEGIN {
#
#	the registry may store fonts in Windows NT or Windows
#
	my @tmpfonts = sort keys %{$Registry->{'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'}};

	@tmpfonts = sort keys %{$Registry->{'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Fonts'}}
		unless scalar @tmpfonts;
#
#	lowercase everything to simplify lookups
#
	my $file;

	foreach (@tmpfonts) {
		$file = uc $Registry->{"HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts$_"};
#
#	only save truetypes
#
		next unless ($file=~/\.ttf$/i);
		s/^\\+//;
		s/\s*\(TrueType\)//;
		$fontkeys{lc $_} = $file;
		push @fontnames, lc $_;
#
#	check for bold or italic (or both)
#
		s/\s+bold\b//i,
		s/\s+(italic|oblique)\b//i,
		s/\s+$//,
		$bold_italic_fonts{lc $_} = $file,
		next
			if (/\s+bold\b/i && /\s+(italic|oblique)\b/i);

		s/\s+bold\b//i,
		s/\s+$//,
		$bold_fonts{lc $_} = $file,
		next
			if /\s+bold\b/i;

		s/\s+(italic|oblique)\b//i,
		s/\s+$//,
		$italic_fonts{lc $_} = $file
			if /\s+(italic|oblique)\b/i;
	}
}

sub get_ttf_abs_path {
	my ($file, $size) = _fileFromFont(@_);
	return $file ?
		(wantarray ? ("$ENV{SYSTEMROOT}\\Fonts\\$file", $size) : "$ENV{SYSTEMROOT}\\Fonts\\$file") :
		undef;
}

sub get_ttf_filename {
	my ($file, $size) = _fileFromFont(@_);
	$file=~s/\.ttf$//i if $file;
	return wantarray ? ($file, $size) : $file;
}

sub _fileFromFont {
	my $font = shift;

	my ($fontdesc, $size, $needbold, $needitalic);
	if (ref $font) {
		$@ = 'Not a Tk::Font object',
		return undef
			unless $font->isa('Tk::Font');
#
#	get family, weight, slant, and size into a string
#
		my %info = $font->actual();
		$fontdesc = lc $info{-family};
		$size = $info{-size};
		$size = abs($size);	# pTk may report as negative
		$needbold = ($info{-weight} eq 'bold');
		$needitalic = ($info{-slant} eq 'italic');
	}
	else {
		$fontdesc = lc $font;
		($fontdesc, $size) = ($1, $2)
			if ($fontdesc=~/^(.+)\s+(\d+)$/);
	}

	my $file =
		$needbold ?
			($needitalic ? $bold_italic_fonts{$fontdesc} : $bold_fonts{$fontdesc}) :
		$needitalic ? $italic_fonts{$fontdesc} :
		$fontkeys{$fontdesc};

	return $file ? ($file, $size) : undef;
}

sub get_ttf_bold {
	my $font = shift;

	my $fontdesc;
	if (ref $font) {
		$@ = 'Not a Tk::Font object',
		return undef
			unless $font->isa('Tk::Font');
#
#	get family
#
		$fontdesc = lc $font->Family();
	}
	else {
		$fontdesc = lc $font;
		$fontdesc=~s/\s+\d+$//;
		$fontdesc=~s/\s+(bold|italic|oblique)\b//g;
	}

	return $bold_fonts{$fontdesc} ?
		"$ENV{SYSTEMROOT}\\Fonts\\$bold_fonts{$fontdesc}" : undef;
}

sub get_ttf_italic {
	my $font = shift;

	my $fontdesc;
	if (ref $font) {
		$@ = 'Not a Tk::Font object',
		return undef
			unless $font->isa('Tk::Font');
#
#	get family
#
		$fontdesc = lc $font->Family();
	}
	else {
		$fontdesc = lc $font;
		$fontdesc=~s/\s+\d+$//;
		$fontdesc=~s/\s+(bold|italic|oblique)\b//g;
	}

	return $italic_fonts{$fontdesc} ?
		"$ENV{SYSTEMROOT}\\Fonts\\$italic_fonts{$fontdesc}" : undef;
}

sub get_ttf_bold_italic {
	my $font = shift;

	my $fontdesc;
	if (ref $font) {
		$@ = 'Not a Tk::Font object',
		return undef
			unless $font->isa('Tk::Font');
#
#	get family
#
		$fontdesc = lc $font->Family();
	}
	else {
		$fontdesc = lc $font;
		$fontdesc=~s/\s+\d+$//;
		$fontdesc=~s/\s+(bold|italic|oblique)\b//g;
	}

	return $bold_italic_fonts{$fontdesc} ?
		"$ENV{SYSTEMROOT}\\Fonts\\$bold_italic_fonts{$fontdesc}" : undef;
}

sub get_ttf_list {
	return @fontnames;
}

sub get_ttf_map {
	return %fontkeys;
}

sub get_ttf_matching {
	my $match = shift;
	$match = lc $match;

	my %fonts = ();
	my $matched;

	foreach (@fontnames) {
		$fonts{$_} = $fontkeys{$_},
		$matched = 1,
		next
			if (substr($_, 0, length($match)) eq $match);

		last if $matched;	# terminate early if we previously matched, but not anymore
	}
	return %fonts;
}

1;
