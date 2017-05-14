package MP3::TAG::ID3v2;

use strict;
use MP3::TAG::ID3v1;
use Compress::Zlib;

use vars qw /%format %long_names/;

=pod

=head1 NAME

MP3::TAG::ID3v2 - Read / Write ID3v2.3 tags from MP3 audio files

=head1 SYNOPSIS

MP3::TAG::ID3v2 is designed to be called from the MP3::Tag module.
It then returns a ID3v2-tag-object, which can be used in a users
program.

  $id3v2 = MP3::TAG::ID3v2->new($mp3obj);

C<$mp3obj> is a object from MP3::Tag. See according documentation.
C<$tag> is undef when no tag is found in the C<$mp3obj>.

* Reading a tag

  @frameIDs = $id3v2->getFrameIDS;

  foreach my $frame (@frameIDs) {
    my ($info, $name) = $id3v2->getFrame($frame);
    if (ref $info) {
      print "$name ($frame):\n";
      while(my ($key,$val)=each %$info) {
	print " * $key => $val\n";
      }
    } else {
      print "$name: $info\n";
    }
  }

* Changing / Writing a tag

  $id3v2->add_frame("TIT2", "Title of the song");
  $id3v2->change_frame("TALB","Greatest Album");
  $id3v2->remove_frame("TLAN");

  $id3v2->write_tag();

* Get information about supported frames

  %tags = $id3v2->supported_frames();
  while (($fname, $longname) = each %tags) {
      print "$fname $longname: ", 
            join(", ", @{$id3v2->what_data($fname)}), "\n";
  }

=head1 AUTHOR

Thomas Geffert, thg@users.sourceforge.net

=head1 DESCRIPTION

=over 4

=item new()

  $tag = new($mp3obj);

C<new()> needs as parameter a mp3obj, as created by C<MP3::Tag> (see documentation
of MP3::Tag).
C<new> tries to find a ID3v2 tag in the mp3obj. If it does not find a tag it returns undef.
Otherwise it reads the tag header, as well an extended header, if available. It reads the
rest of the tag in a buffer, does unsynchronizing if neccessary, and returns a ID3v2-object.
At this moment only ID3v2.3 is supported. Any extended header with CRC data is ignored, so
not CRC check is done at the moment.
The ID3v2-object can then be used to extract information from the tag.  

=cut
  
sub new {
  my $class = shift;
  my $mp3obj = shift;
  my $create = shift;
  my $self={mp3=>$mp3obj};
  my $header=0; my @size;
  bless $self, $class;
  
  $mp3obj->seek(0,0);
  $mp3obj->read(\$header, 10);
  $self->{frame_start}=0;

  if ($self->read_header($header)) {
    if (defined $create && $create) {
      $self->{tag_data} = '';
      $self->{data_size} = 0;
    } else {
      $mp3obj->read(\$self->{tag_data}, $self->{tagsize});
      $self->{data_size} = $self->{tagsize};
      # un-unsynchronize
      if ($self->{flags}->{unsync}) {
	my $hits= $self->{tag_data} =~ s/\xFF\x00/\xFF/gs;
	$self->{data_size} -= $hits;
      }
      # read the ext header if it exists
      if ($self->{flags}->{extheader}) {
	unless ($self->read_ext_header(substr ($self->{tag_data}, 0, 14))) {
	  return undef; # ext header not supported
	} 
      }
    }
    return $self;
  } else {
    if (defined $create && $create) {
      $self->{tag_data}='';
      $self->{tagsize} = -10;
      $self->{data_size} = 0;
      return $self;
    } 
  }
  return undef;
}

=pod

=item getFrameIDs()

  @frameIDs = $tag->getFrameIDs;

getFrameIDs loops through all frames, which exist in the tag. It returns a
list of all available Frame IDs. These are 4-character-codes (short names),
the internal names of the frames.

You can use this list to iterate over all frames to get their data, or to
check if a specific frame is included in the tag.

If there are multiple occurences of a frame in one tag, the first frame is
returned with its normal short name, following frames of this type get a
'00', '01', '02', ... appended to this name. These expanded names can then
used with C<getFrame> to get the information of these frames.

=cut

