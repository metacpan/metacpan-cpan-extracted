package Wrangler::FileSystem::Layers;

use strict;
use warnings;

our @filesystems;

sub new {
	my $class = shift;
	my $self = bless({ @_ }, $class);

	# hardcoded for now
	require Wrangler::FileSystem::Linux;
	push(@filesystems, Wrangler::FileSystem::Linux->new() );

	return $self;
}

sub get_property {
	warn('Layers does not offer a get_property() method, well, for now. You probably want to use richproperty() with a narrow wishlist!');
}

my $regex_case1 = qr/^Extended Attributes::/;
my $regex_case2 = qr/^MIME/;
my $regex_case3 = qr/^Filesystem::/;
my $regex_case4 = qr/mode$|Modified$|Filename$|Basename$|Suffix$/;
sub can_mod {
	my $self = shift;
	my $metakey = shift;
	return 1 if $metakey =~ $regex_case1;
	return 0 if $metakey =~ $regex_case2;
	return 1 if $metakey =~ $regex_case3 && $metakey =~ $regex_case4;
	return 0;
}

sub can_del {
	my $self = shift;
	my $metakey = shift;
	# Wrangler::debug("Layers::can_del: $metakey 1 ") if $metakey =~ $regex_case1;
	return 1 if $metakey =~ $regex_case1;
	return 0;
}

sub set_property {
	my ($self, $path, $metakey, $newval) = @_;

	unless($path){ warn 'path missing!'; return 0; }
	unless($metakey){ warn 'metadata-key missing!'; return 0; }

	unless( $self->can_mod($metakey) ){ warn "set_property can't modify property: '$metakey' on '$path'"; return 0; }

	if($metakey =~ $regex_case1){
		my $ns = 'Extended Attributes';
		$metakey =~ s/$regex_case1//;
		Wrangler::debug("Layers::set_property: $path : $ns : $metakey = $newval");
		return $filesystems[0]->setfattr($path, $metakey, $newval );
	}else{
		warn 'Unimplemented or unknown namespace!';
		return 0;
	}
}

my $regex_asterisk = qr/\*/;
sub del_property {
	my ($self, $path, $metakey) = @_;

	unless($path){ warn 'path missing!'; return 0; }
	unless($metakey){ warn 'metadata-key missing!'; return 0; }

	# allow globbing for del_property
	my @metakeys = ();
	if($metakey =~ $regex_asterisk){
		Wrangler::debug("Layers::del_property: globbed metakey $path : $metakey");

		my $richproperties = $self->richproperties($path);
		$metakey =~ s/\./\\./g;
		for(keys %$richproperties){
			# Wrangler::debug("Layers::del_property:  adding globbed $_") if $_ =~ /^$metakey/;
			push(@metakeys, $_) if $_ =~ /^$metakey/;
		}
	}else{
		push(@metakeys, $metakey);
	}

	my @errors;

	# be more atomic
	for my $metakey (@metakeys){
		push(@errors, "set_property can't delete property: $metakey on $path") unless $self->can_del($metakey);
	}

	return @errors ? 0 : 1 if @errors;

	for my $metakey (@metakeys){
		if($metakey =~ $regex_case1){
			my $ns = 'Extended Attributes';
			$metakey =~ s/$regex_case1//;
			Wrangler::debug("Layers::del_property: $path : $ns : $metakey");
			$filesystems[0]->delfattr($path, $metakey ) or push(@errors, $!);
		}else{
			push(@errors, "Unimplemented or unknown namespace: $metakey");
		}
	}

	return @errors ? 0 : 1;
}

sub available_properties {
	my $self = shift;
	my $path = shift;

	# call each dimension's available_properties (todo, one dimension for now)
	my $prop_ref = $filesystems[0]->available_properties($path);

	return $prop_ref;
}

sub richproperties {
#	my $self = shift;
#	my $path = shift;
#	my $wishlist = shift;

	# call each dimension's properties (todo, one dimension for now)
	my $prop_ref = $filesystems[0]->properties($_[1],$_[2]);

	return $prop_ref;
}


sub richlist {
	my $self = shift;
	my $path = Cwd::abs_path(shift); # see note on abs_path in list()
	my $wishlist = shift;
	# Wrangler::debug("Layers::richlist: @$wishlist") if $wishlist;

	# call each dimension's properties (todo, one dimension for now)
	# on error, an array-ref blessed with 'error' is returned
	my $richlist = $filesystems[0]->list($path,$wishlist);

	return wantarray ? ($richlist,$path) : $richlist;
}

