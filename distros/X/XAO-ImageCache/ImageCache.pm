=head1 NAME

XAO::ImageCache - Images caching by URLs stored in XAO::FS database

=head1 SYNOPSIS

    use XAO::ImageCache;

    # Making new instance of Image Cache object
    my $image_Cache = XAO::ImageCache->new(
        list           => $odb->fetch("/Products"),
        cache_path     => "/var/httpd/shop/product/images/",
        cache_url      => "/products/images/",
        source_url_key => "source_img",
    ) || die "Can't make Image cache!";

    # Init new empty Cache
    $image_cache->init() || die "Can't init new cache!";

    # Start images checking and downloading to cache
    $image_cache->check();

=head1 DESCRIPTION

When we store images links on own database we have no real
images on own site. Some time it may be a problem cause images may
have no right dimension or may be deleted from source site.

XAO::ImageCache made for cache locally images his URL stored
in XAO Founsation Server. Also, images may be resized automaticaly.

This module provide easy methods to scan XAO Foundation Server data
lists, to extract images source URLs from data objects, to download
images to local cache, to resize a local copy of the image to fit into
given dimensions and to store the new local URL of the image back to
the data object.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::ImageCache;
use strict;
use Error qw(:try);
use XAO::Utils;
use XAO::FS;
use XAO::Errors qw(XAO::ImageCache);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::UserAgent;
use URI;
use Image::Magick;
use Date::Manip;
use File::Path;
use File::Copy;

use vars qw($VERSION);
$VERSION='1.22';

###############################################################################

##
# Methods prototypes
#
sub new ($%);
sub init($);
sub check($);
sub download ($$);
sub scale_file($$$$;$);
sub scale_large($$$);
sub scale_thumbnail($$$);
sub remove_cache($);

# Special functions
sub get_filename($);
sub treat_filename($);
sub convert_time($);
sub throw($$);

###############################################################################

sub DESTROY {
    my $self = shift;
    dprint "----- XAO Image Cache finished -----";
}

###############################################################################

=item new($%)

The constructor returns a new C<XAO::ImageCache> object.
You can use it to make new images cache or check images
of already existent cache.

 my $image_cache = XAO::ImageCache->new(
     cache_path     => "cache",         # set cache directory to './cache/'
     source_path    => "cache/source",  # set source directory to './cache/source/'
     local_path     => "images/copy",   # (optional) try to resolve local urls
     cache_url      => "images/",       # set cached images (relative) path to 'images/'
     list           => $odb->fetch("/Products"),
     source_url_key => 'source_image_url',
     dest_url_key   => 'dest_image_url',
     filename_key   => 'product_id',
     min_width      => 50,              # Source image is ignored if smaller
     min_height     => 50,
     size           => {
         width  => 320,
         height => 200,
         save_aspect_ratio => 1,
     },
     thumbnails     => {
         path     => '/var/httpd/shop/product/images/tbn',
         url      => '/products/images/tbn/'
         geometry => "25%",
         url_key  => 'thumbnail_url',
     },
     autocreate     => 1,
     useragent      => {
         agent   => 'My Lovely Browser/v13.01',
         timeout => 30,
     },
     force_download => 1,               # to enforce re-downloads
     force_scale    => 1,               # to enforce re-scaling
     clear_on_error => 0,               # don't clear DB properties even on permanent errors
 ) || die "Image cache creation failure!";

A number of configuration parameters can be passed to
XAO::ImageCache to tune functionality.

=over

=item autocreate

=item cache_path

=item cache_url

=item clear_on_error

=item dest_url_key

=item force_download

=item force_scale

=item list

=item source_url_key

=item size

=item thumbnails

=item useragent

=back

Follow to L<CONFIGURATION PARAMETERS|/"CONFIGURATION PARAMETERS">
section to see what each parameter does.

If any required parameter is not present an error will be thrown.

=cut

