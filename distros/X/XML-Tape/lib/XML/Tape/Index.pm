#
# $Id: Index.pm,v 1.5 2005/09/01 08:19:27 patrick Exp $
#

=head1 NAME

XML::Tape::Index - a XMLtape indexer 

=head1 SYNOPSIS

 use XML::Tape::Index qw(:all);

 unless (indexexists('ex/tape.xml')) {
     $x = indexopen('ex/tape.xml', 'w');
     $x->reindex;
     $x->indexclose();
 }

 $x = indexopen('ex/tape.xml', 'r');

 for (my $rec = $x->list_identifiers();
      defined($rec);
      $rec = $x->list_identifiers($rec->{token})) {
     print "id     : %s\n" , $rec->{identifier};
     print "date   : %s\n" , $rec->{date};
     print "start  : %s\n" , $rec->{start};
     print "length : %s\n" , $rec->{len};
 }

 my $rec = $x->get_identifier('oai:arXiv.org:hep-th:0208183');
 my $xml = $x->get_record('oai:arXiv.org:hep-th:0208183');

=head1 DESCRIPTION

This modules creates an index on XMLtapes to enable fast retrieval of XML documents
from the archive. The index files are stored next to the XMLtape.

=cut
package XML::Tape::Index;
use strict;
use DB_File;
use XML::Tape;
use Digest::MD5 qw(md5);
require Exporter;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.5 $ ' =~ /\$Revision:\s+([^\s]+)/;;

@XML::Tape::Index::ISA = qw(Exporter);
@XML::Tape::Index::EXPORT_OK = qw(indexopen indexexists indexdrop);
%XML::Tape::Index::EXPORT_TAGS = (all => [qw(indexopen indexexists indexdrop)]);
$XML::Tape::Index::VERBOSE = 0;
$XML::Tape::Index::CACHE_SIZE = 4 * 1024 * 1024;

sub _get_index {
    my ($filename) = @_;
    return {
        adm_index_file => "$filename.adm" ,
        rec_index_file => "$filename.rec" ,
        dat_index_file => "$filename.dat" ,
    }
}

=head1 METHODS

=over 4

=item $x = indexopen($tape_file, $flag)

This function opens an index for reading or writing. The parameter tape_file 
is the location of a XMLtape archive. The flag is "w" when creating a new index or
"r" when reading an index. An XML::Tape::Index instance will be returned on
success or undef on failure.

=cut
sub indexopen {
    my ($tape_file, $flag, $mode) = @_;
    my (%admh,$admh);
    my (%rech,$rech);
    my (%idsh,$idsh);
    my (%dath,$dath);
    $mode = 0644 unless $mode;

    my $files = &_get_index($tape_file);

    my $this = bless {} , 'XML::Tape::Index';
    $this->{mode}      = $flag;

    if ($flag eq 'w') {
        $flag = O_CREAT | O_RDWR;
    }
    elsif ($flag eq 'r') {
        $flag = O_RDONLY;
    }
    else {
        die "usage: indexopen(\$tape_file, 'r' | 'w')";
    }

    my $f_hash = new DB_File::HASHINFO;
    $f_hash->{cachesize} = $XML::Tape::Index::CACHE_SIZE;
    my $f_btree = new DB_File::BTREEINFO;
    $f_btree->{cachesize} = $XML::Tape::Index::CACHE_SIZE;
    $f_btree->{flags} = R_DUP;

    $admh = tie %admh, 'DB_File' ,  $files->{adm_index_file} , $flag, $mode, $f_hash
                   || die "can't tie " . $files->{adm_index_file} . ": $!";
    $rech = tie %rech, 'DB_File' ,  $files->{rec_index_file} , $flag, $mode, $f_hash
                   || die "can't tie " . $files->{rec_index_file} . ": $!";
    $dath = tie %dath, 'DB_File' ,  $files->{dat_index_file} , $flag, $mode, $f_btree
                   || die "can't tie " . $files->{dat_index_file} . ": $!";

    $this->{tape_file} = $tape_file;
    $this->{admh}      = $admh;
    $this->{rech}      = $rech;
    $this->{dath}      = $dath;
    $this->{t_admh}    = \%admh;
    $this->{t_rech}    = \%rech;
    $this->{t_dath}    = \%dath;
    return $this;
}

