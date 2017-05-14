package Xbase;
require 5.001;

use strict;
use Carp;
	
#$Xbase::debug=1;
# this line above was used for printing all sorts of junk while debugging :-)

$Xbase::fhd="FHD00";
$Xbase::fhi="FHI00";
$Xbase::fhm="FHM00";

sub new { 
    my ($self)= {};
    bless $self;
    $self->{'DBFH'}= ++$Xbase::fhd;
    $self->{'IDXH'}= ++$Xbase::fhi;
    $self->{'FPTH'}= ++$Xbase::fhm;
    $self;
};

sub dbf_type {
    my ($self)=shift;
    my ($out);
    if ($self->{'hasdbf'}){
	if ($self->{'file_type'}==0x03)
	{ $out="FoxBase+/dBase III Plus/Foxpro/dBase IV, no memo";}
	elsif ($self->{'file_type'}==0x83) 
	{ $out="FoxBase+/dBase III Plus, with memo";}
	elsif ($self->{'file_type'}==0xF5) 
	{ $out="Foxpro, with memo";}
	elsif ($self->{'file_type'}==0x8B) 
	{ $out="dBase IV, with memo";}
	else { $out="Unrecognized format";};
    } else {
	carp "DBF file has not been opened\n";
    };
    $out;
}
	
sub last_update {
    my ($self)=shift;
    my ($out);
    if ($self->{'hasdbf'}){
	$out=$self->{'file_lupdmm'}."/".$self->{'file_lupddd'}."/".$self->{'file_lupdyy'};
    } else {
	carp "DBF file has not been opened\n";
    }
    $out;
}

sub lastrec {
    my ($self)=shift;
    my ($out);
    if ($self->{'hasdbf'}){
	$out=$self->{'file_numrec'};
    } else {
	carp "DBF file has not been opened\n";
    }
    $out;
}


sub open_dbf {
    my ($self)=shift;
    no strict qw(refs);
    ($self->{'dbf'},$self->{'idx'})=@_;
    if (open($self->{'DBFH'},$self->{'dbf'})){
	binmode($self->{'DBFH'});
        seek($self->{'DBFH'},0,0);
        my ($fixed_header)="";
        read($self->{'DBFH'},$fixed_header,32);
        ($self->{'file_type'}, $self->{'file_lupdyy'},
         $self->{'file_lupdmm'}, $self->{'file_lupddd'},
         $self->{'file_numrec'}, $self->{'file_datap'},
         $self->{'file_datal'})=unpack("CCCCVvv",$fixed_header);
        $self->{'num_fields'}=($self->{'file_datap'}-33)/32;

        my ($i, $field_header, $locn)=(0,"",1);  
        for ($i=1;$i<=$self->{'num_fields'};$i++)
        {
            my ($fn, $ft, $fd, $fl, $fld) = 
                ("f_name$i", "f_type$i","f_disp$i", "f_len$i", 
"f_ldec$i");
            seek($self->{'DBFH'},($i-1)*32+32,0);
            read($self->{'DBFH'},$field_header,31);
            my($fname)=unpack("A*",substr($field_header,0,10));
	    my($null_pos)=index($fname,chr(0));
            $self->{$fn}=substr($fname,0,$null_pos);
            $self->{$fname}=$i;
            my($junk);
            ($self->{$ft}, $junk, $junk, $junk, $junk, 
             $self->{$fl}, $self->{$fld})= 
                 unpack("A C CCC CC",substr($field_header,11));

            #
            # Since almost every xBase system treats the 'field data
            # address' differently, why not simply calculate it.  This
            # also gets around the >256 record length problem.
            #
            # Dick Sutton (suttond@federal.unisys.com)
            #
            #
            $self->{$fd} = $locn;  # set new computed location
            $locn += $self->{$fl}; # calculate running offset
        }
        $self->{'hasdbf'}=1;
        $self->{'DRF'}=1;
        $self->{'RECNO'}=1;
    } else {
        $self->{'hasdbf'}=0;
    }
       
# INDEX FILE HANDLING 
    
    $self->{'hasidx'}=0;
    if (defined($self->{'idx'})) {
        if (open($self->{'IDXH'},$self->{'idx'})){
	    binmode($self->{'IDXH'});
            seek($self->{'IDXH'},0,0);
            my ($idx_header)="";
            read($self->{'IDXH'},$idx_header,512);
            ($self->{'idx_root'}, $self->{'idx_free'},
             $self->{'idx_eof'}, $self->{'idx_keyl'},
             $self->{'idx_opt'}, $self->{'idx_key'})=unpack("VVVvCA*",$idx_header);
            $self->{'hasidx'}=1;
        } else {
	    carp "Could not open IDX file ".$self->{'idx'}.". \n";
	}
    }

    # Handle memo files too. Foxpro only right now without someone helping me.
    $self->{'hasfpt'}=0;
    if ($self->{'file_type'}==0xF5) {
	$self->{'hasfpt'}=1;
	my($fptname)=$self->{'dbf'};
	$fptname=~ s/$\.dbf/\.fpt/;
	$fptname=~ s/$\.DBF/\.FPT/;
	$self->{'fpt'}=$fptname;
	if (-e $fptname) {
	    if (open($self->{'FPTH'},$self->{'fpt'})){
		binmode($self->{'FPTH'});
		seek($self->{'FPTH'},0,0);
		my ($fpth)="";
		my ($junk);
		read($self->{'FPTH'},$fpth,16);
		$self->{'fpt_nextf'}=unpack("l",pack("L",unpack("V",substr($fpth,1,4))));
		$self->{'fpt_blksize'}=unpack("l",pack("L",unpack("V",substr($fpth,7,4))));
		$self->{'hasfpt'}=1;
	    } else {
		carp "Could not open FPT (memo) file ".$self->{'fpt'}.". \n";
	    }
	}
    }
  Xbase::go_top($self);
    $self->{'hasdbf'};
}

    
sub dbf_stat {
    my ($self) = shift;
    my ($i);
    if ($self->{'hasdbf'}){
	print "No. Field     Type  Disp  Len  Dec\n";
	for ($i=1;$i<=$self->{'num_fields'};$i++)
	{
	    my ($fn, $ft, $fd, $fl, $fld) = 
		("f_name$i", "f_type$i","f_disp$i", "f_len$i", "f_ldec$i");
	    printf("%3d %-12s %1s  %4d  %3d  %3d\n",
                $i, $self->{$fn}, $self->{$ft}, $self->{$fd}, $self->{$fl},
                $self->{$fld});
	}
    } else {
	carp "DBF file has not been opened\n";
    }
}

