package uSAC::MIME;
use strict;
use warnings;
use version; our $VERSION=version->declare("v0.2.2");

#Private storage for the internal database
my $default_mime_to_ext;

sub load_from_handle {
	my ($self, $fh)=@_;
	for(<$fh>){
		tr/;//d;
		s/^\s+//;
		next if /^\s*#/;
		next if /^\s*$/;
		next if /{|}/;

		my @fields=split /\s+/;
		#first field is the mime type, remaining are extensions
		for my $ext (@fields[1..$#fields]){
			$self->add($ext=>$fields[0]);
		}
	}
}

sub save_to_handle {
	my ($self, $fh)=@_;
	my @keys= sort keys $self->%*;
	my $output="";
	for(@keys){
		$output.= "$_ ".$self->{$_}."\n";
	}
	print $fh $output;
}

sub new {
	my $package=shift//__PACKAGE__;
	my %additional=@_;
	my $self={$default_mime_to_ext->%*};
	bless $self, $package;

	for(keys %additional){
		$self->add($_, $additional{$_});
	}
	$self;
}

sub new_empty {
	my $package=shift//__PACKAGE__;
	my %additional=@_;
	my $self={};

	bless $self, $package;
	for(keys %additional){
		$self->add($_, $additional{$_});
	}
	$self;
}

sub new_from_file {
	#ignore any line with only one word, or   { or }
	my $package=shift//__PACKAGE__;
	my $path=shift;
	my $self={};
	bless $self, $package;
	my $res=open my $fh, "<" ,$path;
	unless($res){
		warn "could not read file: $path";
	}
	else {
		$self->load_from_handle($fh);
	}
	$self;
	
}


sub index{
	my $db=shift;
	my @tmp;
	my @tmp2;
	for my $mime (keys $db->%*){
		for($db->{$mime}){
			my $exts=[split " "];
			push @tmp, map {$_,$mime} @$exts;
			push @tmp2, $mime, $exts

		}
	}
	#first hash is forward map from extention to mime type
	#second hash is reverse map from mime to to array or extension
	if(wantarray){
		return ({@tmp},{@tmp2});
	}
	else {
		return {@tmp};
	}
}


#add an ext=>mime mapping. need to reindex after
#returns
sub add {
	my ($db,$ext,$mime)=@_;
	my $exts_string=$db->{$mime}//"";
	unless($exts_string=~/\b$ext\b/){
		my @items=split " ", $exts_string;
		push @items, $ext;
		$db->{$mime}=join " ", @items;
	}
	$db;
}


sub rem {
	my ($db,$ext,$mime)=@_;
	my $exts_string=$db->{$mime};
	return unless defined $exts_string;
	if($exts_string=~s/\b$ext\b//){
		$exts_string=~s/ +/ /;
		if($exts_string eq " "){
			delete $db->{mime};
		}
		else {
			$db->{$mime}=$exts_string;
		}
	}
	$db
}

#After this unit is compiled, initalise the default map with data from DATA file handle.
#This is then used in the new constructor

UNITCHECK{
	#Force loading of defaults
	my $dummy=uSAC::MIME->new_empty;
	$dummy->load_from_handle(\*DATA);
	$default_mime_to_ext={$dummy->%*};
}

1;


__DATA__
text/html                                        html htm shtml
text/css                                         css
text/xml                                         xml
image/gif                                        gif
image/jpeg                                       jpeg jpg
application/javascript                           js
application/atom+xml                             atom
application/rss+xml                              rss

text/mathml                                      mml
text/plain                                       txt
text/vnd.sun.j2me.app-descriptor                 jad
text/vnd.wap.wml                                 wml
text/x-component                                 htc

image/png                                        png
image/svg+xml                                    svg svgz
image/tiff                                       tif tiff
image/vnd.wap.wbmp                               wbmp
image/webp                                       webp
image/x-icon                                     ico
image/x-jng                                      jng
image/x-ms-bmp                                   bmp

font/ttf                                         ttf
font/woff                                        woff
font/woff2                                       woff2

application/java-archive                         jar war ear
application/json                                 json
application/mac-binhex40                         hqx
application/msword                               doc
application/pdf                                  pdf
application/postscript                           ps eps ai
application/rtf                                  rtf
application/vnd.apple.mpegurl                    m3u8
application/vnd.google-earth.kml+xml             kml
application/vnd.google-earth.kmz                 kmz
application/vnd.ms-excel                         xls
application/vnd.ms-fontobject                    eot
application/vnd.ms-powerpoint                    ppt
application/vnd.oasis.opendocument.graphics      odg
application/vnd.oasis.opendocument.presentation  odp
application/vnd.oasis.opendocument.spreadsheet   ods
application/vnd.oasis.opendocument.text          odt
application/vnd.openxmlformats-officedocument.presentationml.presentation
pptx
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
xlsx
application/vnd.openxmlformats-officedocument.wordprocessingml.document
docx
application/vnd.wap.wmlc                         wmlc
application/x-7z-compressed                      7z
application/x-cocoa                              cco
application/x-java-archive-diff                  jardiff
application/x-java-jnlp-file                     jnlp
application/x-makeself                           run
application/x-perl                               pl pm
application/x-pilot                              prc pdb
application/x-rar-compressed                     rar
application/x-redhat-package-manager             rpm
application/x-sea                                sea
application/x-shockwave-flash                    swf
application/x-stuffit                            sit
application/x-tcl                                tcl tk
application/x-x509-ca-cert                       der pem crt
application/x-xpinstall                          xpi
application/xhtml+xml                            xhtml
application/xspf+xml                             xspf
application/zip                                  zip
application/gzip				 gz

application/octet-stream                         bin exe dll
application/octet-stream                         deb
application/octet-stream                         dmg
application/octet-stream                         iso img
application/octet-stream                         msi msp msm

audio/midi                                       mid midi kar
audio/mpeg                                       mp3
audio/ogg                                        ogg
audio/x-m4a                                      m4a
audio/x-realaudio                                ra

video/3gpp                                       3gpp 3gp
video/mp2t                                       ts
video/mp4                                        mp4
video/mpeg                                       mpeg mpg
video/quicktime                                  mov
video/webm                                       webm
video/x-flv                                      flv
video/x-m4v                                      m4v
video/x-mng                                      mng
video/x-ms-asf                                   asx asf
video/x-ms-wmv                                   wmv
video/x-msvideo                                  avi
