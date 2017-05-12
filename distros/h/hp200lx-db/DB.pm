#
# FILE %gg/perl/HP200LX/DB.pm
#
# access HP 200LX database files
# See POD Section for a few more details
#
# work area:
#   decode_type14
#   dump_type .. export everything in ASCII format
#   loader .. import everything from ASCII format
#
# written:       1997-12-28 (c) g.gonter@ieee.org
# latest update: 2001-02-09 17:22:39
# $Id: DB.pm,v 1.13 2001/03/05 01:52:39 gonter Exp $
#

package HP200LX::DB;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK @REC_TYPE);
use Exporter;

$VERSION= '0.09';
@ISA= qw(Exporter);
@EXPORT_OK= qw(openDB saveDB
  fmt_date fmt_time pack_date hex_dump
);

use HP200LX::DB::vpt;     # view point management, including vpt definition

# ----------------------------------------------------------------------------
my $no_note= 65535;             # note number if there is no note
my $no_val=  65535;             # NIL, empty list, -1 etc.
my $no_time= 32768;             # empty time field
my $no_year=   255;             # empty year, mon, day elements
my $no_mon=    255;
my $no_day=    255;
my $no_date=   255;             # ... no_date values
my $delim= '-'x 74;             # optic delimiter

# ----------------------------------------------------------------------------
my @REC_TYPE=           # HP's internal record type definitions
(
  'DBHEADER',           # 0
  'PASSWORD',           # 1: only present when a password was set
  '',                   # 2
  '',                   # 3
  'CARDDEF',            # 4
  'CATEGORY',           # 5
  'FIELDDEF',           # 6
  'VIEWPTDEF',          # 7 sort and subset
  '',                   # 8
  'NOTE',               # 9
  'VIEWPTTABLE',        # 10 table of viewpoint entries
  'DATA',               # 11
  'LINKDEF',            # 12: usually smart clips
  'CARDPAGEDEF',        # 13
  '',                   # 14 APP:
                        #    + ADB: appt_info
  'SMART_CLIP',         # 15 APP: smart clip def in appt.adb (GG)
                        #    + ADB: appt_list (adbio)
  '',                   # 16 APP
  '',                   # 17 APP
  '',                   # 18 APP
  '',                   # 19 APP
  '',                   # 20 APP
  '',                   # 21 APP
  '',                   # 22 APP
  '',                   # 23 APP
  '',                   # 24 APP
  '',                   # 25 APP
  '',                   # 26 APP
  '',                   # 27 APP
  '',                   # 28 APP
  '',                   # 29 APP
  '',                   # 30 APP
  'LOOKUPTABLE'         # 31
# 14..30 application specific!
);
sub REC_TYPE { my $num= shift; $REC_TYPE[$num] || "USER_TYPE_$num"; }

# ----------------------------------------------------------------------------
my @FIELD_TYPE=            # HP's internal field type definitions
(
  { 'Desc' => 'BYTEBOOL',     'Size' => 1, },      #  0
  { 'Desc' => 'WORDBOOL',     'Size' => 2, },      #  1 .. e.g. check box
  { 'Desc' => 'STRING',       'Size' => 2, },      #  2
  { 'Desc' => 'PHONE',        'Size' => 2, },      #  3
  { 'Desc' => 'NUMBER',       'Size' => 2, },      #  4
  { 'Desc' => 'CURRENCY',     'Size' => 2, },      #  5
  { 'Desc' => 'CATEGORY',     'Size' => 2, },      #  6
  { 'Desc' => 'TIME',         'Size' => 2, },      #  7     Test: store
  { 'Desc' => 'DATE',         'Size' => 3, },      #  8     Test: store
  { 'Desc' => 'RADIO_BUTTON', 'Size' => 2, },      #  9     Note: should be 1 byte but it uses 2 bytes!
  { 'Desc' => 'NOTE',         'Size' => 2, },      # 10     Store: seems to work now
  { 'Desc' => 'GROUP',        'Size' => 0, },      # 11
  { 'Desc' => 'STATIC',       'Size' => 0, },      # 12: Label
  { 'Desc' => 'MULTILINE',    'Size' => 0, },      # 13 ??
  { 'Desc' => 'LIST',         'Size' => 0, },      # 14
  { 'Desc' => 'COMBO',        'Size' => 0, },      # 15
  { 'Desc' => 'U16',          'Size' => 0, },      # 16: WDB time zone difference
  { 'Desc' => 'U17',          'Size' => 0, },      # 17
  { 'Desc' => 'U18',          'Size' => 1, },      # 18: ADB "Repeat Status"
  { 'Desc' => 'U19',          'Size' => 3, },      # 19: ADB "Start Date"
  { 'Desc' => 'U20',          'Size' => 2, },      # 20: ADB "Due Date"
  { 'Desc' => 'U21',          'Size' => 0, },      # 21
  { 'Desc' => 'U22',          'Size' => 2, },      # 22: ADB "Priority"
  { 'Desc' => 'U23',          'Size' => 2, },      # 23: ADB "#consecutive days"
  { 'Desc' => 'U24',          'Size' => 2, },      # 24: ADB "Leadtime"
  { 'Desc' => 'U25',          'Size' => 0, },      # 25
);

# ----------------------------------------------------------------------------
# The HP-LX's password protection engine uses a two constant code blocks:
# CODE_A is 127 byte long, CODE_B is 17 byte long
my @CODE_A=
(
  0xe8, 0xa3, 0xfe, 0x1b, 0x02, 0xce, 0x40, 0x35,
  0xa4, 0x7b, 0xf2, 0xa1, 0x70, 0xd5, 0x40, 0x65,
  0x09, 0x42, 0x23, 0xff, 0xaa, 0xed, 0xf0, 0x2a,
  0xa2, 0xa9, 0x38, 0xd7, 0xe5, 0x95, 0xea, 0x8c,
  0x46, 0xdd, 0x90, 0x94, 0x5e, 0x6b, 0x5d, 0xa4,
  0x7b, 0x8c, 0xea, 0x24, 0xa1, 0x7c, 0xaf, 0x30,
  0x62, 0x2a, 0xa5, 0x8e, 0xad, 0x67, 0xde, 0x3f,
  0xb3, 0xe3, 0x53, 0xde, 0x19, 0x42, 0xf8, 0x40,
  0x96, 0xe8, 0x15, 0x75, 0x43, 0x08, 0x2f, 0xe9,
  0xb1, 0x4f, 0x1d, 0xd5, 0xa9, 0x16, 0x2c, 0xfb,
  0x9f, 0x0f, 0xb2, 0xcc, 0xe4, 0x27, 0xbc, 0x1b,
  0x49, 0xa6, 0x90, 0x79, 0x03, 0x9a, 0xa6, 0x1a,
  0x70, 0x89, 0x9d, 0x35, 0x81, 0xad, 0x80, 0xb0,
  0x79, 0x45, 0x21, 0x5f, 0x94, 0x1c, 0xd1, 0x3f,
  0xdf, 0xa8, 0xa3, 0x40, 0x31, 0x34, 0x66, 0x84,
  0x85, 0x28, 0xf1, 0x8d, 0x82, 0x04, 0xa4
);

my @CODE_B=
(
  0x09, 0x0b, 0x09, 0x0f, 0x09, 0x0b, 0x09, 0x77,
  0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
  0x78
);
my @DIAG_K;  # used for diagnosing the decryption functions

# 17 byte code to decrypt the password
my @PW_CODE=
(
  0xE1, 0xA8, 0xF4, 0x17, 0x0B, 0xE7, 0x09, 0x75,       # 0x00
  0xD2, 0x6B, 0x9F, 0x84, 0x2D, 0x9A, 0x3F, 0x05,       # 0x08
  0x71
);

# ----------------------------------------------------------------------------
my %XHDR=       # debugging: headers that will not be printed
(
  'sig' => 1, 'time' => 1, 'lookup_table_offset' => 1,
  'recheader' => 1, 'file_type' => 1,
);

