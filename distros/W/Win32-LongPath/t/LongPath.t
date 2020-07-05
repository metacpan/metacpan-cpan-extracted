#!/usr/bin/perl
##########
# Test Win32::LongPath Functionality
##########

use Devel::Refcount 'refcount';
use Fcntl qw'O_APPEND O_CREAT O_RDONLY O_RDWR O_TRUNC O_WRONLY :mode';
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

my %oFModes =
  (
  'O_APPEND' => O_APPEND,
  'O_CREAT' => O_CREAT,
  'O_RDWR' => O_RDWR,
  'O_TRUNC' => O_TRUNC,
  'O_WRONLY' => O_WRONLY,
  );

my @sLines =
  (
  "first line\n",
  "appended line\n"
  );

my @oOpens =
  (
    {
    append => 0,
    create => 0,
    mode => ['', O_RDONLY],
    read => 1,
    trunc => 0,
    write => 0,
    },
    {
    append => 0,
    create => 1,
    mode => ['>', O_CREAT | O_TRUNC | O_WRONLY],
    read => 0,
    trunc => 1,
    write => 1,
    },
    {
    append => 0,
    create => 1,
    mode => ['+>', O_CREAT | O_RDWR | O_TRUNC],
    read => 1,
    trunc => 1,
    write => 1,
    },
    {
    append => 0,
    create => 0,
    mode => ['<', O_RDONLY],
    read => 1,
    trunc => 0,
    write => 0,
    },
    {
    append => 0,
    create => 0,
    mode => ['+<', O_RDWR],
    read => 1,
    trunc => 0,
    write => 1,
    },
    {
    append => 1,
    create => 1,
    mode => ['>>', O_APPEND | O_CREAT | O_WRONLY],
    read => 0,
    trunc => 0,
    write => 1,
    },
#    {
#    append => 1,
#    create => 1,
#    mode => ['+>>', O_APPEND | O_CREAT | O_RDWR],
#    read => 1,
#    trunc => 0,
#    write => 1,
#    },
  );

my @oModes =
  (
  { mask => S_IFDIR, name => 'DIR' },
  { mask => S_IFREG, name => 'REG' },
  { mask => S_IRUSR, name => 'READ' },
  { mask => S_IWUSR, name => 'WRITE' },
  { mask => S_IXUSR, name => 'EXEC' },
  );

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
  newsysfile => { name => 'same in Chinese traditional 你好嗎？' },
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
subtest ('Create file w/openL ()', sub {CreateFile (0)});
subtest ('Create file w/sysopenL ()', sub {CreateFile (1)});
subtest ('Rename/copy file', \&ChangeFile);
subtest ('Create links', \&CreateLinks);
subtest ('Change attributes', \&ChangeAttr);
subtest ('Test directory attributes', \&TestDirAttr);
subtest ('Test openL () file attributes', sub {TestFileAttr (0)});
subtest ('Test sysopenL () file attributes', sub {TestFileAttr (1)});
subtest ('Change file times', \&ChangeTime);
subtest ('List directory', \&ListDir);
subtest ('Remove files', \&RemoveFile);
done_testing (14);
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
  ok (attribL ($oAttrib->{attribs}, $sF1), $sAttrib) or diag ("error=$^E");
  my $oStat = statL ($sF1);
  ok ($oStat, 'statL (newfile)') or diag ("error=$^E");
  my $nAttrib = $oStat->{attribs} & $oAttrib->{mask};
  if (!$bExtAttr && ($oAttrib->{set} & FILE_ATTRIBUTE_NOT_CONTENT_INDEXED))
    { $nAttrib |= FILE_ATTRIBUTE_NOT_CONTENT_INDEXED; }
  is ($nAttrib, $oAttrib->{set}, $sAttrib);
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
  { diag "error=$^E"; }
else
  {
  $hFiles {newfile}->{name} = $sName;
  $hFiles {newfile}->{path} = $sF1;
  }
