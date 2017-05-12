use 5.010;
use PerlIO::via::UnicodeDebug;
binmode STDOUT, ':via(UnicodeDebug)' or die $!;

local $Unicode::Debug::Names = 1;
say "Héllò Wörld";