#
# Creating new instance of Image Cache object.
#
# Parameters hash should contain following keys:
#
# cache_path     => path to image cache directory
# source_path    => path to source image directory
# cache_url      => relative URL pointing to cached images
# list           => reference to XAO::DO::FS::List object
#                   containing data elements with images data
# source_url_key => source image url key name
# filename_key   => key name image and thumbnail file names will
#                   be based on
#
# Optional parameters:
#
# dest_url_key   => key name containing destination url name
# size => {
#          width  =>
#          height =>
# }
# autocreate =>

sub new ($%) {

    my $class = shift;
    my $self  = {};
    bless $self,$class;

    # Predefined parameters
    $self->{useragent} = { 'agent' => "XAO-ImageCache/$VERSION", };

    # Passed parameters
    if (@_) {
        my %extra = @_;
        @$self{keys %extra} = values %extra;
    }

    #
    # Check required parameters
    #

    unless (defined($self->{source_path})) {
        $self->throw("- missing 'source_path' parameter!");
    }

    unless (defined($self->{cache_path})) {
        $self->throw("- missing 'cache_path' parameter!");
    }

    unless (defined($self->{list})) {
        $self->throw("- missing 'list' parameter!");
    }

    unless (defined($self->{cache_url})){
        $self->throw("- missing 'cache_url' parameter!") ;
    }

    unless (defined($self->{source_url_key})) {
        $self->throw("- missing 'source_url_key' parameter!");
    }

    unless (defined($self->{dest_url_key})) {
        $self->throw("- missing 'dest_url_key' parameter!");
    }

    #
    # Make sure paths end with /
    #
    $self->{'source_path'}               .= '/' if $self->{'source_path'} !~ /\/$/;
    $self->{'cache_path'}                .= '/' if $self->{'cache_path'}  !~ /\/$/;
    $self->{'cache_url'}                 .= '/' if $self->{'cache_url'}   !~ /\/$/;
    $self->{'thumbnails'}->{'cache_path'}.= '/' if $self->{'thumbnails'}->{'cache_path'}
                                                && $self->{'thumbnails'}->{'cache_path'} !~ /\/$/;
    $self->{'thumbnails'}->{'cache_url'} .= '/' if $self->{'thumbnails'}->{'cache_url'}
                                                && $self->{'thumbnails'}->{'cache_url'}  !~ /\/$/;

    if (defined($self->{'min_period'}) && $self->{'min_period'}) {

        unless ($self->{'min_period'} =~ /\d+[smhd]/) {
            $self->throw("- incorrectly formatted 'min_period' parameter!");
        }

        # Make sure 'min_period' parameters is in seconds
        $self->{'min_period'} =~ s/(\d+)([smhd])/$1/;
        if ($2 eq 'm') {
            $self->{'min_period'} *= 60;
        }
        elsif ($2 eq 'h') {
            $self->{'min_period'} *= 3600;
        }
        elsif ($2 eq 'd') {
            $self->{'min_period'} *= 86400;
        }
    }
    else {
        $self->{min_period} = 0;
    }

    $self->{'reload'}=1 if $self->{'force_download'};

    $self->{'size'}->{'quality'}||=88;
    $self->{'thumbnails'}->{'quality'}||=88;

    # Make LWP::UserAgent instance
    my $hash_ref = $self->{'useragent'};
    $self->{ua}  = LWP::UserAgent->new( %$hash_ref)
                || $self->throw("- LWP::UserAgent creation failure!");

    $self->init() if defined($self->{autocreate} && $self->{autocreate});
    $self;
}

###############################################################################

=item init($)

Cache structure initialization.

Executed automaticaly if C<autocreate> parameter present.

Create image cache directory if non existent and thumbnail cache
directory if non existent and defined as initialization parameter.

=cut