sub getFrameIDs {
  my $self=shift;
  return if exists $self->{frameIDs};
  my $pos=$self->{frame_start}; 
  if ($self->{flags}->{extheader}) {
    warn "getFrameIDs: possible wrong IDs because of unsupported extended header\n";
  }
  my $buf;
  while ($pos+10 < $self->{data_size}) {
    $buf = substr ($self->{tag_data}, $pos, 10);
    my ($ID, $size, $flags) = unpack("a4Nn", $buf);
    if ($size>255) {
      # Size>255 means at least 2 bytes are used for size.
      # Some programs use (incorectly) also for this size
      # the format of the tag size. Trying do detect that here
      if ($pos+10+$size> $self->{data_size} || 
	  !exists $long_names{substr ($self->{tag_data}, $pos+$size,4)}) {
	# wrong size or last frame
	my $fsize=0;
	foreach (unpack("x4C4", $buf)) {
	  $fsize = ($fsize << 7) + $_;
	}
	if ($pos+20+$fsize<$self->{data_size} && 
	    exists $long_names{substr ($self->{tag_data}, $pos+10+$fsize,4)}) {
	  warn "Probably wrong size format found in frame $ID. Trying to correct it\n";
	  #probably false size format detected, using corrected size
	  $size = $fsize;
	}
      }
    }
    if ($ID ne "\000\000\000\000") {
      if (exists $self->{frames}->{$ID}) {
	$ID .= '01';
	while (exists $self->{frames}->{$ID}) {
	  $ID++;
	}
      }
      printf ("%s @ %s for %s (%x)\n", $ID, $pos, $size, $flags) if 1==0;
      $self->{frames}->{$ID} = {start=>$pos+10, size=>$size, flags=>$flags};
      $pos += $size+10;
    } else { # Padding reached, cut tag data here
      last;
    }
  }
  # cut off padding
  $self->{tag_data}=substr $self->{tag_data}, 0, $pos;

  $self->{frameIDs} =1;
  return keys %{$self->{frames}};
}

=pod

=item getFrame()

  ($info, $name) = getFrame($ID);
  ($info, $name) = getFrame($ID, 'raw');

getFrame gets the contents of a specific frame, which must be specified by the
4-character-ID (aka short name). You can use C<getFrameIDs> to get the IDs of
the tag, or use IDs which you hope to find in the tag. If the ID is not found, 
getFrame returns (undef, undef).

Otherwise it extracts the contents of the frame. Frames in ID3v2 tags can be
very small, or complex and huge. That is the reason, that getFrame returns
the frame data in two ways, depending on the tag.

If it is a simple tag, with only one piece of data, this date is returned
directly as ($info, $name), where $info is the text string, and $name is the
long (english) name of the frame.

If the frame consist of different pieces of data, $info is a hash reference, 
$name is again the long name of the frame.

The hash, to which $info points, contains key/value pairs, where the key is 
always the name of the data, and the value is the data itself.

If the name starts with a underscore (as eg '_code'), the data is probably
binary data and not printable. If the name starts without an underscore,
it should be a text string and printable.

If there exists a second parameter like raw, the whole frame data is returned,
but not the frame header. If the data was stored compressed, it is also in
raw mode uncompressed before it is returned. Then $info contains a string
with all data (which might be binary), and $name against the long frame name.

! Encrypted frames are not supported yet !

! Some frames are not supported yet, but the most common ones are supported !

=cut

sub getFrame {
  my ($self, $fname, $raw)=@_;
  $self->getFrameIDs() unless exists $self->{frameIDs};
  return undef unless exists $self->{frames}->{$fname};
  my $frame=$self->{frames}->{$fname};
  my $frame_flags = check_flags($frame->{flags},$fname); 
  $fname = substr ($fname, 0 ,4);
  my $start_offset=0;
  if ($frame_flags->{encryption}) {
    warn "Frame $fname: encryption not supported yet\n" ;
    return undef;
  }
  if ($frame_flags->{groupid}) {
    # groupid is ignored at the moment
    $start_offset=1;
  }
  my $data = substr($self->{tag_data}, $frame->{start}+$start_offset, $frame->{size}-$start_offset);
  if ($frame_flags->{compression}) {
    my $usize=unpack("N", $data);
    $data = uncompress(substr ($data, 4));
    warn "$fname: Wrong size of uncompressed data\n" if $usize=!length($data);
  }
  return ($data, $long_names{$fname}) if defined $raw;

  my $format = getformat($fname);
  my $result;
  $result = extract_data($data, $format) if defined $format;
  if (scalar keys %$result ==1 && exists $result->{Text}) {
    $result= $result->{Text};
  } 
  if (wantarray) {
    return ($result, $long_names{$fname});
  } else {
    return $result;
  }
}

