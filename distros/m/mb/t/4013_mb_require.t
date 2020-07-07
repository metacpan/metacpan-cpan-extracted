# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use Cwd;
use lib Cwd::cwd();
open(FILE,">@{[__FILE__]}.1.pl"); print FILE q{ 1 };                                                      close(FILE);
open(FILE,">@{[__FILE__]}.2.pl"); print FILE q{ "ソ" =~ /ソ/ };                                           close(FILE);
open(FILE,">@{[__FILE__]}.3.pl"); print FILE q{ lc('アA') eq 'アa' };                                     close(FILE);
open(FILE,">@{[__FILE__]}.4.pl"); print FILE q{ sub lowercase { lc($_[0]) } lowercase('アA') eq 'アa'; }; close(FILE);
open(FILE,">@{[__FILE__]}.5.pl"); print FILE q{ sub uppercase { uc($_[0]) } 1; };                         close(FILE);
END { unlink("@{[__FILE__]}.1.pl","@{[__FILE__]}.1.oo.pl") }
END { unlink("@{[__FILE__]}.2.pl","@{[__FILE__]}.2.oo.pl") }
END { unlink("@{[__FILE__]}.3.pl","@{[__FILE__]}.3.oo.pl") }
END { unlink("@{[__FILE__]}.4.pl","@{[__FILE__]}.4.oo.pl") }
END { unlink("@{[__FILE__]}.5.pl","@{[__FILE__]}.5.oo.pl") }

@test = (
# 1
    sub { CORE::require "@{[__FILE__]}.1.pl" },
    sub { mb::require "@{[__FILE__]}.1.pl"   },
    sub { mb::require "@{[__FILE__]}.2.pl"   },
    sub { mb::require "@{[__FILE__]}.3.pl"   },
    sub { mb::require "@{[__FILE__]}.4.pl";  },
    sub { mb::require "@{[__FILE__]}.5.pl"; uppercase('ヂa') eq 'ヂA'; },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