sub renderer {
	my %renderer = (
		'Filesystem::Size' => \&nice_filesize_KB,
		'Filesystem::Accessed' => \&HTTP::Date::time2iso,
		'Filesystem::Modified' => \&HTTP::Date::time2iso,
		'Filesystem::Changed' => \&HTTP::Date::time2iso,
	);

	return defined($renderer{$_[1]}) ? $renderer{$_[1]} : undef;
}

## a value "renderer"
sub nice_filesize_KB {
	my $size = shift;

	if( $size == 0 ){
		return "0 KB";
	}

	if( $size < 1000 ){
		$size = '1';
	}else{
		$size = int(($size + 500) / 1000);
		# $size = $size;
	}

	if(length($size) > 3){
		$size = reverse($size);
		$size = substr($size, 0,3) . "." . substr($size, 3,length($size));
		$size = reverse($size);
	}

	return "$size KB";
}

## a value "renderer"
sub nice_filesize_MB {
	my $size = shift;

	$size = sprintf("%.2f", ($size / 1000000));

	return "$size MB";
}

sub ask_vfs {
	return 'ask_vfs';
}


## other wrappers (todo, as currently most return early)
sub cwd {
	shift(@_); # put away self for now
	return $filesystems[0]->cwd(@_);
}

sub fileparse {
	shift(@_); # put away self for now
	return $filesystems[0]->fileparse(@_);
}

sub catfile {
	shift(@_); # put away self for now
	return $filesystems[0]->catfile(@_);
}

sub mount {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->mount(@_);
	}
}

sub unmount {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->unmount(@_);
	}
}

sub mounts {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->mounts(@_);
	}
}

sub parent {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->parent(@_);
	}
}

sub test {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->test(@_);
	}
}

sub list {
	warn('Layers does not offer a list() method, use richlist() instead!');
}

sub stat {
	warn('Layers does not offer a stat() method, use richproperties() instead!');
}

sub delete {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->delete(@_);
	}
}

sub symlink {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->symlink(@_);
	}
}

sub mknod {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->mknod(@_);
	}
}

sub mkdir {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->mkdir(@_);
	}
}

sub rmdir {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->rmdir(@_);
	}
}

sub trash {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->trash(@_);
	}
}

sub rename {
	shift(@_); # put away self for now
	for(@filesystems){
		# print "Layers::rename: @_\n";
		return $_->rename(@_);
	}
}

sub move {
	shift(@_); # put away self for now
	for(@filesystems){
		# print "Layers::move: @_\n";
		return $_->move(@_);
	}
}

sub copy {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->copy(@_);
	}
}

# todo: Layers shouldn't offer a utime at all. Todo: make sure it's used nowhere and force set_property
sub utime {
	shift(@_); # put away self for now
	for(@filesystems){
		return $_->utime(@_);
	}
}

sub listfattr {
	warn('Layers does not offer any low-level xattr methods, use richproperties() instead!');
}

sub getfattr {
	warn('Layers does not offer any low-level xattr methods, use get_property() instead!');
}

sub setfattr {
	warn('Layers does not offer any low-level xattr methods, use set_property() instead!');
}

sub delfattr {
	warn('Layers does not offer any low-level xattr methods, use del_property() instead!');
}

