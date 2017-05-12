package Wrangler::FileSystem::Linux;

# similar to the Filesys::Virtual API but with some additionas/ optimisations:
# list() returns an array-ref, and all dots
# xattr methods
# trash()

use strict;
use warnings;

use Carp;
use Cwd ();
use File::ExtAttr ();
use File::Path ();
use File::Basename ();
use File::Spec ();
use MIME::Types ();
use Encode;

sub new {
	my $class = shift;
 
	my $self = bless({ @_ }, $class);
  
	return $self;
}

##

sub cwd {
	return Cwd::cwd();
}

# for now, we even want to keep path translation tools in the FileSystem:: modules,
# that's why we have these additional two helpers here
sub fileparse {
	shift(@_);
	return File::Basename::fileparse(@_);
}
sub catfile {
	shift(@_);
	return File::Spec->catfile(@_);
}

sub available_properties {
	my ($self, $path, $args) = @_;
	$path = decode('UTF-8',$path);
	utf8::upgrade($path);

	my @keys;
	if($path){
		my %properties;
		for(@{ $self->list($path) }){
			for my $key (keys %$_ ){
				$properties{ $key } = 1;
			}
		}
		@keys = keys %properties;

		return \@keys;
	}

	return [
		'MIME::mediaType',
		'MIME::subType',
		'MIME::Type',
		'MIME::Description',
		'Filesystem::dev',
		'Filesystem::inode',
		'Filesystem::mode',
		'Filesystem::nlink',
		'Filesystem::uid',
		'Filesystem::gid',
		'Filesystem::rdef',
		'Filesystem::Size',
		'Filesystem::Accessed',
		'Filesystem::Modified',
		'Filesystem::Changed',
		'Filesystem::Blocksize',
		'Filesystem::Blocks',
		'Filesystem::Type',
		'Filesystem::Directory',
		'Filesystem::Path',
		'Filesystem::Filename',
		'Filesystem::Basename',
		'Filesystem::Suffix',
		'Filesystem::Hidden',
		'Filesystem::Xattr',	# numeric value; how many xattr keys are set; this should probably only be offered when xattr are set in a dir
	];
}

