use v5.24;
use warnings;
use fs::Promises qw(open_promise readline_promise slurp_promise);
use fs::Promises::Utils qw(await p_while);

use Test::More;
use Test::Exception;

my $does_not_exist = './does_not_exist_for_test';

throws_ok {
    open my $fh, '<', $does_not_exist or die "File does not exist";
} qr/File does not exist/, "Sanity check: open() cannot open our nonexistent file";

throws_ok {
    await open_promise($does_not_exist)->catch(sub { die "File does not exist" })
} qr/File does not exist/, "open_promise() fails in a similar way";

my $file_to_read = $0;

subtest 'readline' => sub {
    open my $sync_fh, '<', $file_to_read;
    ok($sync_fh, "open(this_file) worked");

    my $async_fh = await open_promise($file_to_read);
    ok($async_fh, "open_promise(this_file) worked");

    my $first_line_sync  = <$sync_fh>;
    my $first_line_async = await readline_promise($async_fh);
    is(
        $first_line_sync,
        $first_line_async,
        "readline() for the first line seems to work the same, trying the rest of the file"
    );

    subtest 'read rest of file' => sub {
        await(p_while { readline_promise($async_fh) } sub {
            my $async_line = shift;
            my $sync_line  = <$sync_fh>;
            is(
                $async_line,
                $sync_line,
                "readline worked",
            );
        });
    };
};

my $sync_content = do {
    open my $fh, '<', $file_to_read;
    local $/;
    scalar <$fh>;
};

subtest 'readline with $/=undef' => sub {
    my $async_content = await open_promise($file_to_read)->then(sub {
        my $fh = shift;
        local $/;
        return readline_promise($fh);
    });

    is(length($sync_content), length($async_content), "local \$/ + readline_promise() works like with <>");
};

subtest 'slurp' => sub {
    my $async_content = await slurp_promise($file_to_read);
    is(length($sync_content), length($async_content), "slurp_promise() works like \$/=undef; <>");
};

done_testing;