=item $x->reindex()

This method reads the XMLtape extracts all identifier and datestamps from
it and stores the byte positions of all records in the index.

=cut
sub reindex {
    my ($this) = @_;

    die "reindex: only allowed in 'w' mode" unless ($this->{mode} eq 'w');

    my $num_of_rec = 0;
    my $tape = XML::Tape::tapeopen($this->{tape_file}, 'r') || return undef;

    my $_start = time();
    my $earliest_datestamp = undef;
    while (my $record = $tape->get_record()) {
        $num_of_rec++;
        my $id     = $record->getIdentifier();
        my $date   = $record->getDate();
        my $start  = $record->getStartByte();
        my $length = $record->getEndByte() - $start;
        my $value  = join("\t", $id, $date, $start, $length);
        my $key    = md5($id);
        $this->{rech}->put($key,$value);
        $this->{dath}->put($date,$key);

        if ($XML::Tape::Index::VERBOSE && $num_of_rec % 10000 == 0) {
            my $speed = int($num_of_rec/(time - $_start + 1));
            print "record: $num_of_rec ($speed r/s) read: " . $record->getEndByte() . " bytes\n";
        }

        my $comp_date = $date; $comp_date =~ s/\D+//g;
        if ( ! defined $earliest_datestamp || $earliest_datestamp->{val} > $comp_date ) {
            $earliest_datestamp->{val} = $comp_date;
            $earliest_datestamp->{str} = $date;
        }
    }
    $tape->tapeclose();

    $this->{admh}->put('tapefile', $this->{tape_file});
    $this->{admh}->put('recnum', $num_of_rec);
    $this->{admh}->put('earliest', $earliest_datestamp->{str});

    return $num_of_rec;
}

=item $x->list_identifiers([$token])

=item $x->list_identifiers($from,$until)

