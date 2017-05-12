# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.

package VisionDB::Read;

use strict;
use warnings;
use Exporter;
use File::Basename;
use Fcntl qw(SEEK_SET SEEK_CUR);

our ($VERSION, @ISA);
@ISA = qw( Exporter );
$VERSION = 0.04;

BEGIN {
}

END {
}
#--------------------------------------#
# Open DB segment from basename and    #
# segment number                       # 
#   in: $basename, $seg                #
#   out: $handle                       #
#        die if error                  #
#--------------------------------------#

sub _open_db_segment {

	my ($basename, $segment) = @_;

	my $fh;
	my $fn = $basename.(($segment) ? ".d".sprintf("%02d", $segment) : '');

	open($fh, "<$fn") || die "open error ($!)\n";
	binmode $fh || die "cannot set binmode ($!)\n";
	return $fh;
}

#-------------------------------------#
# Destroy internal vars               # 
#   in: -                             #
#   out: -                            #
#-------------------------------------#
sub _free_vars {

	my $self = shift;

	undef $self->{_err};
	undef $self->{_db_fname};
	undef $self->{_db_fpath};
	undef $self->{_fh};
	undef $self->{_rec_tot};
	undef $self->{_rec_cur};
	undef $self->{_version};
	undef $self->{_data_hlen};
	undef $self->{_data_cur};
	undef $self->{_seg_tot};
	undef $self->{_seg_cur};
	undef $self->{_seg_size};
	undef $self->{_data_start};
	undef $self->{_data_end};
	undef $self->{_data_keys};
}

#--------------------------------------#
# Read next valid record and increment #
# ptr to the next one                  #
#   in: $objref                        #
#   out: $data_arrayref                #
#	     die if error                  #
#--------------------------------------#
sub _read_next {

    my $self = shift;

	$self->{_rec_cur} >= 0 || die "invalid negatve record number\n";

	my $fh = $self->{_fh};
	my $dseg = $self->{_seg_cur};
	my $dptr = $self->{_data_cur};
    my $data;

	my $del = 0;
	do {
		my $buf;
		my ($h1, $h2) = (0, 0);
		$self->{_seg_size}*$dseg + $dptr < $self->{_data_end} || die "record ptr beyond EOF\n";
		(my $r = read($fh, $buf, $self->{_data_hlen})) || die "read error ($!)\n";
		HDR1: {
			if ($self->{_version} == 4) { ($h1, $h2) = unpack('n2', $buf) if ($r == $self->{_data_hlen}); last HDR1 }
			if ($self->{_version} == 5) { ($h1, $h2, $del) = unpack('N2C', $buf) if ($r == $self->{_data_hlen}); last HDR1 }
		}
		if ($h1 == 0) {
			$dseg++;
			$dptr = $self->{_data_start};
			close $fh if ($fh != $self->{_fh});
			$fh = _open_db_segment($self->{_db_fpath}.$self->{_db_fname}, $dseg);
			seek($fh, $self->{_data_start}, SEEK_SET) || die "seek error ($!)\n";
			read($fh, $buf, $self->{_data_hlen}) == $self->{_data_hlen} || die "read error ($!)\n";
			HDR2: {
				if ($self->{_version} == 4) { ($h1, $h2) = unpack('n2', $buf); last HDR2 }
				if ($self->{_version} == 5) { ($h1, $h2, $del) = unpack('N2C', $buf); last HDR2 }
			}
		}
		$del = ($h2 == 0) if ($self->{_version} == 4);
		if ($del) {
			seek($fh, $h1, SEEK_CUR) || die "seek error ($!)\n";
		} else {
			read($fh, $buf, $h1) == $h1 || die "read error ($!)\n";
			$data = [$buf, $h1];
		}
		$dptr += $self->{_data_hlen}+$h1;
		undef $buf;
	} until ($del == 0);
	close $self->{_fh} if ($fh != $self->{_fh});
	$self->{_fh} = $fh;
	$self->{_seg_cur} = $dseg;
	$self->{_data_cur} = $dptr;
	$self->{_rec_cur}++;
	$self->{_rec_cur} = -1 if ($self->{_rec_cur} >= $self->{_rec_tot});
	
	return $data;
}