sub init($) {
    my $self = shift;

    dprint "----- XAO Image Cache Initialization started -----";

    my $source_path    = $self->{source_path};
    my $img_cache_path = $self->{cache_path};
    my $thm_cache_path = $self->{thumbnails}->{cache_path};

    #
    # Create directories if non existent
    #

    unless (-d $source_path) {
        mkdir($source_path,0777)
          || $self->throw("- cache directory can't be created! $!");
        dprint "Image Cache directory '$source_path' created.";
    }

    unless (-d $img_cache_path) {
        mkdir($img_cache_path,0777)
          || $self->throw("- cache directory can't be created! $!");
        dprint "Image Cache directory '$img_cache_path' created.";
    }

    if ($thm_cache_path) {
        unless (-d $thm_cache_path) {
            mkdir($thm_cache_path, 0777)
              || $self->throw("- can't create thumbnails cache directory ($thm_cache_path)! $!");
            dprint "Thumbnail Cache directory '$thm_cache_path' created.";
        }
    }

    $self->check() if defined($self->{autocreate} && $self->{autocreate});

    return 1;
}

###############################################################################

=item check($)

Goes through given XAO FS data list, downloads images from source url
to cache and puts cache url into destination url key and thumbnail url
key (where applicable).

XAO::ImageCache->download() will be executed for downloading each image.

=cut

sub check($) {

    my $self = shift;

    my $img_src_url_key  = $self->{'source_url_key'};
    my $img_dest_url_key = $self->{'dest_url_key'};
    my $img_cache_url    = $self->{'cache_url'};
    my $thm_src_url_key  = $self->{'thumbnails'}->{'source_url_key'} || '';
    my $thm_dest_url_key = $self->{'thumbnails'}->{'dest_url_key'}   || '';
    my $thm_cache_url    = $self->{'thumbnails'}->{'cache_url'}      || '';
    my $thm_cache_path   = $self->{'thumbnails'}->{'cache_path'}     || '';

    my $getter=$self->{'get_property_sub'} || sub ($$) {
        my ($obj,$prop)=@_;
        return $prop ? $obj->get($prop) : '';
    };

    my $checked     = 0;
    my $list        = $self->{'list'};
    my $list_keys   = $self->{'list_keys'} || [ $list->keys ];

    my $count=0;
    my $total=scalar(@$list_keys);
    foreach my $item_id (@$list_keys) {

        dprint "Checking ID='$item_id', count=".$count++."/$total";

        my $item        = $list->get($item_id);
        my $img_src_url = $getter->($item,$img_src_url_key);
        my $thm_src_url = $getter->($item,$thm_src_url_key);

        # Skipping products without images
        #
        next unless $img_src_url || $thm_src_url;

        # Download source image and create cache image and thumbnail
        #
        try {
            my ($img_cache_file, $thm_cache_file)=$self->download(
                $item,
                $img_src_url,
                $thm_src_url,
            );

            dprint ".storing('$img_cache_file','$thm_cache_file')";
            my %d;
            $d{$img_dest_url_key}=$img_cache_url.$img_cache_file if $img_dest_url_key;
            $d{$thm_dest_url_key}=$thm_cache_url.$thm_cache_file if $thm_dest_url_key;
            $item->put(\%d);
        }
        otherwise {
            my $e=shift;
            eprint "$e";

            # We don't update the item unless this is a permanent error
            # and we have a 'clear_on_error' argument.
            #
            if("$e" =~ /PERMANENT/) {
                if($self->{'clear_on_error'}) {
                    dprint ".permanent error - clearing existing image/thumbnail urls";
                    my %d;
                    $d{$img_dest_url_key}='' if $img_dest_url_key;
                    $d{$thm_dest_url_key}='' if $thm_dest_url_key;
                    $item->put(\%d);
                }
            }
        };

        $checked++;
    }

    return $checked;
}

###############################################################################

=item download($$)

Downloads image into cache directory.

If C<thumbnails> contains C<cache_path> parameter, thumbnail is either
downloaded into thumbnail cache directory or created from downloaded
image.

Source image URL should be passed as parameter. Source thumbnail URL is
an optional parameter:

    $img_cache->download($image_source_url, $thumbnail_source_url);

Downloaded image is resized if C<size> parameter present. Thumbnail is
resized as specified by C<thumbnails> C<geometry> parameter.

When C<force_download> configuration parameter is not set to True value, image
will be downloaded into cache only if image is not already cached or if
cached image has a later modification date than source image.

=cut

