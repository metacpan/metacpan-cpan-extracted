use strict;
use warnings;
use Test::More;
use CPAN::Meta ();
use ExtUtils::Manifest qw(maniread manicheck filecheck);
use lib 'blib/lib';
require 'UUID.pm';

# check this first.
# win32 doesnt chdir during disttest, so the
# '.git' test will fire during disttest.
if ( $ENV{UUID_DISTTEST} ) {
    plan tests => 21;
}
elsif ( -e '.git' ) {
    plan skip_all => 'in repo';
}
else {
    plan skip_all => 'in release';
}

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


ok test_copyright('LICENSE'), 'LICENSE copyright date valid';
ok test_copyright('README'),  'README copyright date valid';
ok test_copyright('UUID.pm'), 'UUID.pm copyright date valid';

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
        grep { ! m{EUMM.h$}                     }
        grep { ! m{UUID.bs$}                    }
        grep { ! m{UUID.c$}                     }
        grep { ! m{UUID.o$}                     }
        grep { ! m{clear.o$}                    }
        grep { ! m{compare.o$}                  }
        grep { ! m{config.h$}                   }
        grep { ! m{copy.o$}                     }
        grep { ! m{dirpaths.h$}                 }
        grep { ! m{gen_uuid.o$}                 }
        grep { ! m{isnull.o$}                   }
        grep { ! m{pack.o$}                     }
        grep { ! m{parse.o$}                    }
        grep { ! m{ulib\/uuid\/gen_uuid.c$}     }
        grep { ! m{unpack.o$}                   }
        grep { ! m{unparse.o$}                  }
        grep { ! m{uuid_time.o$}                }
        grep { ! m{uuid.h$}                     }
        grep { ! m{uuid_types.h$}               }
        grep { ! m{\.exists$}                   }
        grep { ! m{ulib/.patch$}                }
        grep { ! m{ulib/uuid/clear.c$}          }
        grep { ! m{ulib/uuid/compare.c$}        }
        grep { ! m{ulib/uuid/copy.c$}           }
        grep { ! m{ulib/uuid/gen_uuid_nt.c$}    }
        grep { ! m{ulib/uuid/isnull.c$}         }
        grep { ! m{ulib/uuid/pack.c$}           }
        grep { ! m{ulib/uuid/parse.c$}          }
        grep { ! m{ulib/uuid/tst_uuid.c$}       }
        grep { ! m{ulib/uuid/unpack.c$}         }
        grep { ! m{ulib/uuid/unparse.c$}        }
        grep { ! m{ulib/uuid/uuid.h.new$}       }
        grep { ! m{ulib/uuid/uuid_time.c$}      }
        grep { ! m{ulib/uuid/uuidd.h$}          }
        grep { ! m{ulib/uuid/uuidP.h$}          }
        grep { ! m{usrcP/.patch$}               }
        grep { ! m{usrcP/config.h.in$}          }
        grep { ! m{usrcP/dirpaths.h.in$}        }
        grep { ! m{usrcP/uuid/clear.c$}         }
        grep { ! m{usrcP/uuid/compare.c$}       }
        grep { ! m{usrcP/uuid/copy.c$}          }
        grep { ! m{usrcP/uuid/gen_uuid.c$}      }
        grep { ! m{usrcP/uuid/gen_uuid_nt.c$}   }
        grep { ! m{usrcP/uuid/isnull.c$}        }
        grep { ! m{usrcP/uuid/pack.c$}          }
        grep { ! m{usrcP/uuid/parse.c$}         }
        grep { ! m{usrcP/uuid/tst_uuid.c$}      }
        grep { ! m{usrcP/uuid/unpack.c$}        }
        grep { ! m{usrcP/uuid/unparse.c$}       }
        grep { ! m{usrcP/uuid/uuid.h.in$}       }
        grep { ! m{usrcP/uuid/uuid_time.c$}     }
        grep { ! m{usrcP/uuid/uuid_types.h.in$} }
        grep { ! m{usrcP/uuid/uuidd.h$}         }
        grep { ! m{usrcP/uuid/uuidP.h$}         }
        filecheck()
    ;
    my $cnt = 0;
    for my $f ( @extras ) {
        warn "\n\n" unless $cnt++;
        warn "# unlisted: ", $f, "\n";
    }
    return @extras ? 0 : 1;
}

exit 0;
