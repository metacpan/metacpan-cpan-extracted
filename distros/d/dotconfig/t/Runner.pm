package t::Runner;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = 'run';
use dotconfig;
use Encode ();
use Test::More;

sub run($$) {
    my ($testcase, $expected) = @_;

    my $path = "t/testcase/$testcase.config";
    my $text = do {
        open my $fh, "<", $path or Carp::croak $!;
        my $contents = Encode::decode_utf8(do { local $/; <$fh> });
        chomp $contents;
        $contents;
    };

    my $got = eval { load_config($path) };
    if (my $e = $@) {
        fail $e;
    } else {
        is_deeply $got, $expected, Encode::encode_utf8("`$text`") or note explain {
            Got      => $got,
            expected => $expected
        };
    }
}

1;
__END__