Use this method to iterate through the index to return all records. This method
returns an index record on success or undef when no more records are available.
Each index record is a HASH reference containing the fields 'identifier', 'date',
'start' (the starting byte of the XML document in the XMLtape), 'len' (the length of
the XML document in the XMLtape) and 'token'. The 'token' field should be used to
return the next index record. One can filter the returned indexed records by
using two arguments at the first list_identifiers method invocation. Only 
index records with dates greater or equal than 'from' and less than 'until'
will be returned by subsequent list_identifier requests. E.g.

 # Return all index records...
 for (my $r = $x->list_identifiers(); 
      defined($r);
      $r = $x->list_identifiers($r->{token}) {
 }

 # Return all index records with dates between 2000-01-01 and 2005-12-31...
 for (my $r = $x->list_identifiers(
             '2001-01-01T00:00:00Z',
             '2005-12-31T23:59:59Z'
                    );
      defined($r);
      $r = $x->list_identifiers($r->{token}) {
 }

=cut
sub list_identifiers {
    my ($this) = shift;
    my ($from,$until,$md5);
  
    die "list_identifiers: only allowed in 'r' mode" unless ($this->{mode} eq 'r');

    # If we have two arguments we need to filter on 'from' and 'until' date...
    if (@_ == 2) {
        ($from,$until) = @_;
        $this->{'from'}  = $from;
        $this->{'until'} = $until;
    }
    # If we have one argument than it is a resumption token... 
    elsif (@_ == 1) {
        ($from,$md5) = split(/,/,shift,2);
        $md5 = pack("H*",$md5);
        $until = $this->{'until'};
    }
    # Else, we need to return all entries..
    else {
        $from = $until = undef;
        $this->{'from'}  = $from;
        $this->{'until'} = $until;
    }

    my $status;

    if ($md5) {
        $status = $this->{dath}->find_dup($from, $md5);
        $status = $this->{dath}->seq($from, $md5, R_NEXT) if ($status == 0);
    }
    elsif ($from) {
        $status = $this->{dath}->seq($from, $md5, R_CURSOR);
    }
    else {
        $status = $this->{dath}->seq($from, $md5, R_FIRST);
    }

    return undef unless ($status == 0);
    return undef if (defined $until && ($from cmp $until) >= 0);

    my $values;
    $status = $this->{rech}->get($md5,$values);

    return undef unless ($status == 0);

    my (@field) = split(/\t/,$values);
    return {
        'identifier'   => $field[0] ,
        'date'         => $field[1] ,
        'start'        => $field[2] ,
        'length'       => $field[3] ,
        'token'        => $field[1] . "," . unpack("H*",$md5)
    };
}

=item $x->get_earlist_date()

This methods returns earliest date in the index file

=cut
sub get_earliest_date {
    my ($this, $id) = @_;
    my $values;
    $this->{admh}->get('earliest',$values);
    return $values;
}

=item $x->get_tape_file()

This methods returns name of the tape file associated with this index.

=cut
sub get_tape_file {
    my ($this, $id) = @_;
    my $values;
    $this->{admh}->get('tapefile',$values);
    return $values;
}

=item $x->get_num_of_records()

This methods returns the number of record in an index.

=cut
sub get_num_of_records {
    my ($this, $id) = @_;
    my $values;
    $this->{admh}->get('recnum',$values);
    return $values;
}

=item $x->get_identifier($identifier)

This method returns an index record given an identifier as argument. When
no matching index record can be found undef will be returned. The index
record is a HASH reference containing the fields 'identifier', 'date',
'start' and 'len' (see above).

=cut
sub get_identifier {
    my ($this, $id) = @_;
    my $md5 = md5($id);
    my $values;

    die "get_identifier: only allowed in 'r' mode" unless ($this->{mode} eq 'r');

    $this->{rech}->get($md5,$values);

    return undef unless $values;

    my (@field) = split(/\t/,$values);
    return {
        'identifier'   => $field[0] ,
        'date'         => $field[1] ,
        'start'        => $field[2] ,
        'len'          => $field[3] ,
    };
}

=item $x->get_record($identifier)

This method returns an XML document from the XMLtape given an identifier as 
argument. When no matching record can be found undef will be returned.

=cut
sub get_record {
    my ($this, $id) = @_;

    die "get_record: only allowed in 'r' mode" unless ($this->{mode} eq 'r');

    local(*F);
    my $rec = $this->get_identifier($id);
   
    return undef unless $rec;

    my $xml;
    if ($rec->{start} && $rec->{len}) {
        open(F, $this->{tape_file}) || return undef;
        seek(F, $rec->{start}, 0);
        read(F, $xml, $rec->{len});
        close(F);
    }
    return $xml; 
}

=item $x->indexclose();

Closes the XMLtape index.

=cut
sub indexclose {
    my ($this) = @_;

    $this->{admh} = undef;
    $this->{rech} = undef;
    $this->{dath} = undef;
    untie %{$this->{t_admh}};
    untie %{$this->{t_rech}};
    untie %{$this->{t_dath}};
}

=item indexexists($tape_file)

This class method returns true when an index on the XMLtape with location
$tape_file exists, returns false otherwise.

=cut
sub indexexists {
    my ($filename) = @_;
    
    my $files = &_get_index($filename);

    return (-e $files->{adm_index_file} && -e $files->{rec_index_file} && -e $files->{dat_index_file});
}

=item indexdrop($tape_file)

This class method deletes the index associated with the XMLtape with location
$tape_file.

=cut
sub indexdrop {
    my ($filename) = @_;

    my $files = &_get_index($filename);

    unlink $files->{adm_index_file};
    unlink $files->{rec_index_file};
    unlink $files->{dat_index_file};
}

=head1 BUGS

 The XML::Tape::Index doesn't lock XMLtape before writing. It is possible to
 overwrite and index while another process is reading it.

=head1 CREDITS

XMLtape archives were developed by the Digital Library Research & Prototyping
team at Los Alamos National Laboratory.

=head1 SEE ALSO

L<XML::Tape>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=cut
1;