sub idx_stat {
    my ($self) = shift;
    if ($self->{'hasidx'}){
	print "IDX Root Node: $self->{'idx_root'}\n";
	print "IDX Free Node: $self->{'idx_free'}\n";
	print "IDX EOF: $self->{'idx_eof'}\n";
	print "IDX Key Length: $self->{'idx_keyl'}\n";
	print "IDX options: $self->{'idx_opt'}\n";
	print "IDX key: $self->{'idx_key'}\n";
    }
    else
    {
	print "No IDX file present\n";
    }
}


sub go_top {
    my ($self) = shift;
    if ($self->{'hasidx'}) {
      Xbase::go_top_idx($self);
    } else {
	$self->{'DRF'}=1;
	$self->{'RECNO'}=1;
    }
    $self->{'BOF'}=1;
    $self->{'EOF'}=0;
}

sub go_bot {
    my ($self) = shift;
    if ($self->{'hasidx'}) {
      Xbase::go_bot_idx($self);
    } else {
	$self->{'DRF'}=1;
	$self->{'RECNO'}=$self->{'file_numrec'};
    }
    $self->{'BOF'}=0;
    $self->{'EOF'}=1;
}


sub go_next {
    my ($self) = shift;
    if ($self->{'hasidx'}) {
      Xbase::go_next_idx($self);
    } else {
	$self->{'DRF'}=1;
	if ($self->{'RECNO'} < $self->{'file_numrec'}){
	    $self->{'RECNO'}++;
	    $self->{'EOF'}=0;
	} else {
	    $self->{'EOF'}=1;
	}
    }
}


sub go_prev {
    my ($self) = shift;
    if ($self->{'hasidx'}) {
      Xbase::go_prev_idx($self);
    } else {
	$self->{'DRF'}=1;
	if ($self->{'RECNO'}>1) {
	    $self->{'RECNO'}--;
	    $self->{'BOF'}=0;
	} else {
	    $self->{'BOF'}=1;
	}
    }
}