sub download ($$) {
    my ($self, $item, $img_src_url, $thm_src_url) = @_;

    my $fnm_key     = $self->{filename_key} || '';
    my $base_fnm    = $fnm_key ? treat_filename($item->get($fnm_key))
                               : get_filename($img_src_url);
    my $img_fnm     = $img_src_url ? $base_fnm.'_img.jpeg' : '';
    my $img_src_fnm = $img_src_url ? $base_fnm.'_src.jpeg' : '';

    my $user_agent     = $self->{ua};
    my $source_path    = $self->{source_path};
    my $img_cache_path = $self->{cache_path};
    my $thm_cache_path = $self->{thumbnails}->{cache_path} || '';

    ##
    # Local path can be a reference to an array of paths
    #
    my $local_path=$self->{'local_path'} || '';
    $local_path=[ $local_path ] unless ref($local_path);

    my $img_src_file   = $source_path.$img_src_fnm;
    my $img_cache_file = $img_cache_path.$img_fnm;

    my ($thm_fnm, $thm_cache_file, $thm_src_file);
    if ($thm_cache_path) {
        $thm_fnm        = $thm_src_url ? get_filename($thm_src_url) : $base_fnm;
        my $thm_src_fnm = $thm_fnm.'_thmsrc.jpeg';
        $thm_fnm       .= '_thm.jpeg';
        $thm_cache_file = $thm_cache_path.$thm_fnm;
        $thm_src_file   = $source_path.$thm_src_fnm;
    }

    # Download thumbnail if specified and resize (keep source and
    # resized images). If the file is missed in the cache, but it
    # exists in the sources and is actual -- then resizing it without
    # downloading.
    #
    my $time_now = time;
    if($thm_cache_path && $thm_src_url) {
        my $mtime_src = (stat($thm_src_file))[9];
        my $period = $time_now - $mtime_src;
        if($period > $self->{'min_period'}) {
            if($thm_src_url !~ m/^(https?|ftp):\/\//i) {
                my $lfound;
		        if($thm_src_url=~/^\// && -r $thm_src_url) {
                    $lfound=1;
                    copy($thm_src_url,$thm_src_file);
                }
                else {
                    foreach my $lpath (@$local_path) {
                        if(-r "$lpath/$thm_src_url") {
                            copy("$lpath/$thm_src_url",$thm_src_file);
                            $lfound=1;
                            last;
                        }
                    }
                }
                if(!$lfound) {
                    $self->throw("- seems to be a local URL and no local file ($thm_src_url)");
                }
            }
            else {
                my $response = $user_agent->head($thm_src_url);
                if ($response->is_success) {
                    my $mtime_web = convert_time($response->header('Last-Modified'));
                    if ((!-r $thm_src_file) || ($mtime_src < $mtime_web) || $self->{'reload'} || $self->{'force_download'}) {
                        $self->download_file($thm_src_url, $thm_src_file);
                    }
                }
                else {
                    if(-r $thm_src_file) {
                        dprint "...error downloading thumbnail (".$response->status_line."), keeping existing source $thm_src_file";
                    }
                    else {
                        $self->throw("- can't get thumbnail header '$thm_src_url' - ".$response->status_line." (NETWORK)");
                        $thm_src_file = '';
                    }
                }
            }
        }
        else {
            dprint ".thumbnail source file current: $thm_src_url";
        }

        # Resizing if required
        #
        if($thm_src_file) {
            my $mtime_cache=(stat($thm_cache_file))[9];
            $mtime_src=(stat($thm_src_file))[9];
            if($mtime_cache<=$mtime_src) {
                $self->scale_thumbnail($thm_src_file, $thm_cache_file);
            }
        }
    }

    # Download source image and resize (keep source and resized
    # images). Only download source image if cached image not present or
    # older than source.
    #
    if($img_src_url) {
        my $mtime_src = (stat($img_src_file))[9] || 0;
        my $period = $time_now - $mtime_src;
        if($self->{'force_download'} || $period>$self->{'min_period'}) {
            if($img_src_url !~ m/^(https?|ftp):\/\//i) {
                my $lfound;
                if($img_src_url=~/^\// && -r $img_src_url) {
                    $lfound=1;
                    copy($img_src_url,$img_src_file);
                }
                else {
                    foreach my $lpath (@$local_path) {
                        if(-r "$lpath/$img_src_url") {
                            copy("$lpath/$img_src_url",$img_src_file);
                            $lfound=1;
                            last;
                        }
                    }
                }
                if(!$lfound) {
                    $self->throw("- seems to be a local URL and no local file ($img_src_url)");
                }
            }
            else {
                my $response = $user_agent->head($img_src_url);
                if ($response->is_success) {
                    my $mtime_web = convert_time($response->header('Last-Modified'));
                    if ((!-r $img_src_file) || ($mtime_src < $mtime_web) || $self->{'reload'} || $self->{'force_download'}) {
                        $self->download_file($img_src_url, $img_src_file);
                    }
                    else {
                        dprint ".image source file current: $img_src_url";
                    }
                }
                else {

                    # This is here mainly for situations like this: a
                    # superseded item content gets into a new item, but
                    # the image URL is long gone, not accessible; we
                    # have a cached copy and we use it.
                    #
                    if(-r $img_src_file) {
                        dprint "...error downloading image (".$response->status_line."), keeping existing source $thm_src_file";
                    }
                    else {
                        $self->throw("- can't get image header for $img_src_url - ".$response->status_line." (NETWORK)");
                        $img_src_file = '';
                    }
                }
            }
            $mtime_src=(stat($img_src_file))[9] if $img_src_file;
        }

        if($img_src_file) {

            # Now checking if the source file we have is newer then what's in
            # the cache and updating the cache in that case.
            #
            my $mtime_cache=(stat($img_cache_file))[9] || 0;
            if($self->{'force_scale'} || $mtime_cache < $mtime_src) {
                $self->scale_large($img_src_file, $img_cache_file);
            }

            # Create thumbnail from the image source file if necessary
            #
            if($thm_cache_file && (!$thm_src_url || !$thm_src_file)) {
                $mtime_cache=(stat($thm_cache_file))[9] || 0;
                if($self->{'force_scale'} || $mtime_cache < $mtime_src) {
                    $self->scale_thumbnail($img_src_file,$thm_cache_file);
                }
                $thm_src_file=1;    # Just to mark that we have it
            }
        }
    }

    $img_fnm='' unless $img_src_file;
    $thm_fnm='' unless $thm_src_file;

    ### dprint "...scaled->('$img_fnm','$thm_fnm')";

    return ($img_fnm, $thm_fnm);
}