our %exts = ( # possibly no 'x-something', as per RFC 6648
	'3ds'	=> '3D Studio Mesh File',
	'6rn'	=> 'Rendition Image',
	a3d	=> 'MegaGamma 3D LUT File',
	aac	=> 'AAC Audio File',
	aaf	=> ['Advanced Authoring Format File', 'application/aaf'],
	acf	=> 'ACF Curve File',
	acv	=> 'Adobe Photoshop Curve File',
	aiff	=> 'AIFF Audio File',
	als	=> 'Alias Image',
	ani	=> ['Windows Animated Cursor Image', 'image/x-icon'], # mime unknown; not exactly ico/cur, but usually apps able to read the latter read it
	arw	=> ['Sony RAW Image', 'image/x-sony-arw'],
	asf	=> 'Windows Media Audio/Video File',
	asx	=> 'ASX Playlist',
	au	=> ['Basic Audio File', 'audio/basic'],
	avi	=> 'Microsoft AVI File',
	bat	=> 'Batch Script',
	bak	=> 'Backup File',
	bef	=> 'Unified Color HDR Image',
	bmp	=> 'Bitmap Graphic',
	bz2	=> 'bzip2 Archive',
	blend	=> ['Blender 3D File', 'application/blender'],
	blend1	=> ['Blender 3D Backup File', 'application/blender'],
	blend2	=> ['Blender 3D Backup File', 'application/blender'],
	cals	=> 'CALS (Continuous Acquisition and Life-cycle Support) Image',
	cel	=> 'Autodesk Animator (Intermediate) Image', #  an extended single frame .fli or .flc
	cin	=> 'Kodak Cineon Image',	# similar to DPX
	cur	=> ['Windows Cursor Image', 'image/x-icon'],	# same as .ico with header declaring it as .cur
	cr2	=> ['Canon Raw Image', 'image/x-canon-cr2'],
	crw	=> ['Canon Raw Image', 'image/x-canon-crw'],
	cws	=> 'Combustion Workspace File',
	db	=> 'Database File',
	dat	=> ['KUKA Robot Language .dat File', 'text/plain'],
	dcm	=> ['DICOM Image', 'application/dicom'],
	dicom	=> ['DICOM Image', 'application/dicom'],
	dcr	=> ['Kodak Digital Camera RAW File', 'image/raw'],
	divx	=> 'DivX Video',
	dng	=> ['Digital Negative Image', 'image/adobe-dng'],
	doc	=> 'Microsoft Word Document',
	docm	=> 'Office Open XML Document',
	docx	=> 'Office Open XML Document',
	dpx	=> 'Digital Picture Exchange Image',
	droid	=> ['EditDroid Session-db Dump', 'application/editdroid'],
	dxf	=> ['Drawing Interchange File', 'image/vnd.dxf'],
	edl	=> ['Edit Decision List/CMX3600', 'text/plain'],
	eps	=> 'Encapsulated PostScript File',
	exe	=> 'Executable',
	exr	=> 'OpenEXR HDR Image',
	fcp	=> 'Final Cut Pro File',
	fdr	=> 'Final Draft File', # old version 5 - 7 format
	fdx	=> 'Final Draft 8 File', # version 8, 9 ... format
	flac	=> ['Free Lossless Audio File', 'audio/flac'],
	fli	=> 'Autodesk Animator Animation', # max 320x200
	flc	=> 'Autodesk Animator Pro Animation',
	flv	=> ['Flash Video', 'video/x-flv'],
	flx	=> 'Autodesk Image/Animation File', # 3DStudio MAX, also Tempra Pro
	fs	=> 'Framestore Image',
	gbf	=> 'Panavision Binary Format (settings) File',
	gif	=> 'GIF Image',
	graphml	=> ['GraphML File', 'application/graphml+xml'],
	gz	=> 'gzip Archive',
	h264	=> 'h264 Video',
	hdr	=> 'Radiance RGBE HDR Image',
	hgignore => 'Mercurial .hgignore File',
	htm	=> 'HTML Markup File',
	html	=> 'HTML Markup File',
	ico	=> ['Windows Icon Image', 'image/x-icon'],	# compare .cur; sometimes  image/vnd.microsoft.icon
	iff	=> 'Interchange File Format',	# also Autodesk Maya IFF variant
	ion	=> 'Descript.ion File',
	iso	=> 'ISO Disk Image',
	jif	=> 'Jeffs Image Format',	# patent-free GIF alternative
	jls	=> 'JPEG-LS Image',
	jp2	=> ['JPEG 2000 Image', 'image/jp2'],
	jpg	=> ['JPEG Image', 'image/jpeg'],
	jpe	=> ['JPEG Image', 'image/jpeg'],
	jpeg	=> ['JPEG Image', 'image/jpeg'],
	jpx	=> ['JPEG 2000 Image', 'image/jpx'],
	lnk	=> ['Internet URL', 'text/plain'],
	lut	=> 'Thomson Luther 3D LUT File',
	lwo	=> 'Lightwave Object',
	lws	=> 'Lightwave Scene',
	m2ts	=> ['Blu-ray Disc Audio-Video MPEG-2 Transport Stream (BDAV+M2TS)', 'video/MP2T'],	# RFC3555
	m2p	=> ['MPEG Program Stream', 'video/MP2P'],	# RFC3555
	m3u	=> 'M3U Playlist',
	m3u8	=> ['M3U Playlist (UTF-8)', 'application/x-mpegURL'],	# also vnd.apple.mpegURL
	m4a	=> 'MP4 AAC Audio',
	m4p	=> 'MP4 Protected Audio',
	max	=> '3D Studio MAX File',
	mid	=> ['MIDI File', 'audio/midi'],
	midi	=> ['MIDI File', 'audio/midi'],
	md	=> ['Markdown File', 'text/markdown'],
	mkv	=> ['Matroska Video', 'video/x-matroska'],
	mk3d	=> ['Matroska 3D Video', 'video/x-matroska'],
	mka	=> ['Matroska Audio File', 'audio/x-matroska'],
	mov	=> 'Apple QuickTime Media Container',
	motn	=> 'Apple Shake Motion Project File',
	movie	=> ['Silicon Graphics Video', 'video/x-sgi-movie'],
	mp3	=> 'MP3 Audio File',
	mp4	=> 'MP4 Audio-/Video File',
	mpg	=> 'MPEG-1 Video',
	mpeg	=> 'MPEG-2 Video',
	mrw	=> 'Sony (Minolta) Raw Image',
	mxf	=> ['Material Exchange Format File','application/mxf'],
	nar	=> 'Nikon Capture Advanced Raw Image',
	ncv	=> 'Nikon Capture Curves File',
	nef	=> ['Nikon RAW Image', 'image/x-nikon-nef'],
	nid	=> 'Nikon IPTC Data',
	nk	=> 'Nuke File',
	nrw	=> 'Nikon Raw Image',
	ntc	=> ['Natron Cache File', 'application/vnd.natron.cachefile'],
	ntp	=> ['Natron Project File', 'application/vnd.natron.project'],
	nut	=> ['NUT Open Container Format File', 'application/octet-stream'], # mime type?
	nwb	=> 'Nikon White Balance File',
	ogg	=> 'OGG Media',
	omf	=> ['Open Media Framework Interchange File', 'application/avid-omf'],
	on2	=> 'On2 VP6 Video',
	part	=> 'Incomplete Download',
	pbm	=> 'Portable Anymap Bitmap Image',
	pcs	=> 'Apple PICS Animation',
	pct	=> ['Apple PICT Image', 'image/x-pict'],
	pcx	=> ['PC Exchange/Paintbrush Image', 'image/x-pcx'],
	pdf	=> 'Portable Document Format File',
	pgm	=> 'Portable Anymap Graymap Image',
	php	=> 'PHP Dynamic HTML',
	php3	=> 'PHP Dynamic HTML',
	pix	=> 'Alias Raster Image',
	pic	=> ['Apple PICT Image', 'image/x-pict'],	# also Autodesk Softimage
	pict	=> ['Apple PICT Image', 'image/x-pict'],
	pl	=> 'Perl Script',
	png	=> 'PNG Image',
	pnm	=> 'Portable Anymap Image',
	pm	=> 'Perl Module',
	ppm	=> 'Portable Anymap Pixmap Image',
	ps	=> 'PostScript File',
	ppt	=> 'Microsoft PowerPoint Presentation',
	pptm	=> 'Office Open XML Presentation',
	pptx	=> 'Office Open XML Presentation',
	psd	=> 'Photoshop Format Image',
	pxr	=> ['Pixar Image', 'image/pixar'],	# 24/33 bit per pixel log format tiff variant
	py	=> ['Python Script', 'text/x-python'],
	pyc	=> ['Python Compiled Bytecode', 'application/x-python-code'],
	pyo	=> ['Python Compiled Bytecode', 'application/x-python-code'],
	qtl	=> 'QuickTime Playlist',
	rar	=> 'rar Archive',
	raw	=> 'Raw Image or Audio Data',
	r3d	=> 'RED Camera Redcode Raw File',
	rgb	=> ['SGI IRIS Image', 'image/x-rgb'],
	rla	=> 'Wavefront Advanced Visualizer Image',	# RLE compressed
	rsx	=> 'RED Camera metadata file',
	save	=> 'nano Editor Backup File',
	sct	=> 'Scitex CT (Continuous Tone) Image',
	sgi	=> ['SGI IRIS Image', 'image/sgi'],
	smil	=> 'Smil Playlist',
	sr2	=> ['Sony Raw Image File', 'image/x-sony-sr2'],
	src	=> ['KUKA Robot Language .src File', 'text/plain'],
	srf	=> 'Sony Raw Image File',
	stp	=> 'STEP 3D File',
	'sub'	=> ['Close Captioning/ Subtitle File', 'image/vnd.dvb.subtitle'],
	sun	=> ['SUN Raster Image', 'image/sun-raster'],
	svg	=> ['Scalable Vector Graphics File', 'image/svg+xml'],
	svgz	=> ['Compressed Scalable Vector Graphics File', 'image/svg+xml'],
	swf	=> 'Shockwave Flash File',
	sys	=> 'Microsoft System File',
	shtml	=> 'Dynamic HTML',
	tdi	=> 'Thompson Digital Image', # similar/same Maja IFF
	tiff	=> ['Tagged Image File Format Image', 'image/tiff'],	# image/tiff, image/tiff-fx
	tif	=> ['Tagged Image File Format Image', 'image/tiff'],	# image/tiff, image/tiff-fx
	tga	=> ['Targa Image File',	'image/targa'],			# image/x-targa, image/x-tga
	tgz	=> 'tar/gzip Archive',
	thm	=> ['Canon Thumbnail Image', 'image/jpeg'],
	tpic	=> ['Targa Image File', 'image/targa'],			# image/x-targa, image/x-tga
	ts	=> ['MPEG-2 Transport Stream', 'video/mp2ts'],		# http://www.ietf.org/mail-archive/web/ietf-types/current/msg01593.html
	txt	=> 'Text Document',
	veg	=> ['Sony Vegas Project File', 'application/vegas80'],	# application/vegas81, application/vegas90, ...
	vcf	=> 'vCard File',
	vff	=> 'Sun TAAC Image',
	vob	=> ['DVD Video File', 'video/dvd'],
	wav	=> ['Waveform Audio File Format File', 'audio/wav'],	# audio/vnd.wave, audio/wave
	webm	=> ['WebM Audio-/Video File', 'video/webm'],	# also audio/webm
	webp	=> ['WebP Image', 'image/webp'],
	wcl	=> ['Wrangler Column Layout', 'application/json'],	# exported/imported by Settings::Filebrowser, is application/json
	wfl	=> ['Wrangler Field Layout', 'application/json'],	# exported/imported by FormEditor, is application/json
	wma	=> ['Windows Media Audio', 'audio/ms-wma'],
	wmv	=> ['Windows Media Video', 'audio/ms-wmv'],
	xbm	=> 'X Bitmap File',
	xmp	=> ['Extensible Metadata Platform File', 'application/rdf+xml'],
	xcf	=> 'GIMP Image',
	xls	=> 'Microsoft Excel Spreadsheets',
	xlsm	=> 'Office Open XML Spreadsheets',
	xlsx	=> 'Office Open XML Spreadsheets',
	yaml	=> 'YAML Markup File',
	zip	=> 'zip Archive',
);

