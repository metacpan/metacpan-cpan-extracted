##########
# Windows file functions that use very long paths and Unicode characters.
##########

package Win32::LongPath;

use 5.008_000;
use base 'Exporter';
use strict;
use warnings;

use Carp;
require Encode;
use Fcntl qw(O_RDONLY O_RDWR O_WRONLY O_APPEND :mode);
use File::Spec::Functions;
use Time::Local;

##########
# external constants
##########

sub FILE_ATTRIBUTE_ARCHIVE () {0x20}
sub FILE_ATTRIBUTE_COMPRESSED () {0x800}
sub FILE_ATTRIBUTE_DEVICE () {0x40}
sub FILE_ATTRIBUTE_DIRECTORY () {0x10}
sub FILE_ATTRIBUTE_ENCRYPTED () {0x4000}
sub FILE_ATTRIBUTE_HIDDEN () {0x2}
sub FILE_ATTRIBUTE_INTEGRITY_STREAM () {0x8000}
sub FILE_ATTRIBUTE_NORMAL () {0x80}
sub FILE_ATTRIBUTE_NOT_CONTENT_INDEXED () {0x2000}
sub FILE_ATTRIBUTE_NO_SCRUB_DATA () {0x20000}
sub FILE_ATTRIBUTE_OFFLINE () {0x1000}
sub FILE_ATTRIBUTE_READONLY () {0x1}
sub FILE_ATTRIBUTE_REPARSE_POINT () {0x400}
sub FILE_ATTRIBUTE_SPARSE_FILE () {0x200}
sub FILE_ATTRIBUTE_SYSTEM () {0x4}
sub FILE_ATTRIBUTE_TEMPORARY () {0x100}
sub FILE_ATTRIBUTE_VIRTUAL () {0x10000}

sub FILE_CASE_PRESERVED_NAMES () {0x00000002}
sub FILE_CASE_SENSITIVE_SEARCH () {0x00000001}
sub FILE_FILE_COMPRESSION () {0x00000010}
sub FILE_NAMED_STREAMS () {0x00040000}
sub FILE_PERSISTENT_ACLS () {0x00000008}
sub FILE_READ_ONLY_VOLUME () {0x00080000}
sub FILE_SEQUENTIAL_WRITE_ONCE () {0x00100000}
sub FILE_SUPPORTS_ENCRYPTION () {0x00020000}
sub FILE_SUPPORTS_EXTENDED_ATTRIBUTES () {0x00800000}
sub FILE_SUPPORTS_HARD_LINKS () {0x00400000}
sub FILE_SUPPORTS_OBJECT_IDS () {0x00010000}
sub FILE_SUPPORTS_OPEN_BY_FILE_ID () {0x01000000}
sub FILE_SUPPORTS_REPARSE_POINTS () {0x00000080}
sub FILE_SUPPORTS_SPARSE_FILES () {0x00000040}
sub FILE_SUPPORTS_TRANSACTIONS () {0x00200000}
sub FILE_SUPPORTS_USN_JOURNAL () {0x02000000}
sub FILE_UNICODE_ON_DISK () {0x00000004}
sub FILE_VOLUME_IS_COMPRESSED () {0x00008000}
sub FILE_VOLUME_QUOTAS () {0x00000020}

##########
# exports
##########

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
BEGIN
  {
  my @aFuncs =
    qw(abspathL attribL chdirL copyL getcwdL linkL lstatL mkdirL openL
    readlinkL renameL rmdirL shortpathL statL symlinkL testL unlinkL
    utimeL volinfoL);
  my @aAttribs = qw(
    FILE_ATTRIBUTE_ARCHIVE
    FILE_ATTRIBUTE_COMPRESSED
    FILE_ATTRIBUTE_DEVICE
    FILE_ATTRIBUTE_DIRECTORY
    FILE_ATTRIBUTE_ENCRYPTED
    FILE_ATTRIBUTE_HIDDEN
    FILE_ATTRIBUTE_INTEGRITY_STREAM
    FILE_ATTRIBUTE_NORMAL
    FILE_ATTRIBUTE_NOT_CONTENT_INDEXED
    FILE_ATTRIBUTE_NO_SCRUB_DATA
    FILE_ATTRIBUTE_OFFLINE
    FILE_ATTRIBUTE_READONLY
    FILE_ATTRIBUTE_REPARSE_POINT
    FILE_ATTRIBUTE_SPARSE_FILE
    FILE_ATTRIBUTE_SYSTEM
    FILE_ATTRIBUTE_TEMPORARY
    FILE_ATTRIBUTE_VIRTUAL
    );
  my @aVolFlags = qw(
    FILE_CASE_PRESERVED_NAMES
    FILE_CASE_SENSITIVE_SEARCH
    FILE_FILE_COMPRESSION
    FILE_NAMED_STREAMS
    FILE_PERSISTENT_ACLS
    FILE_READ_ONLY_VOLUME
    FILE_SEQUENTIAL_WRITE_ONCE
    FILE_SUPPORTS_ENCRYPTION
    FILE_SUPPORTS_EXTENDED_ATTRIBUTES
    FILE_SUPPORTS_HARD_LINKS
    FILE_SUPPORTS_OBJECT_IDS
    FILE_SUPPORTS_OPEN_BY_FILE_ID
    FILE_SUPPORTS_REPARSE_POINTS
    FILE_SUPPORTS_SPARSE_FILES
    FILE_SUPPORTS_TRANSACTIONS
    FILE_SUPPORTS_USN_JOURNAL
    FILE_UNICODE_ON_DISK
    FILE_VOLUME_IS_COMPRESSED
    FILE_VOLUME_QUOTAS
    );
  @EXPORT = @aFuncs;
  @EXPORT_OK = (@aAttribs, @aVolFlags);
  %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
    funcs => [@aFuncs],
    fileattr => [@aAttribs],
    volflags => [@aVolFlags]
    );
  $VERSION = '1.07';
  require XSLoader;
  XSLoader::load ('Win32::LongPath', $VERSION);
  }

##########
# local constants
##########

my $GENERIC_READ = 0x80000000;
my $GENERIC_WRITE = 0x40000000;
my $GENERIC_RW = 0xC0000000;

my $CREATE_ALWAYS = 2;
my $OPEN_EXISTING = 3;
my $OPEN_ALWAYS = 4;

my $NOFILE = FILE_ATTRIBUTE_DEVICE | FILE_ATTRIBUTE_DIRECTORY
  | FILE_ATTRIBUTE_OFFLINE;