sub go_next_idx {
    my ($self) = shift;
    my ($node, $done, $to_node);
    if ($self->{'node_i'} < ($self->{'node_keys'}-1)){
	    $self->{'node_i'}++;
	    $self->{'EOF'}=0;
	} else {
	    $to_node=$self->{'node_right'};
	    if ($to_node > -1) {
	      Xbase::read_idx_leaf ($self, $to_node);
		$self->{'node_i'}=0;
		$self->{'EOF'}=0;
	    } else {
		$self->{'EOF'}=1;
	    }
	}
    $self->{'DRF'}=1;
    $self->{'RECNO'}=@{$self->{'nk_ptr'}}[$self->{'node_i'}];
    $self->{'BOF'}=0;
}


sub go_prev_idx {
    my ($self) = shift;
    my ($node, $done, $to_node);
    if ($self->{'node_i'} > 0){
	    $self->{'node_i'}--;
	    $self->{'BOF'}=0;
	} else {
	    $to_node=$self->{'node_left'};
	    if ($to_node > -1) {
	      Xbase::read_idx_leaf ($self, $to_node);
		$self->{'node_i'}=$self->{'node_keys'}-1;
		$self->{'BOF'}=0;
	    } else {
		$self->{'BOF'}=1;
	    }
	}
    $self->{'DRF'}=1;
    $self->{'RECNO'}=@{$self->{'nk_ptr'}}[$self->{'node_i'}];
    $self->{'EOF'}=0;
}



sub go_top_idx {
    my ($self) = shift;
    my ($node);
    $node=$self->{'idx_root'};
    do 
    {
      Xbase::read_idx_leaf ($self, $node);
	$node=@{$self->{'nk_ptr'}}[0];
    } until ($self->{'node_attr'}>=2 and $self->{'node_left'}==-1);
    $self->{'RECNO'}=@{$self->{'nk_ptr'}}[0];
    $self->{'node_i'}=0;
    $self->{'DRF'}=1;
}


sub go_bot_idx {
    my ($self) = shift;
    my ($node);
    $node=$self->{'idx_root'};
    do 
    {
      Xbase::read_idx_leaf ($self, $node);
	$node=@{$self->{'nk_ptr'}}[$self->{'node_keys'}-1];
    } until ($self->{'node_attr'}>=2 and $self->{'node_right'}==-1);
    $self->{'RECNO'}=@{$self->{'nk_ptr'}}[$self->{'node_keys'}-1];
    $self->{'node_i'}=$self->{'node_keys'}-1;
    $self->{'DRF'}=1;
}


sub bof {
    my ($self) = shift;
    return $self->{'BOF'};
}

sub eof {
    my ($self) = shift;
    return $self->{'EOF'};
}


sub read_idx_leaf {
    my ($self, $loc) = @_;
    my ($inr)="";
    my ($i, $ptr, @nk_val, @nk_ptr);
    no strict qw(refs);
    seek($self->{'IDXH'},$loc,0);
    read($self->{'IDXH'},$inr,512);
    $self->{'node_attr'}=unpack("v",substr($inr,0,2)); # S
    $self->{'node_keys'}=unpack("v",substr($inr,2,2)); # S

    # Messy below to produce little endian signed long :-)

    $self->{'node_left'}=unpack("l",pack("L",unpack("V",substr($inr,4,4))));
    $self->{'node_right'}=unpack("l",pack("L",unpack("V",substr($inr,8,4))));

    if (defined($Xbase::debug))
    {
	print "Node ATTR $self->{'node_attr'}\n";
	print "Node Keys $self->{'node_keys'}\n";
	print "Node Left $self->{'node_left'}\n"; # used for previous
	print "Node Right $self->{'node_right'}\n"; # used for next
    }
    my ($n_keys,$i_kl) = ($self->{'node_keys'}, $self->{'idx_keyl'});
    for ($i=0;$i<$n_keys;$i++)
    { 
	$ptr=12+$i*($i_kl+4);
	$nk_val[$i]=unpack("A*",substr($inr,$ptr,$i_kl));
	$ptr+=$i_kl;
	$nk_ptr[$i]=unpack("N",substr($inr,$ptr,4));
#    print "## $i of $n_keys $nk_val[$i] at $nk_ptr[$i]\n";
    }

    $self->{'nk_val'}=\@nk_val;
    $self->{'nk_ptr'}=\@nk_ptr;
}



