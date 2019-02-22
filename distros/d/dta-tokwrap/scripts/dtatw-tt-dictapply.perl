#!/usr/bin/perl -w

##-- sanity check
if (@ARGV < 1) {
  print STDERR "Usage: $0 TT_TYPE_DICT [TT_TOKEN_FILE(s)...]\n";
  exit(1);
}

##-- read type dict
our %dict = qw();
my $dictfile = shift;
open(DICT,"<$dictfile") or die("$0: could not open '$dictfile': $!");
my ($text,$typdata);
while (<DICT>) {
  chomp;
  next if (/^\%\%/ || /^\s*$/); ##-- ignore comments & blank lines
  ($text,$typdata) = split(/\t/,$_,2);
  $dict{$text} = "\t".(defined($typdata) ? $typdata : '');
}
close(DICT);

##-- process token files
my ($tokdata);
while (<>) {
  if (/^\%\%/ || /^\s*$/) {
    ##-- pass through comments & blank lines
    print $_;
    next;
  }
  chomp;
  ($text,$tokdata) = split(/\t/,$_,2);
  if (!defined($typdata=$dict{$text})) {
    warn("$0: no dictionary entry for text '$text'");
    $typdata = $dict{$text} = '';
  }
  print $_, $typdata, "\n";
}
