package Win32::MSI::DB;

=head1 NAME

Win32::MSI::DB - Modify MSI databases

=head1 SYNOPSIS

  use Win32::MSI::DB;

  $database = Win32::MSI::DB::new("filename", $flags);

  $database->transform("filename", $flags);

  $table = $database->table("table");
  $view = $database->view("SELECT * FROM File WHERE FileSize < ?", 100000);

  @rec = $table->records();
  $rec4 = $table->record(4);

  $rec->set("field", "value"); # string
  $rec->set("field", 4);       # int
  $rec->set("field", "file");  # streams

  $rec->get("field");
  $rec->getintofile("field", "file");

  $field = $rec->field("field");
  $field->set(2);
  $data = $field->get();
  $field->fromfile("autoexec.bat");
  $field->intofile("tmp.aa");

  $db->error();
  $view->error();
  $rec->error();

=head1 DESCRIPTION

=head2 Obtaining a database object

C<MSI::DB::new($filename, $mode)> returns a new database object, open
in one of the following modes:

=over 4

=item $Win32::MSI::MSIDBOPEN_READONLY

This doesn't really open the file read-only, but changes will not be
written to disk.

=item $Win32::MSI::MSIDBOPEN_TRANSACT

Open in transactional mode so that changes are written only on commit.
This is the default.

=item $Win32::MSI::MSIDBOPEN_DIRECT

Opens read/write without transactional behaviour.

=item $Win32::MSI::MSIDBOPEN_CREATE

This creates a new database in transactional mode.

=back

A database object allows creation of C<table>s or C<view>s.  If you
simply need access to a table you can use the C<table> method; for a
subset of records or even a SQL-query you can use the C<view> method.

=head2 Using transforms

When you have got a handle to a database, you can successively apply
transforms to it.  You do this by using C<transform>, which needs the
filename of the transform file (normally with extension F<.mst>) and
optionally a flag specification.

Most of the possible flag values specify which merge errors are to be
suppressed.

=over 4

=item $Win32::MSI::MSITR_IGNORE_ADDEXISTINGROW

Ignores adding a row that already exists.

=item $Win32::MSI::MSITR_IGNORE_ADDEXISTINGTABLE

Ignores adding a table that already exists.

=item $Win32::MSI::MSITR_IGNORE_DELMISSINGROW

Ignores deleting a row that doesn't exist.

=item $Win32::MSI::MSITR_IGNORE_DELMISSINGTABLE

Ignores deleting a table that doesn't exist.

=item $Win32::MSI::MSITR_IGNORE_UPDATEMISSINGROW

Ignores updating a row that doesn't exist.

=item $Win32::MSI::MSITR_IGNORE_CHANGECODEPAGE

Ignores that the code pages in the MSI database and the transform file
do not match and neither has a neutral code page.

=item $Win32::MSI::MSITR_IGNORE_ALL

This flag combines all of the above mentioned flags.  This is the
default.

=item $Win32::MSI::MSITR_VIEWTRANSFORM

This flag should not be used together with the other flags.  It
specifies that instead of merging the data, a table named
C<_TransformView> is created in memory, which has the columns
C<Table>, C<Column>, C<Row>, C<Data> and C<Current>.

This way the data in a transform file can be directly queried.

For more information please see
S<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/msi/setup/_transformview_table.asp>.

=back

This doesn't open the file read-only, but changes will not be written
to disk.

A transform is a specification of changed values.  So you get a MSI
database from your favorite vendor, make a transform to overlay your
own settings (the target installation directory, the features to be
installed, etc.) and upon installation you can use these settings via
a commandline similar to

  msiexec /i TRANSFORMS = F<your transform file> F<the msi database> /qb

The changes in a transform are stored by a (table, row, cell, old
value, new value) tuple.

=head2 Fetch records from a table or view

When you have obtained a C<table> or C<view> object, you can use the
C<record> method to access individual records.  It takes a number as
parameter.  Records are fetched as needed.  Using C<undef> as parameter
fetches all records and returns the first (index 0).

Another possibility is to use the C<records> method, which returns an
array of all records in this table or view.

=head2 A record has fields

A record's fields can be queried or changed using the C<record>
object, as in

  $rec->set("field", "value"); # string
  $rec->set("field", 4);       # int
  $rec->set("field", "file");  # streams

  $rec->get("field");
  $rec->getintofile("field", "file");