sub seek_dbf {
    my ($self, $seeking) = @_;
# FIND IN INDEX
    if (not ($self->{'hasidx'})){
	carp "Cannot seek without a INDEX file \n";
	return undef;
    }
    my ($start_node)=$self->{'idx_root'};
    my ($done)=0;
    my ($found, $fail, $i, $nk_val, $nk_ptr);
    my ($rec_sought, $ni, $new_node, $field_data);
    do
    {

      Xbase::read_idx_leaf($self, $start_node);
	$nk_val=$self->{'nk_val'};
	$nk_ptr=$self->{'nk_ptr'};
	$found=0;
	for ($i=0;$i<=$self->{'node_keys'};$i++)
	{
	    if ($seeking eq substr(@$nk_val[$i],0,length($seeking)) && !$found)
	    { 
		if ($self->{'node_attr'}>=2)
		{
		    $done=1;
		    $found=1;
		    $rec_sought=@$nk_ptr[$i];
		    $ni=$i;
		}
		else
		{
		    $found=1;
		    $new_node=@$nk_ptr[$i];
		}
	    }
	    if ($self->{'node_attr'}<=1 && $seeking le @$nk_val[$i] && !$found)
	    {
		$found=1;
		$new_node=@$nk_ptr[$i];
	    }
	}
	$start_node=$new_node;
	$fail=!$found;
	
    } until $done || $fail;
    if (!$fail)
    {
	$self->{'DRF'}=1;
	$self->{'RECNO'}=$rec_sought;
	$self->{'node_i'}=$ni;
    } else {
	$self->{'DRF'}=0;
    }
    (! $fail);
}

sub recno {
    my ($self) = @_;
    return $self->{'RECNO'};
}

sub get_field {
    my ($self, $field) = @_;
    if ($self->{'DRF'}) {
	my ($i,$data)=(0, "");
	$i=$self->{'RECNO'};
	no strict qw(refs);
	seek($self->{'DBFH'},$self->{'file_datap'}+($i-1)*$self->{'file_datal'},0);
	read($self->{'DBFH'},$data,$self->{'file_datal'});
	$self->{'RECDATA'}=$data;
	$self->{'DRF'}=0;
    }
    if ($field eq "_DELETED") {
	return substr($self->{'RECDATA'},0,1);
    }
    my ($f)=$self->{$field};
    my ($fn, $ft, $fd, $fl, $fld) =
	("f_name$f", "f_type$f","f_disp$f", "f_len$f", "f_ldec$f");
    if ($self->{$ft} eq "M")
    {
	my($memo)=substr($self->{'RECDATA'}, $self->{$fd}, $self->{$fl});
	return Xbase::read_memo($self, $memo);
    } else {
	return substr($self->{'RECDATA'}, $self->{$fd}, $self->{$fl});
    }
}

sub read_memo {
    my ($self,$memblk)=@_;
    no strict qw(refs);
    seek($self->{'FPTH'},$self->{'fpt_blksize'}*$memblk,0);
    my($mblkhead)="";
    read($self->{'FPTH'},$mblkhead,8);
    my($blksig,$memo_len)=unpack("NN",$mblkhead);
    my($memo_data)="";
    read($self->{'FPTH'},$memo_data,$memo_len);
    return $memo_data;
}



# The following function was contributed by Leonard Samuelson.

sub get_record {
    my ($self, $field) = @_;
    if ($self->{'DRF'}) {
        my ($i,$data)=(0, "");
        $i=$self->{'RECNO'};
        no strict qw(refs);
        seek($self->{'DBFH'},$self->{'file_datap'}+($i-1)*$self->{'file_datal'},0);
        read($self->{'DBFH'},$data,$self->{'file_datal'});
        $self->{'RECDATA'}=$data;
        $self->{'DRF'}=0;
    }
    my $i = 0 ;
    my @fret ;
    for($i=1; $i <= $self->{'num_fields'}; $i++)
    {
	if ($self->{"f_type$i"} eq "M") {
	    my($memo)=substr($self->{'RECDATA'}, $self->{"f_disp$i"}, $self->{"f_len$i"});
	    @fret[$i-1]=Xbase::read_memo($self, $memo);
	} else {
	    @fret[$i-1] = substr($self->{'RECDATA'}, $self->{"f_disp$i"}, $self->{"f_len$i"}) ;
	}
        if( $self->{"f_type$i"} eq 'C' ) {
            @fret[$i-1] =~ s/^(.*?)\s*$/$1/ ;
        }
    }
    return @fret ;
}


