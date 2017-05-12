#!/usr/bin/perl -w

# simple perl benchmarker for different VCard parsers

use Benchmark;
use Text::vFile::asData;
use Text::VCardFast;

opendir(DH, "t/cases");
while (my $item = readdir(DH)) {
  next unless $item =~ m/\.vcf$/;
  doone($item);
}
closedir(DH);

sub doone {
  my $name = shift;

  print "$name\n";
  open(FH, "<t/cases/$name");
  my @lines = <FH>;
  close(FH);
  s/[\r\n]//gs for @lines;
  my $lines = join("\r\n", @lines);

  timethese(10000, {
    vcardasdata => sub { Text::vFile::asData->new->parse_lines(@lines) },
    pureperl => sub { Text::VCardFast::vcard2hash_pp($lines) },
    fastxs => sub { Text::VCardFast::vcard2hash_c($lines) },
  });
}
