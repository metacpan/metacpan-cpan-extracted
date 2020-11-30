use 5.12.0;
use warnings;
use UniEvent;

my $victim = $ARGV[0] // '127.0.0.1';
my $port   = $ARGV[1] // 80;

my $client = UE::Tcp->new;
my $loop = UE::Loop->default_loop;
$client->connect($victim, $port, sub {
    my ($client, $error_code) = @_;
    die("cannot connect: $error_code\n") if $error_code;
    $loop->stop;
});

$loop->run;
say "connected";

my $input    = UE::Streamer::FileInput->new(__FILE__);
my $output   = UE::Streamer::StreamOutput->new($client);
my $streamer = UE::Streamer->new($input, $output);

$streamer->start();
$streamer->finish_callback(sub { $loop->stop; });

$loop->run;

say "done";
