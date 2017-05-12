# $Id: MeGa.pm 193 2009-01-16 13:42:25Z fish $
package WWW::MeGa;
use 5.6.0;
use strict;
use warnings;

=head1 NAME

WWW::MeGa - A MediaGallery

=head1 SYNOPSIS

 use WWW::MeGa;
 my $webapp = WWW::MeGa->new
 $webapp->run;

=head1 DESCRIPTION


THIS IS A SECURITY BUGFIX RELEASE.
PLEASE UPDATE TO 0.1.1 IF YOU HAVE 0.1


WWW::MeGa is a web based media gallery. It should
be run from FastCGI (see examples/gallery.fcgi) or mod_perl (not yet
tested) because it uses some runtime caching.

Every file will be delievered by the CGI itself. So you don't have
to care about setting up picture/thumb dirs.

To see it in action, visit: http://freigeist.org/gallery
or http://sophiesfotos.de

=head1 FEATURES

=over

=item * on-the-fly image resizing (and orientation tag based autorotating)

=item * video thumbnails

=item * displays text files

=item * reads exif tag

=item * very easy to setup (change one path in the config and your done)

=item * templating with L<HTML::Template::Compiled>

=back

=head1 INSTALLATION

=head2 Install the package

Use your favorite way to install this CPAN-Package and make sure you
have C<ffmpeg> somewhere in your path (or specify the path in the
config) if you want video thumbnails.

If you want to install it via the cpan-installer use:

 cpan WWW::MeGa

To install a developer release of WWW::MeGa, use the CPAN-Shell:

 perl -MCPAN -eshell

Now you can see all releases with C<ls fish> and install the one you want: C<install FISH/WWW-MeGa-0.09_6.tar.gz>

B<WARNING>: Installation via C<cpan> or the CPAN-Shell is only recommended
if you have a local administered perl installation.  If you installed
perl from your packet manager you should use the packet manager to
install this package too. Have a look at C<g-cpan> (Gentoo) and
C<dh-make-perl> (Debian/Ubuntu).


=head3 Use FastCGI (preferred) 

Copy C<examples/gallery.fcgi> to some dir and configure your webserver to
use it as a FastCGI:

Example for lighttpd:

   fastcgi.server = (
                        "/gallery" =>
                        ( "localhost" =>
                                (
                                        "socket"        => "/var/run/lighttpd/gallery" + PID + ".socket",
                                        "check-local"   => "disable",
                                        "bin-path"      => "/var/www/gallery.fcgi"
                                )
                        ),
   )

=head3 Use CGI

Copy C<examples/gallery.cgi> to your C<cgi-bin/> directory and make
sure its executable. Now WWW::MeGa should have created a default config
file. Change 'root' to your images and you are done.

=head3 Config

Make sure the user under which the webserver is running has write
permission to the config file. The path to the config file defaults to
to 'gallery.conf' in the same dir as your script. In these cases:
C</var/www/gallery.conf> (FCGI) and
C</path/to/your/cgi-bin/gallery.conf>.

You can (and should, at least in the CGI case) specify a custom path to
the config by changing the scripts to pass:

 PARAMS => { config => '/path/to/your/config' }

to the new method of L<WWW::MeGa>.

=head4 modified gallery.fcgi

 ...
 my $app = WWW::MeGa->new
 (
         QUERY => $q,
         PARAMS => { cache => \%cache, config => '/path/to/your/config' },
 );
 ...

=head4 modified gallery.cgi

 ...
 my $webapp = WWW::MeGa->new(PARAMS => {config => '/path/to/your/config'});
 ...

=head2 Test it

