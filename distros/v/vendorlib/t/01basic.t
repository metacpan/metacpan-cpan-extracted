use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';
use vendorlib;

# check that we can load core XS and non-XS modules
use Data::Dumper;
use File::Basename;
use Config;

eval "require Foo;";

ok $@, '@INC scrubbed';

# test bare tilde expansion
SKIP: {
    skip 'no tilde expansion on Win32', 1 if $^O eq 'MSWin32';

    local @INC;

    my %config = %Config;

    *vendorlib::Config = \%config;

    local $config{vendorarch} = '~/';

    vendorlib->import;

    my $expanded = (getpwuid($<))[7] . '/';

    skip 'home directory reported by getpwuid does not exist', 1 unless -d $expanded;

    shift @INC if $INC[0] eq '/etc/perl';

    is $INC[0], $expanded, 'bare tilde expansion';
}

# test tilde expansion with user name
SKIP: {
    skip 'no tilde expansion on Win32', 1 if $^O eq 'MSWin32';

    local @INC;

    my %config = %Config;

    *vendorlib::Config = \%config;

    my $whoami = (getpwuid($<))[0];

    local $config{vendorarch} = "~${whoami}/";

    vendorlib->import;

    my $expanded = (getpwuid($<))[7] . '/';

    skip 'home directory reported by getpwuid does not exist', 1 unless -d $expanded;

    shift @INC if $INC[0] eq '/etc/perl';

    is $INC[0], $expanded, 'tilde expansion with user name';
}