#################
## constructor ##
#################
sub new {

	my ($class, $filename) = @_;

	my $self = {
		_err		=> 0,
		_db_fname	=> undef,
		_db_fpath	=> undef,
		_fh			=> undef,
		_rec_tot	=> undef,
		_rec_cur	=> undef,
		_version	=> undef,
		_data_hlen	=> undef,
		_data_cur	=> undef,
		_seg_tot	=> undef,
		_seg_cur	=> undef,
		_seg_size	=> undef,
		_data_start	=> undef,
		_data_end	=> undef,
		_data_keys	=> undef,
	};

	eval {
		my ($buf, $hdr_kcnt, $hdr_zip, $hdr_enc);
		(($self->{_db_fname}, $self->{_db_fpath}) = fileparse($filename)) || die "cannot parse filename\n";
		# open file, segment 0
		$self->{_fh} = _open_db_segment($self->{_db_fpath}.$self->{_db_fname}, 0);
		# read 1st 512 bytes (1 block)
		read($self->{_fh}, $buf, 512) == 512 || die "read failed ($!)\n"; 
		# check file type and version
        (my $t, $self->{_version}) = unpack('Nn', $buf);
        $t == 0x10121419 || die "wrong file type\n";
		# acquire data area ptr
		DATA_PTR: {
			if ($self->{_version} == 4) { $self->{_data_start} = unpack('N', substr($buf, 0x001e, 4)); last DATA_PTR; }
			if ($self->{_version} == 5) { $self->{_data_start} = unpack('N', substr($buf, 0x0022, 4)); last DATA_PTR; }
			die "unsupported file version\n";
		}
		# read the rest of header
		(read($self->{_fh}, $buf, $self->{_data_start}-512, 512) == $self->{_data_start}-512 || die "read failed ($!)\n") if ($self->{_data_start} > 0);
		# acquire some more infos from header
		READ_HDR: {
			if ($self->{_version} == 4) { 
				$self->{_data_hlen} = unpack('n', substr($buf, 0x0054, 2)); 
				$self->{_seg_tot} = unpack('n', substr($buf, 0x0062, 2))+1;
				$self->{_seg_size} = unpack('N', substr($buf, 0x0066, 4));
				$self->{_data_end} = unpack('N', substr($buf, 0x0018, 4)) +	unpack('n', substr($buf, 0x001c, 2))*$self->{_seg_size};
				$self->{_rec_tot} = unpack('N', substr($buf, 0x0034, 4));
				$hdr_kcnt = unpack('C', substr($buf, 0x0078, 1));
				$hdr_zip = unpack('C', substr($buf, 0x0079, 1));
				$hdr_enc = unpack('C', substr($buf, 0x007a, 1));
				# get keys data
				$self->{_data_keys} = [] if ($hdr_kcnt > 0);
				for my $i (0 .. $hdr_kcnt-1) {
					my $key_segs = unpack('C', substr($buf, 0x00a0+$i*(11+16*3)+7, 1));
					$self->{_data_keys}->[$i] = [] if ($key_segs > 0);
					for my $j (0 .. $key_segs-1) {
						$self->{_data_keys}->[$i]->[$j] = [
							unpack('C', substr($buf, 0x00a0+$i*(11+16*3)+11+$j*3+0, 1)),	# size
							unpack('n', substr($buf, 0x00a0+$i*(11+16*3)+11+$j*3+1, 2))		# offset
						];
					}
				}
				last READ_HDR; 
			}
			if ($self->{_version} == 5) { 
				$self->{_data_hlen} = unpack('n', substr($buf, 0x0068, 2)); 
				$self->{_seg_tot} = unpack('n', substr($buf, 0x0076, 2))+1;
				$self->{_seg_size} = unpack('N', substr($buf, 0x007a, 4));
				$self->{_data_end} = unpack('N', substr($buf, 0x001c, 4)) +	unpack('n', substr($buf, 0x0020, 2))*$self->{_seg_size};
				$self->{_rec_tot} = unpack('N', substr($buf, 0x003e, 4));
				$hdr_kcnt = unpack('C', substr($buf, 0x009d, 1));
				$hdr_zip = unpack('C', substr($buf, 0x009e, 1));
				$hdr_enc = unpack('C', substr($buf, 0x009f, 1));
				# get keys data
				$self->{_data_keys} = [] if ($hdr_kcnt > 0);
				for my $i (0 .. $hdr_kcnt-1) {
					my $key_segs = unpack('C', substr($buf, 0x00c2+$i*(10+16*6)+7, 1));
					$self->{_data_keys}->[$i] = [] if ($key_segs > 0);
					for my $j (0 .. $key_segs-1) {
						$self->{_data_keys}->[$i]->[$j] = [
							unpack('n', substr($buf, 0x00c2+$i*(10+16*6)+10+$j*6+0, 2)),	# size
							unpack('N', substr($buf, 0x00c2+$i*(10+16*6)+10+$j*6+2, 4))		# offset
						];
					}
				}
				last READ_HDR; 
			}
		}
		# check for unsupported archives
		$hdr_zip == 0 || die "compressed DBs are not supported (yet)\n";
		$hdr_enc == 0 || die "encrypted DBs are not supported (yet)\n";
		# check if all segments files are open-able
		close(_open_db_segment($self->{_db_fpath}.$self->{_db_fname}, $_) || die "some data files are unavailable\n") for (1 .. $self->{_seg_tot}-1);
		# finalize init
		$self->{_rec_cur} = ($self->{_data_start} > 0) ? 0 : -1;
		$self->{_seg_cur} = 0;
		$self->{_data_cur} = $self->{_data_start};
	}; 
	if ($@) {
		close $self->{_fh} if ($self->{_fh});
		chomp $@;
		$self->{_err} = @_;
		#Carp::carp "Unable to initialize DB: $@";
warn "\n*** $@\n";
		return undef;
	}

	bless ($self, $class);
	return $self;
}

