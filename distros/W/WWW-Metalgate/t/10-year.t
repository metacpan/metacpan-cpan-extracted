use strict;
use warnings;
use utf8;

use Test::More tests => 9+353;

use_ok("WWW::Metalgate::Year");
my $year = WWW::Metalgate::Year->new(year=>2000);
ok($year, 'got instance');
is($year->year, 2000);
is($year->uri, "http://www.metalgate.jp/best2000.htm");
isa_ok($year->uri, "URI");

{
    my @albums = $year->best_albums;
    is(0+@albums, 10);
    my $first = {
        'album' => 'ECLIPTICA',
        'artist' => 'SONATA ARCTICA',
        'no' => 1,
        'year' => 2000,
        description => '煌く蒼いメロディがめくるめくスピードの中で乱舞する驚異のデビュー作。荒削りな部分もあるが、楽曲ひとつひとつから眩いまでの才能が感じられる、名曲満載の名盤',
    };
    #use XXX;
    #XXX @albums;
    is_deeply($albums[0], $first);
}

{
    my @tunes = $year->best_tunes;
    is(0+@tunes, 10);
    my $first = {
        artist      => "KAMELOT",
        description => "神秘的なロマンを感じさせる美しいメロディが勇壮に疾走する、完全無欠の凱歌",
        name        => "The Fourth Legacy",
        year        => 2000,
        no          => 1,
    };
    is_deeply($tunes[0], $first);
}

SKIP: {
    skip "too slow", 353 unless $ENV{"LONG_TEST"};

    use_ok("WWW::Metalgate");
    my @years = WWW::Metalgate->years;
    ok(@years > 10);

    for my $year (@years) {
        {
            my @albums = $year->best_albums;
            ok( @albums > 5 );
            for (@albums) {
                my @values  = values %$_;
                my @defined = grep { defined } @values;
                ok( @values == @defined, sprintf("%s %s", $_->{year}, $_->{album} ) );
            }
        }
        {
            my @tunes = $year->best_tunes;
            ok( @tunes > 5 );
            for (@tunes) {
                my @values  = values %$_;
                my @defined = grep { defined } @values;
                ok( @values == @defined, sprintf("%s %s", $_->{year}, $_->{name} ) );
            }
        }
    }
    ok(1, "last test");
};
