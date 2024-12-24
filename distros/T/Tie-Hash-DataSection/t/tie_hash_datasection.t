use Test2::V0 -no_srand => 1;
use Tie::Hash::DataSection;

subtest 'basic' => sub {
    tie my %tie, 'Tie::Hash::DataSection';
    is($tie{'foo.txt'}, "bar\n");
    is(exists $tie{'foo.txt'}, 1);
    is(exists $tie{'bar.txt'}, '');
    is dies { $tie{x} = 1 }, match qr/^hash is read-only/, 'exception';
    is dies { delete $tie{x} }, match qr/^hash is read-only/, 'exception';
    is [keys %tie], bag { item 'foo.txt'; item 'foo.bin'; end; };
};

subtest 'plugin' => sub {
    tie my %tie, 'Tie::Hash::DataSection', __PACKAGE__, 'trim';
    is($tie{'foo.txt'}, "bar");
};

subtest 'plugin with args' => sub {
    tie my %tie, 'Tie::Hash::DataSection', __PACKAGE__, ['trim', extensions => ['bin']];
    is($tie{'foo.txt'}, "bar\n");
    is($tie{'foo.bin'}, "bar");
};

done_testing;

__DATA__

@@ foo.txt
bar
@@ foo.bin
bar
__END__