###############################################################################

sub download_file {
    my $self        = shift;
    my $source_url  = shift;
    my $source_file = shift;

    dprint "DOWNLOAD ($source_url)->($source_file)";

    my $response=$self->{'ua'}->get($source_url);
    my $errstr;
    if($response->is_success) {
        if($response->content_type =~ /^image\//) {
            open(F,"> $source_file.tmp") || $self->throw("- unable to save file '$source_file': $!");
            binmode(F);
            print F $response->content;
            close(F);
            rename("$source_file.tmp",$source_file);
        }
        else {
            $errstr="downloaded '$source_url' is not an image (".$response->content_type.") (PERMANENT)";
        }
    }
    else {
        $errstr="can't download '$source_url' - ".$response->status_line." (NETWORK)";
    }

    return unless $errstr;

    # If the file is already there (from previous downloads then just
    # printing the error, but returning normally to let the file be scaled and
    # stored as image/thumbnail
    #
    if(-f $source_file && !$self->{'clear_on_error'}) {
        eprint "download_file: $errstr -- ignoring and keeping existing file";
        return;
    }
    else {
        $self->throw("- $errstr");
    }
}

###############################################################################

sub scale_file ($$$$;$) {
    my ($self,$infile,$outfile,$params,$label)=@_;

    $label||='unknown';

    if(!$params) {
        dprint "Copying $infile to $outfile as is ($label)";
        copy($infile,$outfile);
        return;
    }

    my $geometry = ''; # image dimensions in ImageMagick geometry format

    my $image = Image::Magick->new() || $self->throw("- Image::Magick creation failure!");
    my $err   = $image->ReadImage($infile);
    ### dprint ".source in '$infile'";

    # Only throwing an error if no image was read. If we consider all
    # warnings as errors then some 3M tiff files don't parse.
    #
    # From http://www.imagemagick.org/script/perl-magick.php:
    #
    #   $x = $image->Read(...);
    #   warn "$x" if "$x";      # print the error message
    #   $x =~ /(\d+)/;
    #   print $1;               # print the error number
    #   print 0+$x;             # print the number of images read
    #
    ### $self->throw("- parsing error ($err) (PERMANENT)") if $err;
    (0 + $err)>0 ||
        $self->throw("- parsing error ($err) (PERMANENT)");

    # We only deal with image/* types -- otherwise ImageMagick can
    # sometimes successfully open and convert HTML or text messages into
    # images.
    #
    $image->Get('mime')=~/^image\// || $self->throw("- not an image file '$infile' (".$image->Get('mime').")");

    # Get source image dimensions
    #
    my ($src_width, $src_height) = $image->Get('columns','rows');

    my $min_width=$self->{'min_width'} || 10;
    my $min_height=$self->{'min_height'} || $min_width;

    if($src_height<=1 || $src_width<=1 || ($src_height<$min_height && $src_width<$min_width)) {
        $self->throw("- image ($src_width,$src_height) is smaller than the minimum ($min_width,$min_height) for '$label' (PERMANENT)");
    }

    # Getting target image width and height
    #
    if($params->{'geometry'}){
        $geometry = $params->{geometry}; # size was set as geometry string
    }
    elsif($params->{'save_aspect_ratio'}) {
        my $src_aspect=$src_width/$src_height;

        my $target_width=$params->{'width'} || $src_width;
        my $target_height=$params->{'height'} || $src_height;
        my $target_aspect=$target_width/$target_height;

        my ($width,$height);

        if($src_width<=$target_width && $src_height<=$target_height) {
            if(lc($image->Get('mime')) eq 'image/jpeg' && ($image->get('colorspace') || '') =~ /^s?RGB$/i) {
                copy($infile,$outfile);
                dprint "..copied ${src_width}x${src_height} as is for '$label' (jpeg, fits into ${target_width}x${target_height})";
                return;
            }
            else {
                $width=$src_width;
                $height=$src_height;
            }
        }
        elsif($target_aspect>$src_aspect) {
            $height=$target_height;
            $width=int($height*$src_aspect+0.5);
        }
        else {
            $width=$target_width;
            $height=int($width/$src_aspect+0.5);
        }

        $geometry=$width.'x'.$height.'!';
    }
    else {
        # Use given width & height as is (or image size if not set)
        $geometry = ($params->{'width'}  || $src_width) .'x'.
                    ($params->{'height'} || $src_height).'!';
    }

    # We don't support transparency and by default transparent regions
    # sometimes get translated to black. Forcing them into white.
    #
    $image->Set(background => 'white');
    $image=$image->Flatten();

    # This is required, otherwise new ImageMagick sometimes converts
    # images to CMYK colorspace for whatever reason.
    #
    # sRGB is the standard colorspace for monitors and printing, RGB
    # is an unspecified Red/Green/Blue encoding. Some images come out
    # darker when converted to RGB.
    #
    $image->Set(
        colorspace  => 'sRGB',
        depth       => 8,
    );

    # Scaling
    #
    $image->Scale(geometry => $geometry);

    # Stripping embedded profiles & comments. They sometimes take
    # upwards of 500kb
    #
    $image->Strip;

    # Writing the results
    #
    $image->Set(magick => 'JPEG');
    $image->Set(quality => ($params->{'quality'} || 88));

    my $rc=$image->Write($outfile);

    !"$rc" || die "Error writing scaled image: $rc";

    dprint "..resized ${src_width}x${src_height} to $geometry for '$label'";
}