1;

__END__

=pod

=head1 NAME

Wrangler::FileSystem::Layers - Filesystem abstraction for Wrangler

=head1 DEVELOPER NOTES

The idea behind Layers is to look at an inode's metadata from an unbiased perspective.
That means, it tries to cover the fact that a file's/directory's properties usually
come from low-level stat() calls, or inspection of the xattr realm and may even
come from read()s to calculate a MIME-Type. But for a user, all what matters are the
resulting attributes, the metadata, and whether a certain property is settable
or not.

In a perfect world, this would be the end of it. But it's not that easy. Some properties
are simple key-value pairs, easily settable by straightforward system calls. Yet,
others are indirect results of other attributes, like a file's Basename, which is
hierarchically linked with the full Filename. Or setting mtime, or xattr, will result
in an update of atime, well, mostly.

All of this means, the logic in Layers has to deal with a lot of corner cases.
And although this incarnation of Layers in Wrangler's 2.x branch is already a rewrite,
yet another shot at tackling the problem, the initial concept is still not fully
realised, and the implementation logic is only halfway there. The current implementation
relies far too often on regular expressions. And it's internal hierarchy of figuring
out which system call should handle getting/setting a certain attribute is quite
simplistic. Also, an intended pluggable structure, in combination with the ability to
overlay same-level mounts in a unionfs/merged transparent way, is not yet there.
In sum, the efficiency of all this could be better, but at least for now, with some
of the GUI widgets compensating for or knowing about some of Layer's shortcomings,
it works. But for the record: it's a work-in-progress.

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.
