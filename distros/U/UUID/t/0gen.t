use strict;
use warnings;

# check this first.
# win32 doesnt chdir during disttest, so the
# '.git' test will fire during disttest.
# (so dont build dists on win32!)
BEGIN {
    if ( ! $ENV{UUID_DISTTEST} ) {
        if ( -e '.git' ) { print "1..0 # SKIP in repo\n"    }
        else             { print "1..0 # SKIP in release\n" }
        exit 0;
    }
}

use MyTest;
use CPAN::Meta ();
use ExtUtils::Manifest qw(maniread manicheck filecheck);
unshift @INC, 'blib/lib';
require 'UUID.pm';

plan tests => 21;

ok -e 'LICENSE',   'LICENSE exists';
ok -e 'META.json', 'META.json exists';
ok -e 'META.yml',  'META.yml exists';
ok -e 'README',    'README exists';

ok -s 'LICENSE',   'LICENSE not empty';
ok -s 'META.json', 'META.json not empty';
ok -s 'META.yml',  'META.yml not empty';
ok -s 'README',    'README not empty';

my $manifest = maniread;
ok exists($manifest->{'LICENSE'}),   'LICENSE in manifest';
ok exists($manifest->{'META.json'}), 'META.json in manifest';
ok exists($manifest->{'META.yml'}),  'META.yml in manifest';
ok exists($manifest->{'README'}),    'README in manifest';


ok test_dynamic('META.json'), 'META.json authoritative';
ok test_dynamic('META.yml'),  'META.yml authoritative';

sub test_dynamic {
    my $f = shift;
    open my $fh, '<', $f or die "open: $!";
    while (<$fh>) {
        return 1 if m/dynamic_config.*?0/;
    }
    return 0;
}


ok test_copyright('LICENSE'),     'LICENSE copyright date valid';
ok test_copyright('README'),      'README copyright date valid';
ok test_copyright('lib/UUID.pm'), 'UUID.pm copyright date valid';

sub test_copyright {
    my $f = shift;
    my $n = 1900 + (localtime(time))[5];
    open my $fh, '<', $f or die 'open: ', $f, ': ', $!;
    while (<$fh>) {
        if (/2014-(\d+)/) {
            my $end = $1;
            return 1 if $end == $n;
        }
    }
    return 0;
}


is provided_version('META.json'), $UUID::VERSION, 'META.json version';
is provided_version('META.yml'),  $UUID::VERSION, 'META.yml version';

sub provided_version {
    my $f = shift;
    my $m = CPAN::Meta->load_file($f);
    return $m->{'provides'}{'UUID'}{'version'};
}


ok manifest_complete(), 'all manifest files found';

sub manifest_complete {
    $ExtUtils::Manifest::Quiet = 1;
    my @missing = manicheck();
    my $cnt = 0;
    for my $f ( @missing ) {
        warn "\n\n" unless $cnt++;
        warn "# unfound: ", $f, "\n";
    }
    return @missing ? 0 : 1;
}


ok manifest_extras(), 'files not in manifest';

sub manifest_extras {
    my @extras =
        grep { ! m{MYMETA.json}                 }
        grep { ! m{MYMETA.yml}                  }
        grep { ! m{Makefile}                    }
        grep { ! m{UUID.bs}                     }
        grep { ! m{UUID.c}                      }
        grep { ! m{UUID.o}                      }
        grep { ! m{blib/arch/.exists}           }
        grep { ! m{blib/arch/auto/UUID/.exists} }
        grep { ! m{blib/arch/auto/UUID/UUID.so} }
        grep { ! m{blib/bin/.exists}            }
        grep { ! m{blib/lib/.exists}            }
        grep { ! m{blib/lib/auto/UUID/.exists}  }
        grep { ! m{blib/lib/UUID.pm}            }
        grep { ! m{blib/man1/.exists}           }
        grep { ! m{blib/man3/.exists}           }
        grep { ! m{blib/script/.exists}         }
        grep { ! m{ulib/EUMM.h}                 }
        grep { ! m{ulib/atomic.o}               }
        grep { ! m{ulib/chacha.o}               }
        grep { ! m{ulib/clear.o}                }
        grep { ! m{ulib/clock.o}                }
        grep { ! m{ulib/compare.o}              }
        grep { ! m{ulib/copy.o}                 }
        grep { ! m{ulib/futex.o}                }
        grep { ! m{ulib/gen.o}                  }
        grep { ! m{ulib/gettime.o}              }
        grep { ! m{ulib/hash.o}                 }
        grep { ! m{ulib/isnull.o}               }
        grep { ! m{ulib/md5.o}                  }
        grep { ! m{ulib/node.o}                 }
        grep { ! m{ulib/pack.o}                 }
        grep { ! m{ulib/parse.o}                }
        grep { ! m{ulib/sha1.o}                 }
        grep { ! m{ulib/splitmix.o}             }
        grep { ! m{ulib/sysrand.o}              }
        grep { ! m{ulib/unpack.o}               }
        grep { ! m{ulib/unparse.o}              }
        grep { ! m{ulib/util.o}                 }
        grep { ! m{ulib/xoshiro.o}              }
        grep { ! m{uu_to_blib}                  }
        filecheck()
    ;
    my $cnt = 0;
    for my $f ( @extras ) {
        warn "\n\n" unless $cnt++;
        warn "# unlisted: ", $f, "\n";
    }
    return @extras ? 0 : 1;
}

done_testing;