or you can have separate C<field> objects:

  $field = $rec->field("field");

  $data = $field->get();
  $field->set(2);

Access to files (streams) is currently not finished.

=head2 Errors

Each object may access an C<error> method, which gives a string or an
array (depending on context) containing the error information.

Help wanted: Is there a way to get a error string from the number
which does not depend on the current MSI database?  In particular, the
developer errors (2000 and above) are not listed.

=head1 REMARKS

This module depends on C<Win32::API>, which is used to import the
functions out of the F<msi.dll>.

Currently the C<Exporter> is not used - patches are welcome.

=head2 AUTHOR

Please contact C<pmarek@cpan.org> for questions, suggestions, and
patches (C<diff -wu2> please).

A big thank you goes to DBH for various changes throughout the code.

=head2 Further plans

A C<Win32::MSI::Tools> package is planned - which will allow to
compare databases and give a diff, and similar tools.

I have started to write a simple Tk visualization.

=head1 SEE ALSO

S<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/msi/setup/installer_database_reference.asp>

=cut

use strict;
use warnings;

use Win32::API;

our $VERSION = "1.06";

###### Constants and other definitions

# Shorthand to define API call constants
sub _def
{
  return Win32::API->new("msi", @_, "I") || die $!;
}

my $MsiOpenDatabase = _def(MsiOpenDatabase => "PPP");
my $MsiOpenDatabasePIP = _def(MsiOpenDatabase => "PIP");
my $MsiCloseHandle = _def(MsiCloseHandle => "I");
my $MsiDataBaseCommit = _def(MsiDatabaseCommit => "I");
my $MsiDatabaseApplyTransform = _def(MsiDatabaseApplyTransform => "IPI");
my $MsiViewExecute = _def(MsiViewExecute => "II");
my $MsiDatabaseOpenView = _def(MsiDatabaseOpenView => "IPP");
my $MsiViewClose = _def(MsiViewClose => "I");
my $MsiViewFetch = _def(MsiViewFetch => "IP");
my $MsiRecordGetFieldCount = _def(MsiRecordGetFieldCount => "I");
my $MsiRecordGetInteger = _def(MsiRecordGetInteger => "II");
my $MsiRecordGetString = _def(MsiRecordGetString => "IIPP");
my $MsiRecordGetStringIIIP = _def(MsiRecordGetString => "IIIP");
my $MsiRecordSetInteger = _def(MsiRecordSetInteger => "III");
my $MsiRecordSetString = _def(MsiRecordSetString => "IIP");
my $MsiRecordSetStream = _def(MsiRecordSetStream => "IIP");
my $MsiCreateRecord = _def(MsiCreateRecord => "I");
my $MsiViewGetColumnInfo = _def(MsiViewGetColumnInfo => "IIP");
my $MsiGetLastErrorRecord = _def(MsiGetLastErrorRecord => "");
my $MsiFormatRecord = _def(MsiFormatRecord => "IIPP");

# External constants

our $MSIDBOPEN_READONLY = 0;
our $MSIDBOPEN_TRANSACT = 1;
our $MSIDBOPEN_DIRECT = 2;
our $MSIDBOPEN_CREATE = 3;

our $MSICOLINFO_NAMES = 0;
our $MSICOLINFO_TYPES = 1;
my $_MSICOLINFO_INDEX = 21231231;    # For own use, not defined by MS

our $MSITR_IGNORE_ADDEXISTINGROW = 0x1;
our $MSITR_IGNORE_DELMISSINGROW = 0x2;
our $MSITR_IGNORE_ADDEXISTINGTABLE = 0x4;
our $MSITR_IGNORE_DELMISSINGTABLE = 0x8;
our $MSITR_IGNORE_UPDATEMISSINGROW = 0x10;
our $MSITR_IGNORE_CHANGECODEPAGE = 0x20;
our $MSITR_VIEWTRANSFORM = 0x100;

our $MSITR_IGNORE_ALL =
  $MSITR_IGNORE_ADDEXISTINGROW |
  $MSITR_IGNORE_DELMISSINGROW |
  $MSITR_IGNORE_ADDEXISTINGTABLE |
  $MSITR_IGNORE_DELMISSINGTABLE |
  $MSITR_IGNORE_UPDATEMISSINGROW |
  $MSITR_IGNORE_CHANGECODEPAGE;