################
## destructor ##
################
sub DESTROY {

	my ($self) = @_;

	_free_vars($self);
}

###############################
# Free object, discard all    #
#   in:	 -                    #
#   out: -                    #
###############################
sub free {

	my ($self) = @_;

	close($self->{_fh});
	_free_vars($self);
}

###################################
# get records counter             #
#   in:	 -                        #
#   out: $scalar (record counter) #
###################################
sub records {

	my $self = shift;
	return $self->{_rec_tot};
}

####################################
# get/set curr.record ptr          #
#   in:	 $recno                    #
#        neg.values count from end #
#   out: $scalar (curr.record)     #
#        undef if error            #
####################################
sub recno {

	my $self = shift;
    if (@_) {
		my $rec = shift;
		$rec += $self->{_rec_tot} if ($rec < 0);
		eval {
			$rec >= 0 || die "requested record is below BOF\n";
			$rec < $self->{_rec_tot} || die "requested record is beyond EOF\n";
			$self->reset if ($rec < $self->{_rec_cur});
			while ($rec > $self->{_rec_cur}) { _read_next($self) } 
			#while ($rec > $self->{_rec_cur}) { (my $d = _read_next($self)) || return undef; undef $d } 
		};
		if ($@) {
			chomp $@;
			$self->{_err} = $@;
			#Carp::carp "Unable to set recno: $@";
			return undef;
		}
	}
	return $self->{_rec_cur};
}

##################################
# reset records counter          #
#   in:	 -                       #
#   out: $scalar (curr.record=0) #
#        undef if error          #		
##################################
sub reset {
	
	my $self = shift;

	my $fh = $self->{_fh};
	eval {
		$self->{_data_start} > 0 || die "cannot reset on an empty DB\n";
		$fh = _open_db_segment($self->{_db_fpath}.$self->{_db_fname}, 0) if ($self->{_seg_cur} != 0);
		(seek($fh, $self->{_data_start}, SEEK_SET) || die "seek error ($!)\n") if ($self->{_data_start} > 0);
	}; 
	if ($@) {
		chomp $@;
		$self->{_err} = $@;
		#Carp::carp "Unable to reset recno: $@";
		return undef;
	}
	close $self->{_fh} if ($fh != $self->{_fh});
	$self->{_fh} = $fh;
	$self->{_rec_cur} = ($self->{_data_start} > 0) ? 0 : -1;
	$self->{_seg_cur} = 0;
	$self->{_data_cur} = $self->{_data_start};
	return 0;
}

