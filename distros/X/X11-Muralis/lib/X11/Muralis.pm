package X11::Muralis;
$X11::Muralis::VERSION = '0.1003';
use strict;
use warnings;
use 5.8.3;

=head1 NAME

X11::Muralis - Perl module to display wallpaper on your desktop.

=head1 VERSION

version 0.1003

=head1 SYNOPSIS

    use X11::Muralis;

    my $obj = X11::Muralis->new(%args);

=head1 DESCRIPTION

The X11::Muralis module (and accompanying script, 'muralis') displays a
given image file on the desktop background (that is, the root window) of
an X-windows display.

This tries to determine what size would best suit the image; whether to
show it fullscreen or normal size, whether to show it tiled or centred
on the screen.  Setting the options overrides this behaviour.

One can also repeat the display of the last-displayed image, changing the
display options as one desires.

This uses an external program (xloadimage, xsri, or feh) to display
the image file.

This also depends on xwininfo to get information about the root window.

=head2 The Name

The name "muralis" comes from the Latin "muralis" which is the word from
which "mural" was derived.  I just thought it was a cool name for a
wallpaper script.

=cut

use Image::Info;
use File::Basename;
use File::Find::Rule;
use X11::Muralis::Backend;
use Module::Pluggable instantiate => 'new', search_path => 'X11::Muralis::Backend', sub_name => 'backends';

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = X11::Muralis->new(
	config_dir=>"$ENV{HOME}/.muralis",
	is_image => qr/.(gif|jpeg|jpg|tiff|tif|png|pbm|xwd|pcx|gem|xpm|xbm)/i,
	);

=cut

sub new {
    my $class = shift;
    my %parameters = (
	config_dir => "$ENV{HOME}/.muralis",
	is_image => qr/.(gif|jpeg|jpg|tiff|tif|png|pbm|xwd|pcx|gem|xpm|xbm)/i,
	imgcmd => 'xloadimage',
	@_
    );
    my $self = bless ({%parameters}, ref ($class) || $class);
    return ($self);
} # new

=head2 get_backends

    my @backends = $obj->list_backends();

Return which backends are available.

=cut
sub get_backends($) {
    my $self = shift;

    my @avail_backends = ();
    my @backends = $self->backends();
    foreach my $be (@backends)
    {
	if ($be->active())
	{
	    push @avail_backends, X11::Muralis::Backend::name($be);
	}
    }
    return @avail_backends;
} # get_backends

=head2 list_backends

    $obj->list_backends();

List which backends are available.

=cut
sub list_backends($) {
    my $self = shift;

    my @backends = $self->get_backends();
    print join("\n", @backends);
    print "\n";
} # list_backends

=head2 list_images

$dr->list_images();

$dr->list_images(match=>'animals',
    list=>'fullname');

List all the images which match the match-string.
(prints to STDOUT)

Arguments:

=over

=item match => I<string>

Limit the images which match the given string.

=item listformat => I<string>

