use strict;
use warnings;
use utf8;
use feature qw/say/;

use Time::Strptime::Format;
say+Time::Strptime::Format->new($ARGV[0])->{parser_src};
__END__
