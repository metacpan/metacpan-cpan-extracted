use strict;
use warnings;
use utf8;
use File::Temp;
use Test::More;

sub _spurt {
  my ($filename, $bytes) = @_;
  open my $fh, '>', $filename or die "Failed to open $filename for writing: $!";
  binmode $fh or die "Failed to binmode $filename: $!";
  print $fh $bytes;
}

sub _slurp {
  my ($filename) = @_;
  open my $fh, '<', $filename or die "Failed to open $filename for reading: $!";
  binmode $fh or die "Failed to binmode $filename: $!";
  local $/;
  return scalar readline $fh;
}

my $dir = File::Temp->newdir;

_spurt "$dir/utf8.txt", "\xE2\x98\x83";
_spurt "$dir/cp1252.txt", "\x80\x0D\x0A";
_spurt "$dir/utf16be.txt", "\xD8\x34\xDD\x1E";
_spurt "$dir/utf16le.txt", "\x03\x26\x0D\x00\x0A\x00";

{
  use open::layers r => ':encoding(UTF-8)';
  # three arg open doesn't see ${^OPEN} until 5.8.8
  open my $read, "< $dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is do { local $/; scalar readline $read }, '☃', 'read decodes from UTF-8';
  close $read;
  open my $write, "> $dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for writing: $!";
  print $write '°';
  close $write;
  is _slurp("$dir/utf8_out.txt"), "\xB0", 'write does not encode to UTF-8';
}

{
  use open::layers w => ':encoding(UTF-8)';
  open my $read, "< $dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is do { local $/; scalar readline $read }, "\xE2\x98\x83", 'read does not decode from UTF-8';
  close $read;
  open my $write, "> $dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for writing: $!";
  print $write '°';
  close $write;
  is _slurp("$dir/utf8_out.txt"), "\xC2\xB0", 'write encodes to UTF-8';
}

{
  use open::layers r => ':encoding(UTF-8)', w => ':encoding(cp1252)';
  open my $read, "< $dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is do { local $/; scalar readline $read }, '☃', 'read decodes from UTF-8';
  close $read;
  open my $write, "> $dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for writing: $!";
  print $write '€';
  close $write;
  is _slurp("$dir/cp1252_out.txt"), "\x80", 'write encodes to cp1252';
}

{
  use open::layers rw => ':encoding(UTF-16BE)';
  open my $read, "< $dir/utf16be.txt" or die "Failed to open $dir/utf16be.txt for reading: $!";
  is do { local $/; scalar readline $read }, "\N{U+1D11E}", 'read decodes from UTF-16BE';
  close $read;
  open my $write, "> $dir/utf16be_out.txt" or die "Failed to open $dir/utf16be_out.txt for writing: $!";
  print $write "\N{U+1D122}";
  close $write;
  is _slurp("$dir/utf16be_out.txt"), "\xD8\x34\xDD\x22", 'write encodes to UTF-16BE';
}

{
  use open::layers rw => ':raw:encoding(cp1252)';
  open my $read, "< $dir/cp1252.txt" or die "Failed to open $dir/cp1252.txt for reading: $!";
  is do { local $/; scalar readline $read }, "€\r\n", 'read decodes from cp1252 (no CRLF)';
  close $read;
  open my $write, "> $dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for writing: $!";
  print $write "€\n";
  close $write;
  is _slurp("$dir/cp1252_out.txt"), "\x80\x0A", 'write encodes to cp1252 (no CRLF)';
}

SKIP: {
  skip ':crlf after :encoding does not work properly on Windows before 5.14', 2
    if $^O eq 'MSWin32' and "$]" < 5.014;
  use open::layers rw => ':raw:encoding(UTF-16LE):crlf:utf8'; # :utf8 for 5.8.8
  open my $read, "< $dir/utf16le.txt" or die "Failed to open $dir/utf16le.txt for reading: $!";
  is do { local $/; scalar readline $read }, "☃\n", 'read decodes from UTF-16LE and CRLF';
  close $read;
  open my $write, "> $dir/utf16le_out.txt" or die "Failed to open $dir/utf16le_out.txt for writing: $!";
  print $write "☃\n";
  close $write;
  is _slurp("$dir/utf16le_out.txt"), "\x03\x26\x0D\x00\x0A\x00", 'write encodes to UTF-16LE and CRLF';
}

{
  open my $read, '<', "$dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  open::layers->import($read => ':encoding(UTF-8)');
  is do { local $/; scalar readline $read }, '☃', 'UTF-8 encoding applied to handle';
  close $read;
  open my $write, '>', "$dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for writing: $!";
  open::layers->import(*$write => ':encoding(cp1252)');
  print $write '€';
  close $write;
  is _slurp("$dir/cp1252_out.txt"), "\x80", 'cp1252 encoding applied to handle';
}

done_testing;