# The following function DOES NOT WORK and just represents a stupid snapshot
# of my code to atleast write into existing records :-)
# Left here since I was too lazy to remove it.

sub set_field {
    my ($self, $field, $value) = @_;
    no strict qw(refs);
    my ($change) = 0;
    my ($i)=0;
    my ($data) = $self->{'RECDATA'};
    print "before $data\n";
    if ($field eq "_DELETED") {	# TOGGLE DELETE FLAG
	if (substr($data,1,1) eq "*") {
	    substr($data,1,1)=" ";
	} else {
	    substr($data,1,1)="*";
	}
    }
    my ($f)=$self->{$field};
    my ($fn, $ft, $fd, $fl, $fld) = 
	("f_name$f", "f_type$f","f_disp$f", "f_len$f", "f_ldec$f");
    my ($t)=substr($value,0,$self->{$fl});
    print "$t\n";
    substr($data, $self->{$fd}, $self->{$fl})=$t;
    print "after $data\n";
    $i=$self->{'RECNO'};
    seek($self->{'DBFH'},$self->{'file_datap'}+($i-1)*$self->{'file_datal'},0);
    write($self->{'DBFH'},$data,$self->{'file_datal'});
    $self->{'RECDATA'}=$data;
}



sub close_dbf
{
    my ($self) = @_;
    no strict qw(refs);
    if ($self->{'hasdbf'}){
	close($self->{'DBFH'});
    }
    if ($self->{'hasidx'}){
	close($self->{'IDXH'});
    }
    if ($self->{'hasfpt'}){
	close($self->{'FPTH'});
    }
    undef $self;
}

1;

__END__

=head1 NAME

Xbase - Perl Module to Read Xbase DBF Files and Foxpro IDX indexes

=head1 ABSTRACT

This is a perl module to access xbase files with simple IDX indexes.
At the moment only read access to the files are provided by this package
Writing is tougher with IDX updates etc and is being worked on. Since the
read functionality is useful in itself this version is being released.

=head1 INSTALLATION

To install this package, change to the directory where this file is present
and type

	perl Makefile.PL
	make
	make install

This will copy Xbase.pm to the perl library directory provided you have the
permissions to do so. To use the module in your programs you will use the
line:

	use Xbase;

If you cannot install it in the system directory, put it whereever you like
and tell perl where to find it by using the following in the beginning of
your script:

	BEGIN {
		unshift(@INC,'/usr/underprivileged/me/lib');
	}
	use Xbase;

=head1 DESCRIPTION

The various methods that are supported by this module are given
below. There is a very distinct xbase like flavour to most of the
commands.

=head2 CREATING A NEW XBASE OBJECT:

    $database = new Xbase;

This will create an object $database that will be used to interact with the
various methods the module provides.

=head2 OPENING A DATABASE

    $database->open_dbf($dbf_name, $idx_name);

Associates the DBF file and optionally the IDX file with the object. It
opens the files and if a associated MEMO file is present automatically
opens it. Only Foxpro Memo files are currently supported and assumes the
same filename as the DBF with a FPT extension.

=head2 DATABASE TYPE

	print $database->dbf_type;

Returns a string telling you if the xbase file opened is DBF3, DBF4 or FOX

=head2 LAST UPDATE DATE

	print $database->last_update;

Returns a date string telling you when the database was last updated.

=head2 LAST RECORD NUMBER

	$end=$database->lastrec;

Returns the record number of the last record in the database file.

=head2 DATABASE STATUS INFORMATION

	$database->dbf_stat;

This prints out on to STDOUT a display of the status/structure of the
database. It is similar to the xbase command DISPLAY STATUS. Since it
prints field names and structure it is commonly used to see if the module
is reading the database as intended and finding out the field names.

