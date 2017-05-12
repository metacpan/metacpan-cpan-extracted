use strict;
use Benchmark qw(cmpthese);

use Text::QueryString;
use Text::QueryString::PP;
use constant HAVE_URL_ENCODE => eval { require URL::Encode };

# Sneaky. don't do this
@Text::QueryString::PP::ISA = qw(Text::QueryString);

my $xs = Text::QueryString->new;
my $pp = Text::QueryString::PP->new;
my @query_string = (
    "foo=bar",
    "foo=bar&bar=1",
    "foo=bar;bar=1",
    "foo=bar&foo=baz",
    "foo=bar&foo=baz&bar=baz",
    "foo_only",
    "foo&bar=baz",
    "日本語=にほんご&ほげほげ=1&ふがふが",
);

cmpthese(-1, {
    xs => sub {
        foreach my $qs (@query_string) {
            my @q = $xs->parse($qs);
        }
    },
    pp => sub {
        foreach my $qs (@query_string) {
            my @q = $pp->parse($qs);
        }
    },
    HAVE_URL_ENCODE ? (
        url_encode => sub {
            foreach my $qs (@query_string) {
                my @q = URL::Encode::url_params_flat($qs);
use Data::Dumper;
warn Dumper(\@q);
            }
        },
    ) :(),
});
