use strict;
use Test::More;
use ExtUtils::Manifest qw( maniread );

my $manifest = maniread();
my @files = grep m{^lib/.*\.p(od|m)$}, keys %$manifest;

my $i = 0;
for my $file (@files) {
    my($code, $line, @option) = extract_synopsis($file);
    unless ($code) {
        ok( 1, "No SYNOPSIS code" );
        next;
    }

    my $option = join(";", @option);
    my $test   = <<"TEST";
package
    Test::Synopsis::Sandbox$i;
use Test::More;
#line $line "$file"
$option;
ok 1, "$file";
$code;
done_testing;
TEST

    subtest $file => sub {
        eval($test);
        if($@) {
            if($@ =~ /Can't locate/) { # ' for poor editors
                pass "skipped: $@";
            }
            else {
                fail($@);
            }
            done_testing;
        }
    };
    $i++;
}

done_testing;

sub _compile {
    package
        Test::Synopsis::Sandbox;
    eval $_[0];    ## no critic
}

sub extract_synopsis {
    my $file = shift;

    my $content = do {
        local $/;
        open my $fh, "<", $file or die "$file: $!";
        <$fh>;
    };

    my $code = ( $content =~ m/^=head1\s+SYNOPSIS(.+?)^=head1/ms )[0];
    my $line = ( $` || '' ) =~ tr/\n/\n/;

    return $code, $line - 1,
      ( $content =~ m/^=for\s+test_synopsis\s+(.+?)^=/msg );
}