Give the list format.  If not defined or empty or "normal", will do a "normal"
listing, which gives the directory names followed by the files.
If 'fullname' then it will list all the files with their full names
(and doesn't list the directory names).

=item outfile => I<filename>

Print the list to the given file rather than to STDOUT.

=back

=cut
sub list_images {
    my $self = shift;
    my %args = (@_);

    my @files = $self->get_image_files(%args);

    my $count = 0;
    my $fh = \*STDOUT;
    if ($args{outfile} and $args{outfile} ne '-')
    {
	open $fh, ">", $args{outfile}
	    || die "Cannot open '$args{outfile}' for writing";
    }
    if ($args{listformat} and $args{listformat} =~ /full/i)
    {
	print $fh join("\n", @files);
	print $fh "\n";
    }
    else
    {
	my $this_dir = '';
	foreach my $file (@files)
	{
	    my ($shortfile,$dir,$suffix) = fileparse($file,'');
	    $dir =~ s#/$##;
	    if ($dir ne $this_dir)
	    {
		print $fh "${dir}:\n";
		$this_dir = $dir;
	    }
	    print $fh $shortfile;
	    print $fh "\n";
	}
    }
    if ($args{outfile} and $args{outfile} ne '-')
    {
	close $fh;
    }
    $count;
}

=head2 provides

    my %prov = $obj->provides($backend_name);

What does this backend provide?

=cut
sub provides($$) {
    my $self = shift;
    my $backend_name = shift;

    my @backends = $self->backends();
    foreach my $be (@backends)
    {
	if (X11::Muralis::Backend::name($be) eq $backend_name)
	{
	    return $be->provides();
	}
    }
    return ();
} # provides

=head2 display_image

    $obj->display_image(%args);

Arguments: 

=over

=item center=>1

Centre the image on the root window.

=item colors=>I<num>

Limit the number of colours used to display the image.  This is useful
for a 256-colour display.

=item fullscreen=>1

The image will be zoomed to fit the size of the screen.

=item match=>I<string>

If using the --list or --random options, limit the image(s) to those 
which match the string.

=item random=>1

Pick a random image to display.  If --match is given, limit
the selection to images in directories which match the match-string.

=item repeat_last=>1

Display the last image which was displayed.  This is useful to
re-display an image while overriding the default display options.

=item option=>I<string>

Additional option or options to pass on to the backend.

=item tile=>1

Tile the image to fill the root window.

=item use=>I<backend>

Use the given backend.

=item verbose=>1

Print informational messages.

=item zoom=>I<percent>

Enlarge or reduce the size of the image by the given percent.

=back

=cut
sub display_image {
    my $self = shift;
    my %args = (
	@_
    );

    my $filename = '';
    undef $self->{_files};
    if ($args{random}) # get a random file
    {
	$filename = $self->get_random_file(%args);
    }
    elsif ($args{nth}) # get nth file (counting from 1)
    {
	$filename = $self->find_nth_file($args{nth}, %args);
    }
    elsif ($args{repeat_last}) # repeat the last image
    {
	my $cdir = $self->{config_dir};
	if (-f "$cdir/last")
	{
	    open(LIN, "$cdir/last") || die "Cannot open $cdir/last";
	    $filename = <LIN>;
	    close(LIN);
	    $filename =~ s/\n//;
	    $filename =~ s/\r//;
	}
    }
    if (!$filename)
    {
	$filename = $args{filename};
    }

    my ($fullname, $opt_ref) = $self->get_display_options($filename, %args);
    my $backend_name = $args{use};
    my @backends = $self->backends();
    foreach my $be (@backends)
    {
	if (X11::Muralis::Backend::name($be) eq $backend_name)
	{
	    $be->display($fullname, %{$opt_ref});
	    last;
	}
    }
    $self->save_last_displayed($fullname, %args);
} # display_image

=head1 Private Methods

=head2 count_images

my $count = $dr->count_images();

my $count = $dr->count_images(match=>'animals');

Counts all the images.

Optional argument: match => I<string>

Counts the images which match the string.

=cut
sub count_images ($;%) {
    my $self = shift;
    my %args = (@_);

    if (!defined $self->{_files}
	|| !$self->{_files})
    {
	my @files = $self->get_image_files(%args);
	$self->{_files} = \@files;
    }
    my $files_ref = $self->{_files};

    my $count = @{$files_ref};
    return $count;
} #count_images

=head2 get_image_files

my @files = $self->get_image_files();

my @files = $self->get_image_files(
    match=>$match,
    exclude=>$exclude
    unseen=>1);

Get a list of matching image files.

If 'unseen' is true, then get the file names from the ~/.muralis/unseen
file, if it exists.

=cut
sub get_image_files {
    my $self = shift;
    my %args = (@_);

    my @files = ();
    my $get_all_files = 1;
    my $update_unseen = 0;
    my $unseen_file = $self->{config_dir} . "/unseen";
    if ($args{unseen} and -f $unseen_file)
    {
	$get_all_files = 0;
	open(UNSEEN, "<", $unseen_file)
	    || die "Cannot read $unseen_file";
	while(<UNSEEN>)
	{
	    chomp;
	    push @files, $_;
	}
	close(UNSEEN);
	# if there are no files there
	# then delete the file and start afresh
	if (!@files)
	{
	    unlink $unseen_file;
	    $get_all_files = 1;
	    $update_unseen = 1;
	}
    }
    if ($get_all_files)
    {
	if (!defined $self->{_dirs}
	    || !$self->{_dirs})
	{
	    my @dirs = $self->get_dirs(%args);
	    $self->{_dirs} = \@dirs;
	}
	@files = File::Find::Rule->file()
	    ->name($self->{is_image})
	    ->in(@{$self->{_dirs}});
    }
    # if we need to update the unseen-images file, do so
    if ($update_unseen)
    {
	if (!-d $self->{config_dir})
	{
	    mkdir $self->{config_dir};
	}
	open(LOUT, ">$unseen_file") || die "Cannot write to $unseen_file";
	print LOUT join("\n", @files);
	print LOUT "\n";
	close LOUT;
	if ($args{verbose})
	{
	    print STDERR "updated $unseen_file\n";
	}
    }

    if ($self->{verbose} and !@files)
    {
	print STDERR "No files at all!\n";
    }
    my @ret_files = ();
    if ($args{match} and $args{exclude})
    {
	@ret_files = grep {/$args{match}/ && !/$args{exclude}/} @files;
    }
    elsif ($args{match})
    {
	@ret_files = grep {/$args{match}/} @files;
    }
    elsif ($args{exclude})
    {
	@ret_files = grep {!/$args{exclude}/} @files;
    }
    else
    {
	@ret_files = @files;
    }
    if ($self->{verbose} and !@ret_files)
    {
	print STDERR "No files found.\n";
    }
    return @ret_files;
} #get_image_files

=head2 get_dirs

my @dirs = $self->get_dirs();

Get the list of directories.

=cut
sub get_dirs {
    my $self = shift;
    my %args = (@_);

    my @dirs = @{$args{dir}};
    if ($args{recursive})
    {
	push @dirs, File::Find::Rule->directory->in(@{$args{dir}});
    }
    return @dirs;
} #get_dirs

=head2 get_root_info

Get info about the root window.  This uses xwininfo.

=cut

sub get_root_info ($) {
    my $self = shift;

    my $verbose = $self->{verbose};

    my $width = 0;
    my $height = 0;
    my $depth = 0;

    my $fh;
    open($fh, "xwininfo -root |") || die "Cannot pipe from xwininfo -root";
    while (<$fh>)
    {
	if (/Width/)
	{
	    /Width:?\s([0-9]*)/;
	    $width = $1;
	}
	if (/Height/)
	{
	    /Height:?\s([0-9]*)/;
	    $height = $1;
	}
	if (/Depth/)
	{
	    /Depth:?\s([0-9]*)/;
	    $depth = $1;
	}
    }
    close($fh);
    if ($verbose)
    {
	print STDERR "SCREEN: width = $width, height = $height, depth = $depth\n";
    }
    $self->{_root_width} = $width;
    $self->{_root_height} = $height;
    $self->{_root_depth} = $depth;
}

=head2 find_nth_file

Find the full name of the nth (matching) file
starting the count from 1.

=cut

sub find_nth_file ($$) {
    my $self = shift;
    my $nth = shift;
    my %args = @_;

    if ($nth <= 0)
    {
	$nth = 1;
    }
    if (!defined $self->{_files}
	|| !$self->{_files})
    {
	my @files = $self->get_image_files(%args);
	$self->{_files} = \@files;
    }
    my $files_ref = $self->{_files};

    my $full_name = $files_ref->[$nth - 1];
    return $full_name;
}

=head2 get_random_file

Get the name of a random file.

=cut
sub get_random_file ($) {
    my $self = shift;
    my %args = @_;

    my $total_files = $self->count_images(%args);
    # get a random number between 1 and the number of files
    my $rnum = int(rand $total_files) + 1;

    my $file_name = $self->find_nth_file($rnum, %args);
    if (!$file_name or ! -f $file_name)
    {
	print STDERR "NOT FOUND #$rnum (of $total_files) $file_name\n";
    }

    if ($args{verbose})
    {
	if ($args{match} || $args{exclude})
	{
	    print STDERR "picked image #${rnum} out of $total_files";
	    print STDERR " matching '$args{match}'" if $args{match};
	    print STDERR " excluding '$args{exclude}'" if $args{exclude};
	    print "\n";
	}
	else
	{
	    print STDERR "picked image #${rnum} out of $total_files\n";
	}
    }

    return $file_name;
} # get_random_file

=head2 find_fullname

Find the full filename of an image file.

=cut
sub find_fullname ($$;%) {
    my $self = shift;
    my $image_name = shift;
    my %args = @_;

    if (!defined $image_name)
    {
	die "image name not defined!";
    }
    my $full_name = '';

    # first check if it's local
    if (-f $image_name)
    {
	$full_name = $image_name;
    }
    else # go looking
    {
	my @files = $self->get_image_files(%args);
    
	my @match_files = grep {/$image_name/ } @files;
	foreach my $ff (@match_files)
	{
	    if (-f $ff)
	    {
		$full_name = $ff;
		last;
	    }
	}
    }
    return $full_name;
} # find_fullname

=head2 get_display_options

Use the options passed in or figure out the best default options.
Return a string containing the options.

    $options = $obj->get_display_options($filename, %args);

=cut
sub get_display_options ($$;%) {
    my $self = shift;
    my $filename = shift;
    my %args = (
	verbose=>0,
	fullscreen=>undef,
	option=>undef,
	center=>undef,
	tile=>0,
	colors=>undef,
	window=>undef,
	zoom=>undef,
	@_
    );

    if (!defined $self->{_root_width}
	|| !$self->{_root_width})
    {
	$self->get_root_info();
    }
    my $options = '';

    my $fullname = $self->find_fullname($filename, %args);
    my $info = Image::Info::image_info($fullname);
    if (my $error = $info->{error})
    {
	warn "Can't parse info for $fullname: $error\n";
	$args{fullscreen} = 0 if !defined $args{fullscreen};
	$args{center} = 0 if !defined $args{center};
    }
    else
    {
	if ($args{verbose})
	{
	    print STDERR "IMAGE: $filename",
		  " ", $info->{file_media_type}, " ",
		  $info->{width}, "x", $info->{height},
		  " ", $info->{color_type},
		  "\n";
	}
	if (defined $args{tile} and $args{tile})
	{
	    # if we want it tiled, we don't want it fullscreen
	    $args{fullscreen} = 0;
	}
	if (!defined $args{fullscreen}) # not set
	{
	    # default is off
	    $args{fullscreen} = 0;
	    # If the width and height are more than half the width
	    # and height of the screen, make it fullscreen
	    # However, if the the image is a square, it's likely to be a tile,
	    # in which case we don't want to expand it unless it's quite big
	    # Also, if one of the sides is the exact size of the screen,
	    # and the other dimension is smaller or equal to the size of the screen,
	    # we don't need to make the image fullscreen, because it already is.
	    if ($info->{width} == $info->{height})
	    {
		 if ($info->{width} > ($self->{_root_width} * 0.7))
		 {
		     $args{fullscreen} = 1;
		 }
	    }
	    elsif (($info->{width} > ($self->{_root_width} * 0.5))
		 && ($info->{height} > ($self->{_root_height} * 0.5))
		 && !(($info->{width} == $self->{_root_width}
		       && $info->{height} <= $self->{_root_height})
		      || ($info->{height} == $self->{_root_height}
			  && $info->{width} <= $self->{_root_width})
		 )
	       )
	    {
		$args{fullscreen} = 1;
	    }
	}
	my $overlarge = ($info->{width} > $self->{_root_width}
			 || $info->{height} > $self->{_root_height});

	# do we want it tiled or centred?
	if (!defined $args{center}) # not set
	{
	    # default is off
	    $args{center} = 0;
	    if (!$args{fullscreen})
	    {
		# if the width and height of the image are both
		# close to the full screen size, don't tile the image
		if (($info->{width} > ($self->{_root_width} * 0.9))
		    && ($info->{height} > ($self->{_root_height} * 0.9))
		   )
		{
		    $args{center} = 1;
		}
	    }
	}
    }

    return ($fullname, \%args);
} # get_display_options

=head2 save_last_displayed

Save the name of the image most recently displayed.
Also update the "unseen" file if 'unseen' is true.

=cut
sub save_last_displayed ($;%) {
    my $self = shift;
    my $filename = shift;
    my %args = (@_);

    if (!-d $self->{config_dir})
    {
	mkdir $self->{config_dir};
    }
    my $cdir = $self->{config_dir};
    open(LOUT, ">$cdir/last") || die "Cannot write to $cdir/last";
    print LOUT $filename, "\n";
    close LOUT;
    if ($args{unseen})
    {
	# get the current files without the match/exclude stuff
	my @files = $self->get_image_files(unseen=>1);

	my $unseen_file = $self->{config_dir} . "/unseen";
	open(UNSEEN, ">", $unseen_file)
	    || die "Cannot write to $unseen_file";
	foreach my $file (@files)
	{
	    if ($file ne $filename)
	    {
		print UNSEEN $file, "\n";
	    }
	}
	close(UNSEEN);
    }
} # save_last_displayed

=head1 REQUIRES

    Image::Info
    File::Basename
    File::Find::Rule
    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.org/tools/muralis

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005-2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of X11::Muralis
__END__
