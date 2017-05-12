package Video::Info::ASF;

use strict;
use constant DEBUG => 0;
our $VERSION = '1.01';

use Video::Info;

use base qw(Video::Info);

#########################################################
# ASF GUID signatures
#
#base ASF object guids
use constant Header                        => 0x75b22630;
use constant data                          => 0x75b22636;
use constant simple_index                  => 0x33000890;

#header object guids
use constant file_properties               => 0x8cabdca1;
use constant stream_properties             => 0xb7dc0791;
use constant stream_bitrate_properties     => 0x7bf875ce;
use constant content_description           => 0x75b22633;
use constant extended_content_encryption   => 0x298ae614;
use constant script_command                => 0x1efb1a30;
use constant marker                        => 0xf487cd01;
use constant header_extension              => 0x5fbf03b5;
use constant bitrate_mutual_exclusion      => 0xd6e229dc;
use constant codec_list                    => 0x86d15240;
use constant extended_content_description  => 0xd2d0a440;
use constant error_correction              => 0x75b22635;
use constant stream_bitrate_porperties     => 0x7bf875ce;
use constant padding                       => 0x1806d474;

#stream properties object stream type guids
use constant audio_media                   => 0xf8699e40;
use constant video_media                   => 0xbc19efc0;
use constant command_media                 => 0x59dacfc0;

#stream properties object error correction type guids
use constant no_error_correction           => 0x20fb5700;
use constant audio_spread                  => 0xbfc3cd50;

#mutual exclusion object exclusion type guids
use constant mutex_bitrate                 => 0xd6e22a01;
use constant mutex_unknown                 => 0xd6e22a02;

#from mplayer
use constant audio_conceal_none            => 0x49f1a440;
use constant header_2_0                    => 0xD6E229D1;
#########################################################

sub header {
  my $self = shift;
  my $val  = shift;
  return undef unless ref $self;
  return $self->{header} unless $val;
  $self->{header} = $val;
  return $val;
}

##------------------------------------------------------------------------
## probe()
##
## Obtain the filehandle from Video::Info and extract the properties from
## the ASF structure.
##------------------------------------------------------------------------
sub init {
  my $self = shift;

  $self->init_attributes(@_);
  return $self;
}

