# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
 # OK, we want to check THIS version, not some older one
 unshift @INC, qw(blib/lib blib/arch);

 require Win32::DriveInfo;

 $| = 1; print "1..11\n";
}
END {print "not ok 1\n" unless $loaded;}

use Cwd;

$loaded = 1;
print "ok 1\n";

$test_num = 2;

# platform/build
eval { ($MajorVersion, $MinorVersion, $BuildNumber,
 $PlatformId, $BuildStr) = Win32::DriveInfo::GetVersionEx() };
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

$ok = 1;
if (defined &Win32::GetOSVersion) {
  eval { ($string, $major, $minor, $build, $id) = &Win32::GetOSVersion };

  if (!$@) {
    $build = $build & 0xffff if Win32::IsWin95();
    $string =~ s/^ *(.*?) *$/$1/;

    $ok =
    $major  eq $MajorVersion &&
    $minor  eq $MinorVersion &&
    $string eq $BuildStr     &&
    $id     eq $PlatformId   &&
    $build  eq $BuildNumber;
  } else {
    $ok = 0; undef $@;
  }
}

print(( $ok ? "" : "not " )."ok ".($test_num++)."\n");

eval { @drives = Win32::DriveInfo::DrivesInUse() };
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

eval { @drives2 = grep Win32::DriveInfo::IsReady($_), ("C".."Z") };
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

eval {
$dr1 = join "", map uc($_), grep {Win32::DriveInfo::DriveType($_) == 3} @drives;
$dr2 = join "", map uc($_), grep {Win32::DriveInfo::DriveType($_) == 3} @drives2;
};
$ok = ! $@ && $dr1 eq $dr2;
warn "Test $test_num fails if one of your fixed drives has no root (not formatted)\n"
  unless $ok;
print(( $ok ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;


eval {
for (@drives2) { # drives that have root (fixed and loaded removable)
  my ($VolumeName,
      $VolumeSerialNumber,
      $MaximumComponentLength,
      $FileSystemName, @attr) = Win32::DriveInfo::VolumeInfo($_);
  $vol->{$_} = {
	"label"   => $VolumeName,
	"serial"  => $VolumeSerialNumber,
	"maxcomp" => $MaximumComponentLength,
	"fsys"    => $FileSystemName,
	"attrs"   => \@attr,
  };
}
};
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

# drive-types
eval {
  for (@drives2) {
    $vol->{$_}{"type"} = Win32::DriveInfo::DriveType($_);
  }
};
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

$ok = 1;
if (defined &Win32::FsType) {
# Win32::FsType is rather strange one - it checks "current drive"
# i.e. the root of the current directory

  my $dir = cwd;

  for (@drives2) {
    chdir "$_:\\";
    my ($fstype, $flags, $maxcomplen) = &Win32::FsType;

    if ($fstype ne $vol->{$_}{"fsys"} || $maxcomplen ne $vol->{$_}{"maxcomp"}) {
       $ok = 0; last;
    }
  }
  chdir $dir;
}
print(( $ok ? "" : "not " )."ok ".($test_num++)."\n");

# drives that give correct "free" value on dir command -
# fixed, CD ROM, RAM drives.
# Removable media (2) are not tested for not to hear unpleasant sounds.
# Network drives(type 4) seems like giving wrong values.
@drives3 = grep {$vol->{$_}{"type"} =~ /[356]/} @drives2;
# print "@drives3\n";

eval {
for (@drives3) { # drives that have root (fixed and loaded removable)
  $vol->{$_}{"free"} = (Win32::DriveInfo::DriveSpace($_))[6];
}
};
print(( ! $@ ? "" : "not " )."ok ".($test_num++)."\n");
undef $@;

$ok=0;
for (@drives3) {
  ($label, $serial, $free, $units) = dir_cmd($_);
#print "$label, $serial, $free, $units|".$vol->{$_}{"label"}.",".$vol->{$_}{"serial"}.",".$vol->{$_}{"free"}."\n";
  $label ||= ""; $serial ||= ""; $free ||= 0;

  $ok =
  $label  eq $vol->{$_}{"label"} &&
  (($serial eq $vol->{$_}{"serial"}) ||
  # god knows why 4DOS does not return serial for CD-ROMs
  # but command.com does
   ($serial eq "") ||
  # RAM drives
  # 4DOS returns 0000:0000 serial when command.com returns nothing
  # I'm sure this is just a misinterpretation
   ($serial eq "0000:0000" && $vol->{$_}{"serial"} eq "")
  ) &&
  ($units ne "bytes" || $free eq $vol->{$_}{"free"});

  if ($units ne "bytes") {
    print "Drive $_: `dir' does not return the exact free space\n";
  } else {
    print "Drive $_: `dir' and module returned ".( $ok ? "" : "not " )."the same\n";
  }

  $ok or last;
}
print(( $ok ? "" : "not " )."ok ".($test_num++)."\n");


sub dir_cmd {
  my $drive = shift;
  substr($drive,1)="";

  my $cmd = $ENV{COMSPEC} || "command.com";

  # cmd.exe + nmake sometimes give $? == -1
  # one case is - when I erroneously called dmake first
  # after that I had to reopen shell to get rid of this error
  my $out = `"$cmd" /c dir $drive:\\`;   # print "$?,".length($out)."\n";
  return if !$out || $out !~ /\S/ || $?;

  # label can contain spaces
  my $label;
  if      ($out =~ /Volume[\t ]+in[\t ]+drive[\t ]+$drive[\t ]+(is[\t ]+unlabeled|has[\t ]+no[\t ]+label)/i) {
      $label = "";
  } elsif ($out =~ /Volume[\t ]+in[\t ]+drive[\t ]+$drive[\t ]+is[\t ]*(.*?)([\t ]+Serial[\t ]+number[\t ]+is|[\t ]*$)/im) {
      $label = $1;
  } else {
      $label = "";
  }

  my ($serial) = ($out =~ /Serial[\t ]+number[\t ]+is[\t ]*(.*?)[\t ]*$/im) ? $1 : "";
  $serial =~ s/-/:/g; # command.com and cmd.exe use - delimiter

  # stupid command.com returns partial MB value on large drives
  # cmd.exe uses , or \xFF or God knows what separator
  my ($free, $units) = $out =~ /(\d[\d\W]+)(bytes|MB|GB)\s+free/i or return;
  $free  =~ s/\D//g;

  ($label, $serial, $free, $units);
}
