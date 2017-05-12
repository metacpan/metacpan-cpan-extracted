#!/usr/bin/perl -w
use strict;
use Image::Magick;
use constant DEBUG =>0;
use Smart::Comments '###';
use File::Copy;
use File::Path;
my %LegalArguments = map { $_ => 1 } qw(
adjoin background bordercolor colormap colorspace colors
compress density dispose delay dither
display font format iterations interlace
loop magick mattecolor monochrome page pointsize
preview_type quality scene subimage subrange
size tile texture treedepth  undercolor
);

my %LegalFilters = map { $_ => 1 } qw(
AddNoise Blur Border Charcoal Chop Contrast Crop Colorize Comment
CycleColormap Despeckle Draw Edge Emboss Enhance Equalize Flip Flop
Frame Gamma Implode Label Layer Magnify Map Minify Modulate Negate
Normalize OilPaint Opaque Quantize Raise ReduceNoise Rotate Sample
Scale Segment Shade Sharpen Shear Solarize Spread Swirl Texture Transparent
Threshold Trim Wave Zoom
);

use WWW::Autosite ':all';
my $err;




# example ENV REQUEST_URI:
# /images//relpathto/image.jpg/filter1&arg1=val&arg2=val/filter2&arg1=val&arg2=val


$ENV{REQUEST_URI}=~/^\/images(\/.+\.jpe{0,1}g)(.*)/i;
my ($rel,$query_string)= ($1,$2); 





my $abs_path = abs_path_n($ENV{DOCUMENT_ROOT}."/$rel");

if (DEBUG) {
	print STDERR "rel $rel, query_string $query_string -- abs= $abs_path\n"; 	
	## %ENV
}


my $details = $query_string;
$details=~s/\//__/g;
my $abs_cached = abs_path_n('/tmp/'.$abs_path.$details);
print STDERR "cache files is/would be: $abs_cached\n" if DEBUG;

if ( showit($abs_cached) ){
	print STDERR "showing chached\n" if DEBUG;
	exit;
}







# READ IMAGE
my $q = new Image::Magick;
$err = $q->Read($abs_path);





my %arguments;


# RUN FILTERS, from path info
for (split '/', $query_string){
	my $chunk = $_;
	$chunk=~/(\w+)\?*(.*)/;
	my ($filter,$arguments )= (ucfirst $1,$2);
	
	next unless $LegalFilters{$filter};
	
	print STDERR "filter $filter, arguments $arguments\n" .	
	"legal filter? " . ($LegalFilters{$filter} || 0)."\n" if DEBUG;
	
	#next unless $LegalFilters{$filter};

	%arguments = map { split '=', $_ } split '&', $arguments;
	## %arguments;
	
	#$err ||= $q->$filter(%arguments);
	$q->$filter(%arguments);

}

# delete 'wrongos'
for (keys %arguments){
	delete $arguments{$_} unless $LegalArguments{$_};
}











my $tmpfile = '/tmp/tempimage'.time;
my $extension = $abs_path; $extension=~s/.+\.//;
print STDERR "ext : $extension\n" if DEBUG;

$err = $q->Write('filename' => "\U$extension\L:$tmpfile", %arguments);

if ($err){
	unlink $tmpfile;
	print STDERR " ERROR= $err\n";
	exit;
}

my $abs_loc = $abs_cached; $abs_loc=~s/\/[^\/]+$//; # or ???
print STDERR "abs loc for cached: $abs_loc " if DEBUG;
File::Path::mkpath($abs_loc); # may already exist
File::Copy::move($tmpfile,$abs_cached); 
print STDERR "moved [$tmpfile] to [$abs_cached]\n" if DEBUG;

showit($abs_cached) ;

#print "Content-Type: image/$extension\n\n";

#binmode STDOUT;
#$q->Write("\U$extension\L:-", %arguments);
exit;





sub showit {
	my $abs = shift;
	
	my $FILE;	
	open($FILE, '<',$abs) or return 0;	#print STDERR "$! - could not open $abs" and return 0;

	print "Content-Type: image/jpeg\n\n";
	binmode STDOUT;	
	binmode $FILE;
	$/ = \1024;
	print while <$FILE>;	
	close $FILE;
	return 1;
}


=pod



in your htaccess::::

	RewriteRule ^images\/ /cgi-bin/apache-magick.cgi [L]

This idea is from OREILLY writing apache modules with perl and c.

=head1 AUTHOR

Leo Charre

=cut