=pod

=item write_tag()

  $id3v2->write_tag;

Saves a frame to the file. It tries to update the file in place, 
when the space of the old tag is big enoug for the new tag.
Otherwise it creates a temp file (i.e. copies the whole mp3 file)
and renames/moves it to the original file name.

An extended header with CRC checksum is not supported yet.

At the moment the tag is automatically unsynchronized.

=cut 

sub write_tag {
  my $self = shift;
  my $n = chr(0);

  # perhaps search for first mp3 data frame to check if tag size is not
  # too big and will override the mp3 data

  # unsync ? global option should be good
  # unsync only if  MPEG 2 layer I, II and III or MPEG 2.5 files.
  # do it twice to do correct unsnyc if several FF are following eachother
  $self->{tag_data} =~ s/\xFF([\x00\xE0-\xFF])/\xFF\x00$1/gos;
  $self->{tag_data} =~ s/\xFF([\xE0-\xFF])/\xFF\x00$1/gos;

  #ext header are not supported yet

  #convert size to header format specific size
  my $size = unpack('B32', pack ('N', $self->{tagsize}));
  substr ($size, -$_, 0) = '0' for (qw/28 21 14 7/);
  $size= pack('B32', substr ($size, -32));
  
  my $flags = chr(128); # unsync
  my $header = 'ID3' . chr(3) . chr(0);

  # actually write the tag

  my $mp3obj = $self->{mp3};  

  if (length ($self->{tag_data}) <= $self->{tagsize}) {
    # new tag can be writte in space of old tag
    $mp3obj->close;
    if ($mp3obj->open("+<")) {
      $mp3obj->seek(0,0);
      $mp3obj->write($header);
      $mp3obj->write($flags);
      $mp3obj->write($size);
      $mp3obj->write($self->{tag_data});
      $mp3obj->write($n x ($self->{tagsize} - length ($self->{tag_data})));
    } else {
      warn "Couldn't write tag!";
      return undef;
    } 
  } else {
    my $tempfile = '/tmp/tmp.mp3'; #BETTER: try first to use same dir
    if (open (NEW, ">$tempfile")) {
      my $padding = 256; # BETTER: calculate padding depending on mp3 size to 
                         #         fit to 4k cluster size
      my $size = unpack('B32', pack ('N', length($self->{tag_data})+$padding));
      substr ($size, -$_, 0) = '0' for (qw/28 21 14 7/);
      $size= pack('B32', substr ($size, -32));
      print NEW $header, $flags, $size, $self->{tag_data}, $n x $padding;
      my $buf;
      $mp3obj->seek($self->{tagsize}+10,0);
      while ($mp3obj->read(\$buf,16384)) {
	print NEW $buf;
      }
      close NEW;
      $mp3obj->close;
      system("mv",$tempfile,$mp3obj->{filename}) 
	unless rename $tempfile, $mp3obj->{filename};
    } else {
      warn "Couldn't write tag!";
      return undef;
    }
  }
  return 1;
}

=pod

=item remove_tag()

  $id3v2->remove_tag();

Removes the whole tag from the file by copying the whole
mp3-file to a temp-file and renaming/moving that to the
original filename.

=cut 

sub remove_tag {
  my $self = shift;
  my $mp3obj = $self->{mp3};  
  my $tempfile = '/tmp/tmp.mp3'; #BETTER: try first to use same dir
    if (open (NEW, ">$tempfile")) {
      my $buf;
      $mp3obj->seek($self->{tagsize}+10,0);
      while ($mp3obj->read(\$buf,16384)) {
	print NEW $buf;
      }
      close NEW;
      $mp3obj->close;
      system("mv",$tempfile,$mp3obj->{filename}) 
	unless rename $tempfile, $mp3obj->{filename};
    } else {
      warn "Couldn't write temp file\n";
      return undef;
    }
  return 1;
}

=pod

=item add_frame()

  $id3v2->add_frame($fname, @data);

