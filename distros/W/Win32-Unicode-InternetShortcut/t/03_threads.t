use strict;
use warnings;
use File::Temp qw/tmpnam/;
use charnames ':full';
use Win32::API;
use Encode;
use threads;
use Carp;
use File::Spec;
use Test::More tests => 21;

BEGIN { use_ok('Win32::Unicode::InternetShortcut') };
Win32::Unicode::InternetShortcut->import('COINIT_APARTMENTTHREADED');

our $PathFileExistsW = Win32::API->new('shlwapi.dll', 'PathFileExistsW', 'P', 'I');
our $DeleteFileW = Win32::API->new('kernel32.dll', 'DeleteFileW', 'P', 'I');
our $utf16le = find_encoding('UTF-16LE') || croak "Failed to load UTF16-LE encoding\n";

#########################

BEGIN {
    no warnings 'once';
    $Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 1;
}

my @thr = ();
foreach (0..19) {
    push(@thr, threads->create('start_thread'));
}
foreach (0..19) {
    isnt(0, $thr[$_]->join, 'thread join');
}

sub start_thread {
    Win32::Unicode::InternetShortcut->CoInitializeEx(COINIT_APARTMENTTHREADED);

    my $self = Win32::Unicode::InternetShortcut->new || die "Cannot create self\n";
    my $url  = "http://www.example.com/?WonSign=\N{WON SIGN}";
    my $path = File::Spec->catfile(File::Spec->tmpdir, "TEST, TID " . threads->tid . ", last char is Hebrew Letter Alef, \N{HEBREW LETTER ALEF}.url");
    my $utf16path = $utf16le->encode("$path\0");
    my $modified = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 12, 12, 12);
    my $lastvisits = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 11, 11, 11);
    my $lastmod = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 2012, 01, 01, 10, 10, 10);
    my $iconindex = 2;
    my $iconfile = "C:\\Windows\\System32\\shell32.dll";

    # Test save method
    # ----------------
    $self->save($path, $url) || die "Cannot save\n";
    $PathFileExistsW->Call($utf16path) || die "Cannot find $utf16path\n";

    # Test load method
    # ----------------
    $self = Win32::Unicode::InternetShortcut->new;
    $self->load($path);
    ($self->{path} eq $path) || die "Path differs\n";
    ($self->{url} eq $url) || die "Url differs\n";

    # Set modified, iconindex and iconfile; save it
    # ---------------------------------------------
    $self->{modified} = $modified;
    $self->{iconindex} = $iconindex;
    $self->{iconfile} = $iconfile;
    $self->save($path, $url) || die "Cannot save\n";

    # Test load method and check url, path, modified, iconindex and iconfile
    # ----------------------------------------------------------------------
    $self = Win32::Unicode::InternetShortcut->new;
    $self->load($path) || die "Cannot load\n";
    ($self->{path} eq $path) || die "Path differs\n";
    ($self->{url} eq $url) || die "Url differs\n";
    ($self->{modified} eq $modified) || die "Modified differs\n";
    ($self->{iconindex} == $iconindex) || die "Iconindex differs\n";
    ($self->{iconfile} eq $iconfile) || die "Iconfile differs\n";

    # Test load properties
    # --------------------
    $self->load_properties($path) || die "Cannot load properties\n";
    (ref($self->{properties}) eq 'HASH') || die "properties is not a HASH\n";
    ($self->{properties}->{url} eq $url) || die "Url differs\n";
    (exists($self->{properties}->{name})) || die "properties->name does not exist\n";
    (exists($self->{properties}->{workdir})) || die "properties->workdir does not exist\n";
    (exists($self->{properties}->{hotkey})) || die "properties->hotkey does not exist\n";
    (exists($self->{properties}->{showcmd})) || die "properties->showcmd does not exist\n";
    (exists($self->{properties}->{iconindex})) || die "properties->iconindex does not exist\n";
    (exists($self->{properties}->{iconfile})) || die "properties->iconfile does not exist\n";
    (exists($self->{properties}->{whatsnew})) || die "properties->whatsnew does not exist\n";
    (exists($self->{properties}->{author})) || die "properties->author does not exist\n";
    (exists($self->{properties}->{description})) || die "properties->description does not exist\n";
    (exists($self->{properties}->{comment})) || die "properties->commentname does not exist\n";
    (ref($self->{site_properties}) eq 'HASH') || die "site_properties->name is not a HASH\n";
    (exists($self->{site_properties}->{whatsnew})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{author})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{lastvisits})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{lastmod})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{visitcount})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{description})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{comment})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{flags})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{url})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{title})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{codepage})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{iconindex})) || die "site_properties->name does not exist\n";
    (exists($self->{site_properties}->{iconfile})) || die "site_properties->name does not exist\n";

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
    $self->save_properties($path);

    $DeleteFileW->Call($utf16path);
    Win32::Unicode::InternetShortcut->CoUninitialize();
}