###############################################################################

=item scale_large($$$)

Scaling image to given size.

=cut

sub scale_large($$$) {
    my ($self,$infile,$outfile)=@_;

    return $self->scale_file($infile,$outfile,$self->{'size'},'large');
}

###############################################################################

=item scale_thumbnail($$$)

Creates thumbnail image from given source image.

=cut

sub scale_thumbnail($$$) {
    my ($self,$infile,$outfile)=@_;

    return $self->scale_file($infile,$outfile,$self->{'thumbnails'},'thumbnail');
}

###############################################################################

=item remove_cache($)

Removing the ENTIRE cache directory from disk.

Be carefully to use this method!!!

Cache structure will be removed from disk completely!
Set C<force_download> parameter to True value to download
images to cache without any conditions.

=cut

sub remove_cache($) {
    my $self = shift;
    rmtree($self->{'cache_path'});
}

###############################################################################

sub throw($$) {
    my ($self,$message)=@_;

    if($message=~/^-/) {
        (my $fname=(caller(1))[3])=~s/^.*://;
        $message=$fname." ".$message;
    }

    throw XAO::E::ImageCache $message;
}

###############################################################################

=item get_filename($)

File name generation for cached images.

Source image URL should be passed. Returned file name is an MD5 digest
of the source URL converted to Base64 string with all non alpha numeric
characters are converted to C<_>.

