##########
# Test Win32::LongPath Functionality
#
# 1.0	R. Boisvert	8/5/2013
#	First release.
# 1.1	R. Boisvert	12/2/2013
#	Disable utimeL testing on Cygwin.
# 1.2	A. Gregory	5/13/2016
#	Added refcount test.
##########

use Devel::Refcount 'refcount';
use Fcntl ':mode';
use File::Spec::Functions;
use Test::More;
use Win32;

use strict;
use utf8;
use warnings;

###########
# make sure module loads
###########

BEGIN { use_ok ('Win32::LongPath', ':all') }

###########
# constants
###########

my @sSubdirs =
  (
  'This part of the name has spaces in it',
  'here we add symbols that are acceptable $#!+=-,',
  "now some extended ASCII\xA2\xA3\xA5\xAB\xBB\xC7\xC9\xE0\xE2\xE4\xE5\xE6\xE7\xE8",
  '平仮名 ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔゕゖ',
  'Hebrew ׆אבגדהוזחטיךכלםמןנסעףפץצקרשתװױײ',
  'Greek ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϐϑϒϓϔϕϖϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯϰϱϲϳϴϵ϶ϷϸϹϺϻϼϽϾϿ',
  'Cyrillic ЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂҈҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӜӝӞӟӠӡ',
  );

my @oAttChk =
  (
  { # set all
    attribs => 'aihrs',
    mask => FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_HIDDEN
      | FILE_ATTRIBUTE_NOT_CONTENT_INDEXED | FILE_ATTRIBUTE_READONLY
      | FILE_ATTRIBUTE_SYSTEM,
    set => FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_HIDDEN
      | FILE_ATTRIBUTE_NOT_CONTENT_INDEXED | FILE_ATTRIBUTE_READONLY
      | FILE_ATTRIBUTE_SYSTEM,
  },
  { # set arch, reset sys
    attribs => '+a-s',
    mask => FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_SYSTEM,
    set => FILE_ATTRIBUTE_ARCHIVE,
  },
  { # set sys, reset read
    attribs => 's-r',
    mask => FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_SYSTEM,
    set => FILE_ATTRIBUTE_SYSTEM,
  },
  { # reset hidden
    attribs => '+h-h',
    mask => FILE_ATTRIBUTE_HIDDEN,
    set => 0,
  },
  );

my @oAttribs =
  (
  { mask => FILE_ATTRIBUTE_ARCHIVE, name => 'ARCHIVE' },
  { mask => FILE_ATTRIBUTE_COMPRESSED, name => 'COMPRESSED' },
  { mask => FILE_ATTRIBUTE_DEVICE, name => 'DEVICE' },
  { mask => FILE_ATTRIBUTE_DIRECTORY, name => 'DIR' },
  { mask => FILE_ATTRIBUTE_ENCRYPTED, name => 'ENCRYPT' },
  { mask => FILE_ATTRIBUTE_HIDDEN, name => 'HIDDEN' },
  { mask => FILE_ATTRIBUTE_INTEGRITY_STREAM, name => 'INTEGRITY' },
  { mask => FILE_ATTRIBUTE_NORMAL, name => 'NORMAL' },
  { mask => FILE_ATTRIBUTE_NOT_CONTENT_INDEXED, name => 'FANCI' },
  { mask => FILE_ATTRIBUTE_NO_SCRUB_DATA, name => 'NOSCRUB' },
  { mask => FILE_ATTRIBUTE_OFFLINE, name => 'OFFLINE' },
  { mask => FILE_ATTRIBUTE_READONLY, name => 'READONLY' },
  { mask => FILE_ATTRIBUTE_REPARSE_POINT, name => 'REPARSE' },
  { mask => FILE_ATTRIBUTE_SPARSE_FILE, name => 'SPARSE' },
  { mask => FILE_ATTRIBUTE_SYSTEM, name => 'SYSTEM' },
  { mask => FILE_ATTRIBUTE_TEMPORARY, name => 'TEMP' },
  { mask => FILE_ATTRIBUTE_VIRTUAL, name => 'VIRTUAL' },
  );