################################
# get next record              #
#   in:  -                     #
#   out: $record_objref        #
#        undef if error        #
################################
sub next {

	my $self = shift;

	my $rec_ref;
	eval {
		$self->{_data_start} > 0 || die "cannot next on an empty DB\n";
		my $data_ref = _read_next($self);
		$rec_ref = VisionDB::Read::record->new($data_ref);
		undef $data_ref;
	};
	if ($@) {
		chomp $@;	
		$self->{_err} = $@;
		#Carp::carp "Unable to read next record: $@";
		return undef;
	}
	return $rec_ref;
}

###############################
# get DB base name            #
#   in:  -                    #
#   out: $scalar (base name)  #
###############################
sub filename {

	my $self = shift;
	return $self->{_db_fname};
}

###############################
# get version number          #
#   in:  -                    #
#   out: $scalar (version)    #
###############################
sub version {

	my $self = shift;
	return $self->{_version};
}

###############################
# get error number            #
#   in:  -                    #
#   out: $scalar (error num.) #
###############################
sub error {

	my $self = shift;
	return $self->{_err};
}

################################
# get fields structure         #
#   in:  -                     #
#   out: $array (fields array) #
################################
sub fields {

	my $self = shift;

    my @f = ();
	foreach my $key (@{$self->{_data_keys}}) {	# each key
		foreach my $seg (@$key) {				# each segment
			my ($len, $off) = @$seg;
			push(@f, $off) if (!exists { map { $_ => 1 } @f }->{$off});
			push(@f, $off+$len) if (!exists { map { $_ => 1 } @f }->{($off+$len)});
		}
	}
	return sort {$a <=> $b} @f;
}

#############################################
# sub-package VisionDB::Read::record        #
#                                           #
# just a data container...                  #
#############################################

package VisionDB::Read::record;

use strict;

our (@ISA, @EXPORT, @EXPORT_OK);

#################
## constructor ##
#################
sub new {

	my ($class, $dataref) = @_;
	my $self = {
		_data	=> $dataref->[0],
		_len	=> $dataref->[1],
	};
	bless($self, $class);
	return $self;
}

################
## destructor ##
################
sub DESTROY {

	my $self = shift;

	undef $self->{_data};
	undef $self->{_len};
}

###############################
# Free object, discard all    #
#   in:	 -                    #
#   out: -                    #
###############################
sub dispose {

	my $self = shift;
	
	undef $self->{_data};
	undef $self->{_len};
}

###############################
# Get data ref                #
#   in:	 -                    #
#   out: $data_ref            #
###############################
sub data {

	my $self = shift;

	return $self->{_data};
}
	
###############################
# Get data len                #
#   in:	 -                    #
#   out: $data_len            #
###############################
sub size {

	my $self = shift;

	return $self->{_len};
}

1;
__END__

=pod

=head1 NAME

VisionDB::Read - Vision DB v.4-5 files parser

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

	use VisionDB::Read;

	# constructor
	my $vision = VisionDB::Read->new('filename');

	# error checking
	print $vision->{error};

	# get some DB infos
	print "File name is: ".$vision->filename."\n";
	print "File is a VisionDB version ".$vision->version."\n";
	print "DB has ".($vision->records+0)." record(s)\n";

	# acquire fields infos
	my @fields = $vision->fields;
	for ($i=0; $i<scalar(@fields); $i++) {
		print "Field $i found at offset ".$fields[$i]."\n";
	}

	# move record ptr
	$vision->reset;         # reset record ptr to 1st record
	$vision->recno(0);      # same thing
	$vision->recno(100);    # goto record #100
	$vision->recno(-1);     # goto last record
	$vision->recno(-10);    # goto 10th record from end

	# get current record number
	print "Current record is: ".($vision->recno+0)."\n";

	# read all data records
	$vision->reset;
	while ($rec = $vision->next) {    # get next record
		print "Record size is ".($rec->size+0)." bytes\n";
		print "Raw data is: ".$rec->data."\n";
		# free the data memory
		$rec->dispose;
	}

	# destructor
	$vision->free;