# my $regex_xattr = qr/xattr/i;
my $regex_dotfile = qr/^\./; # on Linux, the convention is .dotfiles are "hidden"
my $regex_updir = qr/\/\.\.$/;
my $regex_filesystem = qr/^Filesystem::/;
my $regex_filesystem_contains = qr/\bFilesystem::/;
my $regex_mime_contains = qr/\bMIME::/;
my $regex_xattr = qr/^Extended Attributes::/;
my $regex_xattr_contains = qr/\bExtended Attributes::/;
sub properties {
	my ($self, $path, $wishlist) = @_;

	$wishlist = undef if $wishlist && @$wishlist == 0;

	my (@filesystem,@stat,@fileparse,$type,$type_human);
	if(!$wishlist || 'Filesystem' ~~ @$wishlist || "@$wishlist" =~ $regex_filesystem_contains || 'MIME' ~~ @$wishlist){
		# print STDOUT "   ** properties:  -asks for Filesystem\n";
		# 0$dev,1$ino,2$mode,3$nlink,4$uid,5$gid,6$rdev,7$size,8$atime,9$mtime,10$chtime,11$blksize,12$blocks)
		@stat = CORE::lstat($path);

		if(-l _){
			@filesystem = (
				'Filesystem::Link'	=> 'Symlink',
				'Filesystem::LinkTarget' => CORE::readlink($path),
			);
			@stat = CORE::stat($path);
		}

		($type,$type_human) = inode_type_from_mode($stat[2]);
		@fileparse = File::Basename::fileparse($path,qr/\.[^.]*/);
		my $filename = ($fileparse[2] ? $fileparse[0].$fileparse[2] : $fileparse[0]);

		@filesystem = (
			'Filesystem::dev'	=> $stat[0],
			'Filesystem::inode'	=> $stat[1],
			'Filesystem::mode'	=> $stat[2],
			'Filesystem::nlink'	=> $stat[3],
			'Filesystem::uid'	=> $stat[4],
			'Filesystem::gid'	=> $stat[5],
			'Filesystem::rdef'	=> $stat[6],
			'Filesystem::Size'	=> $stat[7],
			'Filesystem::Accessed'	=> $stat[8],
			'Filesystem::Modified'	=> $stat[9],
			'Filesystem::Changed'	=> $stat[10],
			'Filesystem::Blocksize'	=> $stat[11],
			'Filesystem::Blocks'	=> $stat[12],
			'Filesystem::Type'	=> $type_human,
			'Filesystem::Path'	=> $path,
			'Filesystem::Directory'	=> $fileparse[1],
			'Filesystem::Filename'	=> $filename,
			'Filesystem::Basename'	=> $fileparse[0],
			'Filesystem::Suffix'	=> ($fileparse[2] ? substr($fileparse[2],1) : ''),
			'Filesystem::Hidden'	=> $filename ne '..' && $filename =~ $regex_dotfile ? 1 : 0,
			@filesystem
		);
	}

	my @mime;
	if(!$wishlist || 'MIME' ~~ @$wishlist || "@$wishlist" =~ $regex_mime_contains){
		# print STDOUT "   ** properties:  -asks for MIME\n";
		if($type eq '-' && $fileparse[2] && $stat[7] != 0){
			my ($mediaType,$subType,$mimeDesc) = type_from_ext($fileparse[2]);
			@mime = (
				'MIME::mediaType'	=> $mediaType,
				'MIME::subType'		=> $subType,
				'MIME::Type'		=> $mediaType.'/'.$subType
			);
			push(@mime, 'MIME::Description' => $mimeDesc || 'File');
		}elsif($type eq 'd'){
			@mime = (
				'MIME::mediaType'	=> 'inode',	# this is not a standard!
				'MIME::subType'		=> 'directory',
				'MIME::Type'		=> 'inode/directory',
				'MIME::Description'	=> 'Directory'
			);
		}
	}

	## are xattr part of Filesystem or not: that's tricky: they come from Filesys
	# and yet, they usually end up in a separate namespace, as they are not part
	# of traditional stat() return-values; here, we could treat them in a separate
	# driver, but on the other side, the get/set/list xattr calls are part of the
	# FUSE and POSIX filesystem-methods sets; so for now, we combine them in this
	# Filesystem::Linux properties() method, which is able to return both namespaces
	my (@xattr,@xattr_summary);
	# only poll xattr when no $wishlist is given (so getting xattr is the default), or in case $wishlist is given, skip when xattr is omitted
	if(!$wishlist || 'Extended Attributes' ~~ @$wishlist || 'Filesystem::Xattr' ~~ @$wishlist){
		my @keys = $self->listfattr($path);
		# print STDOUT "   ** properties:  -asks for all XATTR \n";
		for my $key ( @keys ){
			next unless $key;
			push(@xattr, 'Extended Attributes::'.$key => $self->getfattr($path, $key) );
		}
		@xattr_summary = ( 'Filesystem::Xattr'	=> scalar(@keys) );
	}elsif("@$wishlist" =~ $regex_xattr_contains){
		# print STDOUT "   ** properties:  -asks for selected XATTR \n";
		my @keys = grep { /$regex_xattr/ } @$wishlist;
		s/$regex_xattr// for @keys;
		for ( @keys ){
			next unless $_;
			my $value = $self->getfattr($path, $_) or next;	# getting undef means this attrib is not there, at all
			push(@xattr, 'Extended Attributes::'.$_ => $value );
		}
	}

	$path = $self->parent($path) if $path =~ $regex_updir; # at this point it's safe to clean up the path of the parent-dir

	my %properties = (
		@filesystem,
		@xattr_summary,
		@mime,
		@xattr
	);

	return \%properties;
}