my @oModes =
  (
  { mask => S_IFDIR, name => 'DIR' },
  { mask => S_IFREG, name => 'REG' },
  { mask => S_IRUSR, name => 'READ' },
  { mask => S_IWUSR, name => 'WRITE' },
  { mask => S_IXUSR, name => 'EXEC' },
  );

my @oVolFlags =
  (
  { mask => FILE_CASE_PRESERVED_NAMES, name => 'PRESERVE_NAME' },
  { mask => FILE_CASE_SENSITIVE_SEARCH, name => 'CASE_SEARCH' },
  { mask => FILE_FILE_COMPRESSION, name => 'FILE_COMPRESS' },
  { mask => FILE_NAMED_STREAMS, name => 'NAMED_STREAM' },
  { mask => FILE_PERSISTENT_ACLS, name => 'PERSIST_ACL' },
  { mask => FILE_READ_ONLY_VOLUME, name => 'READONLY' },
  { mask => FILE_SEQUENTIAL_WRITE_ONCE, name => 'WRITE_ONCE' },
  { mask => FILE_SUPPORTS_ENCRYPTION, name => 'ENCRYPT' },
  { mask => FILE_SUPPORTS_EXTENDED_ATTRIBUTES, name => 'EXT_ATTR' },
  { mask => FILE_SUPPORTS_HARD_LINKS, name => 'HARD_LINK' },
  { mask => FILE_SUPPORTS_OBJECT_IDS, name => 'OBJID' },
  { mask => FILE_SUPPORTS_OPEN_BY_FILE_ID, name => 'OPEN_BY_ID' },
  { mask => FILE_SUPPORTS_REPARSE_POINTS, name => 'REPARSE' },
  { mask => FILE_SUPPORTS_SPARSE_FILES, name => 'SPARSE' },
  { mask => FILE_SUPPORTS_TRANSACTIONS, name => 'TRANSACT' },
  { mask => FILE_SUPPORTS_USN_JOURNAL, name => 'JOURNAL' },
  { mask => FILE_UNICODE_ON_DISK, name => 'UNICODE' },
  { mask => FILE_VOLUME_IS_COMPRESSED, name => 'VOL_COMPRESS' },
  { mask => FILE_VOLUME_QUOTAS, name => 'QUOTAS' },
  );

###########
# varbs
###########

my ($bExtAttr, $bHLink, $sRoot, $bSLink, $sSubdir);
my %hFiles =
  (
  newfile => { name => 'famous Japanese expression お元気ですか？' },
  copy => { name => 'copy میں اپنے بھائی کے طور پر ایک ہی ہوں.' },
  hard => { name => 'hard link 세 번째 테스트' },
  softrel => { name => 'symbolic relative link 첫 번째 테스트' },
  softfull => { name => 'symbolic fullpath link 두 번째 테스트' },
  );

###########
# tests
###########

subtest ('Change to root', \&ChangeRoot);
subtest ('Create a Unicode longpath', \&CreateLong);
subtest ('Create file', \&CreateFile);
subtest ('Rename/copy file', \&ChangeFile);
subtest ('Create links', \&CreateLinks);
subtest ('Change attributes', \&ChangeAttr);
subtest ('Test attributes', \&TestAttr);
subtest ('Change file times', \&ChangeTime);
subtest ('List directory', \&ListDir);
subtest ('Remove files', \&RemoveFile);
done_testing (11);
exit;

sub ChangeAttr

