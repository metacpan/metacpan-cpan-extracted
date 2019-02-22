#!/usr/bin/perl -w

use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode decode);
use strict;

##======================================================================
## Command-line
my $prog = basename($0);
my ($help);
my $rawmode = undef;
my $char_offsets = 0;
my $enc = 'utf8';

##-- parse command-line
my (@opts,@args);
foreach (@ARGV) {
  if (/^\-+[^0-9]/) {
    push(@opts,$_);
  } else {
    push(@args,$_);
  }
}
Getopt::Long::GetOptionsFromArray(\@opts,
				  'help|h' => \$help,
				  'raw|r!' => \$rawmode,
				  'character-offsets|characters|chars|co|c|utf8|u!' => \$char_offsets,
				  'encoding|enc|e=s' => \$enc,
				 );

if (@args < 2 || grep {/^\-h/} @ARGV) {
  print STDERR <<EOF;

Usage(s):
 $prog [OPTIONS] FILE [=]OFFSET \"+\"[LENGTH=1]
 $prog [OPTIONS] FILE [=]OFFSET \"-\"[OFFSET_FROM_FILE_END]
 $prog [OPTIONS] FILE [=]OFFSET    [END_OFFSET] ##-- not inclusive

Options:
 -h, -help         # show this help message
 -c, -chars        # use character offsets rather than byte offsets (expensive!)
 -e, -enc=ENC      # use encoding ENC for character mode (default=$enc)
 -r, -raw          # suppress formatting newlines and "---" separator(s)

Notes:
 + if OFFSET begins with '=', -raw mode is implied

EOF
  exit ($help ? 0 : 1);
}

##======================================================================
## MAIN

while (@args) {
  my ($file,$off,$lenarg) = splice(@args,0,3);
  my $fraw = ($rawmode || $off =~ s/^\=//);

  open(FILE,"<$file") or die("$0: open failed for '$file': $!");

  my ($buf,$len);
  if ($char_offsets) {
    ##-- character mode: buffer & decode whole file
    binmode(FILE,":encoding($enc)")
      or die("$0: failed to set encoding '$enc' for file '$file': $!");
    local $/= undef;
    $buf    = <FILE>;

    if    ($lenarg =~ /^\+(.*)$/) { $len = $1; }
    elsif ($lenarg =~ /^\-(.*)$/) { $len = length($buf) - $1 - $off; }
    else                          { $len = $lenarg - $off; }

    $buf    = encode($enc, substr($buf, $off, $len));
  }
  else {
    ##-- byte-mode: just read specified portion
    if    ($lenarg =~ /^\+(.*)$/) { $len = $1; }
    elsif ($lenarg =~ /^\-(.*)$/) { $len = (-s $file) - $1 - $off; }
    else                          { $len = $lenarg - $off; }

    seek(FILE, $off, 0)
      or die("$0: seek() to offset $off  failed for file '$file': $!");
    $buf = '';
    read(FILE, $buf, $len);
  }

  print
    (($rawmode ? qw() : "---\n"),
     $buf,
     ($rawmode ? qw() : "\n---\n"),
    );
  close(FILE);
}
