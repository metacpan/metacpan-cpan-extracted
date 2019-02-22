#!/usr/bin/perl -w

use bytes;
use Getopt::Long ':config'=>'no_ignore_case';
use File::Basename qw(basename);
use Encode qw(encode_utf8 decode_utf8);
use utf8;

our ($help);
our $prog = basename($0);
our $verbose = 1;
our $max_warnings = 10;
GetOptions(
	   'help|h' => \$help,
	   'quiet|q!' => sub {$verbose = $_[1] ? 0 : 1},
	   'max-warnings|max-warn|n=i' => \$max_warnings,
	  );

if (!@ARGV || $help) {
  print STDERR
    ("\n",
     "Usage: $prog \[OPTION(s)...] TT_FILE [TXT_FILE]\n",
     "\n",
     "Options:\n",
     "  -help         ##-- this help message\n",
     "  -quiet        ##-- only output errors\n",
     "  -max-warn N   ##-- maximum number of warnings per input file (default=$max_warnings)\n",
     "\n",
    );
  exit 1;
}
our $ttfile = shift;
our $txtfile = shift;
if (!$txtfile) {
  ($txtfile=$ttfile)=~s/\.t[t0-9]*$//;
  $txtfile .= '.txt';
}
our $ttbase = File::Basename::basename($ttfile);

##-- buffer txtfile
{
  local $/=undef;
  open(TXT,"<$txtfile") or die("$prog: $ttfile: ERROR: open failed for '$txtfile': $!");
  binmode(TXT);
  $txtbuf = <TXT>;
  close(TXT);
}

my $warned=0;
sub tokwarn {
  warn("$prog: $ttbase: ", @_);
  ++$warned;
}

##-- process .t file
open(TT,"<$ttfile") or die("$0: $ttfile: ERROR: open failed for '$ttfile': $!");
my ($text,$pos,$rest, $off,$len, $buftext,$tokre);
while (<TT>) {
  chomp;
  next if (/^\s*$/ || /^\%\%/); ##-- skip comments and blank lines
  ($text,$pos,$rest) = split(/\t/,$_,3);
  $text //= '';
  $toklabel = "token '$text\t".($pos//'-undef-').($rest ? "\t$rest" : '')."' at $ttfile line $.";
  if (!defined($pos)) {
    tokwarn("no position defined for $toklabel\n");
    next;
  }

  ##-- check for suspicious text
  if ($text =~ /\$[SW]B\$/) {
    tokwarn("tokenizer hint appears in token text for $toklabel\n");
    next;
  }
  if ($text =~ /_$/ && ($rest//'') =~ /\[\$ABBREV\]/) {
    tokwarn("suspicious final underscore for $toklabel\n");
    next;
  }

  ##-- parse offset, length
  ($off,$len) = split(' ',$pos,2);
  if ($off+$len > length($txtbuf)) {
    tokwarn("token offset+length=", ($off+$len), " > buffer length=", length($txtbuf), " for $toklabel\n");
    next;
  }

  ##-- check content
  $buftext = substr($txtbuf, $off,$len);
  if ($buftext ne $text) {
    $tokre = join('', map {($_ eq '_' ? '[_\s]' : "\Q$_\E").'(?:[\s\n\r\t]| |\-|¬|—|–)*'} split(//,$text));
    if ($buftext !~ $tokre) {
      $buftext =~ s/\n/\\n/g;
      $buftext =~ s/\r/\\r/g;
      tokwarn("buffer text=\"$buftext\" doesn't match token text for $toklabel\n");
    }
  }

  ##-- check max warnings?
  if ($warned >= $max_warnings) {
    warn("$prog: $ttbase: WARNING: maximum number of warnings ($max_warnings) emitted -- bailing out");
    last;
  }
}

##-- final report & exit
if ($warned || $verbose >= 1) {
  print "$prog: $ttfile -> $txtfile : ", ($warned ? "NOT ok ($warned warnings)" : "ok"), "\n";
}
exit $warned;
