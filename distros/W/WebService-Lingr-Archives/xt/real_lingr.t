use strict;
use warnings;
use Test::More;
use WebService::Lingr::Archives;
use Encode qw(encode_utf8);
use utf8;


if(!$ENV{WS_LINGR_ARCHIVES_REAL_TEST}) {
    plan 'skip_all', "Set WS_LINGR_ARCHIVES_REAL_TEST to true to do a test with real Lingr.";
    exit 0;
}

sub show_message {
    my ($m) = @_;
    note(encode_utf8 "$m->{id} [$m->{timestamp}] $m->{nickname}: $m->{text}");
}

my $config = do "$ENV{HOME}/test_lingr_config.pl";

my $lingr = WebService::Lingr::Archives->new(
    %$config,
);

{
    note("--- latest messages");
    my @messages = $lingr->get_archives("perl_jp", {limit => 40});
    is(scalar(@messages), 40, "get 40 messages");
    foreach my $m (@messages) {
        ok(defined($m->{id}), "ID defined");
        ok(defined($m->{timestamp}), "timestamp defined");
        ok(defined($m->{text}), "text defined");
        ok(defined($m->{nickname}), "nickname defined");
        show_message $m;
    }
}

{
    note("--- with before param");
    my @messages = $lingr->get_archives("perl_jp", {limit => 1, before => 16198730 + 1});
    is(scalar(@messages), 1, "1 message");
    my $m = shift @messages;
    is($m->{id}, 16198730, "id OK");
    is($m->{text}, 'shipped 0.14', "text OK");
    show_message $m;
}

done_testing();

