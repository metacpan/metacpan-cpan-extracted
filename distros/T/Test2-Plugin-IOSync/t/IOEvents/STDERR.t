use Test2::Bundle::Extended -target => 'Test2::Plugin::IOEvents::STDERR';
use File::Temp qw/tempfile/;

def ok => ($INC{'Test2/Plugin/OpenFixPerlIO.pm'}, "Loaded OpenFixPerlIO");

my ($fh, $file) = tempfile("$$-XXXXXXXX");
binmode($fh, ":via($CLASS)");
print $fh "Test2::API has been required, but has not been 'loaded' yet\n";

do_def;

my $line;
my $events = intercept {
    $line = __LINE__ + 1;
    print $fh "Foo\n";
};

close($fh);

open($fh, '<', $file) or die "$!";
is(
    [<$fh>],
    ["Test2::API has been required, but has not been 'loaded' yet\n"],
    "Output is forwarded if events are not expected yet."
);

is(
    $events,
    array {
        item event Output => sub {
            call diagnostics => T();
            call message => "Foo\n";
            call stream_name => 'STDERR';

            # Verify the context/trace
            prop file => __FILE__;
            prop line => $line;
        };
    },
    "Got the output event"
);

unlink($file);

done_testing;
