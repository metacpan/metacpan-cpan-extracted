package HTML::KhatGallery::Core;
our $VERSION = '0.2402'; # VERSION
use strict;
use warnings;

=head1 NAME

HTML::KhatGallery::Core - the core methods for HTML::KhatGallery

=head1 VERSION

version 0.2402

=head1 SYNOPSIS

    # implicitly
    use HTML::KhatGallery qw(HTML::KhatGallery::Core HTML::KhatGallery::Plugin::MyPlugin ...);

    # or explicitly
    require HTML::KhatGallery;

    @plugins = qw(HTML::KhatGallery::Core HTML::KhatGallery::Plugin::MyPlugin ...);
    HTML::KhatGallery->import(@plugins);
    HTML::KhatGallery->run(%args);


=head1 DESCRIPTION

HTML::KhatGallery is a photo-gallery generator.

HTML::KhatGallery::Core provides the core functionality of the system.
Other functions can be added or overridden by plugin modules.

=cut

use POSIX qw(ceil);
use File::Basename;
use File::Spec;
use Cwd qw(realpath);
use File::stat;
use YAML qw(Dump LoadFile);
use Image::ExifTool;

=head1 CLASS METHODS

=head2 run

HTML::KhatGallery->run(%args);

C<run> is the only method you should need to use from outside
this module; other methods are called internally by this one.

This method orchestrates all the work; it creates a new object,
and applies all the actions.

Arguments:

=over

=item B<captions_file>

The name of the captions file; which is in the same directory
as the images which it describes.   This file is in L<YAML> format.
For example:

    ---
    index.html: this is the caption for the album as a whole
    image1.png: this is the caption for image1.png
    image2.jpg: I like the second image

(default: captions.yml)

=item B<clean>

Instead of generating files, clean up the thumbnail directories to
remove thumbnails and image HTML pages for images which are no
longer there.

=item B<debug_level>

Set the level of debugging output.  The higher the level, the more verbose.
(developer only)
(default: 0)

=item B<dir_match>

Regular expression to match the directories we are interested in.
Hidden directories and the thumbnail directory will never be included.

=item B<force_html>

Force the re-generation of all the HTML files even if they already
exist.  If false (the default) then a given HTML file will only be
created if there is a change in that particular directory.

=item B<force_images>

Force the re-generation of the thumbnail images even if they already
exist.  If false (the default) then a given (thumbnail) image file will
only be created if it doesn't already exist.

=item B<image_match>

Regular expression determining what filenames should be interpreted
as images.

=item B<meta>

Array reference containing formats for meta-data from the images.
Field names are surrounded by % characters.  For example:

    meta => ['Date: %DateTime%', '%Comment%'],

If an image doesn't have that particular field, the data for that field is not
shown.  All the meta-data is placed after any caption the image has.

=item B<page_template>

Template for HTML pages.  The default template is this:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title><!--kg_title--></title>
    <!--kg_style-->
    </head>
    <body>
    <!--kg_content-->
    </body>
    </html>

This can be a string or a filename.

=item B<per_page>

The number of images to display per index page.

=item B<thumbdir>

The name of the directory where thumbnails and image-pages are put.
It is a subdirectory below the directory where its images are.
(default: tn)

=item B<thumb_geom>

The size of the thumbnails.  This doesn't actually define the dimensions
of the thumbnails, but their area.  This gives better-quality thumbnails.
(default:100x100)

=item B<top_dir>

The directory to look for images in; this will be searched for images and
sub-directories.  If this is not given, the current directory is used.

=item B<top_out_dir>

The directory to create galleries in; HTML and thumbnails will be created
there.  If this is not given, it is the same as B<top_dir>.

=item B<top_url>

The URL of the top images directory; if the top_out_dir isn't the
same as the top_dir, then we need to know this in order
to link to the images in the images directory.

=item B<verbose>

Print informational messages.

=back

=cut
sub run {
    my $class = shift;
    my %args = (
	parent=>'',
	@_
    );

    my $self = $class->new(%args);
    $self->init();
    print "Processing directory $self->{top_dir}\n"
	if $self->{verbose};

    $self->do_dir_actions('');
} # run

=head1 OBJECT METHODS

Only of interest to developers and those wishing to write plugins.

=head2 new

Make a new object.  See L</run> for the arguments.
This method should not be overridden by plugin writers; use L</init>
instead.

=cut