=head2 INDEX FILE STATUS INFORMATION

	$database->idx_stat;

Prints on to STDOUT the status information of an open IDX file.

=head2 GO TOP

	$database->go_top;

Moves the record pointer to the top of the database. Physical top of
database if no index is present else first record according to index order.

=head2 GO BOTTOM

	$database->go_bottom;

Moves the record pointer to the bottom of the database. Physical bottom of
database if no index is present else last record according to index order.

=head2 GO NEXT

	$database->go_next;

Equivalent to the xbase command SKIP 1 which moves the record pointer to
the next record.

=head2 GO PREVIOUS

	$database->go_prev;

Equivalent to the xbase command SKIP -1 which moves the record pointer to
the previous record.

=head2 SEEK

	$stat=$database->seek($keyvalue);

This command positions the record pointer on the first matching record that
has the key value specified. The database should be opened with an
associated index. Seek without an available index will print an error
message and abort. The return value indicates whether the key value was
found or not.

=head2 RECORD NUMBER

	$current_rec=$database->recno;

Returns the record number that the record pointer is currently at.

=head2 BEGINNING OF FILE

	if ($database->bof) {
		print "At the very top of the file \n";
	}

Tells you whether you are at the beginning of the file. Like in xbase it is
not true when you are at record number one but rather it is set when you
try to $database->go_prev when you are at the top of the file.

=head2 END OF FILE
 
	if ($database->eof) {
		print "At the very end of the file \n";
	}

Tells you whether you are at the end of the file. Like in xbase it is
not true when you are at the last record but rather it is set when you
try to $database->go_next from the last record.

=head2 READ INDIVIDUAL FIELD VALUES

	print $database->get_field("NAME");

Returns as a string the contents of a field name specified from the current
record. Using the pseudo field name _DELETED will tell you if the current
record is marked for deletion.

=head2 READ FIELD VALUES INTO ARRAY

	@fields = $database->get_record;

Returns as an array all the fields from the current record. The fields are
in the same order as in the database.

=head2 CLOSE DATABASE

	$database->close_dbf;

This closes the database files, index files and memo files that are
associated with the $database object with $database->open_dbf

=head1 COPYRIGHT 

Copyright (c) 1995 Pratap Pereira. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

I request that if you use this module at a web site to make a
link to 
	
	http://eewww.eng.ohio-state.edu/~pereira/software/xbase/

This is just so that others might find it. This is however not
required of you.

=head1 AUTHOR INFORMATION

Please send your comments, suggestions, gripes, bug-reports to 

	Pratap Pereira
	pereira@ee.eng.ohio-state.edu

=head1 UPDATE HISTORY

=over 4

=item Original perl 4 script done in March 1994

=item Perl 5 module done in February 1995

=item RELEASE 2 was first public release now called xbase12.pm

=item RELEASE 3 was done 6/22/95 called xbase13.pm

	Fixed problem with GO_PREV & GO_NEXT after SEEK.
	Fixed problem with parsing headers of dbfs with 
        record length > 255.
	Added Memo file support.

=item RELEASE 4 was done 9/29/95

	Fixed problem with certain IDX failing completely, 
        was a stupid
	indexing mistake.

=item RELEASE 5 was done 11/14/95 (called xbase.pm 1.05)

	Fixed field length inconsistency errors by changing 
        way header is decoded. Should work with more xbase 
        variants. (Dick Sutton & Andrew Vasquez)

=item Version 1.06  was done 11/17/95

        Added binmode command to file handles to support 
        Windows NT 

=item Version 1.07 was done 01/23/96

	Made documentation in pod format, installation 
        automated. Fixed problem with deleted status being 
        improperly read (Chung Huynh). Renamed to Xbase 
        (previously xbase) to be consistent with other perl
        modules. Released in CPAN.
	Prettied up dbf_stat output (Gilbert Ramirez).    

=back

=head1 CREDITS

Thanks are due to Chung Huynh (chuynh@nero.finearts.uvic.ca), Jim
Esposito (jgespo@exis.net), Dick Sutton (suttond@federal.unisys.com),
Andrew Vasquez (praka@ophelia.fullcoll.edu), Leonard Samuelson
(lcs@synergy.smartpages.com) and Gilbert Ramirez Jr
(gram@merece.uthscsa.edu)

=cut