$hFiles {copy}->{path} = catfile ($sSubdir, $hFiles {copy}->{name});
ok (copyL ($hFiles {newfile}->{path}, $hFiles {copy}->{path}),
  'copyL (from, to)') or diag ("error=$^E");
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
ok (chdirL ($sRoot), 'chdirL (root)') or diag ("error=$^E");
my $sPath = getcwdL ();
ok ($sPath, 'getcwdL ()') or diag ("error=$^E");
ok (shortpathL ('.'), 'shortpathL (root)') or diag ("error=$^E");
ok (statL ('.'), 'statL (root)') or diag ("error=$^E");
my $oVol = volinfoL ('.');
ok ($oVol, 'volinfoL (root)') or diag ("error=$^E");
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
  'utimeL (yesterday)') or diag ("error=$^E");
my $oStat = statL ($hFiles {newfile}->{path});
ok ($oStat, 'statL (file)') or diag ("error=$^E");
my $sTime = check_time ($oStat->{atime}, $nNewTime, 1);
is ($sTime, '', 'utimeL () == atime') or diag ("time=$sTime");
$sTime = check_time ($oStat->{mtime}, $nNewTime, 0);
is ($sTime, '', 'utimeL () == mtime') or diag ("time=$sTime");
}

sub CreateFile