{
###########
# o change file attributes
# o check against stat
###########

plan tests => (scalar @oAttChk) * 3;
my $sF1 = $hFiles {newfile}->{path};
foreach my $oAttrib (@oAttChk)
  {
  my $sAttrib = sprintf ('attribL (%s)', attrib_string ($oAttrib->{set}));
  ok (attribL ($oAttrib->{attribs}, $sF1), $sAttrib)
    or test_exit (0, $^E);
  my $oStat = statL ($sF1);
  ok ($oStat, 'statL (newfile)')
    or test_exit (0, $^E);
  my $nAttrib = $oStat->{attribs} & $oAttrib->{mask};
  if (!$bExtAttr && ($oAttrib->{set} & FILE_ATTRIBUTE_NOT_CONTENT_INDEXED))
    { $nAttrib |= FILE_ATTRIBUTE_NOT_CONTENT_INDEXED; }
  is ($nAttrib, $oAttrib->{set}, $sAttrib)
    or test_exit (0, 'actual=' . attrib_string ($oAttrib->{set}));
  }
}

sub ChangeFile

{
###########
# o rename file
# o copy file
###########

plan tests => 2;
my $sName = 'renamed to good-bye in Russian до свидания';
my $sF1 = catfile ($sSubdir, $sName);
if (!ok (renameL ($hFiles {newfile}->{path}, $sF1), 'renameL (old, new)'))
  { test_exit (0, $^E); }
else
  {
  $hFiles {newfile}->{name} = $sName;
  $hFiles {newfile}->{path} = $sF1;
  }
$hFiles {copy}->{path} = catfile ($sSubdir, $hFiles {copy}->{name});
ok (copyL ($hFiles {newfile}->{path}, $hFiles {copy}->{path}),
  'copyL (from, to)')
  or test_exit (0, $^E);
}

sub ChangeRoot

{
###########
# o change to root
# o check getcwdL, shortpathL and volinfoL
# o get hard/soft link capabilities
###########

plan tests => 5;
$sRoot = '.';
ok (chdirL ($sRoot), 'chdirL (root)')
  or test_exit (0, $^E);
my $sPath = getcwdL ();
ok ($sPath, 'getcwdL ()')
  or test_exit (0, $^E);
ok (shortpathL ('.'), 'shortpathL (root)')
  or test_exit (0, $^E);
ok (statL ('.'), 'statL (root)')
  or test_exit (0, $^E);
my $oVol = volinfoL ('.');
ok ($oVol, 'volinfoL (root)')
  or test_exit (0, $^E);
my @aOSVers = Win32::GetOSVersion ();
$bHLink = $oVol->{sysflags} & FILE_SUPPORTS_HARD_LINKS ? 1 : 0;
if (!$bHLink)
  {
  diag
    ('hard link testing disabled because not supported on this file system');
  }
$bSLink = ($oVol->{sysflags} & FILE_SUPPORTS_REPARSE_POINTS)
  && ($aOSVers [1] > 5) ? 1 : 0;
if (!$bSLink)
  {
  diag
    ('soft link testing disabled because not supported on this file system');
  }
$bExtAttr = $oVol->{sysflags} & FILE_SUPPORTS_REPARSE_POINTS ? 1 : 0;
if (!$bExtAttr)
  {
  diag
    ('FANCI bit testing disabled because not supported on this file system');
  }
}

sub ChangeTime

{
###########
# change file time and test
# NOTE: if DST change within 24 it will cause this to fail
###########

if ($^O eq 'cygwin')
  {
  plan tests => 1;
  pass ('utimeL');
  diag ('utimeL testing disabled because not fully supported in Cygwin');
  return;
  }
plan tests => 4;
my $nNewTime = time () - (60 * 60 * 24);
ok (utimeL ($nNewTime, $nNewTime, $hFiles {newfile}->{path}),
  'utimeL (yesterday)')
  or test_exit (0, $^E);
my $oStat = statL ($hFiles {newfile}->{path});
ok ($oStat, 'statL (file)')
  or test_exit (0, $^E);
my $sTime = check_time ($oStat->{atime}, $nNewTime, 1);
is ($sTime, '', 'utimeL () == atime')
  or test_exit (0, $sTime);
$sTime = check_time ($oStat->{mtime}, $nNewTime, 0);
is ($sTime, '', 'utimeL () == mtime')
  or test_exit (0, $sTime);
}

sub CreateFile

