# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2 qw(*mb);
use vars qw(@test);

@test = (
# 1
    sub { $_='ABC';        chop($_); $_ eq 'AB'   },
    sub { $_='ABC';        chop;     $_ eq 'AB'   },
    sub { $_='';           chop($_); $_ eq ''     },
    sub { $_='';           chop;     $_ eq ''     },
    sub { $_='ABC';    mb::chop($_); $_ eq 'AB'   },
    sub { $_='ABC';    mb::chop;     $_ eq 'AB'   },
    sub { $_='';       mb::chop($_); $_ eq ''     },
    sub { $_='';       mb::chop;     $_ eq ''     },
    sub { $_='あいう'; mb::chop($_); $_ eq 'あい' },
    sub { $_='あいう'; mb::chop;     $_ eq 'あい' },
# 11
    sub { $_='ABC';    my $r=    chop($_); $r eq 'C'  },
    sub { $_='ABC';    my $r=    chop;     $r eq 'C'  },
    sub { $_='';       my $r=    chop($_); $r eq ''   },
    sub { $_='';       my $r=    chop;     $r eq ''   },
    sub { $_='ABC';    my $r=mb::chop($_); $r eq 'C'  },
    sub { $_='ABC';    my $r=mb::chop;     $r eq 'C'  },
    sub { $_='';       my $r=mb::chop($_); $r eq ''   },
    sub { $_='';       my $r=mb::chop;     $r eq ''   },
    sub { $_='あいう'; my $r=mb::chop($_); $r eq 'う' },
    sub { $_='あいう'; my $r=mb::chop;     $r eq 'う' },
# 21
    sub { @_=('ABC','DEF','GHI');              chop(@_); ($_[0] eq 'AB')&&($_[1] eq 'DE')&&($_[2] eq 'GH')       },
    sub { @_=('');                             chop(@_); ($_[0] eq '')                                           },
    sub { @_=('ABC','DEF','GHI');          mb::chop(@_); ($_[0] eq 'AB')&&($_[1] eq 'DE')&&($_[2] eq 'GH')       },
    sub { @_=('');                         mb::chop(@_); ($_[0] eq '')                                           },
    sub { @_=('あいう','えおか','きくけ'); mb::chop(@_); ($_[0] eq 'あい')&&($_[1] eq 'えお')&&($_[2] eq 'きく') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { @_=('ABC','DEF','GHI');          my $r=    chop(@_); $r eq 'I'  },
    sub { @_=('');                         my $r=    chop(@_); $r eq ''   },
    sub { @_=('ABC','DEF','GHI');          my $r=mb::chop(@_); $r eq 'I'  },
    sub { @_=('');                         my $r=mb::chop(@_); $r eq ''   },
    sub { @_=('あいう','えおか','きくけ'); my $r=mb::chop(@_); $r eq 'け' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