Example.

    Location:
    http://localhost/icons/medbutton.jpeg

    provide file name:
    4aFNA1utpmCNG2wEIF69mg.jpeg

=cut

# Return MD5 digest of given URL converted to Base64
# string with extension and
sub get_filename($) {
    my $source = shift;
    my $url = URI->new($source);
    my $path= $url->path();
    $path =~ /\./;
    my $file = md5_base64($source);
    return treat_filename($file);
}

###############################################################################

=item treat_filename($)

Makes sure only file name friendly characters are present: all non alpha
numeric characters are converted to C<_>.

=cut

sub treat_filename($) {
    my $fnm = shift;
    $fnm    =~ s/\W/_/gm;
   #$fnm    =~ s/\//_/gm;
   #$fnm    =~ s/\+/\-/gm;
   #$fnm    =~ s/=/\-/gm;
    return $fnm;
}

###############################################################################
# Convert 'Last-Modified' Date/Time in internet format
# to seconds since epoch format
# Wed, 21 Jan 2001 24:55:55 GMT
sub convert_time($) {
    my $date_str = shift;
    #print "Last Modified: $date_str\n";
    $date_str =~ s/,//;
    my @date_arr = split(/[\s+|:]/,$date_str);
    my %month = (
        Jan => 0, Feb => 1, Mar =>  2, Apr =>  3,
        May => 4, Jun => 5, Jul =>  6, Aug =>  7,
        Sep => 8, Oct => 9, Nov => 10, Dec => 11,
    );
    my %wday = (Sun => 0, Mon => 1, Tue => 2, Wed => 3, Thu => 4, Fri => 5, Sat => 6);
    # Clearing leading zero
    $date_arr[1] =~ s/^0//; # Month days
    $date_arr[4] =~ s/^0//; # Hours
    $date_arr[5] =~ s/^0//; # Minutes
    $date_arr[6] =~ s/^0//; # Seconds
    my $time=eval {
        if ($date_arr[7] eq 'GMT') {
            Time::Local::timegm(
                $date_arr[6],
                $date_arr[5],
                $date_arr[4],
                $date_arr[1],
                $month{$date_arr[2]},
                $date_arr[3],
            );
        }
        else{
            Time::Local::timelocal(
                $date_arr[6],
                $date_arr[5],
                $date_arr[4],
                $date_arr[1],
                $month{$date_arr[2]},
                $date_arr[3],
            );
        }
    };
    return $time || 0;
}

###############################################################################

1;

=back

=head1 CONFIGURATION PARAMETERS

The set of configuration parameters contain required and optional parameters.

Required parameters should be defined. Execution will be stoped if required
parameter not present.

Optional parameters just configure aditional functionality and may not present.

=head2 Required parameters

=over

=item cache_path

- Path string where the cache should be placed.

May be absolute or relative from current execution directory path.

For example. Set it to C<./cache> if you whant to place cache in
C<cache> subdirectory of your script working directory.