{
###########
# o create long file in subdir
# o append a line
# o read back
# o verify line count
###########

plan tests => 6;
my $oF1;
$hFiles {newfile}->{path} = catfile ($sSubdir, $hFiles {newfile}->{name});
if (!ok (openL (\$oF1, '>', $hFiles {newfile}->{path}), 'openL (>newfile)'))
  { test_exit (0, $^E); }
else
  {
  print $oF1 "not UTF with UTF '私の名前はボブです。'\n";
  close $oF1;
  }
$hFiles {newfile}->{path} = abspathL ($hFiles {newfile}->{path});
if (!ok (openL (\$oF1, '+<', $hFiles {newfile}->{path}), 'openL (+<newfile)'))
  { test_exit (0, $^E); }
else
  {
  <$oF1>;
  print $oF1 "added 2nd line\n";
  close $oF1;
  }
if (!ok (openL (\$oF1, '>>', $hFiles {newfile}->{path}), 'openL (>>newfile)'))
  { test_exit (0, $^E); }
else
  {
  print $oF1 "added 3rd line\n";
  close $oF1;
  }
my $nIndex;
if (!ok (openL (\$oF1, ':encoding(UTF-8)', $hFiles {newfile}->{path}),
  'openL (:UTF-8newfile)'))
  {
  test_exit (0, $^E);
  $nIndex = 0;
  }
else
  {
  for ($nIndex = 0; <$oF1>; $nIndex++)
    { }
  if (!eof $oF1)
    { test_exit (0, 'stopped before EOF!'); }
  my $nRef = refcount ($oF1);
  is ($nRef, 1, 'refcount')
    or test_exit (0, "Open file has unexpected refcount ($nRef)");
  close $oF1;
  }
ok ($nIndex == 3, 'linecount == 3?')
  or test_exit (0, "found $nIndex lines");
}

sub CreateLinks

{
###########
# create links
# o hard
# o soft relative/dir
# o soft fullpath/file
###########

plan tests => 5;
$hFiles {hard}->{path} = catfile ($sSubdir, $hFiles {hard}->{name});
if (!$bHLink)
  { pass ('no hard link capability to linkL (hard)'); }
else
  {
  ok (linkL ($hFiles {newfile}->{path}, $hFiles {hard}->{path}),
    'linkL (hard)')
    or test_exit (0, $^E);
  }
$hFiles {softrel}->{path} = catfile ($sSubdir, $hFiles {softrel}->{name});
$hFiles {softfull}->{path} = catfile ($sSubdir, $hFiles {softfull}->{name});
if ($bSLink)
  {
  ###########
  # ignore error if privilege does not exist
  ###########

  my $bLink = symlinkL ('..', $hFiles {softrel}->{path});
  if (!$bLink && (Win32::LongPath::get_last_error () == 1314))
    {
    $bSLink = 0;
    diag ('soft link testing disabled because privilege missing');
    }
  else
    {
    ok ($bLink, 'symlinkL (softrel)')
      or test_exit (0, $^E);
    }
  }
if (!$bSLink)
  {
  pass ('no soft link capability to symlinkL (softrel)');
  pass ('no soft link capability to readlink (softrel)');
  pass ('no soft link capability to symlinkL (softfull)');
  pass ('no soft link capability readlinkL (softfull)');
  }
else
  {
  my $sLink = readlinkL ($hFiles {softrel}->{path});
  if (!defined $sLink)
    {
    ok ($sLink, 'readlinkL (softrel)')
      or test_exit (0, $^E);
    }
  else
    {
    is ($sLink, '..', 'readlinkL (softrel)')
      or test_exit (0, ".. != $sLink");
    }
  my $sFull = abspathL ($hFiles {newfile}->{path});
  ok (symlinkL ($sFull, $hFiles {softfull}->{path}), 'symlinkL (softfull)')
    or test_exit (0, $^E);
  $sLink = readlinkL ($hFiles {softfull}->{path});
  if (!defined $sLink)
    {
    ok ($sLink, 'readlinkL (softfull)')
      or test_exit (0, $^E);
    }
  else
    {
    is ($sLink, $sFull, 'readlinkL (softfull)')
      or test_exit (0, "fullpath != $sLink");
    }
  }
}

