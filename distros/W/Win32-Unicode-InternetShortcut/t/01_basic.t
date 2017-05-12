use strict;
use warnings;
use Test::More tests => 42;
use charnames ':full';
use Win32::API;
use Encode;
use Carp;
use File::Spec;

BEGIN { use_ok('Win32::Unicode::InternetShortcut') };

BEGIN {
    no warnings 'once';
    $Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 1;
    Win32::Unicode::InternetShortcut->CoInitialize();
}

our $PathFileExistsW = Win32::API->new('shlwapi.dll', 'PathFileExistsW', 'P', 'I');
our $DeleteFileW = Win32::API->new('kernel32.dll', 'DeleteFileW', 'P', 'I');
our $utf16le = find_encoding('UTF-16LE') || croak "Failed to load UTF16-LE encoding\n";

my $self = Win32::Unicode::InternetShortcut->new;
my $url  = "http://www.example.com/?WonSign=\N{WON SIGN}";
my $path = File::Spec->catfile(File::Spec->tmpdir, "TEST, last char is Hebrew Letter Alef, \N{HEBREW LETTER ALEF}.url");
my $utf16path = $utf16le->encode("$path\0");
my $modified = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 12, 12, 12);
my $lastvisits = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 11, 11, 11);
my $lastmod = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 10, 10, 10);
my $iconindex = 2;
my $iconfile = "C:\\Windows\\System32\\shell32.dll";

# Test save method
# ----------------
ok($self->save($path, $url));
ok($PathFileExistsW->Call($utf16path));

# Test load method
# ----------------
$self = Win32::Unicode::InternetShortcut->new;
ok($self->load($path));
ok($self->{path} eq $path);
ok($self->{url} eq $url);

# Set modified, iconindex and iconfile; save it
# ---------------------------------------------
$self->{modified} = $modified;
$self->{iconindex} = $iconindex;
$self->{iconfile} = $iconfile;
ok($self->save($path, $url));

# Test load method and check url, path, modified, iconindex and iconfile
# ----------------------------------------------------------------------
$self = Win32::Unicode::InternetShortcut->new;
ok($self->load($path));
ok($self->{path} eq $path);
ok($self->{url} eq $url);
ok($self->{modified} eq $modified);
ok($self->{iconindex} == $iconindex);
ok($self->{iconfile} eq $iconfile);

# Test load properties
# --------------------
ok($self->load_properties($path));
ok(ref($self->{properties}) eq 'HASH');
ok($self->{properties}->{url} eq $url);
ok(exists($self->{properties}->{name}));
ok(exists($self->{properties}->{workdir}));
ok(exists($self->{properties}->{hotkey}));
ok(exists($self->{properties}->{showcmd}));
ok(exists($self->{properties}->{iconindex}));
ok(exists($self->{properties}->{iconfile}));
ok(exists($self->{properties}->{whatsnew}));
ok(exists($self->{properties}->{author}));
ok(exists($self->{properties}->{description}));
ok(exists($self->{properties}->{comment}));
ok(ref($self->{site_properties}) eq 'HASH');
ok(exists($self->{site_properties}->{whatsnew}));
ok(exists($self->{site_properties}->{author}));
ok(exists($self->{site_properties}->{lastvisits}));
ok(exists($self->{site_properties}->{lastmod}));
ok(exists($self->{site_properties}->{visitcount}));
ok(exists($self->{site_properties}->{description}));
ok(exists($self->{site_properties}->{comment}));
ok(exists($self->{site_properties}->{flags}));
ok(exists($self->{site_properties}->{url}));
ok(exists($self->{site_properties}->{title}));
ok(exists($self->{site_properties}->{codepage}));
ok(exists($self->{site_properties}->{iconindex}));
ok(exists($self->{site_properties}->{iconfile}));

# Change some properties and save them
# ------------------------------------
note("Overwrite FMTID_Intshcur properties and save them (must be 100% ok)");
$self->{properties}->{name} = "intshcut: New name, last char is Hebrew Letter Pe, \N{HEBREW LETTER PE}";
$self->{properties}->{workdir} = File::Spec->tmpdir();
$self->{properties}->{hotkey} = 2;
$self->{properties}->{iconindex} = 21;
$self->{properties}->{iconfile} = "C:\\Windows\\System32\\shell32.dll";
$self->{properties}->{whatsnew} = "intshcut: New what's new, last char is Hebrew Letter Final Mem, \N{HEBREW LETTER FINAL MEM}";
$self->{properties}->{author} = "intshcut: New author, last char is Hebrew Letter Pe, \N{HEBREW LETTER PE}";
$self->{properties}->{description} = "intshcut: New description, last char is Hebrew Letter Final Mem, \N{HEBREW LETTER FINAL MEM}";
$self->{properties}->{comment} = "intshcut: New comment, last char is Hebrew Letter Pe, \N{HEBREW LETTER PE}";
ok($self->save_properties($path));
$Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 0;
note("Overwrite FMTID_Internetsite properties and save them (likely to fail)");
$self->{site_properties}->{whatsnew} = "internetsite: New what's new, last char is Hebrew Letter Final Mem, \N{HEBREW LETTER FINAL MEM}";
$self->{site_properties}->{author} = "internetsite: New author, last char is Hebrew Letter Pe, \N{HEBREW LETTER PE}";
$self->{site_properties}->{lastvisits} = $lastvisits;
$self->{site_properties}->{lastmod} = $lastmod;
$self->{site_properties}->{visitcount} = 5;
$self->{site_properties}->{description} = "internetsite: New description, last char is Hebrew Letter Final Mem, \N{HEBREW LETTER FINAL MEM}";
$self->{site_properties}->{comment} = "internetsite: New comment, last char is Hebrew Letter Pe, \N{HEBREW LETTER PE}";
$self->{site_properties}->{flags} = 1; # PIDISF_RECENTLYCHANGED
$self->{site_properties}->{url} = "http://www.example.com/?IsItWonSign=\N{WON SIGN}";
$self->{site_properties}->{title} = "internetsite: New title, last char is Hebrew Letter Final Mem, \N{HEBREW LETTER FINAL MEM}";
$self->{site_properties}->{codepage} = 0;
$self->{site_properties}->{iconindex} = 22;
$self->{site_properties}->{iconfile} = "C:\\Windows\\System32\\shell32.dll";
ok($self->save_properties($path));
$Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 1;

END {
    $DeleteFileW->Call($utf16path) if (defined($utf16path));
    Win32::Unicode::InternetShortcut->CoUninitialize();
}

