use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;
use UniEvent::Fs;

catch_run('[log-file]');

my $dir = "t/var";
my $file = "$dir/file.log";

sub test ($&) {
    my ($name, $sub) = @_;
    subtest $name => $sub;
    UniEvent::Fs::remove_all($dir);
}

test "log" => sub {
    XLog::set_logger(XLog::File->new({file => $file}));
    XLog::set_format("%m");
    XLog::set_level(XLog::DEBUG);
    
    XLog::debug("hello world");
    XLog::set_logger(undef);

    open my $fh, '<', $file or die $!;
    my $content = join '', <$fh>;
    is $content, "hello world\n";
};

test 'autoflush' => sub {
    XLog::set_logger(XLog::File->new({
        file      => $file,
        autoflush => 1,
    }));
    XLog::set_format("%m");
    XLog::set_level(XLog::DEBUG);

    XLog::debug("hello");
    
    open my $fh, '<', $file or die $!;
    my $content = join '', <$fh>;
    is $content, "hello\n";
    
    XLog::debug("world");

    open $fh, '<', $file or die $!;
    $content = join '', <$fh>;
    is $content, "hello\nworld\n";
};

done_testing();
