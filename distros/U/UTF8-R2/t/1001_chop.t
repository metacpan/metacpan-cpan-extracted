######################################################################
#
# 1001_chop.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (
# 1
    sub { $_='ABC';              chop($_); $_ eq 'AB'   },
    sub { $_='ABC';              chop;     $_ eq 'AB'   },
    sub { $_='';                 chop($_); $_ eq ''     },
    sub { $_='';                 chop;     $_ eq ''     },
    sub { $_='ABC';    UTF8::R2::chop($_); $_ eq 'AB'   },
    sub { $_='ABC';    UTF8::R2::chop;     $_ eq 'AB'   },
    sub { $_='';       UTF8::R2::chop($_); $_ eq ''     },
    sub { $_='';       UTF8::R2::chop;     $_ eq ''     },
    sub { $_='あいう'; UTF8::R2::chop($_); $_ eq 'あい' },
    sub { $_='あいう'; UTF8::R2::chop;     $_ eq 'あい' },
# 11
    sub { $_='ABC';    my $r=          chop($_); $r eq 'C'  },
    sub { $_='ABC';    my $r=          chop;     $r eq 'C'  },
    sub { $_='';       my $r=          chop($_); $r eq ''   },
    sub { $_='';       my $r=          chop;     $r eq ''   },
    sub { $_='ABC';    my $r=UTF8::R2::chop($_); $r eq 'C'  },
    sub { $_='ABC';    my $r=UTF8::R2::chop;     $r eq 'C'  },
    sub { $_='';       my $r=UTF8::R2::chop($_); $r eq ''   },
    sub { $_='';       my $r=UTF8::R2::chop;     $r eq ''   },
    sub { $_='あいう'; my $r=UTF8::R2::chop($_); $r eq 'う' },
    sub { $_='あいう'; my $r=UTF8::R2::chop;     $r eq 'う' },
# 21
    sub { @_=('ABC','DEF','GHI');                    chop(@_); ($_[0] eq 'AB')&&($_[1] eq 'DE')&&($_[2] eq 'GH')       },
    sub { @_=('');                                   chop(@_); ($_[0] eq '')                                           },
    sub { @_=('ABC','DEF','GHI');          UTF8::R2::chop(@_); ($_[0] eq 'AB')&&($_[1] eq 'DE')&&($_[2] eq 'GH')       },
    sub { @_=('');                         UTF8::R2::chop(@_); ($_[0] eq '')                                           },
    sub { @_=('あいう','えおか','きくけ'); UTF8::R2::chop(@_); ($_[0] eq 'あい')&&($_[1] eq 'えお')&&($_[2] eq 'きく') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { @_=('ABC','DEF','GHI');          my $r=          chop(@_); $r eq 'I'  },
    sub { @_=('');                         my $r=          chop(@_); $r eq ''   },
    sub { @_=('ABC','DEF','GHI');          my $r=UTF8::R2::chop(@_); $r eq 'I'  },
    sub { @_=('');                         my $r=UTF8::R2::chop(@_); $r eq ''   },
    sub { @_=('あいう','えおか','きくけ'); my $r=UTF8::R2::chop(@_); $r eq 'け' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
