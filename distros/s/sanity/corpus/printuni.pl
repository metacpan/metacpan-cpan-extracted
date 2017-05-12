use Unicode::UCD 'charinfo';
use open qw(:utf8 :std);

my ($ttl, $gaps) = (0, 0);
my $codestr = '';
my $first_valid;
my $last_block;
foreach my $ord (0xAE..0xFFFF) {
   my $charinfo = charinfo($ord);
   
   my $valid = 1;
   $valid = 0 unless ($charinfo);
   $valid = 0 if ($valid && $charinfo->{category} =~ /^(?:C.|Mc|Z.)$/);
   $valid = 0 if ($valid && $charinfo->{combining} || $charinfo->{block} =~ /Combining/ || $charinfo->{name} =~ /COMBINING/);
   $valid = 0 if ($valid && $charinfo->{script} =~ /
      Georgian|Samaritan|Mandaic|Myanmar|Tagalog|Hanunoo|Buhid|Tagbanwa|Limbu|Buginese|Tai_tham|Balinese|Sundanese|Batak|Lepcha|
      Ol_chiki|Glagolitic|Coptic|Tai_viet|Saurashtra|Bopomofo|Lisu|Bamum|Syloti_nagri|Kayah_li|Rejang|Javanese|Cham|Meetei_mayek
   /ix);
   $valid = 0 if ($valid && $charinfo->{block} =~ /
      Vedic|
      \QMiscellaneous Technical\E|
      \QEnclosed Alphanumerics\E|
      \QSupplemental Arrows-\E[AB]|
      \QMiscellaneous Mathematical Symbols-\E[AB]|
      \QMiscellaneous Symbols and Arrows\E|
      \QSupplemental Mathematical Operators\E|
      \QSupplemental Punctuation\E|
      \QUnified Canadian Aboriginal Syllabics Extended\E|
      \QKangxi Radicals\E|
      \QControl Pictures\E|
      \QOptical Character Recognition\E|
      \QBlock Elements\E|
      \QYijing Hexagram Symbols\E|
      \QCyrillic Extended-B\E|
      \QModifier Tone Letters\E|
      \QLatin Extended-D\E|
      \QCommon Indic Number Forms\E|
      \QDevanagari Extended\E|
      \QHangul Jamo Extended-\E[AB]|
      \QEthiopic Extended-A\E|
      \QArabic Presentation Forms-\E[AB]|
      \QVariation Selectors\E|
      Specials
   /ix);
   $valid = 0 if ($valid && $charinfo->{name} =~ /FILLER/);
   $valid = 0 if ($valid && 
      ($ord >= 0x0514 && $ord <= 0x0530) ||
      ($ord >= 0x22C0 && $ord <= 0x22FF) ||
      ($ord >= 0x2670 && $ord <= 0x26FF)
   );

   unless ($valid) {
      if (defined $first_valid) {
         if    ($ord-1 == $first_valid) { $codestr .= sprintf("0x%x, ", $first_valid); }
         elsif ($ord-2 == $first_valid) { $codestr .= sprintf("0x%x, 0x%x, ", $first_valid, $ord-1); }
         else                           { $codestr .= sprintf("0x%x..0x%x, ", $first_valid, $ord-1); }
         $codestr .= "\n" unless (++$gaps % 8);
         undef $first_valid;
      }
      next;
   }

   unless ($last_block eq $charinfo->{block}) {
      $last_block = $charinfo->{block};
      print "\n=== $last_block";
      $ttl = 0;
   }

   $first_valid //= $ord;
   printf ("\n0x%04x: ", $ord) unless ($ttl++ % 64);
   print chr($ord);
}

my $base90 = [0..9, 'A'..'Z', 'a'..'z', split(//, '#$%&()*+,-./:;<=>?@[]^_`{|}~')];
my $baseXXX;
eval '$baseXXX = [ @$base90, map { chr } (0xA2..0xAC, '.$codestr.') ];';  

print "\n\n";
print join '', @$baseXXX;
print "\nTotal characters: ".scalar(@$baseXXX)."\n";
print "\n\n$codestr\n";