=head1 DESCRIPTION

This modules parses data from AcuCobol Vision DBs V.4-5 to permit a simple 
way to export the contained data. It offers also a way to discover the data
inner fields by examining the index keys headers. 
This module doesn't use indexes to read data, so index files are generally 
ignored during processing and output dump is ordered using natural DB order.
VisionDB::Read is a pure Perl implementation and doesn't require any 
external library.

=head2 METHODS of I<VisionDB::Read> object

=over 4 

=item B<new($filename)>

This method creates the class object and opens the DB file(s).
It takes one scalar argument B<$filename> specifying the pathname of the 
first DB file (Vision DBs may consist in one or more data files, plus 
indexes). 
The return value is a reference to the newly created VisionDB object or 
B<undef> if any error occurred. 

=item B<free()>

This method frees the class object and releases (closes) the DB files. 
It has no return value.

=item B<reset()>

This method moves the record pointer to the beginning of the DB and returns
the current record number (always 0) or undef if any error occurred; in the
latter case the error message may be read using the B<error> attribute.

=item B<next()>

This method reads the record data and moves the pointer to the next record.
It returns a reference to the newly created record object. 
If there are no more records to read, it returns B<undef> and the current
record number is set to -1. 
If any error occurred, B<undef> is returned and the corresponding error 
message may be read using the B<error> attribute.

=back

=head2 METHODS of I<VisionDB::Read::record> object

=over 4 

=item B<dispose()>

Frees-up the memory used by the record object. This will render the record 
data unusable. Mostly useful for effectively managing big records sets, 
saving some RAM space. This method has no return value.

=back

=head2 ATTRIBUTES of I<VisionDB::Read> object

=over 4 

=item B<version>

This attribute returns the version of the opened DB file.
The return value is a scalar; this is a read-only attribute.

=item B<filename>

This attribute returns the base name (without path) of the DB file.
The return value is a scalar containing the filename or B<undef> if 
no DB was opened; this is a read-only attribute.

=item B<error>

This attribute returns the error code of last executed operation.
The return value is a scalar containing the error string or B<undef>
if no error; this is a read-only attribute.

=item B<records>

This attribute returns the records count of the opened DB file.
The return value is a scalar; this is a read-only attribute.

=item B<recno>

This attribute sets/returns the current record pointer of the opened DB file.
The return value is a scalar or B<undef> if error is detected.
The first record is always at 0. When at EOF this attribute returns -1; 
setting a negative value sets the current recno starting from the end of DB, 
so -1 means the last record, -2 the 2nd from the end, and so on. 
If any error occurred, the error message may be read using the B<error> attribute.

=item B<fields>

This attribure returns an array containing the fields offsets inside records; these
infos are extracted from index keys data, unfortunately they aren't guaranteed to 
be 100% accurate, they just could give a good idea about how each record is built; 
this is a read-only attribute.

=back

=head2 ATTRIBUTES of I<VisionDB::Read::record> object

=over 4

=item B<size>

This attribute returns the size of the whole record data.
The return value is a scalar.

=item B<data>

This attribute returns the raw data from the current record. The content is
not guaranteed to be an ASCII text, so always use the B<size> attribute to
determine the effective data block length. The return value is a scalar.

=back

=head1 SUPPORT

To request for some support you may try to use the mailing list at

L<http://www.opendiogene.it/mailman/listinfo/opendiogene-users>

Bugs should be reported via mailing list at

L<http://www.opendiogene.it/mailman/listinfo/opendiogene-bugs>

=head1 AUTHOR

Riccardo Scussat - OpenDiogene Project E<lt>r.scussat@dsplabs.netE<gt>

=head1 COPYRIGHT

The code in this module is released under GNU GPLv2.

Copyright (C) 2009 - 2011 R.Scussat - OpenDiogene Project.

This program is free software; you can redistribute
it and/or modify it under the terms of supplied license.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