# ----------------------------------------------------------------------------
# create a new (empty) database object
sub new
{
  my $class= shift;
  my $fnm= shift;
  my $apt= shift || &derive_apt ($fnm);

  # print ">>> NEW: fnm='$fnm' apt='$apt'\n";
  my $i;
  my $Types= [];
  my @t= localtime (time);

  for ($i= 0; $i < 32; $i++) { push (@$Types, []); }

  my $obj=
  {
    'Filename'  => $fnm,

    'APT'       => $apt,                # application type
                                        # GDB: generic database (default)
                                        # NDB: note taker (NDB == GDB)
                                        # ADB: appointment book
                                        # WDB: world time
    'APT_Data'  => {},                  # application specific extension data

    'Header'    =>                      # see loader, save
    {
      'sig'       => "hcD\000",
      'recheader' =>
      {
        'type'      => 0,
        'status'    => 0,
        'length'    => 25,
        'idx'       => 0,
      },

      'time'      =>
      {
        'year'      => $t[5]+1900,
        'mon'       => $t[4]+1,
        'day'       => $t[3],
        'min'       => $t[2]*60 + $t[1],
      },

      # guessed data from other examples
      'release_version' => 0x0102,
      'file_type'       => &get_apt ($apt),
      'file_status'     => 0,
      'cur_viewpt'      => 0,
      'num_recs'        => 0,
      'lookup_table_offset' => 0,
      'viewpt_hash'     => 0x8525,    # "Magic Code"
                        #  0x8437 for US american 100LX
    },

    'Types' => $Types,          # DB records of each type

    # pre-processed internal datatypes
    'fielddef'          => [],  # data descriptions of fields
    'carddef'           => [],  # window descriptions of fields
    'cardpagedef'       => [],  # description for the four cards
    'viewptdef'         => [],  # view point definitins; list/sort/filter
    'viewpttable'       => [],  # cached view point table

    'update'            => 0,   # number of items modified
  };

  bless $obj, $class;
}

# ----------------------------------------------------------------------------
sub get_apt
{
  my $APT= shift || 'GDB';
  my $code= 0x44; # generic database, GDB and PDB

     if ($APT eq 'ADB') { $code= 0x32; }
  elsif ($APT eq 'NDB') { $code= 0x4E; }
  elsif ($APT eq 'WDB') { $code= 0x57; }
  # else: gdb, pdb: GDB  (generic data base)

  $code;
}

# ----------------------------------------------------------------------------
sub decode_apt
{
  my $code= shift;
  my $APT= 'GDB';

     if ($code == 0x32) { $APT= 'ADB'; }
  elsif ($code eq 0x4E) { $APT= 'NDB'; }
  elsif ($code eq 0x57) { $APT= 'WDB'; }

  $APT;
}

# ----------------------------------------------------------------------------
sub derive_apt
{
  my $fnm= shift;
  my $APT= 'GDB';       # generic database

     if ($fnm =~ m/\.adb$/i) { $APT= 'ADB'; }   # appointment book
  elsif ($fnm =~ m/\.ndb$/i) { $APT= 'NDB'; }   # note taker
  elsif ($fnm =~ m/\.wdb$/i) { $APT= 'WDB'; }   # world time application
  # else: gdb, pdb: GDB  (generic data base)

  $APT;
}