{
###########
# o form file name in longpath directory
# o calculate test count
# o create files using various open types
###########

my $bSys = $_ [0];
my $sFile = $bSys ? 'newsysfile' : 'newfile';
my $sFPath = catfile ($sSubdir, $hFiles {$sFile}->{name});
$hFiles {$sFile}->{path} = $sFPath;
my $nTests = 0;
foreach my $oOpen (@oOpens)
  {
  $nTests += 6;
  if (!$oOpen->{create})
    { $nTests++; }
  if ($oOpen->{append})
    { $nTests += 2; }
  }
plan tests => $nTests;
my $oF1;
my $bStarted;
foreach my $oOpen (@oOpens)
  {
  ###########
  # not create file?
  ###########

  if ($bStarted)
    { unlinkL $sFPath; }
  $bStarted = 1;
  my $sMode;
  if (!$bSys)
    { $sMode = $oOpen->{mode}->[0]; }
  else
    {
    $sMode = join ('|',
      map { $oOpen->{mode}->[1] & $oFModes {$_} ? $_ : () }
      sort keys %oFModes);
    if (!$sMode)
      { $sMode = 'O_RDONLY'; }
    }
  diag $bSys ? "testing sysopenL ($sMode)" : "testing openL ('$sMode')";
  if (!$oOpen->{create})
    {
    ###########
    # open should have an error since not create
    ###########

    my $bCreated;
    if ($bSys)
      {
      if (!ok (!sysopenL (\$oF1, $sFPath, $oOpen->{mode}->[1]),
        'sysopenL () not create file'))
        { $bCreated = 1; }
      }
    else
      {
      if (!ok (!openL (\$oF1, $oOpen->{mode}->[0], $sFPath),
        'openL () not create file'))
        { $bCreated = 1; }
      }

    ###########
    # create file if not exist
    ###########

    if (!$bCreated)
      {
      if ($bSys)
        {
        if (sysopenL (\$oF1, $sFPath, O_CREAT))
          { $bCreated = 1; }
        }
      else
        {
        if (openL (\$oF1, '>', $sFPath))
          { $bCreated = 1; }
        }
      }
    if ($bCreated)
      { close $oF1; }
    }

  ###########
  # open file
  ###########

  my $bOpen;
  if ($bSys)
    {
    $bOpen = ok (sysopenL (\$oF1, $sFPath, $oOpen->{mode}->[1]),
      'sysopenL () open file');
    }
  else
    {
    $bOpen = ok (openL (\$oF1, $oOpen->{mode}->[0], $sFPath),
      'openL () open file');
    }

  ###########
  # test writing
  ###########

  my $bWrite;
  if (!$bOpen)
    {
    fail ($bSys ? 'syswrite ()' : 'text write');
    fail 'refcount';
    fail 'close file';
    }
  else
    {
    if ($bSys)
      { $bWrite = syswrite $oF1, $sLines [0]; }
    else
      { $bWrite = print $oF1 $sLines [0]; }
    if (!ok (!($bWrite xor $oOpen->{write}),
      $bSys ? 'syswrite ()' : 'text write'))
      {
      if ($oOpen->{write})
        { diag "error=$^E"; }
      }
    is (refcount ($oF1), 1, 'refcount');
    if (!ok (close $oF1, 'close file'))
      { diag "error=$^E"; }
    }

  ###########
  # o write to file
  # o test reading
  ###########

  if (!$bWrite)
    {
    if ($bSys)
      {
      if (sysopenL (\$oF1, $sFPath, O_CREAT | O_TRUNC | O_WRONLY))
        {
        $bWrite = syswrite $oF1, $sLines [0];
        close $oF1;
        }
      }
    else
      {
      if (openL (\$oF1, '>', $sFPath))
        {
        $bWrite = print $oF1 $sLines [0];
        close $oF1;
        }
      }
    }
  if (!$bWrite)
    {
    fail ($bSys ? 'sysopenL ()' : 'openL ()');
    fail ($bSys ? 'sysread ()' : 'text read');
    fail ($bSys ? 'sysread () length' : 'text read length');
    if ($oOpen->{append})
      { fail 'append'; }
    }
  else
    {
    ###########
    # o open file
    # o check read
    ###########

    if ($bSys)
      {
      $bOpen = ok (sysopenL (\$oF1, $sFPath, $oOpen->{mode}->[1]),
        'sysopenL () open file');
      }
    else
      {
      $bOpen = ok (openL (\$oF1, $oOpen->{mode}->[0], $sFPath),
        'openL () open file');
      }
    if (!$bOpen)
      {
      diag "error=$^E";
      fail ($bSys ? 'sysread ()' : 'text read');
      fail ($bSys ? 'sysread () length' : 'text read length');
      if ($oOpen->{append})
        { fail 'append'; }
      }
    else
      {
      ###########
      # check length
      ###########

      my $nRead;
      if ($bSys)
        { $nRead = sysread $oF1, my $sIgnore, 1000; }
      else
        {
        my $sLine = readline $oF1;
        if (defined $sLine)
          { $nRead = length $sLine; }
        }
      if (!defined $nRead)
        {
        ok (!$oOpen->{read} || $oOpen->{trunc},
          $bSys ? 'sysread ()' : 'text read');
        }
      else
        {
        if ($oOpen->{trunc})
          { is ($nRead, 0, 'truncated read size'); }
        else
          { is ($nRead, length ($sLines [0]), 'read size'); }
        }

      ###########
      # append?
      ###########

      if ($oOpen->{append})
        {
        ###########
        # o check write
        # o close, reopen, check read
        ###########

        my $bWrite;
        if ($bSys)
          { $bWrite = syswrite $oF1, $sLines [1]; }
        else
          { $bWrite = print $oF1 $sLines [1]; }
        if (!ok ($bWrite, $bSys ? 'syswrite ()' : 'text write'))
          { diag "error=$^E"; }
        close $oF1;
        if (!openL (\$oF1, '', $sFPath))
          { fail "open to check append=$^E"; }
        else
          {
          $nRead = undef;
          if ($bSys)
            { $nRead = sysread $oF1, my $sIgnore, 1000; }
          else
            {
            local $/;
            my $sLine = <$oF1>;
            if (defined $sLine)
              { $nRead = length $sLine; }
            }
          if (!defined $nRead)
            { fail ($bSys ? "sysread ()=$^E" : "text read=$^E"); }
          else
            {
            is ($nRead, length ($sLines [0]) + length ($sLines [1]),
              'append size');
            }
          }
        }
      close $oF1;
      }
    }
  }
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
    'linkL (hard)') or diag ("error=$^E");
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
    { ok ($bLink, 'symlinkL (softrel)') or diag ("error=$^E"); }
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
    { ok ($sLink, 'readlinkL (softrel)') or diag ("error=$^E"); }
  else
    { is ($sLink, '..', 'readlinkL (softrel)'); }
  my $sFull = abspathL ($hFiles {newfile}->{path});
  ok (symlinkL ($sFull, $hFiles {softfull}->{path}), 'symlinkL (softfull)')
    or diag ("error=$^E");
  $sLink = readlinkL ($hFiles {softfull}->{path});
  if (!defined $sLink)
    { ok ($sLink, 'readlinkL (softfull)') or diag ("error=$^E"); }
  else
    { is ($sLink, $sFull, 'readlinkL (softfull)'); }
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
    { fail ("statL(subdir $nSub) exists"); }
  else
    { ok (mkdirL ($sSubdir), "mkdirL (subdir $nSub)") or diag ("error=$^E"); }
  }