my $MSI_NULL_INTEGER = -0x80000000;
my $ERROR_NO_MORE_ITEMS = 259;
my $ERROR_MORE_DATA = 234;

my $COLTYPE_STREAM = 1;
my $COLTYPE_INT = 2;
my $COLTYPE_STRING = 3;
my %COLTYPES = (
  "i" => $COLTYPE_INT, 
  "j" => $COLTYPE_INT, 
  "s" => $COLTYPE_STRING, 
  "g" => $COLTYPE_STRING, 
  "l" => $COLTYPE_STRING, 
  "v" => $COLTYPE_STREAM, 
);

my $INITIAL_EMPTY_STRING = "\0" x 1024;

##### Default Routines

sub new
{
  my ($file, $mode) = @_;

  return undef unless ($file);

  my $hdl = pack("l",0);
  $mode = $MSIDBOPEN_TRANSACT unless (defined($mode));
  if ($mode =~ /^\d+$/)
  {
    # For special values of mode another call
    # is needed (integer instead of pointer)
    $MsiOpenDatabasePIP->Call($file, $mode, $hdl) and return undef;
  }
  else
  {
    $MsiOpenDatabase->Call($file, $mode, $hdl) and return undef;
  }

  my %a = (handle => unpack("l", $hdl));

  return _bless_type(\%a, "db");
}

sub DESTROY
{
  my $self = shift;

  $self->_commit() if ($self->{""} eq "db");

  if ($self->{"handle"})
  {
    _close($self->{"handle"}) and return undef;
  }
  $self = {};
}

##### Public Routines

# Database method to return the records in $table, optionally
# qualified by SQL clause $where with parameters @param

sub table
{
  my ($self, $table, $where, @param) = @_;

  return undef unless (defined $table);

  $self->_check("db");

  my $sql = "SELECT * FROM $table" . (defined $where && " WHERE $where");

  $self->view($sql, @param);
}

# Database method to return the view obtained by executing $sql SELECT
# statement with parameters @param.  If $sql is not a SELECT then
# return an object of "type" "sql".

sub view
{
  my ($self, $sql, @param) = @_;

  $self->_check("db");

  my $hdl = pack("l",0);
  $MsiDatabaseOpenView->Call($self->{"handle"}, $sql, $hdl) and return undef;
  my %s = (handle => unpack("l", $hdl));

  my $a = 0;
  if (@param)
  {
    $a = _newrecord(@param) or return undef;
  }
  $MsiViewExecute->Call($s{"handle"}, $a) and return undef;
  _close($a) if ($a);

  return _bless_type(\%s, "sql") unless ($sql =~ /^\s*SELECT\s/i);

  my $me = _bless_type(\%s, "v");
  $me->get_info(undef);
  $me->{"coltypes"} = [ map($COLTYPES{lc(substr($_->{type}, 0, 1))},
              @{$me->{"colinfo"}}) ];
  return $me;
}

# Given a table or view, return record number $recnum.  Fetch records
# as necessary.  If $recnum is undef, fetch all records and return the
# first.

sub record
{
  my ($self, $recnum) = @_;

  $self->_check("v");

  while (!defined($recnum) || $recnum > $self->{"fetched"})
  {
    my $hdl = pack("l",0);
    last if ($MsiViewFetch->Call($self->{"handle"}, $hdl)
         == $ERROR_NO_MORE_ITEMS);
    $hdl = unpack("l", $hdl);
    $self->{"records"}[$self->{fetched} ++] =
      _bless_type({handle => $hdl, view => $self}, "r");
  }
  return $self->{"records"}[$recnum || 0];
}

sub records
{
  my ($self) = @_;

  $self->_check("v");
  $self->record(undef);

  return @{$self->{"records"}};
}

sub fields
{
  return field(@_);
}

# Return a record's fields with names @names, or the first such in a
# scalar context

sub field
{
  my ($self, @names) = @_;
  my ($cn);

  $self->_check("r");
  my @ret = ();
  for my $n (@names)
  {
    my $i = $self->{"view"}->get_info($_MSICOLINFO_INDEX, $n);
    if (defined $i)
    {
      push @ret, bless_type({rec => $self, 
                   cn => $i->{"index"}}, "f");
    }
    else
    {
      push @ret, undef;
    }
  }
  return @names > 1 || wantarray() ? @ret : $ret[0];
}

