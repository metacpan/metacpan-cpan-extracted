#!/usr/bin/perl -w

##-- dtatw-trim-encode.perl : trim troublesome input
use utf8;
use open qw(:std :utf8);
use strict;

##-- get trim expression
my $trim_chars = shift // 'DEFAULT';
utf8::decode($trim_chars) if (!utf8::is_utf8($trim_chars));
if ($trim_chars eq '-' || uc($trim_chars) eq 'DEFAULT') {
  ##-- default trim expression
  $trim_chars = join('',
		     "\x{0082}", #-- U+0082 <control> = BREAK PERMITTED HERE
		     "\x{00ad}", #-- U+00AD SOFT HYPHEN
		     "\x{200b}", #-- U+200B ZERO WIDTH SPACE
		     "\x{200c}", #-- U+200C ZERO WIDTH NON-JOINER
		     "\x{200d}", #-- U+200D ZERO WIDTH JOINER
		     "\x{2060}", #-- U+2060 WORD JOINER
		     "\x{fdd3}", #-- U+FDD3 Arabic Presentation Forms-A-undef- (mantis #728)
		     "\x{feff}", #-- U+FEFF ZERO WIDTH NO-BREAK = BYTE ORDER MARK (BOM)
		     "\x{fffe}", #-- U+FFFE <not a character>
		    );
}

##-- generate regex
my @trim_cps = unpack('C0C*',$trim_chars);
my @trim_hex  = qw();
my @trim_dec  = qw();
my $trim_utf8 = '';
foreach my $cp (unpack('C0C*',$trim_chars)) {
  my $hex = sprintf("%x",$cp);
  push(@trim_hex, $hex);
  push(@trim_dec, $cp);
  $trim_utf8  .= "\\x{$hex}";
}

##-- sanity check (no-op)
if ($trim_utf8 eq '') {
  while (<>) { print; }
  exit 0;
}

##-- compile regex
my $trim_re_str = join('|',
		       ($trim_utf8 ? qq{[$trim_utf8]} : qw()),		##-- UTF-8 text literal
		       '(?i:\&\#x0{0,3}(?:'.join('|',@trim_hex).');)',	##-- XML character entities: hex
		       '(?i:\&\#0{0,4}(?:'.join('|',@trim_dec).');)',	##-- XML character entities: decimal
		      );

#print STDERR "$0: trim_re = qr{$trim_re_str}\n";##-- DEBUG
my $trim_re = qr{$trim_re_str}
  or die("$0: failed to compile trim regex qr{$trim_re_str}: $!");

##-- guts
while (<>) {
  s{($trim_re)}{<!--DTATW.TRIM:$1-->}gi;
  print;
}
