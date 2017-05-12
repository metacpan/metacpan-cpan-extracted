=pod

Test the C<mod> or C<modifiers> method

=cut

use strict;
use Test::More tests => 25;

my @tests = (
    sub { cmp_ok shift, 'eq', '', => 'no flags' },
    sub { cmp_ok shift, 'eq', '', => '/c' },
    sub { cmp_ok shift, 'eq', '' => '/g' },
    sub { cmp_ok shift, 'eq', 'i' => '/i' },
    sub { cmp_ok shift, 'eq', 'm' => '/m' },
    sub { cmp_ok shift, 'eq', ''  => '/o' },
    sub { cmp_ok shift, 'eq', 's' => '/s' },
    sub { cmp_ok shift, 'eq', 'x' => '/x' },
    sub { cmp_ok shift, 'eq', 'p' => '/p' },
    sub { like $_[0], qr/$_/ => "/$_ in $_[0]" for unpack "(Z)*", "xi" },
    sub { like $_[0], qr/$_/ => "/$_ in $_[0]" for unpack "(Z)*", "xs" },
    sub {
        for (unpack "(Z)*", "cgimsxp") {
            /[cg]/ and next;
            like $_[0], qr/$_/ => "/$_ in $_[0]"
        }
    },
    sub { cmp_ok shift, 'eq', '', => '/e' },
    sub {
        for (unpack "(Z)*", "egimsxp") {
            /[ge]/ and next;
            like $_[0], qr/$_/ => "/$_ in $_[0]";
        }
    },

    sub { cmp_ok shift, 'eq', ''  => '??' },
    # Leave this as the last
    ,sub { die "add more tests" }
);

use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;

        my $t = shift @tests;

        my %mod = $re->mod;

        my $mod_str = join '', keys %mod;

        $t->($mod_str);
    }
);

# Provide a pattern that can match to avoid running into regexp
# optimizations that won't call exec on C<"" =~ //>;

"" =~ /x/;
"" =~ /x/cg; # meaningless without /g
"" =~ /x/g;
"" =~ /x/i;
"" =~ /x/m;
"" =~ /x/o;
"" =~ /x/s;
"" =~ /x/x;
"" =~ /x/p;
"" =~ /x/xi;
"" =~ /x/xs;
"" =~ /x/cgimosxp;

local $_ = "";

$_ =~ s/1/2/e;
$_ =~ s/1/2/egimosxp;
$_ =~ m??;
