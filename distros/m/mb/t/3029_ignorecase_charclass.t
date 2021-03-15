# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (

    # 1
    sub { mb::eval(q{'A' =~ /A/     }); },
    sub { mb::eval(q{'A' !~ /a/     }); },
    sub { mb::eval(q{'a' =~ /a/     }); },
    sub { mb::eval(q{'a' !~ /A/     }); },
    sub { mb::eval(q{'A' =~ /A/i    }); },
    sub { mb::eval(q{'A' =~ /a/i    }); },
    sub { mb::eval(q{'a' =~ /a/i    }); },
    sub { mb::eval(q{'a' =~ /A/i    }); },
    sub {1},
    sub {1},

    # 11
    sub { mb::eval(q{'A' =~ /[A]/i  }); },
    sub { mb::eval(q{'A' =~ /[a]/i  }); },
    sub { mb::eval(q{'a' =~ /[a]/i  }); },
    sub { mb::eval(q{'a' =~ /[A]/i  }); },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

    # 21
    sub { mb::eval(q{'A' =~ m/A/    }); },
    sub { mb::eval(q{'A' !~ m/a/    }); },
    sub { mb::eval(q{'a' =~ m/a/    }); },
    sub { mb::eval(q{'a' !~ m/A/    }); },
    sub { mb::eval(q{'A' =~ m/A/i   }); },
    sub { mb::eval(q{'A' =~ m/a/i   }); },
    sub { mb::eval(q{'a' =~ m/a/i   }); },
    sub { mb::eval(q{'a' =~ m/A/i   }); },
    sub {1},
    sub {1},

    # 31
    sub { mb::eval(q{'A' =~ m/[A]/i }); },
    sub { mb::eval(q{'A' =~ m/[a]/i }); },
    sub { mb::eval(q{'a' =~ m/[a]/i }); },
    sub { mb::eval(q{'a' =~ m/[A]/i }); },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

    # 41
    sub { mb::eval(q{'A' =~ m'A'    }); },
    sub { mb::eval(q{'A' !~ m'a'    }); },
    sub { mb::eval(q{'a' =~ m'a'    }); },
    sub { mb::eval(q{'a' !~ m'A'    }); },
    sub { mb::eval(q{'A' =~ m'A'i   }); },
    sub { mb::eval(q{'A' =~ m'a'i   }); },
    sub { mb::eval(q{'a' =~ m'a'i   }); },
    sub { mb::eval(q{'a' =~ m'A'i   }); },
    sub {1},
    sub {1},

    # 51
    sub { mb::eval(q{'A' =~ m'[A]'i }); },
    sub { mb::eval(q{'A' =~ m'[a]'i }); },
    sub { mb::eval(q{'a' =~ m'[a]'i }); },
    sub { mb::eval(q{'a' =~ m'[A]'i }); },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
