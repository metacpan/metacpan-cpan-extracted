use Test::Simple tests => 4;
use File::Temp 'tempfile';

sub ok_test
{
    my ($test, $res, $xval) = @_;
    my ($fh, $tmp) = tempfile;
    $xval ||= 0;
    print $fh $test;
    close $fh;
    my $tres = `$^X -Mblib $tmp`;
    my $ok = $tres eq $res && $? == $xval;
    ok($ok, $ok ? '' : "\n<<$tres>>\n<<$res>>\n$?\n");
    unlink $tmp;
}

ok_test(<<'EOT', <<'EOS');
use Test::Tiny tests => 5;
ok(1, 'loaded');
ok(1, 'test 1');
show('1 == "1"', 'Ayn would be proud.');
SKIP: {
    skip "whatever", 2;
}
EOT
1..5
ok 1 - loaded
ok 2 - test 1
ok 3 - 1 == "1"
ok 4 - skipped -- whatever
ok 5 - skipped -- whatever
EOS

ok_test(<<'EOT', <<'EOS');
use Test::Tiny;
ok(1, 'foo');
done_testing;
EOT
1..0
ok 1 - foo
EOS

ok_test(<<'EOT', <<'EOS', 1<<8);
use Test::Tiny tests => 1;
ok(0, 'failure');
EOT
1..1
not ok 1 - failure
# Failed at  line 
EOS

ok_test(<<'EOT', <<'EOS', 1<<8);
use Test::Tiny;
EOT
1..0
EOS