sub CreateLong

{
###########
# o create long subdir
# o statL, abspathL, shortpathL
###########

plan tests => (scalar @sSubdirs) + 3;
$sSubdir = '.';
my $nSub = 0;
foreach my $sDir (@sSubdirs)
  {
  $nSub++;
  $sSubdir .= "/$sDir";
  if (statL ($sSubdir))
    {
    fail ("statL(subdir $nSub)");
    test_exit (0, 'subdir exists');
    }
  else
    {
    ok (mkdirL ($sSubdir), "mkdirL (subdir $nSub)")
      or test_exit (1, $^E);
    }
  }
ok (statL ($sSubdir), 'statL (longpath)')
  or test_warning (0, $^E);
ok (abspathL ($sSubdir), 'abspathL (longpath)')
  or test_warning (0, $^E);
ok (shortpathL ($sSubdir), 'shortpathL (longpath)')
  or test_warning (0, $^E);
}

sub ListDir

{
###########
# o open dir object for subdir
# o read contents
# o examine contents
###########

plan tests => 11;
my $oDir = Win32::LongPath->new ();
ok ($oDir, 'Win32::LongPath->new')
  or test_exit (1, $^E);
ok ($oDir->opendirL ($sSubdir), 'opendirL (subdir)')
  or test_exit (1, $^E);
my @sFound = sort $oDir->readdirL ();
my @sExpect = ('.', '..', $hFiles {newfile}->{name}, $hFiles {copy}->{name});
if ($bHLink)
  { push @sExpect, $hFiles {hard}->{name}; }
else
  { pass ('no hard link capability to opendirL (hard)'); }
if ($bSLink)
  { push @sExpect, $hFiles {softrel}->{name}, $hFiles {softfull}->{name}; }
else
  {
  pass ('no soft link capability to opendirL (softfull)');
  pass ('no soft link capability to opendirL (softrel)');
  }
my $nCount = 0;
foreach my $sFile (sort @sExpect)
  {
  $nCount++;
  if ($nCount > @sFound)
    {
    fail ("Content $nCount: missing");
    next;
    }
  if ($sFile eq $sFound [$nCount - 1])
    {
    pass ("Content $nCount: matches");
    next;
    }
  fail ("Content $nCount: does not match expected");
  }
ok ($nCount == @sFound, 'directory count matches expected')
  or test_exit (0, "Expected: $nCount, Actual: " . scalar @sFound);
ok ($oDir->closedirL (), 'closedirL ()')
  or test_exit (0, $^E);
}

sub RemoveFile

{
###########
# remove
# o hard link
# o soft links
# o all files
# o directory path
###########

plan tests => (scalar @sSubdirs) + 5;
if (!$bHLink)
  { pass ('no hard link capability to unlinkL (hard)'); }
else
  {
  ok (unlinkL ($hFiles {hard}->{path}), 'unlinkL (hard)')
    or test_exit (0, $^E);
  }
if (!$bSLink)
  {
  pass ('no soft link capability to rmdirL (softrel)');
  pass ('no soft link capability to unlinkL (softfull)');
  }
else
  {
  ok (rmdirL ($hFiles {softrel}->{path}), 'rmdirL (softrel)')
    or test_exit (0, $^E);
  ok (unlinkL ($hFiles {softfull}->{path}), 'rmdirL (softfull)')
    or test_exit (0, $^E);
  }
ok (unlinkL ($hFiles {newfile}->{path}), 'unlinkL (newfile)')
  or test_exit (0, $^E);
ok (unlinkL ($hFiles {copy}->{path}), 'unlinkL (copy)')
  or test_exit (0, $^E);
for (my $nIndex = scalar @sSubdirs; $nIndex; $nIndex--)
  {
  my $sDir = $sSubdirs [$nIndex - 1];
  ok (rmdirL ($sSubdir), 'rmdirL (subdir $nIndex)')
    or test_exit (0, $^E);
  $sSubdir =~ s#[\\/]\Q$sDir\E$##;
  }
}