ok (statL ($sSubdir), 'statL (longpath)') or diag ("error=$^E");
ok (abspathL ($sSubdir), 'abspathL (longpath)') or diag ("error=$^E");
ok (shortpathL ($sSubdir), 'shortpathL (longpath)') or diag ("error=$^E");
}

sub ListDir

{
###########
# o open dir object
# o attempt to open a file as a directory
# o read contents
# o examine contents
###########

plan tests => 13;
my $oDir = Win32::LongPath->new ();
ok ($oDir, 'Win32::LongPath->new') or diag ("error=$^E");
ok (!defined $oDir->opendirL ($hFiles {newfile}->{name}), 'opendirL (file)')
  or diag ('Expected failure opening a file as a directory');
ok ($oDir->opendirL ($sSubdir), 'opendirL (subdir)') or diag ("error=$^E");
my @sFound = sort $oDir->readdirL ();
my @sExpect = ('.', '..', $hFiles {newfile}->{name},
  $hFiles {newsysfile}->{name}, $hFiles {copy}->{name});
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
is (scalar @sFound, $nCount, 'directory count');
ok ($oDir->closedirL (), 'closedirL ()') or diag ("error=$^E");
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

plan tests => (scalar @sSubdirs) + 6;
if (!$bHLink)
  { pass ('no hard link capability to unlinkL (hard)'); }
else
  {
  ok (unlinkL ($hFiles {hard}->{path}), 'unlinkL (hard)')
    or diag ("error=$^E");
  }
if (!$bSLink)
  {
  pass ('no soft link capability to rmdirL (softrel)');
  pass ('no soft link capability to unlinkL (softfull)');
  }
else
  {
  ok (rmdirL ($hFiles {softrel}->{path}), 'rmdirL (softrel)')
    or diag ("error=$^E");
  ok (unlinkL ($hFiles {softfull}->{path}), 'rmdirL (softfull)')
    or diag ("error=$^E");
  }
ok (unlinkL ($hFiles {newfile}->{path}), 'unlinkL (newfile)')
  or diag ("error=$^E");
ok (unlinkL ($hFiles {newsysfile}->{path}), 'unlinkL (newsysfile)')
  or diag ("error=$^E");
ok (unlinkL ($hFiles {copy}->{path}), 'unlinkL (copy)')
  or diag ("error=$^E");
for (my $nIndex = scalar @sSubdirs; $nIndex; $nIndex--)
  {
  my $sDir = $sSubdirs [$nIndex - 1];
  ok (rmdirL ($sSubdir), 'rmdirL (subdir $nIndex)')
    or diag ("error=$^E");
  $sSubdir =~ s#[\\/]\Q$sDir\E$##;
  }
}

sub TestDirAttr

{
###########
# test directory attributes
###########

plan tests => 8;
ok (testL ('e', getcwdL ()), 'getcwdL () exists');
ok (testL ('d', '.'), 'rootdir is a directory');
ok (!testL ('f', '.'), 'rootdir is not a file');
ok (testL ('r', '.'), 'rootdir is read');
ok (testL ('w', '.'), 'rootdir is write');
ok (testL ('x', '.'), 'rootdir is exec');
ok (!testL ('s', '.') or testL ('z', '.'), 'rootdir is non-zero');
if (!$bSLink)
  { pass ('no soft link capability to testL (softrel)'); }
else
  { ok (testL ('l', $hFiles {softrel}->{path}), 'soft link is a link'); }
}

sub TestFileAttr

{
###########
# test attributes
###########

plan tests => 9;
my $sF1 = $_ [0] ? $hFiles {newsysfile}->{path} : $hFiles {newfile}->{path};
ok (testL ('e', $sF1), 'file exists');
ok (!testL ('d', $sF1), 'file is not a dir');
ok (testL ('f', $sF1), 'file is a file');
ok (!testL ('l', $sF1), 'file is not a link');
ok (testL ('r', $sF1), 'file is read');
ok (testL ('w', $sF1), 'file is write');
ok (!testL ('x', $sF1), 'file is not exec');
my $nFSize = testL ('s', $sF1);
ok ($nFSize || !testL ('z', $sF1), 'file size is non-zero');
my $nSize = length ($sLines [0]) + length ($sLines [1]);
if (!$_ [0])
  { $nSize += 2; }
is ($nFSize, $nSize, 'file size');
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