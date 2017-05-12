package Wx::Metafile;
use strict;
use warnings;
use base 'DynaLoader';
use Wx;

use vars qw($VERSION);
$VERSION = '0.02',

Wx::wx_boot( 'Wx::Metafile', $Wx::Metafile::VERSION );


package Wx::EnhMetaFile; 

@Wx::EnhMetaFile::ISA = qw(Wx::Metafile);

=pod

=head1 NAME

Wx::Metafile - Implementation of the wxMetafile class of wxWindows

=head1 SYNOPSIS

	my $mf = Wx::Metafile->new('./test.emf');
	# if it loads OK
	if ($mf->Ok)
	{
		# We create an empty bitmap
	    $bmp = Wx::Bitmap->new(100,100);
	    # And a temporary DC
	    $tmpdc = Wx::MemoryDC->new();
	    # Everything we do in the DC changes the bitmap
	    $tmpdc->SelectObject($bmp);
		# We 'play' it inside the DC
		$mf->Play($tmpdc, Wx::Rect->new(0,0,100,100));
	}

=head1 DESCRIPTION

See for more information the wxPerl documentation that can
be downloaded from the wxPerl website (http://wxperl.sf.net),
which also contains the documentation for this class.

Mind you: Wx::Metafile works only on Win32 platforms. It won't
do anything on other platforms. Although it's possible to 
configure wxWindows to support WMF's instead of EMF's, the
Windows Metafile support in wxWindows is broken, and only
Enhanced Metafiles will work.

=head1 AUTHOR

	Jouke Visser
	jouke@cpan.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

Copyright (c) 2003 Jouke Visser. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).


=cut

1;