sub TestAttr

{
###########
# test attributes
###########

plan tests => 17;
my $sF1 = $hFiles {newfile}->{path};
ok (testL ('e', getcwdL (), 'getcwdL () exists'))
  or test_exit (0, 'rootdir does not exist');
ok (testL ('d', '.'))
  or test_exit (0, 'rootdir is not a dir');
ok (!testL ('f', '.'))
  or test_exit (0, 'rootdir is a file');
ok (testL ('r', '.'))
  or test_exit (0, 'rootdir is not read');
ok (testL ('w', '.'))
  or test_exit (0, 'rootdir is not write');
ok (testL ('x', '.'))
  or test_exit (0, 'rootdir is not exec');
ok (!testL ('s', '.') or testL ('z', '.'))
  or test_exit (0, 'rootdir is non-zero');
ok (testL ('e', $sF1))
  or test_exit (0, 'file does not exist');
ok (!testL ('d', $sF1))
  or test_exit (0, 'file is a dir');
ok (testL ('f', $sF1))
  or test_exit (0, 'file is not a file');
ok (!testL ('l', $sF1))
  or test_exit (0, 'file is a link');
ok (testL ('r', $sF1))
  or test_exit (0, 'file is not read');
ok (testL ('w', $sF1))
  or test_exit (0, 'file is not write');
ok (!testL ('x', $sF1))
  or test_exit (0, 'file is exec');
my $nFSize = testL ('s', $sF1);
ok ($nFSize or !testL ('z', $sF1))
  or test_exit (0, 'file is zero');
ok ($nFSize == 83)
  or test_exit (0, "file size is $nFSize instead of 83");
if (!$bSLink)
  { pass ('no soft link capability to testL (softrel)'); }
else
  {
  ok (testL ('l', $hFiles {softrel}->{path}))
    or test_exit (0, 'link is not a link');
  }
}

###########
# functions
###########

sub attrib_string

{
my $nAttrib = shift;
my $sAttrib = sprintf '(%08X)', $nAttrib;
foreach my $oAttrib (@oAttribs)
  {
  if ($nAttrib & $oAttrib->{mask})
    { $sAttrib .= " $oAttrib->{name}"; }
  }
return $sAttrib;
}

sub check_time

{
my ($nActual, $nExpect, $bAccess) = @_;
if ($nActual == $nExpect)
  { return ''; }
my $sTime = $bAccess ? 'access' : 'mod';
my $nDiff = abs ($nActual - $nExpect);
if (!$bAccess && ($nDiff < 2))
  {
  diag ("$sTime time less than 2 seconds");
  return '';
  }
if ($bAccess && ($nDiff < (24 * 60 * 60)))
  {
  diag ("$sTime time less than 1 day");
  return '';
  }
my $sDiff;
my $nDay = int ($nDiff / (24 * 60 * 60));
$nDiff -= $nDay * 24 * 60 * 60;
if ($nDay)
  { $sDiff = "$nDay days"; }
my $nHour = int ($nDiff / 3600);
$nDiff -= $nHour * 3600;
if ($sDiff or $nHour)
  { $sDiff = ($sDiff ? "$sDiff, " : '') . "$nHour hour(s)"; }
my $nMin = int ($nDiff / 60);
$nDiff -= $nMin * 60;
if ($sDiff or $nMin)
  { $sDiff = ($sDiff ? "$sDiff, " : '') . "$nMin minute(s)"; }
$sDiff = ($sDiff ? "$sDiff, " : '') . "$nDiff second(s)";
return "$sTime time: $nActual!=$nExpect, $sDiff";
}

sub test_exit

{
my ($bDie, $sTitle) = @_;
diag ($sTitle);
if ($bDie)
  { BAIL_OUT ($sTitle); }
return;
}