sub new {
    my $class = shift;
    my $self = bless ({@_}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Do some initialization of the object after it's created.
See L</run> for the arguments.
Set up defaults for things which haven't been defined.

Plugin writers should override this method rather than L</new>
if they want to do some initialization for their plugin.

=cut

sub init {
    my $self = shift;

    # some defaults
    $self->{per_page} ||= 16;
    $self->{thumbdir} ||= 'tn';
    $self->{captions_file} ||= 'captions.yml';
    $self->{thumb_geom} ||= '100x100';
    $self->{force_html} ||= 0;
    $self->{force_images} ||= 0;

    $self->{debug_level} ||= 0;
    # if there's no top dir, make it the current one
    if (!defined $self->{top_dir})
    {
	$self->{top_dir} = '.';
    }
    $self->{top_dir} = File::Spec->rel2abs($self->{top_dir});
    $self->{top_base} = basename($self->{top_dir});

    # top_out_dir
    if (!defined $self->{top_out_dir})
    {
	$self->{top_out_dir} = $self->{top_dir};
    }
    $self->{top_out_dir} = File::Spec->rel2abs($self->{top_out_dir});
    $self->{top_out_base} = basename($self->{top_out_dir});

    # trim top_url if it has a trailing slash
    if (defined $self->{top_url})
    {
	$self->{top_url} =~ s!/$!!;
    }
    else
    {
	$self->{top_url} = '';
    }

    # calculate width and height of thumbnail display
    $self->{thumb_geom} =~ /(\d+)x(\d+)/;
    $self->{thumb_width} = $1;
    $self->{thumb_height} = $2;
    $self->{pixelcount} = $self->{thumb_width} * $self->{thumb_height};

    if (!defined $self->{dir_actions})
    {
	$self->{dir_actions} = [qw(init_settings
	    read_captions
	    read_dir
	    read_out_dir
	    filter_images
	    sort_images
	    filter_dirs
	    sort_dirs
	    make_index_page
	    process_images
	    process_subdirs
	    tidy_up
	)];
    }
    if (!defined $self->{clean_actions})
    {
	$self->{clean_actions} = [qw(init_settings
	    read_dir
	    filter_images
	    filter_dirs
	    clean_thumb_dir
	    process_subdirs
	    tidy_up
	)];
    }

    if (!defined $self->{image_actions})
    {
	$self->{image_actions} = [qw(init_image_settings
	    make_thumbnail
	    make_image_page
	    image_tidy_up
	)];
    }

    if (!defined $self->{image_match})
    {
	my @img_ext = map {"\.$_\$"}
	    qw(jpg jpeg png gif tif tiff pcx xwd xpm xbm);
	my $img_re = join('|', @img_ext);
	$self->{image_match} = qr/$img_re/i;
    }

    if (!defined $self->{page_template})
    {
	$self->{page_template} = <<EOT;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><!--kg_title--></title>
<!--kg_style-->
</head>
<body>
<!--kg_content-->
</body>
</html>
EOT
    }

    return ($self);
} # init

=head2 do_dir_actions

$self->do_dir_actions($dir);

Do all the actions in the $self->{dir_actions} list, for the
given directory.  If cleaning, do the actions in the 'clean_actions'
list instead.
If the dir is empty, this is taken to be the directory given in
$self->{top_dir}, the top-level directory.

=cut
sub do_dir_actions {
    my $self = shift;
    my $dir = shift;

    my %state = ();
    $state{stop} = 0;
    $state{dir} = $dir;

    no strict qw(subs refs);
    my @actions = ($self->{clean} 
	? @{$self->{clean_actions}}
	: @{$self->{dir_actions}});
    while (@actions)
    {
	my $action = shift @actions;
	last if $state{stop};
	$state{action} = $action;
	$self->debug(1, "action: $action");
	$self->$action(\%state);
    }
    use strict qw(subs refs);
    1;
} # do_dir_actions

=head2 do_image_actions

$self->do_image_actions(\%dir_state, @images);

Do all the actions in the $self->{image_actions} list, for the
given images.

=cut
sub do_image_actions {
    my $self = shift;
    my $dir_state = shift;
    my @images = @_;

    my %images_state = ();

    no strict qw(subs refs);
    for (my $i = 0; $i < @images; $i++)
    {
	%images_state = ();
	$images_state{stop} = 0;
	$images_state{images} = \@images;
	$images_state{num} = $i;
	$images_state{cur_img} = $images[$i];
	# pop off each action as we go;
	# that way it's possible for an action to
	# manipulate the actions array
	@{$images_state{image_actions}} = @{$self->{image_actions}};
	while (@{$images_state{image_actions}})
	{
	    my $action = shift @{$images_state{image_actions}};
	    last if $images_state{stop};
	    $images_state{action} = $action;
	    $self->debug(1, "image_action: $action");
	    $self->$action($dir_state,
		\%images_state);
	}
    }
    use strict qw(subs refs);
    1;
} # do_image_actions

=head1 Dir Action Methods

Methods implementing directory-related actions.  All such actions
expect a reference to a state hash, and generally will update either
that hash or the object itself, or both, in the course of their
running.

=head2 init_settings

Initialize various settings that need to be set before everything
else.

This is not the same as "init", because this is the start of
the dir_actions sequence; we do it for each directory (or sub-directory)
we traverse.

=cut
sub init_settings {
    my $self = shift;
    my $dir_state = shift;

    $dir_state->{abs_dir} = File::Spec->catdir(
        realpath($self->{top_dir}), $dir_state->{dir});
    $dir_state->{abs_out_dir} = File::Spec->catdir(
        realpath($self->{top_out_dir}), $dir_state->{dir});
    my @path = File::Spec->splitdir($dir_state->{abs_dir});
    if ($dir_state->{dir})
    {
	$dir_state->{dirbase} = pop @path;
	$dir_state->{parent} = pop @path;
	$dir_state->{dir_url} = $self->{top_url} . '/' . $dir_state->{dir};
    }
    else # first dir
    {
	$dir_state->{dirbase} = pop @path;
	$dir_state->{parent} = '';
	$dir_state->{dir_url} = $self->{top_url};
    }
    # thumbnail dir for this directory
    $dir_state->{abs_thumbdir} = File::Spec->catdir($dir_state->{abs_out_dir},
	$self->{thumbdir});

    # reset the per-directory redo_html flag
    $dir_state->{redo_html} = 0;

} # init_settings

=head2 read_captions

Set the $dir_state->{captions} hash to contain all the
captions for this directory (if they exist)

=cut
sub read_captions {
    my $self = shift;
    my $dir_state = shift;

    my $captions_file = File::Spec->catfile($dir_state->{abs_dir},
	$self->{captions_file});
    if (!-f $captions_file)
    {
	$captions_file = File::Spec->catfile($dir_state->{abs_out_dir},
					     $self->{captions_file});
    }
    if (-f $captions_file)
    {
	$dir_state->{captions} = {};
	$dir_state->{captions} = LoadFile($captions_file);
    }
} # read_captions

=head2 read_dir

Read the $dir_state->{dir} directory.  Sets $dir_state->{subdirs}, and
$dir_state->{files} with the relative subdirs, and other files.

=cut
sub read_dir {
    my $self = shift;
    my $dir_state = shift;

    my $dh;
    opendir($dh, $dir_state->{abs_dir}) or die "Can't opendir $dir_state->{abs_dir}: $!";
    my @subdirs = ();
    my @files = ();
    while (my $fn = readdir($dh))
    {
	my $abs_fn = File::Spec->catfile($dir_state->{abs_dir}, $fn);
	if ($fn =~ /^\./ or $fn eq $self->{thumbdir})
	{
	    # skip
	}
	elsif (-d $abs_fn)
	{
	    push @subdirs, $fn;
	}
	# ignore any html files
	elsif ($fn =~ /\.html$/)
	{
	}
	else
	{
	    push @files, $fn;
	}
    }
    closedir($dh);

    $dir_state->{subdirs} = \@subdirs;
    $dir_state->{files} = \@files;
} # read_dir

=head2 read_out_dir

Read the $dir_state->{dir} directory in the output tree.
Sets $dir_state->{index_files} with the index*.html files.

=cut
sub read_out_dir {
    my $self = shift;
    my $dir_state = shift;

    my @index_files = ();
    if (-d $dir_state->{abs_out_dir})
    {
	my $dh;
	opendir($dh, $dir_state->{abs_out_dir}) or die "Can't opendir $dir_state->{abs_out_dir}: $!";
	while (my $fn = readdir($dh))
	{
	    my $abs_fn = File::Spec->catfile($dir_state->{abs_out_dir}, $fn);
	    if ($fn =~ /^\./ or $fn eq $self->{thumbdir})
	    {
		# skip
	    }
	    # remember the index files
	    elsif ($fn =~ /index.*\.html$/)
	    {
		push @index_files, $fn;
	    }
	}
	closedir($dh);
    }

    $dir_state->{index_files} = \@index_files;
} # read_out_dir

=head2 filter_images

Sets $dir_state->{files} to contain only image files that
we are interested in.

=cut
sub filter_images {
    my $self = shift;
    my $dir_state = shift;

    if ($self->{image_match}
	and @{$dir_state->{files}})
    {
	my $img_match = $self->{image_match};
	my @images = grep {
	    /$img_match/
	} @{$dir_state->{files}};
	$dir_state->{files} = \@images;
    }
} # filter_images

=head2 sort_images

Sorts the $dir_state->{files} array.

=cut
sub sort_images {
    my $self = shift;
    my $dir_state = shift;

    if (@{$dir_state->{files}})
    {
	my @images = sort @{$dir_state->{files}};
	$dir_state->{files} = \@images;
    }
} # sort_images

=head2 filter_dirs

Sets $dir_state->{subdirs} to contain only directories that
we are interested in.

=cut
sub filter_dirs {
    my $self = shift;
    my $dir_state = shift;

    if ($self->{dir_match}
	and @{$dir_state->{subdirs}})
    {
	my $dir_match = $self->{dir_match};
	my @dirs = grep {
	    /$dir_match/
	} @{$dir_state->{subdirs}};
	$dir_state->{subdirs} = \@dirs;
    }
} # filter_dirs

=head2 sort_dirs

Sorts the $dir_state->{subdirs} array.

=cut
sub sort_dirs {
    my $self = shift;
    my $dir_state = shift;

    if (@{$dir_state->{subdirs}})
    {
	my @dirs = sort @{$dir_state->{subdirs}};
	$dir_state->{subdirs} = \@dirs;
    }
} # sort_dirs

=head2 make_index_page

Make the index page(s) for this directory.

=cut
sub make_index_page {
    my $self = shift;
    my $dir_state = shift;

    # determine the number of pages
    # To make things easier, always put the subdirs on each index page
    my $num_files = @{$dir_state->{files}};
    my $pages = ceil($num_files / $self->{per_page});
    # if there are only subdirs make sure you still make an index
    if ($pages == 0 and @{$dir_state->{subdirs}})
    {
	$pages = 1;
    }
    $dir_state->{pages} = $pages;

    # make the output dir if it doesn't exist
    if (!-d $dir_state->{abs_out_dir})
    {
	mkdir $dir_state->{abs_out_dir};
    }

    # if we have any new images in this directory, we need to re-make the index
    # files because we don't know which index file it will appear in,
    # and we need to re-make the other HTML files because
    # we need to re-generate the prev/next links
    $dir_state->{redo_html} = $self->index_needs_rebuilding($dir_state);

    # if forcing HTML, delete the old index pages
    # just in case we are going to have fewer pages
    # this time around
    if ($self->{force_html} or $dir_state->{redo_html})
    {
	foreach my $if (@{$dir_state->{index_files}})
	{
	    my $ff = File::Spec->catfile($dir_state->{abs_out_dir}, $if);
	    unlink $ff;
	}
    }

    if ($self->{verbose})
    {
	# if the first index is gone, we're rebuilding all of them
	my $first_index 
	    = $self->get_index_pagename(dir_state=>$dir_state,
					page=>1, get_filename=>1);
	if (!-f $first_index)
	{
	    print "making $pages indexes\n";
	}
    }

    # for each page
    for (my $page = 1; $page <= $pages; $page++)
    {
	# calculate the filename
	my $ifile = $self->get_index_pagename(dir_state=>$dir_state,
	    page=>$page, get_filename=>1);
	if (-f $ifile)
	{
	    next;
	}

	# figure which files are in this page
	# Determine number of images to skip
	my @images = ();
	if (@{$dir_state->{files}})
	{
	    my $skip = $self->{per_page} * ($page-1);
	    # index of last entry to include
	    my $last = $skip + $self->{per_page};
	    $last = $num_files if ($last > $num_files);
	    $last--; # need the index, not the count
		@images = @{$dir_state->{files}}[$skip .. $last];
	}

	my @content = ();
	push @content, $self->start_index_page($dir_state, $page);
	# add the subdirs
	push @content, $self->make_index_subdirs($dir_state, $page);
	# add the images
	push @content, $self->make_image_index(dir_state=>$dir_state,
	    page=>$page, images=>\@images);
	push @content, $self->end_index_page($dir_state, $page);
	my $content = join('', @content);

	# make the head stuff
	my $title = $self->make_index_title($dir_state, $page);
	my $style = $self->make_index_style($dir_state, $page);

	# put the page content in the template
	my $out = $self->get_template($self->{page_template});
	# save the content of the template in case we read it
	# from a file
	$self->{page_template} = $out; 
	$out =~ s/<!--kg_title-->/$title/;
	$out =~ s/<!--kg_style-->/$style/;
	$out =~ s/<!--kg_content-->/$content/;

	# write the page to the file
	my $fh = undef;
	open($fh, ">", $ifile) or die "Could not open $ifile for writing: $!";
	print $fh $out;
	close($fh);
    } # for each page
} # make_index_page

=head2 clean_thumb_dir

Clean unused thumbnails and image-pages from
the thumbnail directory of this directory

=cut
sub clean_thumb_dir {
    my $self = shift;
    my $dir_state = shift;

    my $dir = File::Spec->catdir($dir_state->{abs_out_dir}, $self->{thumbdir});
    my @pics = @{$dir_state->{files}};
    $self->debug(2, "dir: $dir");

    return unless -d $dir;

    # store the pics as a hash to make checking easier
    my %pics_hash = ();
    foreach my $pic ( @pics )
    {
	$pics_hash{$pic} = 1;
    }

    # Read the thumbnail directory
    my $dirh;
    opendir($dirh,$dir);
    my @files = grep(!/^\.{1,2}$/, readdir($dirh));
    closedir($dirh);

    # Check each file to make sure it's a currently used thumbnail or image_page
    foreach my $file ( @files )
    {
	my $remove = '';
	my $name = $file;
	if ($name =~ s/\.html$//)
	{
	    # change the last underscore to a dot
	    $name =~ s/_([a-zA-Z0-9]+)$/.$1/;
	    $remove = "unused image page"
		unless (exists $pics_hash{$name});
	}
	elsif ($name  =~ /(.+)\.jpg$/i) {
	    # Thumbnail?
	    $name = $1;
	    # change the last underscore to a dot
	    $name =~ s/_([a-zA-Z0-9]+)$/.$1/;
	    $self->debug(2, "thumb: $name");
	    $remove = "unused thumbnail"
		unless (exists $pics_hash{$name});
	} else {
	    $remove = "unknown file";
	}
	if ($remove) {
	    print "Remove $remove: $file\n" if $self->{verbose};
	    my $fullname = File::Spec->catfile($dir, $file);
	    warn "Couldn't erase [$file]"
		unless unlink $fullname;
	}
    } # for each file
} # clean_thumb_dir

=head2 process_images

Process the images from this directory.

=cut
sub process_images {
    my $self = shift;
    my $dir_state = shift;

    $self->do_image_actions($dir_state, @{$dir_state->{files}});
} # process_images

=head2 process_subdirs

Process the sub-directories of this directory.

=cut
sub process_subdirs {
    my $self = shift;
    my $dir_state = shift;

    my @image_dirs = @{$dir_state->{subdirs}};

    foreach my $subdir (@image_dirs)
    {
	my $dir = $subdir;
	if ($dir_state->{dir})
	{
	    $dir = File::Spec->catdir($dir_state->{dir}, $subdir);
	}
	print "=== $dir ===\n" if $self->{verbose};
	$self->do_dir_actions($dir);
    }
} # process_subdirs

=head2 tidy_up

Cleanup after processing this directory.

=cut
sub tidy_up {
    my $self = shift;
    my $dir_state = shift;

} # tidy_up

=head1 Image Action Methods

Methods implementing per-image actions.

=head2 init_image_settings

Initialize settings for the current image.

=cut
sub init_image_settings {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    $img_state->{abs_img} = File::Spec->catfile($dir_state->{abs_dir},
	$img_state->{cur_img});
    $img_state->{info} = $self->get_image_info($img_state->{abs_img});

} # init_image_settings

=head2 make_thumbnail

Make a thumbnail of the current image.
Constant pixel count among generated images based on
http://www.chaosreigns.com/code/thumbnail/

=cut
sub make_thumbnail {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my $thumb_file = $self->get_thumbnail_name(
	dir_state=>$dir_state, image=>$img_state->{cur_img},
	type=>'file');
    if (!$self->need_to_generate_image($dir_state, $img_state,
        check_image=>$thumb_file))
    {
	return;
    }
    # make the thumbnail dir if it doesn't exist
    if (!-d $dir_state->{abs_thumbdir})
    {
	mkdir $dir_state->{abs_thumbdir};
    }

    my $x = $img_state->{info}->{ImageWidth};
    my $y = $img_state->{info}->{ImageHeight};
    if (!$x or !$y)
    {
	warn "dimensions of " . $img_state->{abs_img} . " undefined -- faking it";
	print STDERR Dump($img_state);
	print STDERR "========================\n";
	$x = 1024;
	$y = 1024;
    }
    
    my $pixels = $x * $y;
    my $newx = int($x / (sqrt($x * $y) / sqrt($self->{pixelcount})));
    my $newy = int($y / (sqrt($x * $y) / sqrt($self->{pixelcount})));
    my $newpix = $newx * $newy;
    my $command = '';
    if ($img_state->{cur_img} =~ /\.gif$/)
    {
	# in case this is an animated gif, get the first frame only
	$command = "convert -geometry \"${newx}x${newy}\>\" \"$img_state->{abs_img}\[0\]\" \"$thumb_file\"";
    }
    else
    {
	$command = "convert -geometry \"${newx}x${newy}\>\" \"$img_state->{abs_img}\" \"$thumb_file\"";
    }
    system($command) == 0
	or die "$command failed";
    
} # make_thumbnail

=head2 make_image_page

Make HTML page for current image.

=cut
sub make_image_page {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my $img_name = $img_state->{cur_img};
    my $img_page_file = $self->get_image_pagename(dir_state=>$dir_state,
						  image=>$img_state->{cur_img},
						  type=>'file');
    if (-f $img_page_file
	and !$self->{force_html}
	and !$dir_state->{redo_html})
    {
	return;
    }
    # make the thumbnail dir if it doesn't exist
    if (!-d $dir_state->{abs_thumbdir})
    {
	mkdir $dir_state->{abs_thumbdir};
    }
    my @content = ();
    push @content, $self->start_image_page($dir_state, $img_state);
    # add the image itself
    push @content, $self->make_image_content($dir_state, $img_state);
    push @content, $self->end_image_page($dir_state, $img_state);
    my $content = join('', @content);

    # make the head stuff
    my $title = $self->make_image_title($dir_state, $img_state);
    my $style = $self->make_image_style($dir_state, $img_state);

    # put the page content in the template
    my $out = $self->get_template($self->{page_template});
    # save the content of the template in case we read it
    # from a file
    $self->{page_template} = $out; 
    $out =~ s/<!--kg_title-->/$title/;
    $out =~ s/<!--kg_style-->/$style/;
    $out =~ s/<!--kg_content-->/$content/;

    # write the page to the file
    my $fh = undef;
    open($fh, ">", $img_page_file) or die "Could not open $img_page_file for writing: $!";
    print $fh $out;
    close($fh);
} # make_image_page

=head2 image_tidy_up

Clean up after the current image.

=cut
sub image_tidy_up {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

} # image_tidy_up

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 start_index_page

    push @content, $self->start_index_page($dir_state, $page);

Create the start-of-page for an index page.
This contains page content, not full <html> etc (that's expected
to be in the full-page template).
It contains the header, link to parent dirs and links to
previous and next index-pages, and the album caption.

=cut
sub start_index_page {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();
    push @out, "<div class=\"kgindex\">\n";

    # Path array contains basenames from the top dir down to the current dir.
    my @path = split(/[\/\\]/, $dir_state->{dir});

    # Note that what we want is the top_out_base and not the top_base
    # because if they are not the same (because top_out_dir was set)
    # the salient info is the output directory and not the source directory.
    unshift @path, $self->{top_out_base};

    # we want to create relative links to all the dirs
    # above the current one, so work backwards
    my %uplinks = ();
    my $uplink = '';
    foreach my $dn (reverse @path)
    {
	$uplinks{$dn} = $uplink;
	if (!$uplink and $page > 1)
	{
	    $uplinks{$dn} = "index.html";
	}
	else
	{
	    $uplink .= '../';
	}
    }
    my @header = ();
    foreach my $dn (@path)
    {
	my $pretty = $dn;
	$pretty =~ s/_/ /g;
	if ($uplinks{$dn})
	{
	    push @header, "<a href=\"$uplinks{$dn}\">$pretty</a>";
	}
	else
	{
	    push @header, $pretty;
	}
    }
    push @out, '<h1>';
    push @out, join(' :: ', @header);
    push @out, "</h1>\n";

    # now for the prev, next links
    push @out, $self->make_index_prev_next($dir_state, $page);

    # and now for the album caption
    if (exists $dir_state->{captions})
    {
	my $index_caption = 'index.html';
	if (exists $dir_state->{captions}->{$index_caption}
	    and defined $dir_state->{captions}->{$index_caption})
	{
	    push @out, '<div class="albumdesc">';
	    push @out, $dir_state->{captions}->{$index_caption};
	    push @out, "</div>\n";
	}
    }

    return join('', @out);
} # start_index_page

=head2 make_index_prev_next

    my $links = $self->start_index_page($dir_state, $page);

Make the previous next other-index-pages links for the
given index-page.  Generally called for the top and bottom
of the index page.

=cut
sub make_index_prev_next {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();
    if ($dir_state->{pages} > 1)
    {
	push @out, '<p class="prevnext">';
	# prev
	my $label = '&lt; - prev';
	if ($page > 1)
	{
	    my $iurl = $self->get_index_pagename(dir_state=>$dir_state,
						 page=>$page - 1, get_filename=>0);
	    push @out, "<span class=\"pagelink prev\"><a href=\"${iurl}\">$label</a></span> ";
	}

	# pages, but only if more than two
	if ($dir_state->{pages} > 2)
	{
	    for (my $i = 1; $i <= $dir_state->{pages}; $i++)
	    {
		if ($page == $i)
		{
		    push @out, " <span class=\"pagelink curr\">[$i]</span> ";
		}
		else
		{
		    my $iurl = $self->get_index_pagename(dir_state=>$dir_state,
							 page=>$i, get_filename=>0);
		    push @out, " <span class=\"pagelink pagenum\"><a href=\"${iurl}\">$i</a></span> ";
		}
	    }
	}
	$label = 'next -&gt;';
	if (($page+1) <= $dir_state->{pages})
	{
	    my $iurl = $self->get_index_pagename(dir_state=>$dir_state,
						 page=>$page + 1, get_filename=>0);
	    push @out, " <span class=\"pagelink next\"><a href=\"${iurl}\">$label</a></span>";
	}
	push @out, "</p>\n";
    }

    return join('', @out);
} # make_index_prev_next

=head2 end_index_page

    push @content, $self->end_index_page($dir_state, $page);

Create the end-of-page for an index page.
This contains page content, not full <html> etc (that's expected
to be in the full-page template).

=cut
sub end_index_page {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();
    push @out, "\n<hr style=\"clear:both;\"/>\n";
    push @out, $self->make_index_prev_next($dir_state, $page);
    push @out, "</div>\n";
    return join('', @out);
} # end_index_page

=head2 make_index_subdirs

    push @content, $self->make_index_subdirs($dir_state, $page);

Create the subdirs section; this contains links to subdirs.

=cut
sub make_index_subdirs {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();

    if (@{$dir_state->{subdirs}})
    {
	push @out, "\n<hr/>\n";
	push @out, "<div class=\"subdir\">\n";
	# subdirs
	foreach my $subdir (@{$dir_state->{subdirs}})
	{
	    push @out, <<EOT;
<div class="item">
<a href="$subdir/">$subdir</a>
</div>
EOT
	}
	push @out, "</div>\n";
    }
    return join('', @out);
} # make_index_subdirs

=head2 make_image_index

    push @content, $self->make_image_index(dir_state=>$dir_state,
	page=>$page, images=>\@images);

Create the images section; this contains links to image-pages, with thumbnails.

=cut
sub make_image_index {
    my $self = shift;
    my %args = (
	@_
    );
    my $dir_state = $args{dir_state};

    my @out = ();

    if (@{$args{images}})
    {
	push @out, "\n<hr style=\"clear:both;\"/>\n";
	push @out, "<div class=\"images\">\n";
	# subdirs
	foreach my $image (@{$args{images}})
	{
	    my $image_link = $self->get_image_pagename(dir_state=>$dir_state,
		image=>$image, type=>'parent');
	    my $thumbnail_link = $self->get_thumbnail_name(
		dir_state=>$dir_state,
		image=>$image, type=>'parent');
	    my $image_name = $self->get_image_pagename(dir_state=>$dir_state,
		image=>$image, type=>'pretty');
	    push @out, <<EOT;
<div class="item">
<div class="thumb">
<a href="$image_link"><img src="$thumbnail_link" alt="$image"/></a><br/>
<a href="$image_link">$image_name</a>
</div>
</div>
EOT
	}
	push @out, "</div>\n";
    }
    return join('', @out);
} # make_image_index

=head2 make_index_title

Make the title for the index page.
This is expected to go inside a <title><!--kg_title--></title>
in the page template.

=cut
sub make_index_title {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();
    # title
    push @out, $dir_state->{dirbase};
    push @out, " ($page)" if $page > 1;
    return join('', @out);
} # make_index_title

=head2 make_index_style

Make the style tags for the index page.  This will be put in the
<!--kg_style--> part of the template.

=cut
sub make_index_style {
    my $self = shift;
    my $dir_state = shift;
    my $page = shift;

    my @out = ();
    # style
    my $thumb_area_width = $self->{thumb_width} * 1.5;
    # 1.5 times the thumbnail, plus a fudge-factor for the words underneath
    my $thumb_area_height = ($self->{thumb_height} * 1.5) + 20;
    push @out, <<EOT;
<style type="text/css">
.subdir, .images, .prevnext {
    display: flex;
    flex-wrap: wrap;
}
.item {
    vertical-align: middle;
    text-align: center;
    margin: 10px;
}
.thumb {
    overflow: auto;
    font-size: small;
}
.albumdesc {
    width: 80%;
    border: solid 2px;
    margin-left: auto;
    margin-right: auto;
    background: #eeeeee;
    color: black;
}
.albumdesc p {
    margin: 0.75em;
}
</style>
EOT
    return join('', @out);
} # make_index_style

=head2 get_index_pagename

    my $name = self->get_index_pagename(
	dir_state=>$dir_state,
	page=>$page,
	get_filename=>0);

Get the name of the given index page; either the file name
or the relative URL.

=cut
sub get_index_pagename {
    my $self = shift;
    my %args = (
	get_filename=>0,
	@_
    );
    my $dir_state = $args{dir_state};
    my $page = $args{page};

    my $pagename;
    if ($page == 1)
    {
	$pagename = 'index.html';
    }
    elsif ($dir_state->{pages} > 9)
    {
	$pagename = sprintf("index%02d.html", $page);
    }
    else
    {
	$pagename = "index${page}.html";
    }
    
    if ($args{get_filename})
    {
	return File::Spec->catfile($dir_state->{abs_out_dir}, $pagename);
    }
    else # get URL
    {
	return $pagename;
    }
} # get_index_pagename

=head2 get_image_pagename

    my $name = self->get_image_pagename(
	dir_state=>$dir_state,
	image=>$image,
	type=>'file');

Get the name of the image page; either the file name
or the relative URL from above, or the relative URL
from the sibling, or a 'pretty' name suitable for a title.

The 'type' can be 'file', 'parent', 'sibling' or 'pretty'.

=cut
sub get_image_pagename {
    my $self = shift;
    my %args = (
	type=>'parent',
	@_
    );
    my $dir_state = $args{dir_state};
    my $image = $args{image};
    
    my $thumbdir = $self->{thumbdir};
    my $img_page = $image;
    # change the last dot to underscore
    $img_page =~ s/\.(\w+)$/_$1/;
    $img_page .= ".html";
    if ($args{type} eq 'file')
    {
	return File::Spec->catfile($dir_state->{abs_out_dir}, $thumbdir, $img_page);
    }
    elsif ($args{type} eq 'parent')
    {
	return "${thumbdir}/${img_page}";
    }
    elsif ($args{type} eq 'sibling')
    {
	return ${img_page};
    }
    elsif ($args{type} eq 'pretty')
    {
	my $pretty = ${image};
	$pretty =~ s/\.(\w+)$//;
	$pretty =~ s/_/ /g;
	return $pretty;
    }
    return '';
} # get_image_pagename

=head2 get_thumbnail_name

    my $name = self->get_thumbnail_name(
	dir_state=>$dir_state,
	image=>$image,
	type=>'file');

Get the name of the image thumbnail file; either the file name
or the relative URL from above, or the relative URL
from the sibling.

The 'type' can be 'file', 'parent', 'sibling'.

=cut
sub get_thumbnail_name {
    my $self = shift;
    my %args = (
	type=>'parent',
	@_
    );
    my $dir_state = $args{dir_state};
    my $image = $args{image};
    
    my $thumbdir = $self->{thumbdir};
    my $thumb = $image;
    # change the last dot to underscore
    $thumb =~ s/\.([\w]+)$/_$1/;
    $thumb .= ".jpg"; 
    if ($args{type} eq 'file')
    {
	return File::Spec->catfile($dir_state->{abs_out_dir}, $thumbdir, $thumb);
    }
    elsif ($args{type} eq 'parent')
    {
	return "${thumbdir}/${thumb}";
    }
    elsif ($args{type} eq 'sibling')
    {
	return ${thumb};
    }
    return '';
} # get_thumbnail_name

=head2 get_caption

    my $name = self->get_caption(
	dir_state=>$dir_state,
	img_state->$img_state,
	image=>$image)

Get the caption for this image.
This also gets the meta-data if any is required.

=cut
sub get_caption {
    my $self = shift;
    my %args = (
	@_
    );
    my $dir_state = $args{dir_state};
    my $img_state = $args{img_state};
    my $image = $args{image};
    
    my @out = ();
    if (exists $dir_state->{captions})
    {
	if (exists $dir_state->{captions}->{$image}
	    and defined $dir_state->{captions}->{$image})
	{
	    push @out, $dir_state->{captions}->{$image};
	}
    }
    if ($img_state and defined $self->{meta} and @{$self->{meta}})
    {
	# only add the meta data if it's there
	foreach my $fieldspec (@{$self->{meta}})
	{
	    $fieldspec =~ /%([\w\s]+)%/;
	    my $field = $1;
	    if (exists $img_state->{info}->{$field}
		and defined $img_state->{info}->{$field}
		and $img_state->{info}->{$field})
	    {
		my $val = $fieldspec;
		my $fieldval = $img_state->{info}->{$field};
		# make the fieldval HTML-safe
		$fieldval =~ s/&/&amp;/g;
		$fieldval =~ s/</&lt;/g;
		$fieldval =~ s/>/&gt;/g;
		$val =~ s/%${field}%/$fieldval/g;
		push @out, $val;
	    }
	}
    }
    return join("\n", @out);
} # get_caption

=head2 get_template

my $templ = $self->get_template($template);

Get the given template (read if it's from a file)

=cut
sub get_template {
    my $self = shift;
    my $template = shift;

    if ($template !~ /\n/
	&& -r $template)
    {
	local $/ = undef;
	my $fh;
	open($fh, $template)
	    or die "Could not open ", $template;
	$template = <$fh>;
	close($fh);
    }
    return $template;
} # get_template

=head2 start_image_page

    push @content, $self->start_image_page($dir_state, $img_state);

Create the start-of-page for an image page.
This contains page content, not full <html> etc (that's expected
to be in the full-page template).
It contains the header, link to parent dirs and links to
previous and next image-pages.

=cut
sub start_image_page {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my @out = ();
    push @out, "<div class=\"kgimage\">\n";

    # Path array contains basenames from the top dir
    # down to the current dir.
    my @path = split(/[\/\\]/, $dir_state->{dir});
    unshift @path, $self->{top_out_base};
    # we want to create relative links to all the dirs
    # including the current one, so work backwards
    my %uplinks = ();
    my $uplink = '';
    foreach my $dn (reverse @path)
    {
	$uplink .= '../';
	$uplinks{$dn} = $uplink;
    }
    my @breadcrumb = ();
    foreach my $dn (@path)
    {
	if ($uplinks{$dn})
	{
	    push @breadcrumb, "<a href=\"$uplinks{$dn}\">$dn</a>";
	}
	else
	{
	    push @breadcrumb, $dn;
	}
    }
    push @out, '<h1>';
    push @out, $img_state->{cur_img};
    push @out, "</h1>\n";
    push @out, '<p class="breadcrumb">';
    push @out, join(' > ', @breadcrumb);
    push @out, "</p>\n";

    # now for the prev, next links
    push @out, $self->make_image_prev_next(dir_state=>$dir_state,
	img_state=>$img_state);

    return join('', @out);
} # start_image_page

=head2 end_image_page

    push @content, $self->end_image_page($dir_state, $img_state);

Create the end-of-page for an image page.
This contains page content, not full <html> etc (that's expected
to be in the full-page template).

=cut
sub end_image_page {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my @out = ();

    # now for the prev, next links
    push @out, $self->make_image_prev_next(dir_state=>$dir_state,
	img_state=>$img_state,
	use_thumb=>1);
    push @out, "\n</div>\n";

    return join('', @out);
} # end_image_page

=head2 make_image_prev_next

    my $links = $self->make_image_prev_next(
	dir_state=>$dir_state,
	img_state=>$img_state);

Make the previous next other-image-pages links for the
given image-page.  Generally called for the top and bottom
of the image page.

=cut
sub make_image_prev_next {
    my $self = shift;
    my %args = (
	use_thumb=>0,
	@_
    );
    my $dir_state = $args{dir_state};
    my $img_state = $args{img_state};

    my $img_num = $img_state->{num};
    my @out = ();
    if ($dir_state->{files} > 1)
    {
	push @out, '<div class="prevnext">';
	# prev
	push @out, "<span class=\"prev\">";
	my $label = '&lt; - prev';
	my $iurl;
	my $turl;
	if ($img_num > 0)
	{
	    $iurl = $self->get_image_pagename(dir_state=>$dir_state,
					      image=>$img_state->{images}->[$img_num - 1],
					      type=>'sibling');
	    $turl = $self->get_thumbnail_name(dir_state=>$dir_state,
					      image=>$img_state->{images}->[$img_num - 1],
					      type=>'sibling');
	}
	else
	{
	    # loop to the last image
	    $iurl = $self->get_image_pagename(dir_state=>$dir_state,
		image=>$img_state->{images}->[$#{$img_state->{images}}],
					      type=>'sibling');
	    $turl = $self->get_thumbnail_name(dir_state=>$dir_state,
		image=>$img_state->{images}->[$#{$img_state->{images}}],
					      type=>'sibling');
	}
	push @out, "<span class=\"pagelink\"><a href=\"${iurl}\">$label</a></span> ";
	if ($args{use_thumb})
	{
	    push @out, "<span class=\"thumb\"><a href=\"${iurl}\"><img src=\"$turl\" alt=\"$label\"/></a></span> ";
	}
	push @out, "</span>";

	push @out, "<span class=\"next\">";
	$label = 'next -&gt;';
	if (($img_num+1) < @{$img_state->{images}})
	{
	    $iurl = $self->get_image_pagename(dir_state=>$dir_state,
					      image=>$img_state->{images}->[$img_num + 1],
					      type=>'sibling');
	    $turl = $self->get_thumbnail_name(dir_state=>$dir_state,
					      image=>$img_state->{images}->[$img_num + 1],
					      type=>'sibling');
	}
	else
	{
	    # loop to the first image
	    $iurl = $self->get_image_pagename(dir_state=>$dir_state,
					      image=>$img_state->{images}->[0],
					      type=>'sibling');
	    $turl = $self->get_thumbnail_name(dir_state=>$dir_state,
					      image=>$img_state->{images}->[0],
					      type=>'sibling');
	}
	if ($args{use_thumb})
	{
	    push @out, "<span class=\"thumb\"><a href=\"${iurl}\"><img src=\"$turl\" alt=\"$label\"/></a></span> ";
	}
	push @out, " <span class=\"pagelink\"><a href=\"${iurl}\">$label</a></span>";
	push @out, "</span>";
	push @out, "</div>\n";
    }

    return join('', @out);
} # make_image_prev_next

=head2 make_image_content

Make the content of the image page, the image itself.

=cut
sub make_image_content {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my $img_name = $img_state->{cur_img};
    my $caption = $self->get_caption(dir_state=>$dir_state,
				     img_state=>$img_state,
				     image=>$img_name);
    my $img_url = "../$img_name";
    if ($self->{top_dir} ne $self->{top_out_dir})
    {
	$img_url = $dir_state->{dir_url} . '/' . $img_name;
    }
    my @out = ();
    push @out, "<div class=\"image\">\n";
    my $width = $img_state->{info}->{ImageWidth};
    my $height = $img_state->{info}->{ImageHeight};
    push @out, "<img src=\"$img_url\" alt=\"$img_name\" style=\"width: ${width}px; height: ${height}px;\"/>\n";
    push @out, "<p class=\"caption\">$caption</p>\n";
    push @out, "</div>\n";
    return join('', @out);
} # make_image_content

=head2 make_image_title

Make the title for the image page.
This is expected to go inside a <title><!--kg_title--></title>
in the page template.

=cut
sub make_image_title {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my @out = ();
    # title
    push @out, $img_state->{cur_img};
    return join('', @out);
} # make_image_title

=head2 make_image_style

Make the style tags for the image page.  This will be put in the
<!--kg_style--> part of the template.

=cut
sub make_image_style {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;

    my @out = ();
    # style
    push @out, <<EOT;
<style type="text/css">
.image {
    text-align: center;
    margin-left: auto;
    margin-right: auto;
}
.prevnext {
    display: flex;
    width: 100%;
    justify-content: space-between;
}
.caption {
    white-space: pre-line;
}
</style>
EOT
    return join('', @out);
} # make_image_style

=head2 need_to_generate_image

Check if a thumbnail needs to be made (or rebuilt).

=cut
sub need_to_generate_image {
    my $self = shift;
    my $dir_state = shift;
    my $img_state = shift;
    my %args = @_;

    if (!-f $args{check_image} or $self->{force_images})
    {
	return 1;
    }
    return 0;
} # need_to_generate_image

=head2 index_needs_rebuilding

Check to see if there are any new (or deleted) images or directories
in this directory.

=cut
sub index_needs_rebuilding {
    my $self = shift;
    my $dir_state = shift;

    # ------- Subdirs -------------
    # Need to check if any of the subdirs are new or deleted
 
    my @subdirs = @{$dir_state->{subdirs}};
    my @dest_subdirs = ();
    my $dirh;
    opendir($dirh,$dir_state->{abs_out_dir});
    while (my $fn = readdir($dirh))
    {
	my $abs_fn = File::Spec->catfile($dir_state->{abs_out_dir}, $fn);
	if ($fn =~ /^\./ or $fn eq $self->{thumbdir})
	{
	    # skip
	}
	elsif (-d $abs_fn)
	{
	    push @dest_subdirs, $fn;
	}
    }
    closedir($dirh);

    my %destdir_has_src = ();
    my %srcdir_has_dest = ();
    # initialise to false
    foreach my $sd ( @subdirs )
    {
	$srcdir_has_dest{$sd} = 0;
    }
    # Are there dest-dirs without src-dirs?
    foreach my $dsd ( @dest_subdirs )
    {
        if (exists $srcdir_has_dest{$dsd})
        {
            $srcdir_has_dest{$dsd} = 1;
            $destdir_has_src{$dsd} = 1;
        }
        else
        {
	    $destdir_has_src{$dsd} = 0;
            return 1;
        }
    }
    # Are there src-dirs without dest-dirs? 
    while (my ($key, $dir_exists) = each(%srcdir_has_dest))
    {
	if (!$dir_exists)
	{
	    return 1;
	}
    }

    # --------- Thumbnail Directory ----------
    my $thumb_dir = File::Spec->catdir($dir_state->{abs_out_dir}, $self->{thumbdir});
    my @pics = @{$dir_state->{files}};
    $self->debug(2, "dir: $thumb_dir");

    # if the thumbnail directory doesn't exist, then either all images
    # are new, or we don't have any images in this directory
    if (!-d $thumb_dir)
    {
	return (@pics ? 1 : 0);
    }

    # Read the thumbnail directory
    opendir($dirh,$thumb_dir);
    my @files = grep(!/^\.{1,2}$/, readdir($dirh));
    closedir($dirh);

    # check whether a picture has a thumbnail, and a thumbnail has a picture
    my %pic_has_tn = ();
    my %tn_has_pic = ();

    # initialize to false
    foreach my $pic ( @pics )
    {
	$pic_has_tn{$pic} = 0;
    }

    # Check each file to make sure it's a currently used thumbnail or image_page
    foreach my $file ( @files )
    {
	my $name = $file;
	if ($name =~ s/\.html$//)
	{
	    # change the last underscore to a dot
	    $name =~ s/_([a-zA-Z0-9]+)$/.$1/;
	    if (exists $pic_has_tn{$name})
	    {
		$pic_has_tn{$name} = 1;
		$tn_has_pic{$name} = 1;
	    }
	    else
	    {
		$tn_has_pic{$name} = 0;
		return 1;
	    }
	}
	elsif ($name  =~ /(.+)\.jpg$/i) {
	    # Thumbnail?
	    $name = $1;
	    # change the last underscore to a dot
	    $name =~ s/_([a-zA-Z0-9]+)$/.$1/;
	    $self->debug(2, "thumb: $name");
	    if (exists $pic_has_tn{$name})
	    {
		$pic_has_tn{$name} = 1;
		$tn_has_pic{$name} = 1;
	    }
	    else
	    {
		$tn_has_pic{$name} = 0;
		return 1;
	    }
	}
    } # for each file

    # now check if there are pics without thumbnails
    while (my ($key, $tn_exists) = each(%pic_has_tn))
    {
	if (!$tn_exists)
	{
	    return 1;
	}
    }

    return 0;
} # index_needs_rebuilding

=head2 get_image_info

Get the image information for an image.  Returns a hash of
information.

%info = $self->get_image_info($image_file);

=cut
sub get_image_info {
    my $self = shift;
    my $img_file = shift;

    my $info = Image::ExifTool::ImageInfo($img_file);
    # add the basename
    my ($basename, $path, $suffix) = fileparse($img_file, qr/\.[^.]*/);
    $info->{file_basename} = $basename;
    return $info;
} # get_image_info

=head2 debug

    $self->debug($level, $message);

Print a debug message (for debugging).
Checks $self->{'debug_level'} to see if the message should be printed or
not.

=cut
sub debug {
    my $self = shift;
    my $level = shift;
    my $message = shift;

    if ($level <= $self->{'debug_level'})
    {
	my $oh = \*STDERR;
	print $oh $message, "\n";
    }
} # debug

=head1 Private Methods

Methods which may or may not be here in future.

=head2 _whowasi

For debugging: say who called this 

=cut
sub _whowasi { (caller(1))[3] . '()' }

=head1 REQUIRES

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
    http://www.katspace.org/tools

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::KhatGallery::Core
__END__