sub list {
	my ($self, $path, $wishlist) = @_;
	$path = decode('UTF-8',$path);
	utf8::upgrade( $path );

	$wishlist = undef if $wishlist && @$wishlist == 0;

	my $ok = opendir(my $dh, Cwd::abs_path($path) ); # not perfect, see http://www.perlmonks.org/?node_id=655134
	 return bless([], 'error') unless $ok;
	 my @items = readdir($dh);
	closedir($dh);

	# strings coming from filesystem are probably utf8 (although we'd better check the system's locale)
	# transfer them to perl-internal
	for(@items){
		$_ = decode('UTF-8',$_);
		utf8::upgrade( $_ );
	}

	my @richlist;
	if($wishlist && "@$wishlist" eq 'Plain'){	# we'll see what the final name for "only dir contents, no stats, nothing" will be
		for(@items){
			# not optimal: we're doing partly the same as in properties here; what we should do
			# is distinguish in properties() between Filesystem:: metadata that requires us to do
			# a stat() and metadata that can be derived simply from the dir-item name, without IO.
			# For that, we probably have to rethink our vocabulary - if we need to add a special
			# "fast-track" $wishlist keyword or if we separate Filesystem:: by adding Filesystem::Stat::
			# or something like that. Until then (as these sceleton dir-listings are used so seldomly):
			my @fileparse = File::Basename::fileparse($path,qr/\.[^.]*/);
			my $filename = ($fileparse[2] ? $fileparse[0].$fileparse[2] : $fileparse[0]);
			push(@richlist, {
				'Filesystem::Type'	=> 'inode',
				'Filesystem::Path'	=> File::Spec->catfile($path, $_),
				'Filesystem::Directory'	=> $fileparse[1],
				'Filesystem::Filename'	=> $filename,
				'Filesystem::Basename'	=> $fileparse[0],
				'Filesystem::Suffix'	=> ($fileparse[2] ? substr($fileparse[2],1) : ''),
				'Filesystem::Hidden'	=> $filename ne '..' && $filename =~ $regex_dotfile ? 1 : 0,
			});
		}
	}else{
		for(@items){
			push(@richlist, $self->properties( File::Spec->catfile($path, $_), $wishlist )  );
		}
	}

	return \@richlist;
}

sub inode_type_from_mode {
	my $mode = shift;

	my @ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?);	# learn about ftypes for example from File-Stat-ModeString
	$ftype[0] = '';

	if(wantarray){
		my $type = $ftype[($mode & 0170000)>>12];
		my $type_human;
		if($type eq '-'){	# first few ordered by probability
			$type_human = 'File';
		}elsif($type eq 'd'){
			$type_human = 'Directory';
		}elsif($type eq 'l'){
			$type_human = 'Link';
		}elsif($type eq 'p'){
			$type_human = 'FIFO';
		}elsif($type eq 'l'){
			$type_human = 'Character Device';
		}elsif($type eq 'b'){
			$type_human = 'Block Device';
		}elsif($type eq '-'){
			$type_human = 'File';
		}elsif($type eq 's'){
			$type_human = 'Socket';
		}else{
			$type_human = '?';
		}
		return ($type, $type_human);
	}else{
		return $ftype[($mode & 0170000)>>12];
	}
}