Now visit the the URL to you script. (In these examples:
http://example.com/gallery (FastCGI) and
http://example.com/cgi-bin/gallery.cgi (CGI)) and you
should see the example photos. 

=head1 CONFIG

L<WWW::MeGa> uses L<CGI::Application::Plugin::Config::Simple> for config handling.
You can specify the path to a (writable) config file in the new methode of WWW::MeGa:

   my $gallery = WWW::MeGa->new(PARAMS => { config => '/path/to/gallery.conf' })

It defaults to $RealBin/gallery.conf, see L<FindBin> for more info.
After the first run it will create a config containing the defaults.


=head2 Parameters

=head3 root

Path to your images


=head3 cache

Path where to store the thumbnails

=head3 album-thumb

specifies which file should be used a thumbnail for a folder. Defaults to C<THUMBNAIL>.
The file named like that will be skipped when showing the content of the folder.

=head3 thumb-type

Type of the thumbnails.
L<WWW::MeGa> uses L<Image::Magick> for generating thumbnails.
See C<convert -list format> for file types supported by you ImageMagick
installation.

=head3 video-thumbs

If set to 1, enables video-thumbs. Default: 1

=head3 video-thumbs-offset

specifies which frame to grab in seconds. Default: 10

=head3 exif

If set to 1, enables the extraction of exif-data. Default: 1

=head3 ffmpeg-path

Specify the path to the ffmpeg-binary. Defaults to 'ffmpeg'. (Should be
looked up in your PATH)

=head3 sizes

A array of valid "thumbnail"/resized image sizes, defaults to
C<[ 120, 600, 800 ]>.
The CGI parameter C<size> is the index to that array.


=head3 debug

If set to 1, enabled debugging to your server's error log.


=head3 album_thumb

Specify the name of the image which will be used as a thumbnail for the
containing album, defaults to C<THUMBNAIL>.

So if you want to have the image C<foo.jpg> be the thumbnail for the album C<bar>, copy it to C<bar/THUMBNAIL> (or use a symlink)


=head3 icons and templates

Path to the icons and templates, defaults to C<icons/> in the module's share dir as defined by L<Module::Install> and L<File::ShareDir>


=head1 METHODES

=cut

use CGI::Application;
use File::Spec::Functions qw(splitdir catdir no_upwards);
use Scalar::Util;
use File::ShareDir;
use FindBin qw($RealBin);

use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

use CGI::Application::Plugin::Config::Simple;
use CGI::Application::Plugin::Stream (qw/stream_file/);

use WWW::MeGa::Item;

use Carp;

our $VERSION = '0.11';
sub setup
{
	my $self = shift;
	$self->{PathPattern} = "[^-,()'.\/ _0-9A-Za-z\[\]]";
	
	my $share = eval { File::ShareDir::module_dir('WWW::MeGa') } || "$RealBin/../share";

	my $config = $self->config_file($self->param('config') || "$RealBin/gallery.conf");

	my %default_config =
	(
		'sizes' => [ 120, 600, 800 ],
		'cache' => '/tmp/www-mega',
		'album_thumb' => 'THUMBNAIL',
		'thumb-type' => 'png',
		'video-thumbs' => 1,
		'video-thumbs-offset' => 10,
		'exif' => 1,
		'ffmpeg-path' => 'ffmpeg',
		'root' => catdir($share, 'images'),
		'debug' => 0,
		'icons' => catdir($share, 'icons'),
		'templates' => catdir($share, 'templates', 'default')
	);

	unless ( -e $config )
	{
		warn "config '$config' not found, creating default config";
		my $cfg = new Config::Simple(syntax=>'simple');
		foreach my $k (keys %default_config)
		{
			$cfg->param($k, $default_config{$k})
		}

		warn "saving $config";
		$cfg->write($config) or croak "could not create config '$config': $!";
	}

	$self->config_file($config) or croak "could not load config '$config': $!";

	foreach my $k (keys %default_config)
	{
		next if defined $self->config_param($k);
		$self->config_param($k, $default_config{$k});
	}

	croak $self->config_param('root') . " is no directory" unless -d $self->config_param('root');

	$self->tmpl_path($self->config_param('templates'));

	$self->{sizes} = $self->config_param('sizes');

	$self->{cache} = $self->param('cache');

	$self->run_modes
	(
		view => 'view_path',
		image => 'view_image',
	);
	$self->start_mode('view');
	$self->error_mode('view_error');
	return;
}

sub view_error
{
	my $self = shift;
	my $error = shift;
	warn "ERROR: $error";
	my $t = $self->load_tmpl('error.tmpl', die_on_bad_params=>0, global_vars=>1, default_escape =>'HTML');
	$self->header_props ({-status => 404 });
	$t->param(ERROR => $error);
	return $t->output;
}

sub saneReq
{
	my $self = shift;
	my $param = shift;
	my $pattern = shift || $self->{PathPattern};
	defined(my $req = $self->query->param($param)) or return;
	$req =~ s/$pattern//g;
	return $req;
}

sub pathReq
{
	my $self = shift;
	my $path = $self->saneReq('path') || '';
	$path = catdir no_upwards splitdir $path;
	return $path;
}

sub sizeReq
{
	my $self = shift;
	defined ( my $size = $self->saneReq('size', '[^0-9]') ) or return; # 0; #return @{$self->{sizes}}[0];
	die "no size '$size'" unless $self->{sizes}->[$size];
	return $size;
}


=head2 runmodes

the public runmodes, accessable via the C<rm> parameter

=head3 image

shows a thumbnail

=cut

sub view_image
{
	my $self = shift;
	my $path = $self->pathReq or die 'no path specified';

	my $s = $self->sizeReq;
	my $item = WWW::MeGa::Item->new($path,$self->config,$self->{cache});

	return $self->binary($item, defined $s ? $self->{sizes}->[$s] : undef);
}


=head3 view (DEFAULT RUNMODE)

shows a html page with one or more items

=cut

sub view_path
{
	my $self = shift;
	my $path = $self->pathReq;
	my $size_idx = $self->sizeReq || 0;
	my $off;
	{
		my $tmp = $self->query->param('off');
		$off = $tmp if $tmp && ($tmp eq 'next' || $tmp eq 'prev');
	}

	my %sizes =
	(
		SIZE => $size_idx,
		SIZE_IN => $size_idx+1,
		SIZE_OUT => $size_idx-1
	);

	my @path_e = File::Spec->splitdir($path);
	my $parent = File::Spec->catdir(@path_e[0 .. @path_e-2]); # bei file: album des files, bei folder: enthaltener folder

	if ($off)
	{
		my $pitem = WWW::MeGa::Item->new($parent,$self->config,$self->{cache}); # should be a folder in every case;
		my @n = $pitem->neighbours($path, $off);
		$path = $off eq 'next' ? $n[1] : $n[0];
	}

	my $item = WWW::MeGa::Item->new($path,$self->config,$self->{cache});



	my %hash = (PARENT => $parent, %sizes, %{ $item->data }, CONFIG => { $self->config->vars }, MIME => $item->{mime});
	my $template;

	if (Scalar::Util::blessed($item) eq 'WWW::MeGa::Item::Folder')
	{
		$template = 'album.tmpl';
		my @items = map { (WWW::MeGa::Item->new($_,$self->config(),$self->{cache}))->data } $item->list;
		$hash{ITEMS} = \@items;
	} else
	{
		$template = 'image.tmpl';
	}

	my $t = $self->load_tmpl($template, die_on_bad_params=>0, global_vars=>1, default_escape =>'HTML');
	$t->param(%hash);

	return $t->output;
}




sub binary
{
	my $self = shift;
	my $item = shift;
	my $size = shift;

	$self->header_add( -'Content-disposition' => 'inline' );
	return $self->stream_file($item->thumbnail($size)) ? undef : $self->error_mode;
}

=head1 FAQ

=head2 How do i..

=head3 ..select a image a Folder-Thumbnail?

L<WWW::MeGa> uses the image named C<THUMBNAIL> (or whatever you setup
for C<album_thumb> in the config) in each folder as its thumbnail. So
if you want to have the image C<foo/bar.jpg> to be the thumbnail for
C<foo>, set a symlink called C<foo/THUMBNAIL> to it (or copy it there)

=head3 ..(re)create all thumbnail so that my visitors don't have to wait?

See L<ping-mega.pl> for that.


=head1 BUGS, TODO AND NEW FEATURES

I tried to write a clean and elegant app but I'm not a perl guru so
B<please> bash me about everything you think suck in this project. I'm
willing to learn and appreciate constructive critic.

If you think this app is cool and you like to see new features please
let me know!

=head1 THANKS

Thanks to EXP (at least I guess he was it) who suggests me to learn
perl some years ago.

And thanks alot to the people from irc.perl.org / #perlde for the
current support.

=head1 COPYRIGHT

=head2 Code

Copyright 2008 by Johannes 'fish' Ziemke.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head2 Icons

The shipped icons are copyrighted by the "Tango Desktop Project" and
are licensed under the Creative Commons Attribution Share-Alike 2.5
license. See http://creativecommons.org/licenses/by-sa/2.5

=head2 Photos

biene.jpg and steine.jpg are copyrighted by Sophie Bischoff. For
more, see: http://sophiesfotos.de

moewe.jpg is copyrighted by Johannes 'fish' Ziemke.

The shipped example photos are licensed unter the Creative Commons
Attribution Share-Alike 3.0 license. See
http://creativecommons.org/licenses/by-sa/3.0/

=head1 SEE ALSO


=over

=item * L<ping-mega.pl>

=item * L<WWW::MeGa::Item>

=item * L<CGI::Application>

=back

=head1 AUTHOR

Johannes 'fish' Ziemke <my nickname at cpan org>


=cut

1;