sub close
{
  my $self = shift;

  $self->DESTROY();
}

sub get
{
  my ($self, $field) = @_;

  $self->_check("r", "f");

  if ($self->_type() eq "f")      # Get the value of a field
  {
    return $self->{"rec"}{data}[$self->{cn}];
  }

  if (!$self->{"data"})        # Get $field from a record
  {
    $self->{"data"} = [_extract_fields($self->{handle}, 
                       @{$self->{"view"}{coltypes}} ) ];
  }
  my $f = $self->{"view"}->get_info($_MSICOLINFO_INDEX, $field);

  return defined($f) ? $self->{"data"}[$f] : undef;
}

sub set
{
  my ($self, $field, $value) = @_;
  my ($rec, $cn, $type);

  $self->_check("r", "f");

  if ($self->_type() eq "r")      # Set $field of this record
  {
    $rec = $self;
    $cn = $self->{"view"}->get_info($_MSICOLINFO_INDEX, $field);
  }
  else                # Set this field
  {
    $rec = $self->{"rec"};
    $cn = $self->{"cn"};
    $value = $field;        # $field not given
  }

  $type = $rec->{"view"}{coltypes}[$cn];
  $cn++;                # MSI numbers columns from 1
  if ($type == $COLTYPE_INT)
  {
    $MsiRecordSetInteger->Call($rec->{"handle"}, $cn, $value)
      and return undef;
  }
  elsif ($type == $COLTYPE_STRING)
  {
    $MsiRecordSetString->Call($rec->{"handle"}, $cn, $value)
      and return undef;
  }
  elsif ($type == $COLTYPE_STREAM)
  {
    $MsiRecordSetStream->Call($rec->{"handle"}, $cn, $value)
      and return undef;
  }
  else
  {
    return undef;
  }
  return 1;
}

sub coltypes
{
  my ($self) = @_;

  $self->get_info($MSICOLINFO_TYPES);
}

sub colnames
{
  my ($self) = @_;

  $self->get_info($MSICOLINFO_NAMES);
}

# Return column names or types for this view
# $which =
#   $MSICOLINFO_NAMES
#  $MSICOLINFO_TYPES
#  $_MSICOLINFO_INDEX => Return column index of $field
#   undef => return whole colinfo hash