=item cache_url

- complet URL (or relative location) to cached images.

Place here your URL reflection of cache directory in condition with
your HTTP server configuration.

For example. Set it to C<http://my.host.com/images/> if your HTTP
server configured for provide access to your cache directory by
hostname C<my.host.com> and location C<images/>. Cached images names
will be added to image URL automaticaly.

=item list

- reference to C<XAO::DO::FS::List> object containing the data objects
with Image source URL

Meaning, your data look like a XAO Foundation Server list of objects
with references to images. This parameter should contain reference to
to XAO::DO::FS::List object. This reference may be result of
XAO::Objects->fetch() methode.

XAO::ImageCache will process each record of this list.

=item source_url_key

- data key containing the URL of source image.

Contain the name of key of data object containing the source image reference.

=back

=head2 Optional parameters

=over

=item dest_url_key

- data key for storing URL of image in cache.

Optional parameter cause image name in cache will be a MD5 Base64
digest of source image path where C<=> character removed, C<\> and C<+>
translated to C<_> and C<-> simultaniosely.

To get cached image name

=item size

- Prefered image size may set as C<geometry> equal to C<geometry> parameter
of Image::Magick module to pass it dirrectly to Image::Magick Scale function.

Other way to set the image size is set a width and height keys to preffered
values.

If one of image dimension is not defined then corresponding parameter of
original image will be used.

This way, image will be resized with same aspect ratio (same proportions) to
the original image if C<save_aspect_ratio> parameter present.

Image width and height will be resized exactly to given size if
C<save_aspect_ratio> parameter not present.

Parameter C<geometry> has higher priority and other parameters has no effects
if C<geometry> peresent.

For example.

    # Size 320x200 as geometry settings
    %params = (size => {geometry => "320x200!"} );

    # Size 320x200 as dimensions settings
    %params = (size => {width => 320, height => 200} );

    # Fit size into 320x200 with saving image proportions
    %params = (
        size => {
            width                   => 320,
            height                   => 200,
            save_aspect_ratio => 1,
        }
    );

=item autocreate

- create or check cache content automaticaly.

If non zero value present, cache directory will be created
and images checking will be runned. Otherwithe you should run
init() and check() methodes manualy.

Existent cache directory will not be removed. You may do it
manualy using remove_cache() methode.

=item force_download

- each image should be reloaded to cache and processed without
dependance of source image modification time. Any conditions
ignored.

=item thumbnail

- thumbnails creator configuration

Some thubnails configuration parameters may be set for
automatic thumbnails creation. This parameter should contain
the reference to hash with thumbnails configuration parameters.

Only C<path> parameter is required. Other parameters are
optional.

=over

=item path

path where thumbnail images should be placed.

=item url

URL for access to thumbnails directory. Same way as C<cache_url>.

=item url_key

Data object key name where thumbnail URL should be stored.

=item geometry

Geometry string to set thumbnail images size in Image Magick geometry
format. May be set as dimension ("320x200!") or as persent of actual
size of cached image ("25%").

Default value is "50%" the half of actual image size.

=back

=item useragent

- configuration parameters hash for LWP::UserAgent

=over

=item agent

Default value C<XAO-ImageCache/#.##>

=item env_proxy

Default value 1

=item keep_alive

Default value 1

=item timeout

Default value 30

=back

For more information please follow to L<LWP::UserAgent>

=back

=head1 SEE ALSO

Specifics of List API can be found in

L<XAO::DO::FS::List>.

For additional information please see

L<XAO::DO::FS::Glue>,

L<XAO::DO::FS::Global>,

L<XAO::DO::FS::Glue::MySQL_DBI>,

Refer to L<Image::Magick> documentation for additional
information about setting of image scaling parameters.

Refer to L<LWP::UserAgent> documentation for additional
information about user agent parameters.

=head1 BUGS

Please, inform me about found bugs.

=head1 AUTHORS

The XAO::ImageCache package maintained by
Konstantin Safronov <skv@xao.com>.  Specification by
Andrew Maltsew <am@xao.com>

=cut