# ----------------------------------------------------------------------------
# open a given file and read the database into memory
sub openDB
{
  my $fnm= shift;
  my $APT= shift;
  my $dont_decrypt= shift;

  my $obj= new HP200LX::DB ($fnm, $APT);
  $APT= $obj->{APT};  # use application detection logic in new
  my $b;
  my $sig;
  local *FI;

  unless (open (FI, $fnm))
  {
    print "ERROR: could not open DB file '$fnm'!\n";
    return undef;
  }
  binmode (FI); # MS-DOS systems need this, T2D: how about Mac?

  read (FI, $sig, 4);

  # BEGIN to read the db header; see save
  my $recheader= &get_recheader (*FI);
  my $lng= $recheader->{'length'};
  print "WARNING lng=$lng, 25 expected!\n" unless ($lng == 25);

  read (FI, $b, 19);  # lng minus length of record header: 19+6= 25
  my ($release_version, $file_type, $file_status,
      $cur_viewpt, $num_recs, $lookup_table_offset,
      $year, $mon, $day, $min, $viewpt_hash)= unpack ('vCCvvVCCCvv', $b);
  # END to read the record header

  my $time=
  {
    'year'      => $year+1900,
    'mon'       => $mon+1,
    'day'       => $day+1,
    'min'       => $min,
  };

  my $hdr=
  {
    'sig'       => $sig,
    'time'      => $time,
    'recheader' => $recheader,

    'release_version'   => $release_version,
    'file_type'         => $file_type,
    'file_status'       => $file_status,
    'cur_viewpt'        => $cur_viewpt,
    'num_recs'          => $num_recs,
    'lookup_table_offset' => $lookup_table_offset,
    'viewpt_hash'       => $viewpt_hash,
  };

  $obj->{Header}= $hdr;
  $APT= $obj->{APT}= &decode_apt ($file_type);
  # &hex_dump ($b);
  # print "APT=$APT file_type=$file_type num_recs=$num_recs",
  #       " cur_viewpt=$cur_viewpt\n";
  # printf ("lookup_table_offset= 0x%08lX\n", $lookup_table_offset);

  # read lookup table
  my ($v, $i, $xrec);
  my @ltbl= (); # lookup table
  my @ftbl= (); # "type first" table

  if ($lookup_table_offset > 0)
  {
    seek (FI, $lookup_table_offset, 0);
    $xrec= &get_recheader (*FI);
    # &print_recheader (*STDOUT, "lookup table (offset=$lookup_table_offset)", $xrec);
    $lng= $xrec->{'length'}-6;
    $i= read (FI, $b, $lng);

    print "WARNING: could not read complete lookup table; read=$i lng=$lng\n"
      unless ($i == $lng);

    $i= $num_recs * 8; # 8 byte per lookup table entry
    print "WARNING: lookup table size seems wrong;",
          " lng=$lng num_recs=$num_recs $num_recs*8=$i\n"
       unless ($i == $lng);

    for ($i= 0; $i < $num_recs; $i++)
    {
      my ($size, $filters, $flags, $off_low, $off)=
        unpack ('vvCCv', substr ($b, $i*8, 8));
      $off= $off*256+$off_low;

      # print "lut [$i] off=$off size=$size\n";
      my $lut=
      {
        'siz'     => $size,
        'off'     => $off,
        'filters' => $filters,
        'flags'   => $flags,
      } ;

      push (@ltbl, $lut);
    }
    # $hdr->{lookup_table_header}= $xrec;
    # $hdr->{lookup_table}= \@ltbl;

    # typefirst table
    #
    # Purpose:
    #   This table points into the lookup table at the position of the
    #   first record of each record type
    # Example:
    #   lookup data for record 3 of type 4 is at: ltbl [ftbl [4] + 3]
    # NOTE:
    #   this is not used here!
    #
    # printf ("typefirst table: 0x%08lX\n", $lookup_table_offset + $lng + 6);
    $i= read (FI, $b, 64);
    print "WARNING: could not read complete typefirst table; read=$i lng=64\n"
      unless ($i == 64);
    for ($i= 0; $i < 32; $i++)
    {
      $v= unpack ('v', substr ($b, $i*2, 2));
      push (@ftbl, $v);
      # print "ftbl[$i]= $v\n";
    }
    # $hdr->{typefirst_table}= \@ftbl;
  } # lookup table read
  # else { print "no lookup table present!\n"; }

  $obj->{Meta}= 'Plaintext';
  $obj->{dont_decrypt}= $dont_decrypt;
  my ($CODE, $CODE_SIZE);       # used to decrypt data records

  for ($i= 0;; $i++)
  {
    my ($off, $siz, $type, $lut);

    if ($lookup_table_offset > 0)
    { # use lookup table to seek each record otherwise read file seqentially
      last if ($i > $#ltbl);

      $lut= $ltbl [$i];

      $off= $lut->{off};
      $siz= $lut->{siz} - 6;

      if ($siz < 0 || $off < 0)
      { # empty record
        # print "[$i] type=???? siz=$siz off=$off\n";
        next;
      }

      seek (FI, $off, 0);
    }

    last unless (defined ($xrec= &get_recheader (*FI)));

    $siz= $xrec->{length}- 6;
    $type= $xrec->{type};
    # the real record data!
    read (FI, $b, $siz);

    if ($type < 0 || $type >= 32)
    {
      print "WARNING: unknown record type: $type; IGNORED\n";
      &print_recheader (*STDOUT,
                        "record [$i] type=$type siz=$siz off=$off",
                        $xrec);
      &hex_dump ($b);
      next;
    }

    if (defined ($lut))
    { # additional record data from the LUT
      $xrec->{off}= $off;
      $xrec->{flags}= $lut->{flags};
      $xrec->{filters}= $lut->{filters};
    }

    &analyze_record ($obj, $xrec, $i, $b);
  }
  # print "LUT table size: i=$i\n";

  close (FI);

  $obj;
}

# ----------------------------------------------------------------------------
sub analyze_record
{
  my ($obj, $xrec, $i, $b)= @_;

  my $type= $xrec->{type};
  my $siz= $xrec->{length}-6;

  # $xrec only contains only fields from the LUT
  # filters:length:type:off:status:flags:idx
  # inserts only $xrec->{data} which contains the (decrypted) data

    if ($type > 1 && $obj->{Meta} eq 'Encrypted' && !$obj->{dont_decrypt})
    {
      # print "DATA encoded \n"; &hex_dump ($b);

      $b= &decrypt_data ($b, $siz, $obj->{Key});

      # print "DATA decoded\n"; &hex_dump ($b); print "\n";
    }

    $xrec->{data}= $b;

    # specially handled objects
    if ($type == 9) # NOTE
    { # note records may be missing, but they are accessed according
      # to their index, thus leave the blank entries in the table.
      $obj->{Types}->[9]->[$xrec->{idx}]= $xrec;
      return;
    }

    push (@{$obj->{Types}->[$type]}, $xrec);

    if ($type > 1
        && $obj->{Meta} eq 'Encrypted'
        && $obj->{dont_decrypt})
    { # no usuefull data to process if encrypted
      return;
    }

    # Main DB type decoder
    if ($type == 0)
    { # record header; this is actually read twice and was already
      # decoded, see above
      # NOTE: The DB header seems to get modified as soon as an
      #       application opens the database to indicate it is busy
      #       by setting the viewpoint table offset to NULL
    }
    elsif ($type == 1)
    { # password record; this code is very experimental!
      $obj->{Meta}= 'Encrypted';

      if ($obj->{dont_decrypt})
      { # do not attempt to decrypt this password
        return;
      }

      # decode and print the password
      my ($pass, $key)= &decrypt_password ($b, $siz);
      $obj->{Password}= $pass;
      $obj->{Key}= $key;
      # print "session key:\n";
      # &hex_dump ($key);
    } # END of type == 1 processing; password record

    elsif ($type == 4) # CARDDEF
    { # only one record of this type allowed!!
      $obj->{carddef}= &get_carddef ($b);
    }
    elsif ($type == 6) # FIELDDEF
    {
      my ($fdef, $rec_size)= &get_fielddef ($b);
      push (@{$obj->{fielddef}}, $fdef);
      $obj->{rec_size}= $rec_size if ($rec_size > $obj->{rec_size});
    }
    elsif ($type == 7) # VIEWPTDEF
    {
      # print ">>> view point defintion\n"; &hex_dump ($b);
      my $vptd= &get_viewptdef ($b);
      # $vptd->show_viewptdef (*STDOUT);
      push (@{$obj->{viewptdef}}, $vptd);
      $vptd->{index}= $#{$obj->{viewptdef}};
    }
    elsif ($type == 10) # VIEWPTTABLE
    {
      # print ">>> view point table\n"; &hex_dump ($b);
      push (@{$obj->{viewpttable}}, &get_viewpttable ($b));
    }
    elsif ($type == 13) # CARDPAGEDEF
    { # only none or one record of this type allowed!!
      $obj->{cardpagedef}= &get_cardpagedef ($b);
    }

    unless ($REC_TYPE[$type])
    {
      # application specific data
      my $APT= $obj->{APT};

      if ($type == 14 && $APT eq 'ADB')
      {
        $obj->decode_type14 (*STDOUT, $b);
      }
      else
      { # dump info about other unknown field types
        my $off= $xrec->{off} || 'SEQ';
        print "[$i] off=$off siz=$siz type=$type APT='$APT'\n";
        &print_recheader (*STDOUT, "record [$i]:", $xrec);

        # print "b='$b'\n";
        &hex_dump ($b);
        $obj->{has_unknown_records}++;
      }
    }
}

# ----------------------------------------------------------------------------
sub has_errors
{
  my $self= shift;
  return 1 if ($self->{has_unknown_records});
  0;
}

# ----------------------------------------------------------------------------
sub saveDB
{
  my $self= shift;
  my $fnmo= shift || $self->{Filename};

  my $hdr= $self->{Header};
  my $Types= $self->{Types};

  my ($type, $Data, $rec, $lng, $idx);

  # fixup header if necessary
  $Data= $Types->[0];

  my ($off)= 4;
  my (@lut, @ftype, $ftype);   # lookup table and first type table
  my $lut= 0;
  my $num_recs= 0;

  # calculate lookup table and firsttype table
  # . for each record type: calculate size of each entry
  # print "lut_size= $#lut $lut\n";
  for ($type= 0; $type < 32; $type++)
  {
    push (@ftype, $lut);
    $Data= $Types->[$type];

    for ($idx= 0; $idx <= $#$Data; $idx++)
    {
      $rec= $Data->[$idx];

      # print ">>> save: type=$type idx=$idx\n";

      # T2D, TEST: note records may be blank!!
      if (defined ($rec))
      { # populated record to be saved
        $lng= length ($rec->{data});

        $rec->{off}= $off;
        $off += ($rec->{'length'}= $lng + 6);  # 6 off ???
        $rec->{idx}= $idx;

        unless (defined ($rec->{type}))
        { # set type if not alrady done
          $rec->{type}= $type;
        }

        unless (defined ($rec->{status}))
        { # set type if not alrady done
          $rec->{status}= 2; # T2D: status == 2 means what ???
        }
      }
      else
      { # empty record, set up an entry for the lookup table
        print ">>>>> save rec type=$type idx=$idx undefined!\n";

        $rec=
        {
          off     => 0,
          'length'=> 0,
          flags   => 0,
          filters => 0,
        };
      }

      $lut [$lut++]= $rec;
      $num_recs++;
    }
  }

  # print "lut_size= $#lut $lut num_recs=$num_recs off=$off\n";

  $hdr->{lookup_table_offset}= $off;
  $hdr->{num_recs}= $num_recs;

  local *FO;
  open (FO, ">$fnmo") || die;
  binmode (FI); # MS-DOS systems need this, T2D: how about Mac?

  # save db header; see also loader
  print FO $hdr->{sig};
  &put_recheader (*FO, $hdr->{recheader});
  my $time= $hdr->{'time'};
  my $b= pack ('vCCvvVCCCvv',
           $hdr->{release_version},
           $hdr->{file_type}, $hdr->{file_status},
           $hdr->{cur_viewpt}, $hdr->{num_recs},
           $off, # lookup_table_offset
           $time->{year}-1900, $time->{mon}-1,
           $time->{day}-1, $time->{min},
           $hdr->{viewpt_hash},
         );
  print FO $b;

  # save each record for each type
  for ($type= 1; $type < 32; $type++)
  {
    $Data= $Types->[$type];

    for ($idx= 0; $idx <= $#$Data; $idx++)
    {
      $rec= $Data->[$idx];

      next unless (defined ($rec->{data})); # empty records
      # print ">>> save data records type=$type idx=$idx\n";
      &put_recheader (*FO, $rec);
      print FO $rec->{data};
    }
  }

  # print "lut_size= $#lut $lut\n";

  # save lookup table
  $rec=
  {
    'type'      => 31,
    'status'    => 0,
    'length'    => ($#lut+1)*8+6,
    'idx'       => 0,
  };

  &put_recheader (*FO, $rec);
  foreach $lut (@lut)
  {
    my $off_low= $lut->{off}%256;
    my $off= $lut->{off}/256;

    my $b= pack ('vvCCv', 
             $lut->{'length'},
             $lut->{filters}, $lut->{flags},
             $off_low, $off
           );

    print FO $b;
  }

  # save firsttype table
  foreach $ftype (@ftype)
  {
    my $b= pack ('v', $ftype);
    print FO $b;
  }

  close (FO);
}

# ----------------------------------------------------------------------------
sub print_summary
{
  my $db= shift;
  my $prt_hdr= shift;

  my $hdr= $db->{Header};
  my $t= $hdr->{time};
  my $min= $t->{min};
  my $h= int ($min/60);
  $min= $min%60;

  printf ("Type %-24s  Recs View   Hash %-16s Comment\n",
          'Filename', 'created')
    if ($prt_hdr);

  my $Comment;
  $Comment .= ' CORRUPTED!' if ($db->has_errors);
  $Comment .= ' Password' if ($db->{Meta} eq 'Encrypted');

  printf ("%-4s %-24s %5d %4d 0x%04X %4d-%02d-%02d %2d:%02d%s\n",
          $db->{APT}, $db->{Filename},
          $hdr->{num_recs},
          $hdr->{cur_viewpt}, $hdr->{viewpt_hash},
          $t->{year}, $t->{mon}, $t->{day}, $h, $min,
          $Comment,
         );
}

# ----------------------------------------------------------------------------
sub get_field_def
{
  my $self= shift;
  my $num= shift;

  $self->{fielddef}->[$num];
}

# ----------------------------------------------------------------------------
sub show_db_def
{
  my $self= shift;
  local *FO= shift;

  my $Fdef= $self->{'fielddef'};
  my $field;
  my $num= 0;
  my %off= (); # sorted by offset
  my $off;

  my $hdr= sprintf ("[##] ## %-12s Siz %-24s FID  Off  Res  Flg\n",
                    "Type", "Name");
  print FO $delim, "\n";
  print FO "DB def by field number\n", $hdr;

  foreach $field (@$Fdef)
  {
    $off= &show_field_def (*FO, $field, $num++);
    push (@{$off{$off}}, $field);
  }

  $num= 0;

  print FO $delim, "\n", "DB def by offset position\n", $hdr;
  foreach $off (sort keys %off)
  {
    foreach $field (@{$off{$off}})
    {
      &show_field_def (*FO, $field, $num);
    }
    $num++
  }

  print FO $delim, "\n";
}

# ----------------------------------------------------------------------------
sub show_card_def
{
  my $self= shift;
  local *FO= shift;

  my $Cdef= $self->{'carddef'};
  return if ($#$Cdef < 0);
  my ($field, $f);

  print FO "card definition:\n";
  my $i= 0;
  foreach $field (@$Cdef)
  {
    # &show_field_window ($field);
    printf FO ("field [%2d]:", $i++);
    foreach $f (sort keys %$field)
    {
      if ($f eq 'Parent' || $f eq 'Style')
      {
        printf (" %s=%8X,", $f, $field->{$f});
      } else {
        printf (" %s=%3d,", $f, $field->{$f});
      }
    }
    print "\n";
  }
}

# ----------------------------------------------------------------------------
sub dump_data
{
  my $self= shift;

  my $APT= $self->{APT};
  my $T= $self->{Types} || die;
  my $D= $T->[11];  # array of data records
  my $N= $T->[9];   # array of note records

  my $rec_beg= shift || 0;
  my $rec_end= shift || $#$D;
  my $Fdef= shift || $self->{fielddef};  # array of field definitions

  my ($rec, $field);

  print "show_data\n";
  foreach $rec ($rec_beg .. $rec_end)
  {
    my $d= $D->[$rec] || next;
    my $b= $d->{data} || next;

    my ($ok, $o)= &fetch_data ($b, $Fdef, $N, $APT);
    &dump_data_record ($b, $ok, $o);
  }
}

# ----------------------------------------------------------------------------
sub dump_type
{
  my $self= shift;
  local *FO= shift;
  my $Ty= shift;        # if undef, dump all items
  my $Format= shift || 'auto';

  # print '# ', join (' ', keys %$self), "\n";
  my ($T, $Ty_from, $Ty_end);

  unless (defined ($T= $self->{Types}))
  {
    print STDERR "can't access Type table in $self\n";
    return;
  }

  if (defined ($Ty)) { $Ty_from= $Ty_end= $Ty; }
  else { $Ty_from= 0; $Ty_end= 255; }

  for ($Ty= $Ty_from; $Ty <= $Ty_end; $Ty++)
  {
    my $D= $T->[$Ty];
    my $c= $#$D;
    next if ($c == -1);

    my $format= $Format;
    if ($Format eq 'auto')
    { # see @REC_TYPE
      if ($Ty == 5 || $Ty == 9 || $Ty == 11) { $format= 'QP'; }
      else { $format= 'HEX'; }
    }

    my $ty_str= $REC_TYPE[$Ty] || "USER$Ty";

    my ($i, $Dk, $Dv, $cp, $ch, $cv, $lng, $llng);
    for ($i= 0; $i <= $c; $i++)
    {
      print FO "<record>$Ty $ty_str $i/$c\n";

      $Dv= $D->[$i];
      # NOTE: fields not written: off (completely redundant)
      # off, filters, and flags come from the LUT
      # print FO '# ZZ ', join (' ', keys %$Dv), "\n";
      foreach $Dk (qw(type idx length status filters flags))
      {
        next unless (defined ($Dv->{$Dk}));
        print FO "<$Dk>$Dv->{$Dk}\n";
      }

      print FO "<data fmt=$format>\n";
      if ($format eq 'HEX')
      {
        &hex_dump ($Dv->{data}, *FO);
      }
      else # especially if ($format eq 'QP')
      {
        my $data= $Dv->{data};
        $lng= length ($data);
        for ($cp= 0; $cp < $lng; $cp++)
        {
          $cv= unpack ('C', $ch= substr ($data, $cp, 1));

          if (($cv >= 0x00 && $cv <= 0x1F)
              || ($cv >= 0x3C && $cv <= 0x3E)
              || ($cv >= 0x7F && $cv <= 0xFF)
             )
          {
            $ch= sprintf ("=%02X", $cv);
            $llng += 3;
          }
          else { $llng++; }

          print FO $ch;
          if ($llng > 72) { print FO "=\n"; $llng= 0; }
        }
        if ($llng > 0) { print FO "\n"; $llng= 0; }
      }

      print FO "</data>\n</record>\n\n";
    }
  }
}

# ----------------------------------------------------------------------------
# load ASCII file; name should be changed...
sub loader
{
  my $self= shift;
  local *FI= shift;

  my $status= 'undef';
  my ($rec, $counter, $b, $format);
  while (<FI>)
  {
    chomp;
    # print ">>> $_\n";

    if (m#<record>#)
    {
      $rec= {};
      $status= 'record';
      $counter++;
      $b= '';
    }
    elsif (m#</record>#)
    {
      if ($status ne 'record' && $status ne 'data')
      {
        print "WARNING: unexpected status $status\n";
      }

      # analyze header if necessary:
      # filters:length:type:off:status:flags:idx
      # print ">>> insert record: ", join (':', %$rec), "\n";
      # &hex_dump ($b);
      &analyze_record ($self, $rec, $counter, $b);
      $status= 'undef';
    }
    elsif (m#<data fmt=(.+)>#)
    {
      $format= $1;
      $status= 'data';
    }
    elsif (m#</data>#)
    {
      $status= 'record';
    }
    elsif (m#<(type|idx|length|status|filters|flags)>(.*)#)
    {
      $rec->{$1}= $2;
    }
    elsif ($status eq 'data')
    {
      if ($format eq 'QP')
      {
        s/=$//;
        s/=([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $b .= $_;
      }
      elsif ($format eq 'HEX')
      {
        my @x= split (/\|/);
        @x= split (' ', $x[0]);
        shift (@x);
        # print "[", join (':', @x), "]\n";
        $b .= pack ("C*", map { hex ($_); } @x);
      }
      else
      {
        print "WARNING: unexpected data format: '$format'\n";
      }
    }
    elsif (/^#/ || /^[ \t]*$/) {} # comment
    else
    {
      print "WARNING: unexpected data: '$_'\n";
    }
  }
}

# ----------------------------------------------------------------------------
sub TIEARRAY
{
  return $_[1];
}

# ----------------------------------------------------------------------------
sub FETCH
{
  my $db= shift;
  my $idx= shift;

  my $T= $db->{Types} || die 'not a database';
  my $D= $T->[11];      # array of data records
  return undef if ($idx > $#$D);

  my $Dx= $D->[$idx];   # data record for the given index
  my $rv;

  unless (defined ($rv= $Dx->{obj}))
  { # no record data was previously stored, fetch that
    my $N= $T->[9];   # array of note records
    my $F= $db->{fielddef};
    my $b= $Dx->{data};
    my $APT= $db->{APT};

    # print "FETCH: T=$T D=$D N=$N F=$F b=$b\n";
    my ($ok, $o)= &fetch_data ($b, $F, $N, $APT);
    # &dump_data_record ($b, $ok, $o);

    $Dx->{obj}= $rv= $o;
    $Dx->{ok}= $ok;
  }

  return $rv;
}

# ----------------------------------------------------------------------------
sub FETCH_data_raw
{
  my $db= shift;
  my $idx= shift;

  my $T= $db->{Types} || return undef;
  my $D= $T->[11];      # array of data records
  return undef if ($idx > $#$D);

  $D->[$idx]->{data};   # data record for the given index
}

# ----------------------------------------------------------------------------
sub FETCH_note_raw
{
  my $db= shift;
  my $idx= shift;

  my $T= $db->{Types} || return undef;
  my $N= $T->[9];      # array of note records
  return undef if ($idx > $#$N);

  $N->[$idx]->{data};   # data record for the given index
}

# ----------------------------------------------------------------------------
sub STORE
{
  my $db= shift;
  my $idx= shift;
  my $val= shift;
  # print "STORE: ", join (':', %$val), "\n";

  my $T= $db->{Types} || die;
  my $D= $T->[11];  # array of data records
  my $N= $T->[9];   # array of note records
  my $F= $db->{fielddef};
  my $APT= $db->{APT};

  my $Dx;

  if ($idx > $#$D)
  {
    # print "adding records: num=$#$D idx=$idx\n";
    $Dx= { 'data' => '' };
  }
  else
  {
    $Dx= $D->[$idx];   # data record for the given index
  }

  my ($ok, $b)= &store_data ($val, $F, $N, $APT, $db->{rec_size});

  $Dx->{data}= $b;
  undef ($Dx->{obj});
  undef ($Dx->{ok});
  $D->[$idx]= $Dx;

  # T2D: unfinished
  # missing items: refreshing and/or invalidating view points
  $db->{update}++;
}

# ----------------------------------------------------------------------------
sub STORE_data_raw
{
  my $db= shift;
  my $idx= shift;
  my $data= shift;

  my $T= $db->{Types} || die;
  my $D= $T->[11];  # array of data records
  $D->[$idx]->{data}= $data;
  $db->{update}++;
}

# ----------------------------------------------------------------------------
sub STORE_note_raw
{
  my $db= shift;
  my $idx= shift;
  my $data= shift;

  my $T= $db->{Types} || die;
  my $N= $T->[9];   # array of note records
  $N->[$idx]->{data}= $data;
  $db->{update}++;
}

# ----------------------------------------------------------------------------
sub FETCHSIZE
{
  my $db= shift;
  return 1 + $db->get_last_index();
}

# ----------------------------------------------------------------------------
sub get_last_index
{
  my $db= shift;

  my $T= $db->{Types} || die;
  my $D= $T->[11];      # array of data records
  return $#$D;
}

# ----------------------------------------------------------------------------
sub get_str
{
  my $b= shift;
  my $off= shift;

  my $res= substr ($$b, $off);
  my $idx= index ($res, "\000");
  $res= substr ($res, 0, $idx) if ($idx >= 0);
  $res;
}

# ----------------------------------------------------------------------------
sub fmt_date
{
  my $str= shift;

  my ($year, $mon, $day)= unpack ('CCC', $str);
  ($year == $no_year && $mon == $no_mon && $day == $no_day)
  ? '' # empty date field
  : sprintf ("%d-%02d-%02d", 1900 + $year, $mon+1, $day+1);
}

# ----------------------------------------------------------------------------
sub pack_date
{
  my $val= shift;
  my ($year, $mon, $day);

  $year= $mon= $day= $no_date;
  if ($val =~ /(\d+)-(\d+)-(\d+)/)
  {
    ($year, $mon, $day)= ($1, $2, $3);
    # check for valid dates otherwise set no_date value
    $year= $mon= $day= $no_date
    if ($year < 1900 || $year > 2155
        || $mon < 1 || $mon > 12
        || $day < 1 || $day > 31);

    $year -= 1900;
    $mon--;
    $day--;
  }

  pack ('CCC', $year, $mon, $day);
}

# ----------------------------------------------------------------------------
sub fmt_time
{
  my $str= shift;

  my $val= unpack ('v', $str);
  return '' if ($val == $no_time || $val == $no_val);

  my $min= $val % 60;
  my $xval= int ($val / 60);
  sprintf ("%d:%02d", $xval, $min);
}

# ----------------------------------------------------------------------------
sub fetch_data
{
  my $b=        shift;  # raw binary data
  my $Fdef=     shift;  # Field Definitions
  my $N=        shift;  # Notes Data
  my $APT=      shift;  # application type

  my $ok= 1;
  my %o;
  my %RB;     # radio button at offset
  my $field;

  my @Fdef= @$Fdef;     # Field Definition List
  my $APT2;

  if ($APT eq 'ADB')
  { # For appointment book entries we have to analyze if
    # the record describes a to-do item or a date or event

    my $val= unpack ('C', substr ($b, 0x0E, 1));
    my @TLT= ();

    #  if ($val & 0x02) { $APT2= 'Done'; } # checked to-do entry
       if ($val & 0x10) { $APT2= 'To-Do'; @TLT= (0, 1, 8..12); }
    elsif ($val & 0x20) { $APT2= 'Event'; @TLT= (0..7, 12, 14, 15); }
    elsif ($val & 0x80) { $APT2= 'Date';  @TLT= (0..7, 12, 14, 15); }

    $o{'type'}= $APT2;
    $o{'repeat'}= unpack ('C', substr ($b, 0x1A, 1));

    @Fdef= map { $Fdef[$_] } @TLT;
  }

  FIELD: foreach $field (@Fdef)
  {
    my $type= $field->{ftype};
    my $off=  $field->{off};
    my $name= $field->{name};
    my $res;
    # printf ("APT= 0x%02X %2d '%s'\n", $off, $type, $name);

      if ($type == 0) # BYTE_BOOL
      {
        my $val= unpack ('C', substr ($b, $off, 1));
        $res= ($val) ? 'X' : '';
      }
      elsif ($type == 1) # WORD_BOOL
      {
        my $val= unpack ('v', substr ($b, $off, 2));
        $res= ($val) ? 'X' : '';
      }
      elsif ($type == 2 && $APT eq 'ADB' && $off eq 0x1B)
      { # Beschreibung bei ADB geht ohne Offset!
        $res= &get_str (\$b, $off);
      }
      elsif ($type == 2         # STRING
             || $type == 3      # PHONE
             || $type == 4      # NUMBER
             || $type == 6      # CATEGORY
            )
      {
        my $offs= unpack ('v', substr ($b, $off, 2));
        $res= &get_str (\$b, $offs);
      }
      elsif ($type == 7  # TIME
             || ($type == 24 && $APT eq 'ADB') # Vorlauf
            )
      {
        #??? next if ($APT eq 'APT' && $APT2 eq 'To-Do'); # overlapping fields
        $res= &fmt_time (substr ($b, $off, 2));
      }
      elsif ($type == 8 # DATE
             || ($type == 19 && $APT eq 'ADB') # Beginndatum
            )
      {
        $res= &fmt_date (substr ($b, $off, 3));
      }
      elsif ($type == 9) # RADIO_BUTTON
      {
        my $val= unpack ('C', substr ($b, $off, 1));  # 2 or 1 byte??
        my $cnt= ++$RB{$off};
        $res= ($cnt == $val) ? 'X' : '';
      }
      elsif ($type == 10) # NOTE
      {
        my $note_number= unpack ('v', substr ($b, $off, 2));
        $o{"$name&nr"}= $note_number;
        unless ($note_number eq $no_note)
        {
          my $nr;
          $nr= $N->[$note_number];    # $nr should be a valid reference!
          $res= (defined ($nr)) ? $nr->{data} : '';
        }
      }
      elsif ($type == 11        # GROUP
             || $type == 12     # STATIC (e.g. Label)
             || $type == 14     # LIST
             || $type == 15     # COMBO
             || ($type == 18 && $APT eq 'ADB') # repeat factor
            ) # no action ?!?!?
      {
        next FIELD;
      }
      elsif ($type == 16 && $APT == 'WDB')
      {
        $res= unpack ('v', substr ($b, $off, 2));
      }
      elsif ($APT eq 'ADB'
             && ($type == 23    # number of days
                 || $type == 20 # date due Faelligkeitsdatum
                )
            )
      {
        next if ($type == 23 && $APT2 eq 'To-Do');
        next if ($type == 20 && $APT2 ne 'To-Do');

        $res= unpack ('v', substr ($b, $off, 2)); # 2 byte integer value
      }
      elsif ($APT eq 'ADB' && $type == 22)
      {
        # print "\n", $delim, "\n>>> U22: APT2='$APT2'\n";
        next unless ($APT2 eq 'To-Do'); # priority code
        $res= substr ($b, $off, 2);
        $res=~ s/\x00//g;
      }
      else
      {
        $res= "unknown type $type";
        &show_field_def (*STDOUT, $field, -1);
        $ok= 0;
      }

    # print "fetch: name=$name res=$res\n";
    $o{$name}= $res;
  }

  return ($ok, \%o);
}

# ----------------------------------------------------------------------------
sub store_data
{
  my $data= shift;      # record data to be stored into the database
  my $Fdef= shift;      # Field Definitions
  my $N= shift;         # Notes Data; array of references
  my $APT= shift;       # application type
  my $rec_size= shift;  # standard record size and next string position

  my $b_off= 0;         # offset into binary data
  my @b=                # binary data at each offset
  my $b;                # final binary data
  my $nil_addr;         # address of the NIL string record
                        # this is set up when there are actually strings
                        # see notes below

  my $ok= 1;
  my %RB;
  my $field;

  # print "rec_size= $rec_size\n";

  # NOTE: ADB records should possibly not be handled here at all!!!

  FIELD: foreach $field (@$Fdef)
  {
    my $type= $field->{ftype};
    my $off=  $field->{off};
    my $name= $field->{name};
    my $ex=   (exists ($data->{$name})) ? 1 : 0;        # data value present?
    my $val=  $data->{$name};                           # actual value
    my $APT2;

    $APT2= $data->{type} if ($APT eq 'ADB');

    # print "offset= $off type=$type name=$name val='$val'\n";

      if ($type == 0)           # BYTEBOOL
      {
        $b [$off]= pack ('C', ($val) ? 1 : 0);
      }
      elsif ($type == 1)        # WORDBOOL
      {
        $b [$off]= pack ('v', ($val) ? 1 : 0);
      }
      elsif ($type == 2         # STRING
             || $type == 3      # PHONE
             || $type == 4      # NUMBER
             || $type == 6      # CATEGORY
            )
      {
        if ($nil_addr eq '')
        { # create empty string which is used for all other empty strings
          # see note below
          $nil_addr= $rec_size;
          $b [$rec_size++]= "\000";
          # print "insert nil at $nil_addr, rec_size=$rec_size\n";
        }

        if ($val)
        {
          $b [$off] = pack ('v', $rec_size);
          $b [$rec_size]= $val . "\000";
          $rec_size += length ($val) + 1;
        }
        else
        { # store pointer to the empty string record
          $b [$off] = pack ('v', $nil_addr);
        }
        # &hex_dump ($b[$off]);
      }
      elsif ($type == 7)         # TIME
      {
        next if ($APT eq 'ADB' && $APT2 eq 'To-Do');

        my ($h, $m, $t);
        $h= $val;
        ($h, $m)= ($1, $2) if ($val =~ /(\d+)[:\.](\d+)/);
        $t= $h*60+$m;
        $t= $no_time if (!$ex || $t < 0 || $t > $no_time);
        $b [$off]= pack ('v', $t);
      }
      elsif ($type == 8)        # DATE
      {
        $b [$off]= &pack_date ($val);
      }
      elsif ($type == 9)        # RADIO_BUTTON
      { # several radio buttons point to the same offset
        # the value can be the number of the button pointing there
        # or 0 when no button is checked

        my $v;                       # value to be stored
        my $checked= ($val) ? 1 : 0;
        $checked= 0 if ($v= $RB{$off});     # only the first button is valid
        $RB{$off}= $v= $field->{res} if ($checked);

        $b [$off]= pack ('v', $v); # Note: should be 'c' ?!?!
      }
      elsif ($type == 10)       # NOTE
      { # store note record

        # possible cases:
        # stored | new | action
        #     no |  no | no action, $no_note is already stored
        #     no | yes | store new note number
        #    yes |  no | T2D: delete old note, but how??
        #    yes | yes | store note number and replace the note

        my $note_nr= $no_note;
        my $xn= "$name&nr";
        $note_nr= $data->{$xn} if (defined ($data->{$xn}));  # stored note

        if ($note_nr == $no_note && $val ne '')
        { # no note before but a valid note: create new note record
          push (@$N, { data => $val });
          $data->{$xn}= $note_nr= $#$N;
        }
        elsif ($note_nr != $no_note && $val eq '')
        { # T2D: delete note!!
          # this leaves an empty note record in the database !!!
          undef ($N->[$note_nr]->{data}); # T2D, Test
          $data->{$xn}= $note_nr= $no_note;
        }
        elsif ($note_nr != $no_note && $val ne '')
        { # replace existing note
          $N->[$note_nr]->{data}= $val;
        }

        $b [$off]= pack ('v', $note_nr);
      }
      elsif ($type == 11        # GROUP
             || $type == 12     # STATIC
             || $type == 14     # LIST
             || $type == 15     # COMBO
            ) # no action ?!?!?
      {
        next FIELD;
      }
      else
      {
        print "store_data: ERROR! unknown type $type\n";
        &show_field_def (*STDOUT, $field, -1);
        print "value: $val\n";
        $ok= 0;
      }
  }

  if ($ok)
  {
    $b= join ('', @b);

    if (length ($b) != $rec_size)
    {
      print "ERROR: resulting record size does not match!\n",
            "length=", length ($b), " rec_size=$rec_size\n";
      &hex_dump ($b);
      my ($x, $y);
      for ($x= 0; $x <= $#b; $x++)
      {
        next unless ($y= $b[$x]);
        printf ("[%02d] %2d '%s'\n", $x, length ($y), $y);
      }
    }
  }

  # T2D: unfinished
  return ($ok, $b);
}

# NOTES:
# Empty Strings are stored as null character at the beginning of the
# extended data record.  All empty strings point to the same address.
# An empty string is stored even when all strings have a value.

# ----------------------------------------------------------------------------
# read a 6 byte record header
sub get_recheader
{
  local *F= shift;
  my $b;

  read (F, $b, 6) || return undef;
  my ($type, $status, $length, $idx)= unpack ('CCvv', $b);

  my $rec=
  {
    'type'      => $type,
    'status'    => $status,
    'length'    => $length,
    'idx'       => $idx,
  };

  $rec;
}

# ----------------------------------------------------------------------------
# write a 6 byte record header
sub put_recheader
{
  local *F= shift;
  my $r= shift;

  my $b= pack ('CCvv', $r->{'type'}, $r->{'status'},
                       $r->{'length'}, $r->{'idx'});
  print F $b;
}

# ----------------------------------------------------------------------------
sub fmt_time_stamp
{
  my $time= shift;
  my $Time= sprintf ("%d-%02d-%02d %2d:%02d",
                    $time->{'year'}, $time->{'mon'}+1, $time->{'day'}+1,
                    $time->{'min'} / 60, $time->{'min'} % 60);

  $Time;
}

# ----------------------------------------------------------------------------
sub get_carddef
{
  my $def= shift;
  my @wins;
  my $num= 0;

  # print ">>> processing card definition\n";
  while ($def)
  {
    my $pw= substr ($def, 0, 20);
    $def= substr ($def, 20);

    my ($u, $x, $y, $w, $h, $Lsize, $style, $parent)=
       unpack ('VvvvvvVv', $pw);

    # printf ("[%3d] x=%3d y=%3d w=%3d h=%3d L=%3d S=0x%08lX P=0x%04X\n",
    #         $num, $x, $y, $w, $h, $Lsize, $style, $parent);

    $num++;

    my $win=
    {
      'x' => $x,
      'y' => $y,
      'w' => $w,
      'h' => $h,
      'Lsize' => $Lsize,
      'Style' => $style,
      'Parent' => $parent,
    };

    push (@wins, $win);
  }

  \@wins;
}

# ----------------------------------------------------------------------------
sub get_fielddef
{
  my $def= shift;

  my ($ftype, $fid, $off, $flg, $res)= unpack ('CCvCv', $def);
  my $name= substr ($def, 7, length ($def)-8);
  $name=~ s/\&//g;

  my $fd=
  {
    'ftype'     => $ftype,
    'Ftype'     => $FIELD_TYPE [$ftype]->{Desc},
    'fid'       => $fid,
    'off'       => $off,
    'flg'       => $flg,
    'res'       => $res,
    'name'      => $name,
  };

  $off += $FIELD_TYPE [$ftype]->{Size};
  ($fd, $off);
}

# ----------------------------------------------------------------------------
sub get_cardpagedef
{
  my $def= shift;

  # print ">>> processing card page definition\n";
  my @pages;
  my ($PW, $CP, $PC, @ps, @pc, $i);

  ($PW, $CP, $PC,
   $ps[1], $ps[2], $ps[3], $ps[4],
   $pc[1], $pc[2], $pc[3], $pc[4])= unpack ('vvvvvvvvvv', $def);

  # print ">>>> CP=$CP PC=$PC\n";
  for ($i= 1; $i <= $PC; $i++)
  {
    push (@pages, { 'num' => $i, 'start' => $ps[$i], 'size' => $pc[$i] });
    # print ">>>>> [$i] start=$ps[$i] size=$pc[$i]\n";
  }

  \@pages;
}

# ----------------------------------------------------------------------------
sub show_field_def
{
  local *FO= shift;
  my $fdef= shift;
  my $num= shift;

  my $type= $fdef->{'ftype'};
  my $ftype= $FIELD_TYPE[$type];
  my $ttype= $ftype->{Desc} || "USER$type";
  my $x_siz= $ftype->{Size};
  my $x_off= sprintf ('0x%02X', $fdef->{off});
  my $x_flg= sprintf ('0x%02X', $fdef->{flg});
  my $x_name= $fdef->{name};
  $x_name=~ s/[\x80-\xFF]/?/g;

  printf FO "[%02d] %2d %-12s %3s %-24s %3d %s 0x%02X %s\n",
            $num, $type, $ttype, $x_siz, "'$x_name'",
            $fdef->{fid}, $x_off, $fdef->{res}, $x_flg;

  # print FO "<td>'$x_name'\n";
  # print FO "[$num] type= $ttype ($type) name='$fdef->{name}'"
  #          " id=$fdef->{fid} off=$x_off res=$fdef->{res} flg=$x_flg\n";

  $x_off;
}

# ----------------------------------------------------------------------------
sub decode_type14          # analyze application specific field type 14
{
  my $obj= shift;
  local *FO= shift;
  my $b= shift;

  my $AD= $obj->{APT_Data};
  my $lng= length ($b);

  my ($off, $d, $v);
  if (defined ($AD->{View_Table}))
  {
    print <<EOX;
Warning: type 14 in data base appears more than twice.
Please send a sample of your database to the author
    &hex_dump ($b);
EOX
  }
  elsif (defined ($AD->{Header}))
  {
    my @View_Table;
    for ($off= 0; $off+5 <= $lng; $off += 5)
    {
      $d= &fmt_date (substr ($b, $off, 3));
      $v= unpack ('v', substr ($b, $off+3, 2));
      last if ($v eq $no_val);  # end marker
      push (@View_Table, { 'date' => $d, num => $v } );
      # print FO "    date=$d num=$v\n";
    }
    $AD->{View_Table}= \@View_Table;
    # &hex_dump ($b);
  }
  else
  {
    $d= &fmt_date (substr ($b, 0, 3));
    $AD->{Head_Date}= $d;
    $AD->{Header}= $b;
  }
}

# ----------------------------------------------------------------------------
sub print_recheader
{
  local *FH= shift;
  my $txt= shift;
  my $r= shift;

  my @extra= @_;
  my $fld;
  my $type= $r->{'type'};
  my $ttype= $REC_TYPE[$type] || "USER$type";

  print "$txt\n";

  print "  type= $ttype ($type)\n";
  foreach $fld ('status', 'length', 'idx', @extra)
  {
    print "  $fld= $r->{$fld}\n";
  }
}

# ----------------------------------------------------------------------------
sub dump_def
{
  my $self= shift;
  local *FO= shift;
  my $level= shift;

  my $hdr= $self->{Header};
  my $Time= &fmt_time_stamp ($hdr->{'time'});

  my $fld;
  my $sig= substr ($hdr->{sig}, 0, 3);
  my $x_ltable= sprintf ("0x%08lX", $hdr->{lookup_table_offset});
  my $APT= &decode_apt ($hdr->{file_type});

  print FO <<EOX;
Filename: $self->{Filename}
Meta: $self->{Meta}
DB Header:
  sig= $sig
  time= $Time
  lookup_table_offset= $x_ltable
  file_type= $hdr->{file_type} $APT
EOX

  foreach $fld (sort keys %$hdr)
  {
    print FO "  $fld= $hdr->{$fld}\n" unless (defined ($XHDR{$fld}));
  }

  # &print_recheader (*FO, 'record header:', $hdr->{recheader});
  # print FO 'self:: ', join (',', sort keys %$self), "\n";

  # $level= 0 if ($self->{Meta} eq 'Encrypted' && $level < 10);

  if ($level > 0)
  {
    $self->show_db_def (*FO);
    # $self-> show_card_def (*FO);
  }

  if ($level > 1)
  {
    print FO $delim, "\n\n";
    for ($fld= 0; $fld < 32; $fld++)
    {
      $self->dump_db (*FO, $fld);
    }
  }
}

# ----------------------------------------------------------------------------
sub dump_db
{
  my $self= shift;
  local *FO= shift;
  my $type= shift;
  my $idx= shift;

  my $Types= $self->{Types};
  my $Data= $Types->[$type];
  my ($el, $i);

  if (defined ($idx))
  {
    $el= $Data->[$idx];
    &dump_db_rec (*FO, $idx, $el);
    return;
  }

  $idx= 0;
  foreach $el (@$Data)
  {
    &dump_db_rec (*FO, $idx, $el);
    $idx++;
  }
}

# ----------------------------------------------------------------------------
sub dump_db_rec
{
  local *FO= shift;
  my $i= shift;
  my $el= shift;

    unless (defined ($el))
    {
      print FO "data record [$i] not defined!\n";
      return;
    }

    &print_recheader (*FO, "data record [$i]", $el, 'filters', 'flags');
    # print FO "el= ", join (':', keys %$el), "\n";
    print FO "data=\n";
    &hex_dump ($el->{data}, *FO);
    print FO $delim, "\n\n";
}

# ----------------------------------------------------------------------------
sub dump_data_record
{
  my $b= shift;
  my $ok= shift;
  my $o= shift;

  print "dump_data_record:\n";
  print join (':', %$o), "\n";
  # print "note: $nd\n" if ($nd);

  unless ($ok && 0)
  {
    &hex_dump ($b);
  }
}

# ----------------------------------------------------------------------------
sub hex_dump
{
  my $data= shift;
  local *FX= shift || *STDOUT;

  my $off= 0;
  my ($i, $c, $v);

  while ($data)
  {
    my $char= '';
    my $hex= '';
    my $offx= sprintf ('%08X', $off);
    $off += 0x10;

    for ($i= 0; $i < 16; $i++)
    {
      $c= substr ($data, 0, 1);

      if ($c ne '')
      {
        $data= substr ($data, 1);
        $v= unpack ('C', $c);
        $c= '.' if ($v < 0x20 || $v >= 0x7F);

        $char .= $c;
        $hex .= sprintf (' %02X', $v);
      }
      else
      {
        $char .= ' ';
        $hex  .= '   ';
      }
    }

    print FX "$offx $hex |$char|\n";
  }
}

# ----------------------------------------------------------------------------
# Decrypt the password of a HP 200LX Database.
# This function implements the algorithm in Curtis Cameron's dbcheck program.
# Returns a session key and the original password.  I'm not quite sure
# if the original password is correct in all cases, this needs more testing.
sub decrypt_password
{
  my ($b, $siz)= @_;
  my ($pass, $key);

  if ($siz != 17)
  {
    print "WARNING: decrypt_password (siz=$siz): ",
          "password block size should be 17 byte!\n";
  }

  my ($i, $c, $k, $p);
  for ($i= 0; $i < 17; $i++)
  {
    $c= unpack ('C', substr ($b, $i, 1));
    $k= $c ^ $i ^ $CODE_A[$i];
    # my $diag= sprintf ("%02X ^ %02X ^ A[%3d]=%02X", $c, $i, $i, $CODE_A[$i]);

    # this CODE_B round cancels the effect of the same thing in decrypt_data
    # $k ^= $CODE_B[$i];
    # $diag .= sprintf (" ^ B[%2d]=%02X", $i, $CODE_B[$i]);

    push (@$key, $k);
    # push (@DIAG_K, $diag);

    $p= $PW_CODE [$i] ^ $c;
    $pass .= pack ('C', $p) if ($p > 0x00);
  }

  print "database is encrypted\npassword record, encrypted, siz=$siz\n";
  &hex_dump ($b);
  print "password record, decryption attempted (1)\n";
  &hex_dump ($pass);
  print "password= '$pass'\n";

  ($pass, $key);
}

# ----------------------------------------------------------------------------
# Decrypt the data portion of a HP 200LX Database record.
# This function implements the algorithm in Curtis Cameron's dbcheck program.
sub decrypt_data
{
  my ($b, $siz, $code_ref)= @_;

  my ($cc, $c0, $bb);
  my ($c_a, $c_b, $c_k);
  my ($ii, $i_127, $i_17);
  for ($ii= 0; $ii < $siz; $ii++)
  {
    $c0= unpack ('C', substr ($b, $ii, 1));

    $c_a= $CODE_A [$i_127];
    $c_k= $code_ref->[$i_17];
    $cc= $c0 ^ $c_k ^ $c_a;

    # my $diag= sprintf ("[%4d] %02X ^ K[%2d]=(%s)=%02X ^ A[%3d]=%02X",
    #             $ii, $c0,
    #             $i_17, $DIAG_K[$i_17], $c_k,
    #             $i_127, $c_a);

    # this CODE_B round cancels the effect of the same thing in decrypt_password
    # $c_b= $CODE_B [$i_17];
    # $cc ^= $c_b;
    # $diag .= sprintf (" ^ B[%3d]=%02X", $i_17, $c_b);

    if ($ii > 126)
    {
      my $ti;
      for ($ti= $ii-127; $ti >= 0; $ti -= 127)
      {
        $c_b= $CODE_B [$ti % 17];
        $cc ^= $c_b;
        # $diag .= sprintf (" ^ B[%3d]=%02X", $ti%17, $c_b);
      }
    }
    # $diag .= sprintf (" =: %02X %c", $cc, $cc); print $diag, "\n";

    $bb .= pack ('C', $cc);
    $i_17= 0  if (++$i_17  >=  17);
    $i_127= 0 if (++$i_127 >= 127);
  }

  $bb;
}

# ----------------------------------------------------------------------------
sub recover_password
{
  my $self= shift;
  my $note_nr= shift;
  my $ptx_fnm= shift;
  my $key_fnm= shift;

  # fetch encrypted note
  my $T= $self->{Types} || die;
  my $D= $T->[11];  # array of data records
  my $N= $T->[9];   # array of note records
  my $enc_txt= $N->[$note_nr]->{data};
  # print "encrypted text:\n"; &hex_dump ($enc_txt);

  # fetch plain text
  my $ptx_txt;
  open (FI, $ptx_fnm) || die;
  while (<FI>) { $ptx_txt .= $_; }
  close (FI);
  # print "plain text:\n"; &hex_dump ($ptx_txt);

  # recover the key
  my ($pp, $cc, $ee, $ii, $key);
  my $ll_enc= length ($enc_txt);
  my $ll_ptx= length ($ptx_txt);
  print "text size enc=$ll_enc plain=$ll_ptx\n";

  for ($ii= 0; $ii < $ll_ptx; $ii++)
  {
    $pp= unpack ('C', substr ($ptx_txt, $ii, 1));
    $ee= unpack ('C', substr ($enc_txt, $ii, 1));
    $cc= $pp ^ $ee ^ $ii;
    $key .= pack ('C', $cc);
  }

  # print "the key is\n"; &hex_dump ($key);

  print "dumping key to $key_fnm\n";
  open (FO, ">$key_fnm") || die;
  binmode (FI); # MS-DOS systems need this, T2D: how about Mac?
  print FO $key;
  close (FO);
}

# ----------------------------------------------------------------------------
sub get_field_type
{
  my $ty= shift;
  $FIELD_TYPE[$ty];
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# POD Section

=head1 NAME

HP200LX::DB - Perl module to access HP-200 LX database files

=head1 SYNOPSIS

  use HP200LX::DB;

  interface functions:
    $db= HP200LX::DB::openDB ($fnm)     read database and return an DB object
    $db= new HP200LX::DB ($fnm)         create database and return an DB object
    $db->saveDB ($fnm)                  save DB object as a (new) file

  array tie implementation to access database data records:
    tie (@dbd, HP200LX::DB, $db);       access database data in array form
    TIEARRAY                            stub to get an tie for the database
    FETCH                               retrieve a record
    STORE                               store a record

  additional data retrieval and storage methods:
    $db->FETCH_data_raw ($idx)          retrieve raw data record
    $db->FETCH_note_raw ($idx)          retrieve raw note record
    $db->STORE_data_raw ($idx, $data)   store raw data record
    $db->STORE_note_raw ($idx, $note)   store raw note record
    $db->get_last_index ()              return highest index

  internal methods:
    $db->show_db_def (*FH)              show database definition
    $db->show_card_def (*FH)            show card layout definition
    $db->get_field_def ($num)           retrieve field definition
    $db->print_summary ($header)        print DB summary line;
                                        print also header if $header==1
    show_field_def                      show a field definition
    fetch_data                          used by FETCH to get db record
    store_data                          used by STORE to save db record
    get_recheader                       read gdb internal record structure
    put_recheader                       store gdb internal record structure
    fmt_time_stamp                      create a readable date and time string
    get_fielddef                        decode a field definition record
    get_carddef                         decode a card definiton record

  Diagnostics and Debugging methods:
    $db->dump_db (*FH, $type)           dump a complete data base
    $db->dump_data                      dump all data records
    $db->recover_password               attempt to reconstruct DB password

  Diagnostics and Debugging functions:
    print_recheader (*FH, $txt, $rec)   print details about a record
    dump_def                            dump database definition
    dump_data_record                    print and dump data record
    hex_dump                            perform a hex dump of some data
    decrypt_password                    attempt to decote the DB password
    decrypt_data                        attempt to decode a DB recrod

=head1 DESCRIPTION

  DB.pm implements the Perl package HP200LX::DB which is intended
  to provide a Perl 5 interface for files in the generic database
  format of the HP 200LX palmtop computer.  The Perl modules are
  intended to be used on a work station such as a PC or a Unix
  machine to read and write data records from and to a database
  file.  These modules are not intended to be run directly on the
  palmtop!

  Please see the README file for a few more details or consult
  the examples which can be found at the web site mentioned below.

=head1 Copyright

  Copyright (c) 1998-2001 Gerhard Gonter.  All rights reserved.
  This is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

=head1 AUTHOR

  Gerhard Gonter, g.gonter@ieee.org

=head1 SEE ALSO

  http://sourceforge.net/projects/hp200lx-db/,
  perl(1).

=cut
