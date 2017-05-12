package TheBat::Read_TBB;

use 5.00001;
use strict;
use warnings;
use bytes;
use Digest::MD5;

require Exporter;

=head1 NAME

TheBat::Read_TBB - Read individual email messages out of TheBat! .tbb messages files

=head1 SYNOPSIS

  use TheBat::Read_TBB;
  while(&Read_TBB("messages.tbb",\%ref) {
    print "$ref{'sender'}\n";
  }

=head1 DESCRIPTION

Reads the TheBat! binary messages flags (status codes like "deleted" or "replied" or "flagged" etc)
as well as the email headers and body, and returns md5 checksums of some parts as well as flags
and headers etc.

Call repeatedly in a loop; returns 0 when there's no more to read.

The Write_TBB function will set or reset only the 4 flags: flag_P (parked) flag_F (flagged) flag_o (read) flag_D (deleted) (see note below re writing binary files)


=head2 EXPORT

Read_TBB
Write_TBB

=head2 EXAMPLE

  use TheBat::Read_TBB;
  my %ref;
  while(&Read_TBB("t/messages.tbb",\%ref)) {	# List all emails
    foreach my $k (keys %ref) {
      print "$k:\t" . $ref{$k} . "\n";
    }
    if($ref{$msgno}==3){ $ref{'flag_P'}=1; &Write_TBB(\%ref); }	# Set the "Parked" flag on the 3rd email
  }

  
=head1 SEE ALSO

http://www.felix-schwarz.name/files/thebat/tbb.txt


=head1 NOTE re TheBat TBB file format differences

Some more modern TheBat! clients may store messages in .TBB files with a different format in them which this code can't read.
You can fix this problem by finding an older .tbb file (there's one in this package in the t/ folder)
and creating a new bat folder, then exiting TheBat!, copying the old .tbb over the new folder tbb 
and erasing the tbn file, restarting TheBat!, and moving all your messages into this new folder


=head1 NOTE re Writing to the binary files

I only coded changed to the Deleted, Parked, and Flagged flags; and you may need to erase 
the MESSAGES.TBN file if you change those; warning; the TBN file holdes your memos and message colours and stuff.


=head1 AUTHOR

Chris Drake, E<lt>cdrake@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Chris Drake

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut



our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use TheBat::Read_TBB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	Read_TBB
        Write_TBB
);

our $VERSION = '0.02';


# Change some flags (deleted, parked, or flagged only; flag_P flag_F flag_D) inside a TBB file
sub Write_TBB {
  my($ref)=@_;	# Must use an already opened Read_TBB file 
  $ref->{'curpos'}=sysseek(TBB,0,1);	# Remember where we are now
  sysseek(TBB,$ref->{'tell'},0);	# Go to where they want to write
  my($buf,$bytes_read);
  $bytes_read=sysread(TBB,$buf,$ref->{'msghead_size'});	# Get the tbb message header
  my $tbbhdr=unpack('b*',$buf);
  my %flagmod=qw(D 112 o 113 P 115 F 118);
  foreach my $k (keys %flagmod) {	# Set or unset 4 flags:
    if($ref->{"flag_$k"}) {
      substr($tbbhdr,$flagmod{$k},1)="1";
    } else {
      substr($tbbhdr,$flagmod{$k},1)="0";
    }
  }
  my $newbuf=pack('b*',$tbbhdr);
  my $ret=-2;
  if($newbuf ne $buf) {	# changed something
    sysseek(TBB,$ref->{'tell'},0);	# Go to where they want to write
    $bytes_read=syswrite(TBB,$newbuf,$ref->{'msghead_size'});	# Write the tbb message header
    $ret=1;
    if($bytes_read ne $ref->{'msghead_size'}) {
      warn ".TBB ".$ref->{'tbb'}." file write problem: $!";
      $ret=-1;
    }
  } else {
    $ret=0;
  }
  sysseek(TBB,$ref->{'curpos'},0);	# go back to where we were
  return $ret;
} # Write_TBB


# Call repeatedly; returns 1 email at a time
sub Read_TBB {
  my($tbb,$ref)=@_;	# Supply input .TBB filename, and a ref to keep status info	

  my($readbuf)=536870911;			# How big shall our message-sysread chunks be?
  my $flagcodes='DoaPAxFft.c................m....';
  my($buf,$bytes_read)=(undef,0); my %persist=qw(tbb 1 more 1 total 1 msgs 1 deld 1 msgno 1 seek 1); foreach my $k(keys %{$ref}){$ref->{$k}=undef unless($persist{$k})}
  if(!$ref->{'tbb'}) {	# Not opened yet
    if(open(TBB,'+<',$tbb)) {
      $ref->{'tbb'}=$tbb;
      binmode(TBB);
      $bytes_read=sysread(TBB,$buf,6);			# Get magic number and file header size
      $ref->{'seek'}=$bytes_read;
      ($ref->{'file_magic'},$ref->{'head_size'})=unpack("VS",$buf);
      $ref->{'head_size'}-=6; # remove the size of the header(magic+size) itself from the header

      if($ref->{'file_magic'} != 427361824) { # if(unpack('H*',substr($buf,0,6)) ne '20067919080c');
        &write_log("Possible input file corruption: magic number mismatch: " . $ref->{'file_magic'} . " != 427361824 " . unpack('H*',$buf));
	close(TBB);
        return 0;
      }

      $bytes_read=sysread(TBB,$buf,$ref->{'head_size'});	# Get the TBB file header
      $ref->{'seek'}+=$bytes_read;
      &write_log("Possible input file corruption: $bytes_read != ". $ref->{'head_size'} ." - too short") if($bytes_read != $ref->{'head_size'});

      $ref->{'more'}=1;
      $ref->{'total'}=0;
      $ref->{'msgs'}=0;
      $ref->{'deld'}=0;
      $ref->{'msgno'}=0;

    } else {
      &write_log("Skipping: " . $ref->{'tbb'} . " - $!");
      return 0;
    }
  } else {
    goto NOMORE unless($ref->{'more'});
  }

  $bytes_read=sysread(TBB,$buf,6);	# Get the message header's magic and size
  $ref->{'seek'}+=$bytes_read;
  if($bytes_read<6) {
NOMORE:
    close(TBB);
    # &write_log("End of " . $ref->{'tbb'} . " - Total messages:".$ref->{'total'} ." (." . $ref->{'msgs'}." messages, ".$ref->{'deld'}." deleted): run=".$ref->{'grandtot'});# if($switch{'debug'});
    undef $ref;	# works
    return 0;
  }


  ($ref->{'msg_magic'},$ref->{'msghead_size'})=unpack("VS",$buf);	# V is a little-endian 32bit int, S is an unsigned little-ending 16 bit short)
  $ref->{'msghead_size'}-=6; # remove the size of the header(magic+size) itself from the header
  if($ref->{'msg_magic'} != 426772769) {
    die "Possible input file corruption: message magic number mismatch: " . $ref->{'msg_magic'}. " != 426772769 / 21 09 70 19 != " . unpack('H*',$buf);
  }

  $ref->{'msghead_size'}=0 if($ref->{'msghead_size'}<0);
  # &write_log($ref->{'tbb'} . " message header size is $ref->{'msghead_size'}"); # debug
  &write_log("Possible input file corruption: message header size unusual") if($ref->{'msghead_size'} != 42);
  
  $ref->{'tell'}=$ref->{'seek'}; # remember where this message started
  $bytes_read=sysread(TBB,$buf,$ref->{'msghead_size'});	# Get the tbb message header
  $ref->{'tbbheader'}=$buf;
  $ref->{'seek'}+=$bytes_read;
  if($bytes_read != $ref->{'msghead_size'}) {
    &write_log("Possible input file corruption: message header too short");
    goto NOMORE;
  }

  $ref->{'total'}++; $ref->{'grandtot'}++;
  $ref->{'msgno'}++;
  
   #(	0  ,3441210366,1038086103,1830,0  ,146    ,0  ,0   ,1   ,78594    ,0         ,0)
  my(	$z1,$unknown  ,$time     ,$id ,$z2,$status,$z4,$col,$pri,$msg_size,$msg_sizeB,$z5)=unpack(
        'v  V          V          v    v   b32     V   V    V    V         V          V',$buf);
  my $flags='';for(my $i=0; $i<length($status);$i++){my $f='-'; my $f2=substr($flagcodes,$i,1); $f='' if($f2 eq '.'); $f=$f2 if(substr($status,$i,1) eq '1'); $flags.=$f; $ref->{"flag_$f"}++;}	# DoaPAxFft.c................m....
  $ref->{'flags'}=$flags;


  my($read)=0; 
  my($head)=1; 
  my($towrite)=1;
  my($full)='';
  $ref->{'sender'}='<>'; 
	
  if(substr($status,0,1)) {
    $ref->{'deld'}++;
  } else {
    $ref->{'msgs'}++;
  }

  $ref->{'md5'} = Digest::MD5->new; 
  $ref->{'md5h'} = Digest::MD5->new;
  $ref->{'md5b'} = Digest::MD5->new;
  my %hdr; my($more)=1;
  $ref->{'size'} = 0;

  while(($more)&&($read<$msg_size)&&($msg_size>0)) { # Loop over sensible sized reads of the message
    if(($msg_size-$read)<$readbuf) {
      $bytes_read=sysread(TBB,$buf,($msg_size-$read));		# Get the rest of the message
      $ref->{'seek'}+=$bytes_read;
      $ref->{'size'}+=$bytes_read;
      if($bytes_read != ($msg_size-$read)) {
        $more=0; $ref->{'more'}=0;
        &write_log("Possible input file corruption: file ends before message $ref->{'total'} does");
      }
      $read=$msg_size;	# Got the lot now
    } else {
      $bytes_read=sysread(TBB,$buf,$readbuf);			# Get 32k of the message
      $ref->{'seek'}+=$bytes_read;
      $ref->{'size'}+=$bytes_read;
      if($bytes_read != $readbuf) {
        $more=0; $ref->{'more'}=0;
        &write_log("Possible input file corruption: file ends before message $ref->{'total'} does");
      }
      $read+=$readbuf;
    }


    if($head) {		# We're in the header
      $head=0;
      ($ref->{'header'},$buf)=split(/(?:\r\r|\n\n|\r\n\r\n|\n\r\n\r)/,$buf,2);
      $ref->{'header'}=~s/\r\n/\n/gsm;
      chop($ref->{'header'}) while(substr($ref->{'header'},-1) eq "\r");
      &ParseHead(\$ref->{'header'},\%hdr);

      ($ref->{'sender'})=($ref->{'header'}=~/[\s<]([^\s<>]+\@[a-z0-9\.\-]+)/i);

      if(substr($ref->{'header'},0,5) ne 'From ') {
        $ref->{'header'}=~s/^From /X-From:/gsm;		# Don't allow another "^From " in the headers
        $ref->{'header'}="From $ref->{'sender'}\n" . $ref->{'header'};
      }

      $ref->{'md5h'}->add($ref->{'header'});
      foreach my $hk (qw(From To Date Message-ID Subject)) {
	$hdr{lc($hk)}='' unless(defined $hdr{lc($hk)});
        $ref->{'md5b'}->add("$hk:" . $hdr{lc($hk)});
      }

        # $ref->{'md5b'}->add("From:" . $hdr{'from'} .  "\tTo:" . $hdr{'to'} .  "\tDate:" . $hdr{'date'} .  "\tId:"  . $hdr{'message-id'} .  "\tSubject:"  . $hdr{'subject'} );

      foreach my $k (keys %hdr){$ref->{"h_$k"}=$hdr{$k};}
    }

    $ref->{'md5'}->add($buf);

    #$full.=$buf if($switch{'uniq'}); 

  } # loop over 1 email

  foreach my $h (qw(md5 md5h md5b)) {
    $ref->{"b$h"}=$ref->{$h}->digest;
    $ref->{$h.'hex'}=unpack("H*",$ref->{"b$h"});	# $ref->{'bmd5'} / $ref->{'md5hex'} / etc
  }

  return 1;
} # Read_TBB



#######################################################################

=head2 ParseHead

Extract fields from header

=cut
#######################################################################


sub ParseHead {
  my($phdrc,$phdr)=@_;
  my @hdr=split(/(?:\r\n|\n\r|\r|\n)/,$$phdrc);
  push @hdr,'';	# So the loop below also does the last element properly (the $i++ bit)
  my $i=0; while($i<($#hdr)) {
#print "h$i =$hdr[$i]\n";
    if($hdr[1+$i]=~/^\s(.*)/) {
      $hdr[$i].=" $1"; splice(@hdr,$i+1,1);
    } else {
      my($f,$b)=split(':',$hdr[$i],2); if(!defined $phdr->{lc($f)}){$phdr->{lc($f)}=$b}else{$phdr->{lc($f)}.=" ".$b}
      $i++;
    }
#print "h$i'=$hdr[$i]\n";
  }
  pop @hdr;	# @hdr now has headers, all one-lined.

} # ParseHead






#######################################################################

=head2 write_log

Outputs debugging and informational letters to /var/log file.

=cut
#######################################################################
sub write_log {
  my($message)=@_;
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my($date)=sprintf("%02d/%02d %02d:%02d.%02d",$mon+1,$mday,$hour,$min,$sec);
  print STDERR "$date $$ Read_TBB $message\n";
}




__END__

=head1 BUGS

=over 3

=item *

Little testing

=back

=head1 SEE ALSO

	TBB file format from: http://www.felix-schwarz.name/files/thebat/tbb.txt

	http://www.felix-schwarz.name/TheBat_Importer_(en)


=head2 TBB file format specification

	Every TBB file consists of a global file header and the parts per message.


=head3 Global File Header

	The header has always the same length (0x0C08 bytes). The file starts with a
	magic number: 0x20 0x06 0x79 0x19 0x08 0x0C
					  ^^^^^^^^^ total header length (*including* these 6 bytes)
	That number is being followed by (0x0C08 - 6) zeros.


=head3 The Message Part

	The message part has a per message header which is always 48 bytes long. This
	header is followed by a RFC 822 mail message.

	The Mail Header
	A mail header starts with another magic number: 0x21 0x09 0x70 0x19 0x30.

	bytes 0-3:      21 09 70 19		magic number
	bytes 4-5	30 00			message header size
	bytes 6-7:      00 00
	bytes 8-11:     38 ed ad 7a		(not always "38 ed ad 7a")
	bytes 12-15     WW WW WW WW             received time (unix timestamp) (little endian! 15, 14, 13, 12)
	bytes 16-17:    07 00                   id number (maybe display position) (little endian! 17, 16)
	bytes 18-19:    00 00
	bytes 20-21:    XX XX XX XX             message status flag
	bytes 22-27:    00 00 00 00
	bytes 28-31:    YY YY YY YY             message belongs to a certain color group
	bytes 32-35:    VV VV VV VV		priority status
	bytes 36-39:    ZZ ZZ ZZ ZZ             size of the variable part (little endian! 39, 38, 37, 36)
	bytes 40-47:    00 00 00 00 00 00 00 00

	The size of the RFC 822 message is specified by the bytes 36-39. The mail is
	followed by the next message or EOF. There is no way to know in advance if
	there is another message.


=head4 The message status flag (chris):

						 01234567abcdefghijklmnopqrstuvwx
	typical status using perl unpack b32 is "01001000001000000000000000010000"
			   			 01234567abcdefghijklmnopqrstuvwx


=head4 The message status flag:

	Bit 7654 3210
	    0000 0000

	1 = yes, 0 = no
	D Bit 0   deleted
	o Bit 1   read				(0=unread)
	a Bit 2   answered			message is replied (envelope with green arrow icon)
	P Bit 3   parked				message is parked (blue p icon)
	A Bit 4   has attachement
	x Bit 5   attachment was deleted (?)
	F Bit 6   flagged				message is flagged (red flag icon)
	f Bit 7   forwarded/redirected
	m     t = message has memo or is tagged (or has been modified?)

	DoaPaxFft-c----------------m----
	01234567abcdefghijklmnopqrstuvwx


=head4 The priority status field:

	00 00 00 00	normal priority
	05 00 00 00	high priority
	FB FF FF FF	low priority


=cut

# Preloaded methods go here.

1;
__END__
