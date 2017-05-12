use 5.010;
use PerlIO::via::UnicodeDebug;
binmode STDOUT, ':via(UnicodeDebug)' or die $!;

say "Héllò Wörld";