my $ALL_ATTRIBS = FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_HIDDEN
  | FILE_ATTRIBUTE_NOT_CONTENT_INDEXED | FILE_ATTRIBUTE_OFFLINE
  | FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_TEMPORARY;

##########
# local varbs
##########

my $_UTF16 ||= Encode::find_encoding ('utf16-le');

##########
# external functions
##########

###########
# Absolute Path
#
# INPUT:
#   Arg (1) = relative path
# OUTPUT: absolute path; undef=error
###########

sub abspathL

{
my $sPath = shift;
if (!defined $sPath)
  { croak 'path missing!'; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
my $sLong = get_long_path ($sPath);
if ($sLong ne '')
  { $sPath = $sLong; }
return _denormalize_path ($sPath);
}

###########
# Set Attributes
#
# INPUT:
#   Arg (1) = attribute string
#   Arg (2) = path
# OUTPUT: success=1; undef=error
###########

sub attribL

{
###########
# o get current attributes
# o adjust attributes
###########

my ($sAttribs, $sPath) = @_;
if (!defined $sAttribs)
  { croak 'attributes missing!'; }
if (!defined $sPath)
  { croak 'path missing!'; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
my $nAttribs = get_attribs ($sPath);
if (!defined $nAttribs)
  { return; }
$nAttribs &= $ALL_ATTRIBS;
my $bSet = 1;
foreach my $sAttrib (split //, lc $sAttribs)
  {
  if ($sAttrib eq '+')
    {
    $bSet = 1;
    next;
    }
  if ($sAttrib eq '-')
    {
    $bSet = 0;
    next;
    }
  my $nMask;
  if ($sAttrib eq 'a')
    { $nMask = FILE_ATTRIBUTE_ARCHIVE; }
  elsif ($sAttrib eq 'h')
    { $nMask = FILE_ATTRIBUTE_HIDDEN; }
  elsif ($sAttrib eq 'i')
    { $nMask = FILE_ATTRIBUTE_NOT_CONTENT_INDEXED; }
  elsif ($sAttrib eq 'r')
    { $nMask = FILE_ATTRIBUTE_READONLY; }
  elsif ($sAttrib eq 's')
    { $nMask = FILE_ATTRIBUTE_SYSTEM; }
  else
    { croak 'invalid attribute!'; }
  if ($bSet)
    { $nAttribs |= $nMask; }
  else
    { $nAttribs &= ~$nMask; }
  }

###########
# set attributes
###########

if (!set_attribs ($sPath, $nAttribs))
  { return; }
return 1;
}

###########
# Change Current Working Directory
#
# INPUT:
#   [Arg (1)] = directory path; default=$ENV{HOME} or $ENV{LOGDIR}
# OUTPUT: 1=success; undef=error
###########

sub chdirL

{
my $sPath = shift;
if (!defined $sPath && exists $ENV {HOME})
  { $sPath = $ENV {HOME}; }
elsif (!defined $sPath && exists $ENV {LOGDIR})
  { $sPath = $ENV {LOGDIR}; }
if (!defined $sPath)
  { return $sPath; }
if ($sPath !~ /[\\\/]$/)
  { $sPath .= '/'; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
if (set_current_directory ($sPath))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Copy File
#
# INPUT:
#   Arg (1) = from
#   Arg (2) = to
# OUTPUT: 1=success; undef=error
###########

sub copyL

{
my ($sFrom, $sTo) = @_;
if (!defined $sFrom)
  { croak 'from missing!'; }
if (!defined $sTo)
  { croak 'to missing!'; }
$sFrom = _normalize_path ($sFrom);
if (!defined $sFrom)
  { return; }
$sTo = _normalize_path ($sTo);
if (!defined $sTo)
  { return; }
if (copy_file ($sFrom, $sTo))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Get Current Working Directory
#
# INPUT: none
# OUTPUT: cwd
###########

sub getcwdL

{
return _denormalize_path (get_current_directory ());
}

###########
# Create Hard Link
#
# INPUT:
#   Arg (1) = to
#   Arg (2) = from
# OUTPUT: 1=success; undef=error
###########

sub linkL

{
###########
# o check args
# o relative target?
# o create link
###########

my ($sTo, $sFrom) = @_;
if (!defined $sTo)
  { croak 'oldname missing!'; }
if (!defined $sFrom)
  { croak 'newname missing!'; }
$sTo = _normalize_path ($sTo);
if (!defined $sTo)
  { return; }
$sFrom = _normalize_path ($sFrom);
if (!defined $sFrom)
  { return; }
if (make_hlink ($sTo, $sFrom))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Linked Status Information
#
# INPUT:
#   [Arg (1)] = path; default=$_
# OUTPUT: status object; undef=error
###########

sub lstatL

{
return statL (shift, 1);
}

###########
# Make Directory
#
# INPUT:
#   [Arg (1)] = path; default=$_
# OUTPUT: 1=success; undef=error
###########

sub mkdirL

{
my $sPath = shift;
if (!defined $sPath)
  { $sPath = $_; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
if (create_directory ($sPath))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Open File
#
# INPUT:
#   Arg (1) = filehandle
#   Arg (2) = mode
#   Arg (3) = path
# OUTPUT: 1=success; undef=error
###########

sub openL

{
##########
# check parms
##########

my ($oFH, $sMode, $sPath) = @_;
if (!ref $oFH)
  { croak 'filehandle reference missing!'; }
if (!defined $sMode)
  { croak 'mode missing!'; }
if (!defined $sPath)
  { croak 'path missing!'; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
my $sLayer = '';
if ($sMode =~ /^([^\:]*)(\:.*)/)
  {
  ($sMode, $sLayer) = ($1, $2);
  if ($sLayer eq ':')
    { croak 'invalid layer for openL!'; }
  }
my $nFD;
if ($sMode eq '' or $sMode eq '<')
  {
  $nFD = create_file ($sPath, $GENERIC_READ, $OPEN_EXISTING, O_RDONLY);
  $sMode = '<';
  }
elsif ($sMode eq '+<')
  {
  $nFD = create_file ($sPath, $GENERIC_RW, $OPEN_EXISTING, O_RDWR | O_APPEND);
  $sMode = '>>';
  }
elsif ($sMode eq '>')
  {
  $nFD = create_file ($sPath, $GENERIC_WRITE, $CREATE_ALWAYS, O_WRONLY);
  $sMode = '>';
  }
elsif ($sMode eq '+>')
  {
  $nFD = create_file ($sPath, $GENERIC_RW, $CREATE_ALWAYS, O_RDWR | O_APPEND);
  $sMode = '>>';
  }
elsif ($sMode eq '>>')
  {
  $nFD = create_file ($sPath, $GENERIC_WRITE, $OPEN_ALWAYS, O_WRONLY);
  $sMode = '>>';
  }
elsif ($sMode eq '+>>')
  {
  $nFD = create_file ($sPath, $GENERIC_RW, $OPEN_ALWAYS, O_RDWR | O_APPEND);
  $sMode = '>>';
  }
else
  { croak 'invalid mode!'; }

##########
# o file descriptor valid?
# o open as Perl file
# o set layer with binmode
##########

if (!defined $nFD)
  { return; }
if (!CORE::open (my $oFH1, "$sMode&=$nFD"))
  { return; }
else
  {
  # this avoids a bug in Perl 5.22 when opening files w/a scalar reference
  $$oFH = $oFH1;
  }
if ($sLayer ne '')
  {
  if (!binmode $$oFH, $sLayer)
    {
    close $$oFH;
    return;
    }
  }
return 1;
}

###########
# Read Link Value
#
# INPUT:
#   [Arg (1)] = path; default=$_
# OUTPUT: path that link points to; undef=error or unable to find
###########

sub readlinkL

{
##########
# o get default path if undef
# o find link
##########

my $sPath = shift;
if (!defined $sPath)
  { $sPath = $_; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
my $sLink = find_link ($sPath);
if (!defined $sLink)
  { return; }
set_last_error (0);
return _denormalize_path ($sLink);
}

###########
# Rename (Move) File
#
# INPUT:
#   Arg (1) = from
#   Arg (2) = to
# OUTPUT: 1=success; undef=error
###########

sub renameL

{
my ($sFrom, $sTo) = @_;
if (!defined $sFrom)
  { croak 'oldname missing!'; }
if (!defined $sTo)
  { croak 'newname missing!'; }
$sFrom = _normalize_path ($sFrom);
if (!defined $sFrom)
  { return; }
$sTo = _normalize_path ($sTo);
if (!defined $sTo)
  { return; }
if (move_file ($sFrom, $sTo))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Remove Directory
#
# INPUT:
#   [Arg (1)] = path; default=$_
# OUTPUT: 1=success; undef=error
###########

sub rmdirL

{
my $sPath = shift;
if (!defined $sPath)
  { $sPath = $_; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
if (remove_directory ($sPath))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Short Path
#
# INPUT:
#   Arg (1) = path
# OUTPUT: shortpath; blank=error
###########

sub shortpathL

{
my $sPath = shift;
if (!defined $sPath)
  { croak 'path missing!'; }
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return ''; }
my $sShort = get_short_path ($sPath);
return _denormalize_path ($sShort);
}

###########
# Status Information
#
# INPUT:
#   [Arg (1)] = expression; default=$_
#   [Arg (2)] = true then lstat
# OUTPUT: status object; undef=error
###########

sub statL

{
##########
# o get default path if undef
# o check if lstatL
# o get stats
# o convert size from large int
# o get time as gmtime
##########

my ($sPath, $bLStat) = @_;
if (!defined $sPath)
  { $sPath = $_; }
$bLStat = $bLStat ? 1 : 0;
$sPath = _normalize_path ($sPath);
if (!defined $sPath)
  { return; }
my $oStat = get_stat ($sPath, $bLStat);
if (!defined $oStat)
  { return; }
$oStat->{size} = $oStat->{size_high}
  ? (($oStat->{size_high} << 32) + $oStat->{size_low}) : $oStat->{size_low};
delete $oStat->{size_high};
delete $oStat->{size_low};
foreach my $sTime (qw (atime ctime mtime))
  {
  if ($oStat->{$sTime})
    { $oStat->{$sTime} = timegm (split /,/, $oStat->{$sTime}); }
  }
return $oStat;
}

###########
# Create Symbolic Link
#
# INPUT:
#   Arg (1) = to
#   Arg (2) = from
# OUTPUT: 1=success; undef=error
###########

sub symlinkL

{
###########
# o check args
# o relative target?
# o create link
###########

my ($sTo, $sFrom) = @_;
if (!defined $sTo)
  { croak 'oldname missing!'; }
if (!defined $sFrom)
  { croak 'newname missing!'; }
$sTo =~ s#/#\\#g;
if ($sTo =~ /^\\/ or $sTo =~ /^[a-z]:/i)
  { $sTo = _normalize_path ($sTo); }
else
  { $sTo = $_UTF16->encode ($sTo) . "\x00"; }
if (!defined $sTo)
  { return; }
$sFrom = _normalize_path ($sFrom);
if (!defined $sFrom)
  { return; }
if (make_slink ($sTo, $sFrom))
  {
  set_last_error (0);
  return 1;
  }
return;
}

###########
# Test Path
#
# INPUT:
#   Arg (1) = test
#   [Arg (2)] = path; default=$_
# OUTPUT: success=1; fail=''; undef=error
###########

sub testL

{
###########
# o valid test?
# o get stat
# o check test
###########

my $sTest = shift;
if ($sTest !~ /^[bcdeflOoRrsWwXxz]$/)
  { croak 'invalid test!'; }
my $oStat = $sTest eq 'l' ? lstatL (shift) : statL (shift);
if (!defined $oStat)
  { return; }
my $nRet = '';
if ($sTest eq 'd')
  {
  if ($oStat->{mode} & S_IFDIR)
    { $nRet = 1; }
  }
elsif ($sTest eq 'e')
  { $nRet = 1; }
elsif ($sTest eq 'f')
  {
  if (!($oStat->{attribs} & $NOFILE))
    { $nRet = 1; }
  }
elsif ($sTest eq 'l')
  {
  if ($oStat->{attribs} & FILE_ATTRIBUTE_REPARSE_POINT)
    { $nRet = 1; }
  }
elsif ($sTest =~ /o/i)
  { $nRet = 1; }
elsif ($sTest =~ /r/i)
  {
  if ($oStat->{mode} & S_IRUSR)
    { $nRet = 1; }
  }
elsif ($sTest eq 's')
  {
  if ($oStat->{size})
    { $nRet = $oStat->{size}; }
  }
elsif ($sTest =~ /w/i)
  {
  if ($oStat->{mode} & S_IWUSR)
    { $nRet = 1; }
  }
elsif ($sTest =~ /x/i)
  {
  if ($oStat->{mode} & S_IXUSR)
    { $nRet = 1; }
  }
elsif ($sTest eq 'z')
  {
  if (!$oStat->{size})
    { $nRet = 1; }
  }
return $nRet;
}

###########
# Delete Files
#
# INPUT:
#   [Arg (...)] = files to delete; default=$_
# OUTPUT: number of files deleted; undef=error
###########

sub unlinkL

{
##########
# o get default path if undef
# o delete each file
##########

my @sPaths = @_;
if (!@sPaths)
  { push @sPaths, $_; }
my $nFiles = 0;
my $nErr = 0;
foreach my $sPath (@sPaths)
  {
  $sPath = _normalize_path ($sPath);
  if (!defined $sPath)
    {
    $nErr = get_last_error ();
    next;
    }
  if (remove_file ($sPath))
    { $nFiles++; }
  else
    {
    $nErr = get_last_error ();
    next;
    }
  }

##########
# errors?
##########

if ($nErr)
  {
  set_last_error ($nErr);
  return;
  }
return $nFiles;
}

###########
# Change File Times
#
# INPUT:
#   Arg (1) = access time; undef=now
#   Arg (2) = modification time; undef=now
#   Arg (...) = files to change
# OUTPUT: number of files changed; undef=error
###########

sub utimeL

{
##########
# o get times and files
# o process each file
##########

my ($nATime, $nMTime, @sPaths) = @_;
if (!defined $nATime && !defined $nMTime)
  { $nATime = $nMTime = time; }
if (!defined $nATime)
  { $nATime = 0; }
if (!defined $nMTime)
  { $nMTime = 0; }
my $nFiles = 0;
my $nErr = 0;
foreach my $sPath (@sPaths)
  {
  $sPath = _normalize_path ($sPath);
  if (!defined $sPath)
    {
    $nErr = get_last_error ();
    next;
    }
  if (set_filetime ($nATime, $nMTime, $sPath))
    { $nFiles++; }
  else
    {
    $nErr = get_last_error ();
    next;
    }
  }

##########
# errors?
##########

if ($nErr)
  { set_last_error ($nErr); }
return $nFiles;
}

###########
# Get Volume Information
#
# INPUT:
#   Arg (1) = path
# OUTPUT: volume object; undef=error
###########

sub volinfoL

{
###########
# o get fullpath
# o limit to root
# o get volume info
###########

my $sPath = abspathL (shift);
if (!defined $sPath)
  { return; }
if ($sPath =~ /^([a-z]:)/i)
  { $sPath = "$1\\"; }
else
  {
  $sPath =~ /^(\\\\[^\\]+\\[^\\]+)/;
  $sPath = "$1\\";
  }
my $oVol = get_vol_info (_normalize_path ($sPath));
if (!defined $oVol)
  { return; }
$oVol->{name} = _wide_to_utf8 ($oVol->{name});
return $oVol;
}

##########
# object functions
##########

###########
# Close Directory
#
# INPUT: none
# OUTPUT: close handle
###########

sub closedirL

{
###########
# close if handle already open
###########

my $self = shift;
if (!defined $self->{handle})
  { croak 'no directory open!'; }
$self->find_close ();
delete $self->{handle};
return 1;
}

##########
# destructor
##########

sub DESTROY

{
##########
# close handle
##########

my $self = shift;
if (defined $self->{handle})
  { $self->find_close (); }
return;
}

###########
# Create Directory Object
###########

sub new

{
return bless { }, shift;
}

###########
# Open Directory
#
# INPUT:
#   [Arg (1)] = directory path; default=current dir
# OUTPUT: 1=success, undef=error
###########

sub opendirL

{
###########
# o close if handle already open
# o normalize path
# o find first file
# o return opendir object
###########

my ($self, $sDir) = @_;
if (defined $self->{handle})
  { $self->find_close (); }
if (!defined $sDir)
  { $sDir = '.'; }
my $sPath = _normalize_path ($sDir);
if (!defined $sPath)
  { return; }
$self->{dirpath} = _denormalize_path ($sPath);
$self->find_first_file (_normalize_path (catfile ($sDir, '*')));
if ($self->{handle} == 4294967295)
  { return; }
$self->{first} = _denormalize_path ($self->{first});
set_last_error (0);
return 1;
}

###########
# Read Directory
#
# INPUT: none
# OUTPUT:
#   list: all remaining directory entries
#   otherwise next entry or undef if none
###########

sub readdirL

{
###########
# o check for first entry from opendir
# o retrieve entries
# o return entries
###########

my $self = shift;
if (!defined $self->{handle})
  { croak 'no directory open!'; }
my $bList = wantarray;
my @sDirs;
if ($self->{first} ne '')
  {
  push @sDirs, $self->{first};
  $self->{first} = '';
  if (!$bList)
    { return $sDirs [0]; }
  }
while (defined (my $sDir = $self->find_next_file ()))
  {
  push @sDirs, _denormalize_path ($sDir);
  if (!$bList)
    { last; }
  }
return $bList ? @sDirs : pop @sDirs;
}

##########
# local functions
##########

###########
# Denormalize Path
#
# INPUT:
#   Arg (1) = normalized path
# OUTPUT: denormalized path
###########

sub _denormalize_path

{
###########
# o convert to UTF-8
# o strip out trailing null
# o strip off extended path prefix
###########

my $sPath = shift;
if (!defined $sPath)
  { return $sPath; }
$sPath = _wide_to_utf8 ($sPath);
$sPath =~ s/^\\\\\?\\UNC/\\/;
$sPath =~ s/^\\\\\?\\//;
return $sPath;
}

###########
# Normalize Path
#
# INPUT:
#   Arg (1) = denormalized path
# OUTPUT: normalized path
###########

sub _normalize_path

{
###########
# o make sure using backslashes for separator
# o extended path?
###########

my $sPath = shift;
if (!defined $sPath)
  { return $sPath; }
$sPath =~ s#/#\\#g;
if ($sPath !~ /^\\\\\?\\/)
  {
  ###########
  # add root path if missing
  ###########

  if ($sPath !~ /^\\\\/ && $sPath !~ /^[a-z]:/i)
    {
    if ($sPath !~ /^\\/)
      { $sPath = getcwdL () . "\\$sPath"; }
    else
      {
      my $sRoot = getcwdL ();
      if ($sRoot =~ /^(\\\\[^\\]+\\[^\\]+)/)
        { $sPath = "$1$sPath"; }
      elsif ($sRoot =~ /([a-z]:)/i)
        { $sPath = "$1$sPath"; }
      }
    }
  if ($sPath =~ /^([a-z]:)[^\\+]\\/i)
    {
    ###########
    # o switch drive
    # o add root path
    # o switch drive back
    ###########

    my $sDrive = $1;
    my $sCurDir = getcwdL ();
    if (!chdirL ($sDrive))
      { return; }
    $sPath = getcwdL () . substr ($sPath, 2);
    if (!chdirL ($sCurDir))
      { return; }
    }

  ###########
  # strip off volume (drive letter or UNC)
  ###########

  my $sVol;
  if ($sPath =~ /^([a-z]:)(.*)/i)
    { ($sVol, $sPath) = ($1, $2); }
  elsif ($sPath =~ /^\\(\\[^\\]+\\[^\\]+)(.*)/)
    { ($sVol, $sPath) = ($1, $2); }
  else
    {
    set_last_error (3);
    return;
    }

  ###########
  # remove relative dirs
  ###########

  my @sNewDirs;
  foreach my $sDir (split /\\/, $sPath)
    {
    if ($sDir eq '' or $sDir eq '.')
      { next; }
    if ($sDir ne '..')
      {
      push @sNewDirs, $sDir;
      next;
      }
    if (!@sNewDirs)
      {
      set_last_error (3);
      return;
      }
    pop @sNewDirs;
    }

  ###########
  # o return to the original path
  # o form extended path
  ###########

  $sPath = '\\\\?\\' . ($sVol =~ /\\/ ? 'UNC' : '')
    . "$sVol\\" . join ('\\', @sNewDirs);
  }

###########
# convert to UTF-16 and add trailing null
###########

return $_UTF16->encode ($sPath) . "\x00";
}

###########
# Wide to UTF-8
#
# INPUT:
#   Arg (1) = wide char string
# OUTPUT: Perl UTF-8 string
###########

sub _wide_to_utf8

{
my $sText = $_UTF16->decode (shift);
$sText =~ s/\x00$//;
return $sText;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Win32::LongPath - provide functions to access long paths and Unicode in the Windows environment

=head1 SYNOPSIS

	use File::Spec::Functions;
	use Win32::LongPath;
	use utf8;

	# make a really long path w/Unicode from around the world
	$path = 'c:';
	while (length ($path) < 5000) {
	  $path = catdir ($path, 'ελληνικά-русский-日本語-한국-中國的-עִברִית-عربي');
	  if (!testL ('e', $path)) {
	    mkdirL ($path) or die "unable to create $path ($^E)";
	  }
	}
	print 'ShortPath: ' . shortpathL ($path) . "\n";

	# next, create a file in the path
	$file = catfile ('more interesting characters فارسی-தமிழர்-​ພາສາ​ລາວ');
	openL (\$FH, '>:encoding(UTF-8)', $file)
	  or die ("unable to open $file ($^E)");
	print $FH "writing some more Unicode characters\n";
	print $FH "דאס שרייבט אַ שורה אין ייִדיש.\n";
	close $FH;

	# now undo everything
	unlinkL ($file) or die "unable to delete file ($^E)";
	while ($path =~ /[\/\\]/) {
	  rmdirL ($path) or die "unable to remove $path ($^E)";
	  $path =~ s#[/\\][^/\\]+$##;
	}

=head1 DESCRIPTION

Although Perl natively supports functions that can access files in Windows
these functions fail for Unicode or long file paths (i.e. greater than the
Windows MAX_PATH value which is about 255 characters). Win32::LongPath
overcomes these limitations by using Windows wide-character functions
which support Unicode and extended-length paths. The end result is that
you can process any file in the Windows environment without worrying about
Unicode or path length.

Win32::LongPath provides replacement functions for most of the native Perl
file functions. These functions attempt to imitate the native functionality
and format as closely as possible and accept file paths which include
Unicode characters and can be up to 32,767 characters long.

Some additional functions are also available to provide low-level features
that are specific to Windows files.

=head2 Paths

File and directory paths can be provided containing any of the following
components.

=over 4

=item *

B<path separators>: Both the forward (/) and reverse (\) slashes can be used
to separate the path components.

=item *

B<Unicode>: Unicode characters can be used anywhere in the path provided they
are supported by the Windows file naming standard. If Unicode is used, the
string must be internally identified as UTF-8. See L<perlunicode> for more
information on using Unicode with Perl.

=item *

B<drive letter>: The path can begin with an upper or lower case letter from A
to Z followed by a colon to indicate a drive letter path. For example,
C<C:/path> (fullpath) or C<c:path> (relative path).

=item *

B<UNC>: The path can begin with a UNC path in the form C<\\server\share> or
C<//server/share>.

=item *

B<extended-length>: The path can begin with an extended-length prefix in the
form of C<\\?\> or C<//?/>.

=back

All input paths will be converted (I<normalized>) to a fullpath using the
extended-length format and wide characters. This allows paths to be up to
32,767 characters long and to include Unicode characters. The Microsoft
specification still limits the directory component to MAX_PATH (about 255)
characters.

Output paths will be converted back (I<denormalized>) to a UTF-8 fullpath
that begins with a drive letter or UNC.

B<NOTE:> See the I<Naming Files, Paths, and Namespaces> topic in the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about extended-length paths.

=head2 Return Values

Unless stated otherwise, all functions return true (a numeric value of 1)
if successful or false (undef) if an error occurred. Generally, if a
function fails it will set the $! value to the failure. However, $^E will
have the more specific Windows error value.

=head1 FILE FUNCTIONS

This section lists the replacements for native Perl file functions. Since
L</openL> returns a native Perl file handle, functions that use open file
handles (read, write, close, binmode, etc.) can be used as is and do not
have replacement functions. Functions that are specific to the Unix
environment (chmod, chown, umask, etc.) do not have replacements. A
replacement for sysopen was not provided since it uses the fdopen () C
library.

=over 4

=item X<linkL>linkL OLDFILE,NEWFILE

If the Windows file system supports it, a hard link is created from
B<NEWFILE> to B<OLDFILE>.

	linkL ('goodbye', 'до свидания')
	  or die ("unable to link file ($^E)");

=item X<lstatL>lstatL

=item lstatL PATH

Does the same thing as the L</statL> function but will retrieve the
statistics for the link and not the file it links to.

=item X<openL>openL FILEHANDLEREF,MODE,PATH

open is a very powerful and versatile Perl function with many modes and
capabilities. The openL replacement does not provide the full range of
capability but does provide what is needed to open files in the Windows
file system. It only supports the three-argument form of open.

B<FILEHANDLEREF> cannot be a bareword file handle or a scalar variable.
It must be a reference to a scalar value which will be set to be a Perl
file handle. For example:

	openL (\$fh, '<', $file) or die ("unable to open $file: ($^E)");

For the most part, B<MODE> matches the native definition and can begin
with E<lt>, E<gt>, E<gt>E<gt>, +E<lt>, +E<gt> and +E<gt>E<gt> to
indicate read/write behavior. The E<verbar>-, -E<verbar>, E<lt>-, -,
E<gt>- modes are not valid since they apply to pipes, STDIN and STDOUT.
Read-only is assumed if the read/write symbols are not used. B<MODE>
can also include a colon followed by the I/O layer definition. For
example:

	openL (\$fh, '>:encoding(UTF-8)', $file);

B<PATH> is the relative or fullpath name of the file. It cannot be undef
for temporary files, a reference to a variable for in-memory files or
a file handle.

	# these are WRONG!
	openL ($infh, '', $infile);
	openL (INFILE, '', $infile);
	openL (\$infh, '', undef);
	openL (\$infh, '', \$memory);
	openL (\$infh, '', INFILE);
	openL (\$infh, '-|', "file<$infile");

	# these are correct
	# append infile to outfile
	openL (\$infh, '', $infile)
	  or die ("unable to open $infile: ($^E)");
	openL (\$outfh, '>>', $outfile)
	  or die ("unable to open $outfile: ($^E)");
	while (<$infh>) {
	  print $outfh $_;
	}
	eof ($infh) or print "terminated before EOF!\n";
	close $infh;
	close $outfh;

=item X<readlinkL>readlinkL

=item readlinkL PATH

Returns the path that a junction/mount point or symbolic link points to. If
B<PATH> is not provided, $_ is used. It will fail for hard links.

	# symlinks should always be equal
	symlinkL ($orig, $slink) or die ("unable to symlink file ($^E)");
	$rlink = readlinkL ($slink) or die ("unable to read link ($^E)");
	die ("links not equal!") if ($rlink ne $orig);

	# hard links should always be undef
	linkL ($orig, $hlink) or die ("unable to link file ($^E)");
	!readlinkL ($hlink) or die ("should have failed!");

=item X<renameL>renameL OLDNAME,NEWNAME

Changes the name or moves B<OLDNAME> to B<NEWNAME>. Renames directories
as well as files. Cannot move directories across volumes.

B<NOTE:> See I<MoveFile> in the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information.

	# should work
	renameL ('c:/file', 'c:/newfile');
	# fails, can't move file to directory
	renameL ('d:/file', '.');
	# should work for files
	renameL ('e:/file', 'f:/newfile');
	# should work
	renameL ('d:/dir', 'd:/topdir/subdir');
	# fails, can't move directory across volumes
	renameL ('c:/dir', 'd:/newdir');

=item X<statL>statL

=item statL PATH

Returns an object with the statistics for the file. B<PATH> must be a path
to a file and cannot be a file or directory handle. If it is not provided,
$_ is used. If there is an error gathering the statistics undef is returned
and the error variables are set. The definition of object elements are very
similar to the native Perl stat function although the access method is like
L<File::stat>.

=over 4

B<atime>: Last access time in seconds. B<NOTE:> Different file systems have
different time resolutions. For example, FAT has a resolution of 1 day for
the access time. See the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about file time.

B<attribs>: File attributes as returned by the Windows GetFileAttributes ()
function. Use the following constants to retrieve the individual values. See
the L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about the meaning of these values. Import these values into your
L<environment|/MODULE EXPORTS> if you do not want to refer to them with the
C<Win32::LongPath::> prefix.

=over 4

=over 4

=item FILE_ATTRIBUTE_ARCHIVE

=item FILE_ATTRIBUTE_COMPRESSED

=item FILE_ATTRIBUTE_DEVICE

=item FILE_ATTRIBUTE_DIRECTORY

=item FILE_ATTRIBUTE_ENCRYPTED

=item FILE_ATTRIBUTE_HIDDEN

=item FILE_ATTRIBUTE_INTEGRITY_STREAM

=item FILE_ATTRIBUTE_NORMAL

=item FILE_ATTRIBUTE_NOT_CONTENT_INDEXED

=item FILE_ATTRIBUTE_NO_SCRUB_DATA

=item FILE_ATTRIBUTE_OFFLINE

=item FILE_ATTRIBUTE_READONLY

=item FILE_ATTRIBUTE_REPARSE_POINT

=item FILE_ATTRIBUTE_SPARSE_FILE

=item FILE_ATTRIBUTE_SYSTEM

=item FILE_ATTRIBUTE_TEMPORARY

=item FILE_ATTRIBUTE_VIRTUAL

=back

=back

B<ctime>: Although defined to be inode change time in seconds for native
Perl, it will reflect the Windows creation time.

B<dev>: The Windows serial number for the volume. See the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information.

B<gid>: Is always zero.

B<ino>: Is always zero.

B<mode>: File mode (type and permissions). C<use Fcntl ':mode'> can be used
to extract the meaning of the mode. Regardless of the actual user and group
permissions, the following bits are set.

=over 4

=item *

Directories: C<S_IFDIR>, C<S_IRWXU>, C<S_IRWXG> and C<S_IRWXO>

=item *

Files: C<S_IFREG>, C<S_IRUSR>, C<S_IRGRP> and C<S_IROTH>

=item *

Files without read-only attribute: C<S_IWUSR>, C<S_IWGRP> and C<S_IWOTH>

=item *

Files with BAT, CMD, COM and EXE extension: C<S_IXUSR>, C<S_IXGRP>
and C<S_IXOTH>

=back

B<mtime>: Last modify time in seconds. B<NOTE:> Different file systems have
different time resolutions. For example, FAT has a resolution of 2 seconds
for the modification time. See the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about file time.

B<nlink>: Is always one.

B<rdev>: Same as B<dev>.

B<size>: Total size of the file in bytes. Has a value of zero for directories.

B<uid>: Is always zero.

=back

	use Fcntl ':mode';
	use Win32::LongPath qw(:funcs :fileattr);

	# get object
	testL ('e', $file)
	  or die "$file doesn't exist!";
	$stat = statL ($file)
	  or die ("unable to get stat for $file ($^E)");

	# this test for directory
	$stat->{mode} & S_IFDIR ? print "Directory\n" : print "File\n";
	# is the same as this one
	$stat->{attribs} & FILE_ATTRIBUTE_DIRECTORY ? print "Directory\n" : print "File\n";

	# show file times as local time
	printf "Created: %s\nAccessed: %s\nModified: %s\n",
	  scalar localtime $stat->{ctime},
	  scalar localtime $stat->{atime},
	  scalar localtime $stat->{mtime};

=item X<symlinkL>symlinkL OLDFILE,NEWFILE

If the Windows OS, file system and user permissions support it, a symbolic
link is created from B<NEWFILE> to B<OLDFILE>.

B<OLDFILE> can be a relative or full path. If relative path is used, it
will not be converted to an extended-length path.

B<NOTE:> See I<CreateSymbolicLink> in the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about symbolic links.

	symlinkL ('no problem', '問題ない')
	  or die ("unable to link file ($^E)");
	symlinkL ('c:/', 'rootpath')
	  or die ("unable to link file ($^E)");

=item X<testL>testL TYPE,PATH

Used to replace the native I<-X> functions. B<TYPE> is the same value as
the I<-X> function. For example:

	# these are equivalent
	die 'unable to read!' if -r $file;
	die 'unable to read!' if testL ('r', $file);

The supported B<TYPE>s and their values are:

=over 4

=item *

B<b>: Block device. Always returns undef.

=item *

B<c>: Character device. Always returns undef.

=item *

B<d>: Directory.

=item *

B<e>: Exists.

=item *

B<f>: Plain file. Returns true if not a directory of Windows offline file.

=item *

B<l>: Link file. Only returns true for junction/mount points and symbolic
links.

=item *

B<o> or B<O>: Owned. Always returns true.

=item *

B<r> or B<R>: Read. Always returns true.

=item *

B<s>: File has nonzero size (returns size in bytes).

=item *

B<w> or B<W>: Read. Returns true if the file does not have the read-only attribute.

=item *

B<x> or B<X>: Read. Returns true if the file has one of the following extensions:
F<bat>, F<cmd>, F<com>, F<exe>.

=item *

B<z>: Zero size.

=back

=item X<unlinkL>unlinkL PATH[,...]

Deletes the list of files. If successful, it returns the number of files
deleted. It will fail if the file has the read-only attribute set. It
returns undef if an error occurs, and the error variable is set to the
value of the last error encountered.

	# if you do this you don't know which failed
	die ("delete of some files failed!") if !unlinkL ($f1, $f2, $f3, $f4);

	# this identifies the failures
	foreach my $file ($f1, $f2, $f3, $f4) {
	  unlinkL ($file) or print "Unable to delete $file ($^E)\n";  
	}

=item X<utimeL>utimeL [ATIME],[MTIME],PATH[,...]

Changes the access and modification times on each file. B<ATIME> and
B<MTIME> are the numeric times from the time () function. If both are
undef then the times will be changed to the current time. If only one
is undef that one will use a time value of zero.

B<PATH> must be the path to a file.

If successful, it returns the number of files changed. It returns undef if
an error occurs, and the error variable is set to the value of the last
error encountered.

B<NOTE:> This function is not supported in Cygwin and will return an error.

B<NOTE:> Different file systems have different time resolutions. For
example, FAT has a resolution of 2 seconds for modification time and
1 day for the access time. See the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about file time.

	# set back 24 hours
	$yesterday = time () - (24 * 60 * 60);
	utimeL ($yesterday, $yesterday, $file)
	  or die ("unable to change time on $file ($^E)");

	# this is the same as the touch command
	utimeL (undef, undef, $file)
	  or die ("unable to change time on $file ($^E)");

=back

=head1 DIRECTORY FUNCTIONS

B<NOTE:> Although extended-length paths are used, the Microsoft
specification still limits the directory component to MAX_PATH (about
255) characters.

=over 4

=item X<chdirL>chdirL

=item chdirL PATH

Changes the working directory. If B<PATH> is missing it tries to change to
C<$ENV{HOME}> if it is set, or C<$ENV{LOGDIR}> if that is set. If neither is
set then it will do nothing and return.

Unlike other functions, the B<PATH> cannot exceed MAX_PATH characters,
although it can contain Unicode and be in the extended-path format.

	chdirL ($path)
	  or die ("unable to change to $path ($^E)");

=item X<getcwdL>getcwdL

Returns the fullpath of the current working directory. This does not replace
a native Perl function since none exists. It works like the curdir function
in L<File::Spec>.

	print "The current directory is: ", getcwdL (), "\n";

=item X<mkdirL>mkdirL

=item mkdirL PATH

Creates a directory which inherits the permissions of the parent. If B<PATH>
is not provided, $_ is used. An error is returned if the parent directory
does not exist.

	mkdirL ($dir)
	  or die ("unable to create $dir ($^E)");

=item X<rmdirL>rmdirL

=item rmdirL PATH

Deletes a directory. If B<PATH> is not provided, $_ is used. An error is
returned if the directory is not empty.

	rmdirL ($dir)
	  or die ("unable to delete $dir ($^E)");

=back

=head1 OPENDIR FUNCTIONS

Unlike the L</openL> function which returns a native handle, the open
directory functions must create a directory object and then use that
object to manipulate the directory. The native Perl rewinddir, seekdir
and telldir functions are not supported.

=over 4

=item new

Creates a directory object.

	$dir = Win32::LongPath->new ();

=item X<closedirL>closedirL

Closes the current directory for reading.

	$dir->closedirL ();

=item X<opendirL>opendirL PATH

Opens a directory for reading. If the directory object is already open the
existing directory will be closed before opening the new one.

	$dir->opendirL ($dir)
	  or die ("unable to open $dir ($^E)");

=item X<readdirL>readdirL

Reads the next item in the directory. In list context returns all the items
as a list. Otherwise returns the next item or undef if there are no more
items or an error occurred.

B<NOTE>: Only the item name is returned, not the whole path to the item.

	use Win32::LongPath qw(:funcs :fileattr);

	# search down the whole tree
	search_tree ($rootdir);
	exit 0;

	sub search_tree {

	# open directory and read contents
	my $path = shift;
	my $dir = Win32::LongPath->new ();
	$dir->opendirL ($path)
	  or die ("unable to open $path ($^E)");
	foreach my $file ($dir->readdirL ()) {
	  # skip parent dir
	  if ($file eq '..') {
	    next;
	  }

	  # get file stats
	  my $name = $file eq '.' ? $path : "$path/$file";
	  my $stat = lstatL ($name)
	    or die "unable to stat $name ($^E)";

	  # recurse if dir
	  if (($file ne '.') && (($stat->{attribs}
	    & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT))
	    == FILE_ATTRIBUTE_DIRECTORY)) {
	    search_tree ($name);
	    next;
	  }

	  # output stats
	  print "$name\t$stat->{attribs}\t$stat->{size}\t",
	    scalar localtime $stat->{ctime}, "\t",
	    scalar localtime $stat->{mtime}, "\n";
	}
	$dir->closedirL ();
	return;
	}

=back

=head1 MISCELLANEOUS FUNCTIONS

The following functions are not native Perl functions but are useful
when working with Windows.

=over 4

=item X<abspathL>abspathL PATH

Returns the absolute (fullpath) for B<PATH>. If the path exists, it will
replace the components with WindowsE<apos> long path names. Otherwise, it
returns a path that may contain short path names.

	$short = '../SYSTEM~2.PPT';
	$long = abspathL ($short);
	print "$short = $long\n";
	# if it exists it could print something like
	# ../SYSTEM~2.PPT = c:\rootdir\subdir\System File.ppt
	# if not, it might print
	# ../SYSTEM~2.PPT = c:\rootdir\subdir\SYSTEM~2.PPT

	# probably not the same because TMP is short path
	chdirL ($ENV {TMP}) or die "unable to change to TMP dir!";
	$curdir = getcwdL ();
	if (abspathL ($curdir) ne $curdir) {
	  print "not the same!\n";
	}

=item X<attribL>attribL ATTRIBS,PATH

Sets file attributes like the DOS attrib command.

B<ATTRIBS> is a string that identifies the attributes to enable or
disable. A plus sign (+) enables and a minus sign (-) disables the
attributes that follow. If not provided, a plus sign is assumed.

The attributes are identified by letters which can be upper or
lower case. The letters and their values are:

=over 4

=item *

B<H>: Hidden.

=item *

B<I>: Not content indexed. This value may not be valid for all file
systems.

=item *

B<R>: Read-only.

=item *

B<S>: System.

=back

	# sets System and hidden but disables read-only
	# could also be '-r+sh', 's-r+h', '+hs-r', etc.
	attribL ('sh-r', $file)
	  or die "unable to set attributes for $file ($^E)";

=item X<copyL>copyL FROM,TO

Copies the B<FROM> file to the B<TO> file. If the file exists it is
overwritten unless it is hidden or read-only. If it does not exist it
inherits the permissions of the parent directory. File attributes are
copied with the file. If the B<FROM> file is a symbolic link the target
is copied and not the symbolic link. If the B<TO> file is a symbolic
link the target is overwritten.

	copyL ($from, $to)
	  or die "unable to copy $from to $to ($^E)";

=item X<shortpathL>shortpathL PATH

Returns the short path of the file. It returns a blank string if it is
unable to get the short path.

	if (shortpathL ($file) eq '') {
	  or die "unable to get shortpath for $file";
	}

=item X<volinfoL>volinfoL PATH

Returns an object with the volume information for the B<PATH>. B<PATH>
can be a relative or fullpath to any object on the volume. The object
elements are:

=over 4

B<maxlen>: The maximum length of path components (the characters between
the backslashes; usually directory names).

B<name>: The name of the volume.

B<serial>: The Windows serial number for the volume.

B<sysflags>: System flags. Indicates the features that are supported by
the file system. Use the following constants to retrieve the individual
values. Import these values into your L<environment|/MODULE EXPORTS> if
you do not want to refer to them with the C<Win32::LongPath::> prefix.

=over 4

=over 4

=item FILE_CASE_PRESERVED_NAMES

=item FILE_CASE_SENSITIVE_SEARCH

=item FILE_FILE_COMPRESSION

=item FILE_NAMED_STREAMS

=item FILE_PERSISTENT_ACLS

=item FILE_READ_ONLY_VOLUME

=item FILE_SEQUENTIAL_WRITE_ONCE

=item FILE_SUPPORTS_ENCRYPTION

=item FILE_SUPPORTS_EXTENDED_ATTRIBUTES

=item FILE_SUPPORTS_HARD_LINKS

=item FILE_SUPPORTS_OBJECT_IDS

=item FILE_SUPPORTS_OPEN_BY_FILE_ID

=item FILE_SUPPORTS_REPARSE_POINTS

=item FILE_SUPPORTS_SPARSE_FILES

=item FILE_SUPPORTS_TRANSACTIONS

=item FILE_SUPPORTS_USN_JOURNAL

=item FILE_UNICODE_ON_DISK

=item FILE_VOLUME_IS_COMPRESSED

=item FILE_VOLUME_QUOTAS

=back

=back

=back

B<NOTE:> See the
L<Microsoft MSDN Library|http://msdn.microsoft.com/library> for more
information about this feature.

	use Win32::LongPath qw(:funcs :volflags);

	$vol = volinfoL ($file)
	  or die "unable to get volinfo for $file";
	if (!($vol->{sysflags} & FILE_SUPPORTS_REPARSE_POINTS)) {
	  die "symbolic links will not work on $vol->{name}!";
	}

=back

=head1 MODULE EXPORTS

All functions are automatically exported by default. The following tags
export specific values:

=over 4

=item *

B<:all>: all values

=item *

B<:funcs>: all functions

=item *

B<:fileattr>: file attributes used by the L</statL> and L</lstatL> functions

=item *

B<:volflags>: system flags used by the L</volinfoL> function

=back

=head1 LIMITATIONS

This module was developed for the Microsoft WinXP and greater environment.
It also supports the Cygwin environment.

=head1 AUTHOR

Robert Boisvert <rdbprog@gmail.com>

=head1 CREDITS

Many thanks to Jan Dubois for getting Windows support started with
L<Win32>. It remains the number one module in use on almost every
Windows installation of Perl.

A big thank you (どうもありがとうございました) to Yuji Shimada for L<Win32::Unicode>.
The concepts used there are the basis for much of Win32::LongPath.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