Add a new frame, identified by the short name $fname. 
The $data must consist from so much elements, as described
in the ID3v2.3 standard. If there is need to give an encoding
parameter and you would like standard ascii encoding, you
can omit the parameter or set it to 0. Any other encoding
is not supported yet, and thus ignored. 

Examples:

 add_frame("TIT2", 0, "Abba");   # both the same, but
 add_frame("TIT2", "Abba");      # this one with implicit encoding
 add_frame("COMM", "ENG", "Short text", "This is a comment");

=cut 

sub add_frame {
  my ($self, $fname, @data) = @_;
  $self->getFrameIDs() unless exists $self->{frameIDs};
  my $format = getformat($fname);
  return undef unless defined $format;

  #prepare the data
  my $args = $#$format;

  # encoding is not used yet
  my $encoding=0;
  my $defenc=1 if (($#data == ($args - 1)) && ($format->[0]->{name} eq "_encoding"));
  return 0 unless $#data == $args || defined $defenc;

  my $datastring="";
  foreach my $fs (@$format) {
    if ($fs->{name} eq "_encoding") {
      $encoding = shift @data unless $defenc;
      warn "Encoding of text not supported yet\n" if $encoding!=0;
      $encoding = 0; # other values are not used yet, so let's not write them in a tag
      $datastring .= chr($encoding);
      next;
    }
    my $d = shift @data;
    if ($fs->{len}>0) {
      $d = substr $d, 0, $fs->{len};
    }elsif ($fs->{len}==0) {
      $d .= chr(0);
    }
    $datastring .= $d;
  }
  #encrypt or compress data if this is wanted

  #prepare header
  my $flags = 0;
  my $header = $fname . pack("Nn", length ($datastring), $flags);

  #add frame to tag_data
  my $pos =length($self->{tag_data})+1;
  $self->{tag_data} .= $header . $datastring;

  if (exists $self->{frames}->{$fname}) {
    $fname .= '01';
    while (exists $self->{frames}->{$fname}) {
      $fname++;
    }
  }
  printf ("%s @ %s for %s (%x)\n", $fname, $pos, length($datastring), $flags) if 0==1;
  $self->{frames}->{$fname} = {start=>$pos+10, size=>length($datastring), flags=>$flags};

  return 1;
}

=pod

=item change_frame()

  $id3v2->change_frame($fname, @data);

Change an existing frame, which is identified by its
short name $fname. @data must be same as in add_frame;

=cut 

sub change_frame {
  my ($self, $fname, @data) = @_;
  $self->getFrameIDs() unless exists $self->{frameIDs};
  return undef unless exists $self->{frames}->{$fname};

  $self->remove_frame($fname);
  $self->add_frame($fname, @data);

  return 0;
}

=pod

=item remove_frame()

  $id3v2->remove_frame($fname);

Remove an existing frame. $fname is the short name of a frame,
eg as returned by C<getFrameIDs>.

=cut 

sub remove_frame {
  my ($self, $fname) = @_;
  $self->getFrameIDs() unless exists $self->{frameIDs};
  return undef unless exists $self->{frames}->{$fname};
  my $start = $self->{frames}->{$fname}->{start}-10;
  my $size = $self->{frames}->{$fname}->{size}+10;
  substr ($self->{tag_data}, $start, $size) = "";
  delete $self->{frames}->{$fname};
  foreach (keys %{$self->{frames}}) {
    $self->{frames}->{$_}->{start} -= $size
      if ($self->{frames}->{$_}->{start}>$start);
  }
  return 1;
}

=pod

=item supported_frames()

  %frames = $id3v2->supported_frames();

Returns a hash with all supported frames. The keys of the
hash are the short names of the supported frames, the 
according values are the long (english) names of the frames.

=cut

sub supported_frames {
  my $self = shift;

  my (%tags, $fname, $lname);
  while ( ($fname, $lname) = each %long_names) {
    $tags{$fname} = $lname if getformat($fname, "quiet");
  }

  return \%tags;
}

=pod 

=item what_data()

  @data = $id3v2->what_data($fname);

Returns for a frame the needed data fields to write this tag.
At this moment only the internal field names are returned,
without any additional information about the data format of
this field. Names beginning with an underscore (normally '_data')
can contain binary data. 

This will change hopefully later on...

=cut

sub what_data{
  my $self=shift;
  my $format = getformat(shift, "quiet");
  return unless defined $format;
  my @data;

  foreach (@$format) {
    push @data, $_->{name};
  }

  return \@data;
}

################## 
##
## internal subs
##

# This sub tries to read the header of an ID3v2 tag and checks for the right header
# identification for the tag. It reads the version number of the tag, the tag size
# and the flags.
# Returns true if it finds a ID3v2.3 header, false otherwise.

sub read_header {
  my ($self, $header) = @_;
  my %params;

  if (substr ($header,0,3) eq "ID3") {
    # extract the header data
    my ($version, $subversion, $pflags) = unpack ("x3CCC", $header);
    # check the version
    if ($version != 3 || $subversion != 0) {
      warn "Unknown ID3v2-Tag version: V$version.$subversion\n";
      return 0;
    }
    # get the tag size
    my $size=0;
    foreach (unpack("x6C4", $header)) {
      $size = ($size << 7) + $_;
    }
    # check the flags
    my $flags={};
    my $unknownFlag=0; 
    my $i=0;
    foreach (split (//, unpack('b8',pack('v',$pflags)))) {
      if ($_) {
	if ($i==7) {
	  $flags->{unsync}=1;
	} elsif ($i==6) {
	  $flags->{extheader}=1;
	} elsif ($i==5) {
	  $flags->{experimental}=1;
	  warn "Flag: Experimental not supported\n      But trying to read the tag...\n";
	} else {
	  $unknownFlag = 1;
	  warn "Unsupported flag: Bit $i set in Header-Flags\n";
	}
      }
      $i++;
    }
    return 0 if $unknownFlag;
    $self->{version} = "V$version.$subversion";
    $self->{tagsize} = $size;
    $self->{flags} = $flags;
    return 1;
  }
  return 0; # no ID3v2-Tag found
}

# Reads the extended header and adapts the internal counter for the start of the
# frame data. Ignores the rest of the ext. header (as CRC data).

sub read_ext_header {
  my ($self, $ext_header) = @_;
  # flags, padding and crc ignored at this time
  my $size = unpack("N", $ext_header);
  $self->{frame_start} += $size+4; # 4 bytes extra for the size
  return 1;
}


# Main sub for getting data from a frame.

sub extract_data {
  my ($data, $format) = @_;
  my ($rule, $found,$encoding, $result);

  foreach $rule (@$format) {
    $encoding=0;
    # get the data
    if ( $rule->{len} == 0 ) {
      if (exists $rule->{encoded} && $encoding !=0) {
	($found, $data) = split /\x00\x00/, $data, 2;
      } else {
	($found, $data) = split /\x00/, $data, 2;
      }
    } elsif ($rule->{len} == -1) {
      ($found, $data) = ($data, "");
    } else {
      $found = substr $data, 0,$rule->{len};
      substr ($data, 0,$rule->{len}) = '';
    }

    # was data found?
    unless (defined $found && $found ne "") {
      $found = "";
      $found = $rule->{default} if exists $rule->{default};
    }
    # work with data
    if ($rule->{name} eq "_encoding") {
      $encoding=unpack ("C", $found);
    } else {
      if (exists $rule->{encoded} && $encoding != 0) {
	# decode data
	warn "Encoding not supported yet: found in $rule->{name}\n";
	next;
      }

      $found = $rule->{func}->($found) if (exists $rule->{func});

      unless (exists $rule->{data}) {
	$found =~ s/[\x00]+$//;   # some progs pad text fields with \x00
	$found =~ s![\x00]! / !g; # some progs use \x00 inside a text string to seperate text strings
	$found =~ s/ +$//;        # no trailing spaces after the text
      }

      if (exists $rule->{re2}) {
	while (my ($pat, $rep) = each %{$rule->{re2}}) {
	  $found =~ s/$pat/$rep/gis;
	}
      }
      # store data
      $result->{$rule->{name}}=$found;
    } 
  }
  return $result;
}

#Searches for a format string for a specified frame. format strings exist for
#specific frames, or also for a group of frames. Specific format strings have
#precedence over general ones.

sub getformat {
  my $fname = shift;
  # to be quiet if called from supported_frames or what_data
  my $quiet = shift;
  my $fnamecopy = $fname;
  while ($fname ne "") {
    return $format{$fname} if exists $format{$fname};
    substr ($fname, -1) =""; #delete last char
  }
  warn "Unknown Frame-Format found: $fnamecopy\n" unless defined $quiet;
  return undef;
}

#Reads the flags of a frame, and returns a hash with all flags as keys, and 
#0/1 as value for unset/set.

sub check_flags {
  # how to detect unknown flags?
  my ($flags,$fname)=@_;
  my %flags;
  my @flags = split (//, reverse unpack('b16',pack('v',$flags)));
  $flags{tag_preserv}= $flags[0];
  $flags{file_preserv}= $flags[1];
  $flags{read_only}= $flags[2];
  $flags{compression}= $flags[8];
  $flags{encryption}= $flags[9];
  $flags{groupid}= $flags[10];
  return \%flags;
}

sub DESTROY {
}

##################################
#
# How to store frame formats?
#
# format{fname}->[i]->{xxx}
#
# i - von 0 - ... in der Reihenfolge, in der die bestandteile des frames ausgelesen werden sollen
#
#  xxx =   * {len}=s reg expr pattern  - gibt an, wieviele zeichen gelesen werden sollen
#                                        spezialfälle: 0 = lesen bis \x00
#                                                     -1 = alle restlichen zeichen lesen
#          * {name}=s - name unter der bestandteil an benutzer zurueckgegeben wird, aber:
#                     name = encoding - wird nicht zurueckgegeben, sondern setzt encoding fuer diesen frame
#          * {encoded}=1   - das ergebnis laut encoding codieren
#          * {func}=s - reference auf funktion. diese funktion erhält den gefunden Wert als Argument, und
#                       einen neuen Wert zurückgeben
#          * {re2}=s - hash, das reg expr enthaelt, die vor rueckgabe an benutzer angewendet werden (anwendung
#                      nachdem {func} aufgerufen wurde)
#
#          * {data}=1 - gibt an, dass binary data im feld enthalten sein kann (auch nachdem evtl. func aufgerufen wurde)
#
#          * {default}=s - default fuer feld, falls feld leer oder nicht gefunden
#
# TCON example:
# 
# $format{TCON}->[0]->{len}      = 1
#                   ->{name}     = 'encoding'
#                   ->{data}     = 1
#              ->[1]->{len}      = -1
#                   ->{name}     = 'text'
#                   ->{func}     = \&TCON
#                   ->{re2}      = {'\(RX\)'=>'Remix', '\(CR\)'=>'Cover'}
#
# Fragen / Ideen
#
# * Tags duerfen mehrfach vorkommen. Wie werden die einzelnen verschiedenen Tags getrennt voneinander
#   gespeichert? $result->{COMM}->[i]=... falls mehrere, sonst string direkt in $result->{COMM} speichern 
#
# * Frame size faelschlicherweise im Tag size format gespeichert? kann das automatisch erkannt werden?
# 
############################

sub toNumber {
  return unpack ("C", shift);
}

sub APIC {
  my $byte = shift;
  my $index = unpack ("C", $byte);
  my @pictypes = ("Other", "32x32 pixels 'file icon' (PNG only)", "Other file icon", 
		  "Cover (front)", "Cover (back)", "Leaflet page", 
		  "Media (e.g. lable side of CD)", "Lead artist/lead performer/soloist",
		  "Artist/performer", "Conductor", "Band/Orchestra", "Composer",
		  "Lyricist/text writer", "Recording Location", "During recording",
		  "During performance", "Movie/video screen capture",
		  "A bright coloured fish", "Illustration", "Band/artist logotype",
		  "Publisher/Studio logotype");
  return "" if $index > $#pictypes;
  return $pictypes[$index];
}

sub TCON {
  my $data = shift;
  if ($data =~ /\((\d+)\)/) {
    $data =~ s/\((\d+)\)/MP3::TAG::ID3v1::genres($1)/e;
  }
 return $data;
} 

sub TFLT {
  my $text = shift;
  return "" if $text eq "";
  $text =~ s/MPG/MPEG Audio/;  
  $text =~ s/VQF/Transform-domain Weighted Interleave Vector Quantization/;  
  $text =~ s/PCM/Pulse Code Modulated audio/;
  $text =~ s/AAC/Advanced audio compression/;
  unless ($text =~ s!/1!MPEG 1/2 layer I!) {
    unless ($text =~ s!/2!MPEG 1/2 layer II!) {
      unless ($text =~ s!/3!MPEG 1/2 layer III!) {
	$text =~ s!/2\.5!MPEG 2.5!;
      }
    }
  }
  return $text;
}

sub TMED {
  my $text = shift;
  return "" if $text eq "";
  if ($text =~ /(?<!\() \( ([\w\/]*) \) /x) {
    my $found = $1;
    if ($found =~ s!DIG!Other digital Media! || 
	$found =~ /DAT/ ||
	$found =~ /DCC/ ||
	$found =~ /DVD/ ||
	$found =~ s!MD!MiniDisc!  || 
	$found =~ s!LD!Laserdisc!) {
      $found =~ s!/A!, Analog Transfer from Audio!;
    }
    elsif ($found =~ /CD/) {
      $found =~ s!/DD!, DDD!;
      $found =~ s!/AD!, ADD!;
      $found =~ s!/AA!, AAD!;
    }
    elsif ($found =~ s!ANA!Other analog Media!) {
	$found =~ s!/WAC!, Wax cylinder!;
	$found =~ s!/8CA!, 8-track tape cassette!;
    }
    elsif ($found =~ s!TT!Turntable records!) {
      $found =~ s!/33!, 33.33 rpm!;
      $found =~ s!/45!, 45 rpm!;
      $found =~ s!/71!, 71.29 rpm!;
      $found =~ s!/76!, 76.59 rpm!;
      $found =~ s!/78!, 78.26 rpm!;
      $found =~ s!/80!, 80 rpm!;
    }
    elsif ($found =~ s!TV!Television! ||
	   $found =~ s!VID!Video! ||
	   $found =~ s!RAD!Radio!) {
      $found =~ s!/!, !;
    }
    elsif ($found =~ s!TEL!Telephone!) {
    TEL    Telephone
      $found =~ s!/I!, ISDN!;
    }
    elsif ($found =~ s!REE!Reel! ||
	   $found =~ s!MC!MC (normal cassette)!) {
      $found =~ s!/4!, 4.75 cm/s (normal speed for a two sided cassette)!;
      $found =~ s!/9!, 9.5 cm/s!;
      $found =~ s!/19!, 19 cm/s!;
      $found =~ s!/38!, 38 cm/s!;
      $found =~ s!/76!, 76 cm/s!;
      $found =~ s!/I!, Type I cassette (ferric/normal)!;
      $found =~ s!/II!, Type II cassette (chrome)!;
      $found =~ s!/III!, Type III cassette (ferric chrome)!;
      $found =~ s!/IV!, Type IV cassette (metal)!;
    }
    $text =~ s/(?<!\() \( ([\w\/]*) \)/$found/x;
  }
  $text =~ s/\(\(/\(/g;
  $text =~ s/  / /g;

  return $text;
}

BEGIN {
  my $encoding    ={len=>1, name=>"_encoding", data=>1};
  my $text_enc    ={len=>-1, name=>"Text", encoded=>1};
  my $text        ={len=>-1, name=>"Text"};
  my $description ={len=>0, name=>"Description", encoded=>1};
  my $url         ={len=>-1, name=>"URL"};
  my $data        ={len=>-1, name=>"_Data", data=>1};
  my $language    ={len=>3, name=>"Language"};

  %format = (
	     #AENC => [],
	     APIC => [$encoding, {len=>0, name=>"MIME type"}, 
		      {len=>1, name=>"Picture Type", func=>\&APIC}, $description, $data],
	     COMM => [$encoding, $language, {name=>"short", len=>0, encoding=>1}, $text_enc],
	     #COMR => [],
	     ENCR => [{len=>0, name=>"Owner ID"}, {len=>0, name=>"Method symbol"},
		      $data],
	     #EQUA => [],
	     #ETCO => [],
	     GEOB => [$encoding, {len=>0, name=>"MIME type"}, 
		      {len=>0, name=>"Filename"}, $description, $data],
	     #GRID => [],
	     IPLS => [$encoding, $text_enc],
	     LINK => [{len=>3, name=>"_ID"}, {len=>0, name=>"URL"}, $text],
	     MCDI => [$data],
	     #MLLT => [],
	     OWNE => [$encoding, {len=>0, name=>"Price payed"}, 
		      {len=>0, name=>"Date of purchase"}, $text],
	     PCNT => [{len=>-1, name=>"Text", func=>\&toNumber}], 
	     POPM => [{len=>0, name=>"URL"},{len=>1, name=>"Rating", func=>\&toNumber}, $data],
	     #POSS => [],
	     PRIV => [{len=>0, name=>"Text"}, $data],
	     #RBUF => [],
	     #SYCT => [],
	     #SYLT => [],
	     T    => [$encoding, $text_enc],
	     TCON => [$encoding, {%$text_enc, func=>\&TCON, re2=>{'\(RX\)'=>'Remix', '\(CR\)'=>'Cover'}}], 
	     TCOP => [$encoding, {%$text_enc, re2 => {'^'=>'(C) '}}],
	     TFLT => [$encoding, {%$text_enc, func=>\&TFLT}],
	     TMED => [$encoding, {%$text_enc, func=>\&TMED}],
	     TXXX => [$encoding, $description, $text],
	     USER => [$encoding, $language, $text],
	     USLT => [$encoding, $language, $description, $text],
	     #RVAD => [],
	     #RVRB => [],
	     W    => [$url],
	     WXXX => [$encoding, $description, $url],
	     UFID => [{%$description, name=>"Text"}, $data],
	    );

  %long_names = (
		AENC => "Audio encryption",
		APIC => "Attached picture",
		COMM => "Comments",
		COMR => "Commercial frame",
		ENCR => "Encryption method registration",
		EQUA => "Equalization",
		ETCO => "Event timing codes",
		GEOB => "General encapsulated object",
		GRID => "Group identification registration",
		IPLS => "Involved people list",
		LINK => "Linked information",
		MCDI => "Music CD identifier",
		MLLT => "MPEG location lookup table",
		OWNE => "Ownership frame",
		PRIV => "Private frame",
		PCNT => "Play counter",
		POPM => "Popularimeter",
		POSS => "Position synchronisation frame",
		RBUF => "Recommended buffer size",
		RVAD => "Relative volume adjustment",
		RVRB => "Reverb",
		SYLT => "Synchronized lyric/text",
		SYTC => "Synchronized tempo codes",
		TALB => "Album/Movie/Show title",
		TBPM => "BPM (beats per minute)",
		TCOM => "Composer",
		TCON => "Content type",
		TCOP => "Copyright message",
		TDAT => "Date",
		TDLY => "Playlist delay",
		TENC => "Encoded by",
		TEXT => "Lyricist/Text writer",
		TFLT => "File type",
		TIME => "Time",
		TIT1 => "Content group description",
		TIT2 => "Title/songname/content description",
		TIT3 => "Subtitle/Description refinement",
		TKEY => "Initial key",
		TLAN => "Language(s)",
		TLEN => "Length",
		TMED => "Media type",
		TOAL => "Original album/movie/show title",
		TOFN => "Original filename",
		TOLY => "Original lyricist(s)/text writer(s)",
		TOPE => "Original artist(s)/performer(s)",
		TORY => "Original release year",
		TOWN => "File owner/licensee",
		TPE1 => "Lead performer(s)/Soloist(s)",
		TPE2 => "Band/orchestra/accompaniment",
		TPE3 => "Conductor/performer refinement",
		TPE4 => "Interpreted, remixed, or otherwise modified by",
		TPOS => "Part of a set",
		TPUB => "Publisher",
		TRCK => "Track number/Position in set",
		TRDA => "Recording dates",
		TRSN => "Internet radio station name",
		TRSO => "Internet radio station owner",
		TSIZ => "Size",
		TSRC => "ISRC (international standard recording code)",
		TSSE => "Software/Hardware and settings used for encoding",
		TYER => "Year",
		TXXX => "User defined text information frame",
		UFID => "Unique file identifier",
		USER => "Terms of use",
		USLT => "Unsychronized lyric/text transcription",
		WCOM => "Commercial information",
		WCOP => "Copyright/Legal information",
		WOAF => "Official audio file webpage",
		WOAR => "Official artist/performer webpage",
		WOAS => "Official audio source webpage",
		WORS => "Official internet radio station homepage",
		WPAY => "Payment",
		WPUB => "Publishers official webpage",
		WXXX => "User defined URL link frame", 
	       );
}

=pod

=head1 SEE ALSO

MP3::Tag, MP3::TAG::ID3v1

ID3v2 standard - http://www.id3.org

=cut


1;
