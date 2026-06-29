die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Step 6 test for import() / main() argument acceptance and error messages.
#
# mb keeps accepting every encoding name (big5 / big5hkscs / eucjp / gb18030 /
# gbk / rfc2279 / sjis / uhc / utf8 / wtf8) plus the runtime tokens *mb and %mb,
# exactly as before (no narrowing). An unsupported argument must die with a
# message that lists the usable arguments. The modulino main() -e handling dies
# the same way for an unknown encoding. This file loads mb with require and only
# inspects the argument scan: the rejection paths die before any tie / alias /
# filter side effect, and the acceptance paths are exercised in a child perl so
# the parent test environment is never modified. It runs on every perl from
# 5.005_03 up (no source filter, no perl-version-specific feature).

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

my $mb = "$FindBin::Bin/../lib/mb.pm";
my $child = "$FindBin::Bin/_import_args_$$.pl";

# every token mb must keep accepting from use mb '...'
my @accept = qw( *mb %mb big5 big5hkscs eucjp gb18030 gbk rfc2279 sjis uhc utf8 wtf8 );

sub spew {
    open(OUT, ">$_[0]") or die "can't write $_[0]: $!";
    print OUT $_[1];
    close(OUT);
}

# run "use mb 'TOKEN'" in a child interpreter with PERL_MB_OCTET set (so no
# source filter is installed) and return the combined stdout+stderr. A token
# that is accepted prints ACCEPTED; a rejected token dies with "not supported".
sub try_use {
    my $token = $_[0];
    spew($child, qq{use mb '$token';\nprint "ACCEPTED\\n";\n});
    local $ENV{PERL_MB_OCTET} = 1;
    my $out = scalar `$^X -I"$FindBin::Bin/../lib" "$child" 2>&1`;
    unlink $child;
    return $out;
}

# capture the die message from mb->import('TOKEN') without running side effects
sub import_err {
    eval { mb->import($_[0]); 1 };
    return $@;
}

# capture the die message from the modulino main() for a given @ARGV
sub main_err {
    local @ARGV = @_;
    eval { mb::main(); 1 };
    return $@;
}

@test = (
# 1 -- unsupported import argument dies with an explicit, listing message
    sub { import_err('nosuchthing') ne ''                              },
    sub { import_err('nosuchthing') =~ /not supported/                 },
    sub { import_err('nosuchthing') =~ /use one of:/                   },
    sub { import_err('nosuchthing') =~ /\*mb/                          },
    sub { import_err('nosuchthing') =~ /%mb/                           },
    sub { import_err('nosuchthing') =~ /\bbig5\b/                      },
    sub { import_err('nosuchthing') =~ /\butf8\b/                      },
    sub { import_err('nosuchthing') =~ /\bwtf8\b/                      },
    sub { import_err('nosuchthing') =~ /'nosuchthing'/                 },
    sub {1},
# 11 -- main() -e with an unknown encoding (glued form: -eXXX)
    sub { main_err('-enosuchthing', 'dummy.pl') ne ''                  },
    sub { main_err('-enosuchthing', 'dummy.pl') =~ /not supported/     },
    sub { main_err('-enosuchthing', 'dummy.pl') =~ /use one of:/       },
    sub { main_err('-enosuchthing', 'dummy.pl') =~ /'nosuchthing'/     },
    sub {1},
# 16 -- main() -e with an unknown encoding (separated form: -e XXX)
    sub { main_err('-e', 'nosuchthing', 'dummy.pl') ne ''              },
    sub { main_err('-e', 'nosuchthing', 'dummy.pl') =~ /not supported/ },
    sub { main_err('-e', 'nosuchthing', 'dummy.pl') =~ /use one of:/   },
    sub { main_err('-e', 'nosuchthing', 'dummy.pl') =~ /'nosuchthing'/ },
    sub {1},
# 21 -- the main() listing names a representative encoding from each family
    sub { main_err('-ezzz', 'dummy.pl') =~ /\bbig5hkscs\b/             },
    sub { main_err('-ezzz', 'dummy.pl') =~ /\beucjp\b/                 },
    sub { main_err('-ezzz', 'dummy.pl') =~ /\bgb18030\b/               },
    sub { main_err('-ezzz', 'dummy.pl') =~ /\bsjis\b/                  },
    sub { main_err('-ezzz', 'dummy.pl') =~ /\buhc\b/                   },
    sub {1},
# 26 -- the main() listing does NOT advertise *mb / %mb (those are import-only)
    sub { main_err('-ezzz', 'dummy.pl') !~ /\*mb/                      },
    sub { main_err('-ezzz', 'dummy.pl') !~ /%mb/                       },
    sub {1},
# 29 -- every supported token is still accepted by use mb '...' (no regression)
    sub { try_use('*mb')       =~ /ACCEPTED/ },
    sub { try_use('%mb')       =~ /ACCEPTED/ },
    sub { try_use('big5')      =~ /ACCEPTED/ },
    sub { try_use('big5hkscs') =~ /ACCEPTED/ },
    sub { try_use('eucjp')     =~ /ACCEPTED/ },
    sub { try_use('gb18030')   =~ /ACCEPTED/ },
    sub { try_use('gbk')       =~ /ACCEPTED/ },
    sub { try_use('rfc2279')   =~ /ACCEPTED/ },
    sub { try_use('sjis')      =~ /ACCEPTED/ },
    sub { try_use('uhc')       =~ /ACCEPTED/ },
    sub { try_use('utf8')      =~ /ACCEPTED/ },
    sub { try_use('wtf8')      =~ /ACCEPTED/ },
    sub {1},
# 42 -- an accepted token never emits the rejection message
    sub { try_use('utf8') !~ /not supported/ },
    sub { try_use('sjis') !~ /not supported/ },
    sub { try_use('*mb')  !~ /not supported/ },
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } for my $t (@test) { ok($t->()); }

__END__