## currently uses MIME::Types, alt:
## - File::Type, nice but would need tweaks to handle filehandles (which we need for remote objects etc)
## - Media::Type::Simple allows an extension of the internal db
my $videosuffixes = qr/\.avi$|\.mpeg$|\.mpg$|\.m2v$|\.asf$|\.wmv$|\.mov$|\.rm$|\.flv$|\.ogg$|\.mkv$|\.mp4$|\.h264|\.webm|\.on2|\.3gp$|\.3g2$|\.mxf$|\.m2t$|\.vob$/i;
my $imagesuffixes = qr/\.ani$|\.cr2$|\.gif$|\.jls$|\.jpeg$|\.jpg$|\.thm$|\.jp2$|\.jpe$|\.jpx$|\.png$|\.pcx$|\.pnm$|\.tif$|\.pbm$|\.pgm$|\.pnm$|\.psd$|\.ppd$|\.ppm$|\.bmp$|\.xbm$|\.xpm$|\.rle$|\.tga$|\.tif$|\.iff$|\.ico$|\.cur$|\.raw$|\.dcr$/i;
my $audiosuffixes = qr/\.wav$|\.aiff$|\.mp3$|\.ogg$|\.mka$|\.flac$|\.aac$|\.mid$|\.mpa$|\.au$|\.ram$|\.smp$|\.ape$|\.gsm$/i;
my $textsuffixes  = qr/\.txt$|\.py$|\.pl$|\.mk$|\.pod$/i;
my $mt = MIME::Types->new;
my $regex_dot_first = qr/^\./;
sub type_from_ext {
	my $suffix = shift;
	my $ext = $suffix =~ $regex_dot_first ? substr($suffix,1) : $suffix;

	my ($mediaType,$subType,$mimeDesc) = ('unknown','unknown','');

	if($mediaType = $mt->mimeTypeOf($suffix)){
		($mediaType,$subType) = split(/\//,$mediaType,2);
	}else{
		if($suffix =~ $videosuffixes){
			$mediaType = 'video';
		}elsif($suffix =~ $imagesuffixes){
			$mediaType = 'image';
		}elsif($suffix =~ $audiosuffixes){
			$mediaType = 'audio';
		}elsif($suffix =~ $textsuffixes){
			$mediaType = 'text';
		}else{
			$mediaType = 'unknown'; # mediaType might have been reset by mimeTypeOf call above
		}
	}

	$ext = lc($ext);
	if(defined($Wrangler::FileSystem::Layers::exts{$ext})){
		if( ref($Wrangler::FileSystem::Layers::exts{$ext}) ){
			$mimeDesc = $Wrangler::FileSystem::Layers::exts{$ext}->[0];
			($mediaType,$subType) = split(/\//,$Wrangler::FileSystem::Layers::exts{$ext}->[1],2);
		}else{
			$mimeDesc = $Wrangler::FileSystem::Layers::exts{$ext};
		}
	}else{
		if($mediaType eq 'audio'){
			$mimeDesc = uc($ext) .'-'.'Audiofile';
		}elsif($mediaType eq 'image'){
			$mimeDesc = uc($ext) .'-'.'Imagefile';
		}elsif($mediaType eq 'video'){
			$mimeDesc = uc($ext) .'-'.'Videofile';
		}else{
			$mimeDesc = uc($ext) .'-'. 'File';
		}
	}

	return ($mediaType,$subType,$mimeDesc);
}

##

sub mount {
	my ($self, %cfg) = @_;

	$self->{driveletter}	= undef;		# nothing as a driveletter on *nix
	$self->{username}	= $cfg{username};
	$self->{password}	= $cfg{password};
}

sub parent {
	shift(@_);
	return Cwd::abs_path( $_[0] ) if $_[0] =~ $regex_updir;
	return Cwd::abs_path( File::Spec->catfile($_[0],'..') ); # see note on abs_path in list()
}

## these low level tests should probably all return a warning: "use 'properties()' instead!"
sub test {
	my ($self, $test, $path) = @_;

	# $path =~ s/'/\\'/g;
	# $test =~ s/^(.)/$1/;

	my $ret = eval("-$test '$path'");
	return ($@) ? undef : $ret;
}
sub stat {
	my ($self, $path) = @_;
				
	# $path =~ s/\s+/ /g;
	# $path = $self->_path_from_root($path);

	return CORE::stat($path);
}
sub lstat {
	my ($self, $path) = @_;
				
	# $path =~ s/\s+/ /g;
	# $path = $self->_path_from_root($path);

	return CORE::lstat($path);
}

sub symlink {
	my ($self, $old, $new) = @_;
	# $dir = $self->_path_from_root($dir);
	# print STDOUT " Linux::symlink(@_) \n";

	return CORE::symlink($old, $new);
}

sub mknod {
	# note: could be replace with Unix::Mknod
	# todo: does not use mode/dev
#	my $result = open(my $fh,'>', $_[0]);
#	close($fh);
	my $self = shift;
	# print "mknod(@_)\n";
	return 0 if -e $_[0];
	my $result = system('touch',@_); # return 0 on success, -1 or similar on error
	return $result == 0 ? 1 : 0;	 # mknod returns 1 on success
}

sub delete {
	my ($self, $path) = @_;
	# $path = $self->_path_from_root($path);
	# print "mknod(@_)\n";
	return ((-e $path) && (!-d $path) && (CORE::unlink($path))) ? 1 : 0;
}

sub mkdir {
	my ($self, $dir) = @_;
	# $dir = $self->_path_from_root($dir);

	return 2 if (-d $dir);
	
	return CORE::mkdir($dir);
}

sub rmdir {
	my ($self, $path, $recursive) = @_;

	if (-e $path) {
		if (-d $path) {
			if($recursive){
				# todo: support for recycle bin!
				return 1 if (File::Path::rmtree($path));
			}else{
				return 1 if (CORE::rmdir($path));
			}
		}
		## Filesys::Virtual optionally does a file unlink, we won't
	}

	return 0;
}

# move a file/dir to undo'able trash can
# see also: File::Trash::FreeDesktop, File::Trash::Undoable, File::Remove 
sub trash {
	my $self = shift;

	# don't allow empty values in list of supplied paths, because gvfs-trash would accept that as "current dir"
	for(@_){ return 0 if $_ eq ''; }

	my $result = system('gvfs-trash', @_); # return 0 on success, -1 or similar on error
	# print "trash(@_): $result\n";
	return $result == 0 ? 1 : 0;	 # mknod returns 1 on success
}

sub rename {
	my ($self, $path, $new) = @_;
	# print "rename(@_)\n";
	## todo: check if this is a 'rename' or a 'move' across filesystem boundaries
	return CORE::rename($path,$new);
}

sub move {
	my $self = shift;
	# print "move(@_)\n";
	return 0 if !-e $_[0];
	my $result = system('mv',@_);	# return 0 on success, -1 or similar on error
	return $result == 0 ? 1 : 0;	# move returns 1 on success
}

sub copy {
	my $self = shift;
	# print "copy(@_)\n";
	return 0 if !-e $_[0];
	my $result = system('cp','-R',@_); # return 0 on success, -1 or similar on error
	return $result == 0 ? 1 : 0;	 # copy returns 1 on success
}

sub utime {
	my ($self, $atime, $mtime, @path) = @_;

#	foreach my $i ( 0 .. $#path ) {
#		$path[$i] = $self->_path_from_root($path[$i]);
#	}
	
	return CORE::utime($atime, $mtime, @path);
}

sub listfattr {
	my ($self, $path) = @_;

	my @attr_list = File::ExtAttr::listfattr($path);

	# more recent WxWidgets expect decoded/Perl-internal'ed strings
	# Mark's note: http://grokbase.com/t/perl/wxperl-users/134pn2zyr7/can-we-print-utf-8-chars-in-wx-textctrl-fields#20130429gjrtttc5l3q6zxegl7hgngxwwa
	for(@attr_list){
		# we keep values in Perl-internal
		utf8::upgrade( $_ );
	}

	return @attr_list;
}

sub getfattr {
	my ($self, $path, $key) = @_;

	# we return values from the 'user.' namespace only, for now (and we omit the 'user.' prefix in keys)
	my $value = File::ExtAttr::getfattr($path, $key, { namespace => 'user' });

	# xattr are encoding agnostic, means they simply store bytes.
	# It's on us to store it in a useful encoding: we decide for utf-8
	if( defined($value) ){
		$value = decode('utf-8', $value);
		utf8::upgrade($value);	# Mark's note: http://grokbase.com/t/perl/wxperl-users/134pn2zyr7/can-we-print-utf-8-chars-in-wx-textctrl-fields#20130429gjrtttc5l3q6zxegl7hgngxwwa
	}

	# more recent WxWidgets expect decoded/Perl-internal'ed strings
#	return $value ? decode_utf8($value) : $value; # test for undef
	return $value;
}

sub setfattr {
	my ($self, $path, $key, $value) = @_;

	# It's on us to store it in a useful encoding: we decide for utf-8
	File::ExtAttr::setfattr($path, encode('utf-8',$key), encode('utf-8',$value), { namespace => 'user' });
#	File::ExtAttr::setfattr($path, $key, $value, { namespace => 'user' });
}

sub delfattr {
	my ($self, $path, $key) = @_;

	File::ExtAttr::delfattr($path, encode('utf-8',$key), { namespace => 'user' });
}

1;
