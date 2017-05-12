#!/usr/bin/perl -w
# $Id$

use strict;

=head1 NAME

C<ping-mega.pl> - generates urls to each image in each size

=head1 SYNOPSIS

  ping-mega.pl url [ /path/to/image-root | /path/to/config ]

=head1 DESCRIPTION

C<ping-mega.pl> takes a url and optional a path to the image-root or
the config. Without that path it will expect the images in the default
location (see L<WWW::MeGa>) which is most likely not what you want.

Now it searches for files in the root dir and outputs the matching url
to each file in each size (atm the sizes are: 0, 1 and 2, see
L<WWW::MeGa> for more futher info about the thumbnail sizes).

The idea behind that is simple: The thumbnails of WWW::MeGa are getting
generated on the fly, but you might force the (re)generation of the
thumbnails (for not letting your visitors wait when the thumbnail is
getting created the first time or if you have changed some images)

=head1 USAGE EXAMPLES

You can pipe to output to a tool like wget for creating read the
thumbnail:

 ping-mega.pl http://sophiesfotos.de/gallery /webjail/bilder/sophie/ | xargs -d'\n' wget -O /dev/null


=head1 TODO

=over

=item * read sizes from config

=item * refresh Folder thumbnails only (for the case the THUMBNAIL link was changed)

=back

=cut

use File::Find;
use File::Spec;
use FindBin qw($RealBin);

use constant 'URL_FS' => "%s?rm=image;path=%s;size=%s\n";
use constant 'SIZES' => ( 0, 1, 2 );

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";

use WWW::MeGa;

my $url = shift or die "$0 url [ /path/to/image-root | /path/to/config ]";
my $in = shift;

die "path '$in' specified but invalid: $!" if $in and not -e $in;

my $ROOT = ($in and -d $in) ? $in : WWW::MeGa->new(PARAMS => { config => $in })->config->param('root');

find \&ping, $ROOT;

### 
sub ping
{
	my $abs = $File::Find::name;
	return unless -f $abs;
	my $rel = File::Spec->abs2rel($abs, $ROOT);
	printf URL_FS, $url, $rel, $_ for (SIZES);
}