sub probe {
  my $self = shift;
  my $fh = $self->handle; ## inherited from Video::Info
  my $header;

  sysread($fh,$header,24);# or die "died probe(): $!";

  die "not an ASF" unless unpack("V",substr($header,0,4)) == Header;
  $self->type('ASF');
  my($h1,$h2) = unpack("VV",substr($header,16,8));
  my $headersize = ($h2 * 0xffffffff) + $h1;
  my $bytes = sysread($fh,$header,$headersize,24);
  die "probe() sysread: $!" unless $bytes = $headersize;
  #warn length($header);
  #exit;
  $self->header($header);

	my %guid = ();

	for(0..$headersize-5){
		my $window = substr($header,$_,4);

		$guid{codec_list}         = $_ if(unpack("V",$window)) == codec_list;
		$guid{header}             = $_ if(unpack("V",$window)) == Header;
		$guid{audio_media}        = $_ if(unpack("V",$window)) == audio_media;
		$guid{video_media}        = $_ if(unpack("V",$window)) == video_media;
		$guid{audio_conceal_none} = $_ if(unpack("V",$window)) == audio_conceal_none;
		$guid{audio_spread}       = $_ if(unpack("V",$window)) == audio_spread;
		$guid{content_description}= $_ if(unpack("V",$window)) == content_description;
		$guid{data}               = $_ if(unpack("V",$window)) == data;
		$guid{simple_index}       = $_ if(unpack("V",$window)) == simple_index;
		$guid{stream_properties}  = $_ if(unpack("V",$window)) == stream_properties;
		$guid{header_2_0}         = $_ if(unpack("V",$window)) == header_2_0;
		$guid{file_properties}    = $_ if(unpack("V",$window)) == file_properties;
	}

	my @guids = map {$_->[0]}	sort {$a->[1] <=> $b->[1]} map {[$_,$guid{$_}]} keys %guid;

	for(my $i=0;$i<scalar(@guids);$i++){
		my $thisguid = $guids[$i];
		my $nextguid = $guids[$i+1];
		#print $thisguid,"\t",$nextguid,"\n";

		my $thisguidpos = $guid{$thisguid};
		my $nextguidpos = $nextguid ? $guid{$nextguid} : length($header);

		my $head = substr($header,$thisguidpos,$nextguidpos - $thisguidpos - 1);

		my $guid   = unpack("V",substr($head,0,4));

		#warn "guid $thisguid: ".$thisguidpos."-".$nextguidpos;

		if($guid == Header){
			warn "Header" if DEBUG;
		  #noop yet.  we should switch modes depending on whether or not we have a 1.0 or 2.0 header
		} elsif($guid == header_2_0){
			warn "Header 2.0" if DEBUG;
			#no exmple yet
			die "header_2_0. Please email allenday\@ucla.edu";
		}

		elsif($guid == codec_list){
			warn "codec_list" if DEBUG;
			next unless length($head) >= 40; #prevent substr() errors on bad headers
			my($codecs) = unpack("V",substr($head,40,4));

			#print $head, "\n";

			#print "\ttotal codecs: $codecs\n";

			my $offset = 44;
			my $i = 0;
			while($i < $codecs){
				my($type,$namelen) = unpack("vv",substr($head,$offset,4)); $offset += 4;

				#print "\tcodec type: $type ";
				#print $type == 0x0000 ? "video\n"   :  #this is not standard by ASF 1.0
				#      $type == 0x0001 ? "video\n"   :
				#	  $type == 0x0002 ? "audio\n"   :
				#	  $type == 0xffff ? "unknown\n" : "huh?\n";

				$namelen *= 2; #because it is a unicode string
				my $name = substr($head,$offset,$namelen); $offset += $namelen;

				#print "\t\tname $namelen: $name\n";
				if($type == 0x0000 || $type == 0x0001){
				  $self->vcodec($self->vcodec || $name);
				  $self->vstreams( ($self->vstreams || 0) + 1);
				}

				if($type == 0x0002){
				  $self->acodec($name) unless $self->acodec;
				  $self->astreams( ($self->astreams || 0) + 1);
				}

				#we don't worry about these (for now)
				my($desclen) = unpack("v",substr($head,$offset,2));
				$desclen *= 2;
				my $desc = substr($head,$offset,$desclen); $offset += $desclen;
				#print "\t\tdesc: $desc\n";

				my($infolen) = unpack("v",substr($head,$offset,2));
				$infolen *= 2;
				my $info = substr($head,$offset,$infolen); $offset += $infolen;
				#print "\t\tinfo: $info\n";

				$i++;
			}
		}

		elsif($guid == file_properties){
			warn "file_properties" if DEBUG;
			next unless length($head) >= 32; #prevent substr() errors on bad headers

			my($size1,$size2,$date1,$date2,$count1,$count2,$dur1,$dur2) = unpack("VVVVVVVV",substr($head,40,32));
			my($maxbitrate) = unpack("V",substr($head,100,4));

			#these are 64bit values, so we have to put them together manually.
			#some systems (like mine) don't support q and Q unpacking.
			my $size  = ($size2 * 0xffffffff) + $size1;              #filesize in bytes
			my $date  = (($date2 * 0xffffffff) + $date1) / 1_000;    #creation time.  i have no idea what format --aday
			my $count = ($count2 * 0xffffffff)+ $count1;             #number of data packets in the data object
			my $dur   = (($dur2 * 0xffffffff) + $dur1) / 10_000_000; #was in 100 nanosecond units, zheesh

			#print "\tsize: $size\n";
			$self->date($date);
			#print "\tdate: ".$self->date."\n";
			$self->packets($count);
			#print "\tcount: ".$self->count."\n";
			$self->duration($dur);
			#print "\tduration: ".$self->duration."\n";
			$self->vrate($maxbitrate);
			#print "\tmax bitrate: ".$self->vrate."\n";
		}

		elsif($guid == content_description){
			warn "content_description" if DEBUG;
			next unless length($head) >= 34; #prevent substr() errors on bad headers
			my $offset = 34;
			my($titlelen,$authlen,$copylen,$desclen,$ratlen) = unpack("vvvvv",substr($head,24,10));
			my $title       = substr($head,$offset,$titlelen); $offset += $titlelen;
			my $author      = substr($head,$offset,$authlen);  $offset += $authlen;
			my $copyright   = substr($head,$offset,$copylen);  $offset += $copylen;
			my $description = substr($head,$offset,$desclen);  $offset += $desclen;
			my $rating      = substr($head,$offset,$ratlen);

			$self->title($title);
			$self->author($author);
			$self->copyright($copyright);
			$self->description($description);
			$self->rating($rating);
		}

		elsif($guid == video_media){
			warn "video_media" if DEBUG;
			next unless length($head) >= 16; #prevent substr() errors on bad headers

			my $codec = substr($head,81,4); #hack.  is it really at 81?  should be at 16 from 1.0 spec.
			$self->vcodec($codec);
			
			my($width,$height,$bpp,$colors) = unpack("VVxxvxxxxxxxxxxxxxxxxV",substr($head,54,32));

			$self->width($width);
			$self->height($height);

			#print "\tbpp: $bpp\n";
			#print "\tcompression ID: $codec\n";
			#print "\tcolors used: $colors\n";
		}

		elsif($guid == audio_spread || $guid == audio_media){
			warn "audio" if DEBUG;
			next unless length($head) >= 18; #prevent substr() errors on bad headers
			my($codecID,$achan,$samp,$bpsec,$blk,$bpsamp,$format) = unpack("vvVVvvv",substr($head,38,18));	

			#print "\tcodec ID: $codecID\n";
			#$self->acodec($codecID) unless $self->acodec; #???
			#print "\tcodec   : ".$self->acodec."\n";
			#print "\taudio channels: $achan\n";
			$self->achans($achan);
			#print "\tsample rate: $samp\n";
			#print "\tbytes/second: $bpsec\n";
			$self->arate($bpsec * 8);
			#print "\tblock alignment: $blk\n";
			#print "\tbits/sample: $bpsamp\n";
			#print "\tformat: $format\n";
			$self->acodec($format);
		}

		elsif($guid == script_command) {
			warn "script_command" if DEBUG;
		  #hmm, interesting
		  warn "*********************script_command";
#		  my($rawsize1,$rawsize2) = unpack("VV",substr($head,16,8));
#		  my $objsize = (($rawsize2 * 0xffffffff) + $rawsize1);
#		  my $obj = 
		}

		elsif($guid == stream_properties){
			warn "stream_properties" if DEBUG;
			#noop
		}

		elsif($guid == data){
			warn "data" if DEBUG;
			#noop, this is the movie itself
		}

		elsif($guid == simple_index){
			warn "simple_index" if DEBUG;
			#no example yet
			#warn "******************simple_index";
		}

		elsif($guid == audio_conceal_none){
			warn "audio_conceal_none" if DEBUG;
			#no example yet
			#warn "******************audio_conceal_none";
		}
	}

  return 1;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Video::Info::ASF - ASF files for attributes
like:

 -video codec
 -audio codec
 -frame height
 -frame width
 -frame count

and more!

=head1 SYNOPSIS

  use Video::Info::ASF;

  my $video;

  $video = Video::Info::ASF->new(-file=>$filename);                          #like this

  $video->vcodec;                         #video codec
  $video->acodec;                         #audio codec
  ...

=head1 DESCRIPTION

ASF stands for Advanced Systems Format, in case you were wondering.
It used to stand for Active Streaming Format, but Microsoft decided
to change it.  This type of file is primarily used to store audio &
video data for local or streaming playback.  It can also be embedded
with commands (to launch a web browser, for instance), for an "immersive"
experience.  ASF is similar in structure to RIFF. (See L<RIFF::Info>).
The morbidly curious can find out more below in I<REFERENCES>.

=head2 INHERITED METHODS

Video::Info::ASF is a subclass of Video::Info, a wrapper module designed to
meet your multimedia needs for many types of files.  As such, not all
methods available in Video::Info::ASF are documented here.

Video::Info::ASF has one constructor, new().  It is called as:
  -file       => $filename,   #your ASF file
Returns a Video::Info::ASF object if the file was opened successfully.

The Video::Info::ASF object to parses the file by method probe().  This
does a series of sysread()s on the file to figure out what the
properties are.

Now, call one (or more) of the Video::Info methods to get the 
low-down on your file.  See L<Video::Info>.

=head2 CLASS SPECIFIC METHODS

header() : returns the header section of the ASF file.

=head1 BUGS

Audio codec name mapping is incomplete.  If you know the name
that corresponds to an audio codec ID that I don't, tell me.

Some Video::Info methods are not honored, such as fps and vframes.
I haven't been able to figure out how to extract this information from
the ASF 1.0 spec.  Any information would be appreciated.

=head1 AUTHOR

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day <allenday@ucla.edu>

=head1 REFERENCES

mplayer - movie player for linux:
  http://www.mplayerhq.hu/homepage/

Microsoft ASF:
  http://www.microsoft.com/windows/windowsmedia/WM7/format/asfspec11300e.asp

=head1 SEE ALSO

 L<perl>
 L<Video::Info>
 L<RIFF::Info>

=cut