sub get_info
{
  my ($self, $which, $field) = @_;

  $self->_check("v");

  # Fetch and store my colinfo if absent
  if (!$self->{"colinfo"})
  {
    my $hdl = pack("l",0);
    $MsiViewGetColumnInfo->Call($self->{"handle"}, $MSICOLINFO_NAMES, $hdl)
      and return undef;
    $hdl = unpack("l", $hdl);
    my @name = _extract_fields($hdl);
    _close($hdl);

    $hdl = pack("l",0);
    $MsiViewGetColumnInfo->Call($self->{"handle"}, $MSICOLINFO_TYPES, $hdl)
      and return undef;
    $hdl = unpack("l", $hdl);
    my @type = _extract_fields($hdl);
    _close($hdl);

    foreach my $i (0..$#name)
    {
      my $n = $name[$i];
      $self->{"colinfo_hash"}{$n} = $self->{colinfo}[$i] =
        {name => $n, type => $type[$i], index => $i};
    }
  }

  if  (defined $which && $which == $_MSICOLINFO_INDEX)
  {
    return undef unless ($field);

    my $t = $self->{"colinfo_hash"}{$field};
    return $t ? $t->{"index"} : undef;
  }
  return       !defined($which) ? %{$self->{"colinfo_hash"}} :
    $which == $MSICOLINFO_NAMES ? map($_->{"name"}, @{$self->{colinfo}}) :
    $which == $MSICOLINFO_TYPES ? map($_->{"type"}, @{$self->{colinfo}}) :
    undef;
}

# die with $message followed by error info from $self

sub db_die
{
  my ($self, @msg) = @_;

  die join(" ", @msg), ": ", join("/", $self->error);
}

sub error
{
  my ($self) = shift;

  my $e = $MsiGetLastErrorRecord->Call() or return undef;
  my @a = _extract_fields($e);
  _close($e);

  return wantarray ? @a : join("/", @a);
}

# XXX Errors 1000-1999 are install-time errors and their strings are
# stored in the Error table but errors > 2000 are MSI authoring errors
# and are not in the error table.

# ms-help://MS.PSDKXPSP2.1033/msi/setup/windows_installer_error_messages.htm

sub _error_string_to_do
{
  my ($self, @a) = @_;

  print join("<>", @a), "\n";
  my $q = $self->openview("SELECT Message FROM Error WHERE Error = ?", $a[0])
    or die $!;
  push @a, $q->fetch();
  _close($q);
  $q = newrecord(@a) or die $!;
  print "rec = $q\n";
  my $s = " " x 1024;
  my $l = pack("l", length($s));
  $MsiFormatRecord->Call($self, $q, $s, $l) or die $!;
  print "->$s\n";
  substr($s, unpack("l", $l)) = "";

  return $s;
}

sub transform
{
  my ($self, $filename, $flags) = @_;

  $self->_check("db");
  return undef unless ($filename);

  $flags = $MSITR_IGNORE_ALL if (!defined($flags));

  my $r = $MsiDatabaseApplyTransform->Call(
    $self->{"handle"}, $filename, $flags);

  return $r;
}

##### Internal Routines - not for use outside this module

sub _commit
{
  my $self = shift;

  $MsiDataBaseCommit->Call($self->{"handle"}) and return undef;
}

sub _close
{
  my $hdl = shift;

  $MsiCloseHandle->Call($hdl) and return undef;
}

# Bless hash $ref into this package, setting its "type" in the hash
# element with an empty string key.  Ugh.

sub _bless_type
{
  my ($ref, $type, $class) = @_;

  my $me = bless $ref, $class || __PACKAGE__;
  $me->{""} = $type;

  return $me;
}

sub _type
{
  my ($self) = @_;

  return $self->{""};
}

sub _check
{
  my ($self, @allowed) = @_;

  my $t = $self->_type();

  die "$self is type '$t' instead of " . join(", ", @allowed)
    unless (grep($t eq $_, @allowed));
}

# Return the handle for a new record containing @list

sub _newrecord
{
  my (@list) = @_;

  my $hdl = $MsiCreateRecord->Call(scalar(@list)) or return undef;

  for my $i (0..$#list)
  {
    # print "new rec. $i: ", $list[$i], " is ";
    if ($list[$i] =~ /^\d+$/)
    {
      # print "int\n";
      $MsiRecordSetInteger->Call($hdl, $i+1, $list[$i]) and return undef;
    }
    else
    {
      # print "string\n";
      $MsiRecordSetString->Call($hdl, $i+1, $list[$i]) and return undef;
    }
  }
  return $hdl;
}

sub _getI
{
  my ($hdl, $num) = @_;

  my $i = $MsiRecordGetInteger->Call($hdl, $num);

  return $i == $MSI_NULL_INTEGER ? undef : $i;
}

sub _getS
{
  my ($hdl, $num) = @_;
  my ($len);

  my $s = $INITIAL_EMPTY_STRING;
  my $p = pack("l", length($s));    # Initial size
  my $e = $MsiRecordGetString->Call($hdl, $num, $s, $p);
  if ($e == $ERROR_MORE_DATA)
  {
    $len = unpack("l", $p)*2;    # Unicode?
    $s = "\0" x $len;
    $e = $MsiRecordGetString->Call($hdl, $num, $s, $len);
  }
  die $! if ($e);

  $len = unpack("l", $p);
  return "((too big))" if ($len > length($s));

#  $l = index($s, "\0");
#  $l = length($s) if $l<0;

  return substr($s, 0, $len);
}

# Get values of fields for $hdl.  If present, @types gives the type,
# $COLTYPE_INT or $COLTYPE_STRING of each field; otherwise try to
# fetch it as an int and if that fails try string.

sub _extract_fields
{
  my ($hdl, @types) = @_;

  my $i = $MsiRecordGetFieldCount->Call($hdl) or die $!;
  my @a = ();
  for my $c (1..$i)
  {
    my $s;
    if (@types)
    {
      my $t = shift @types;
      $s = $t == $COLTYPE_INT ? _getI($hdl, $c) :
         $t == $COLTYPE_STRING ? _getS($hdl, $c) :
         undef;          # STREAMS and other not processed here
    }
    else              # Autodetect mode
    {
      $s = _getI($hdl, $c);
      $s = _getS($hdl, $c) unless (defined($s));
    }
    push @a, $s;
  }
  return @a;
}

# vim: sw=2 ai

