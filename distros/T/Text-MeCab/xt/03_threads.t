use strict;
use utf8;
use Test::More;
use Encode;
use Test::Requires 'threads';
use_ok "Text::MeCab";

my $x = Text::MeCab->new; 
my $node = $x->parse( encode( &Text::MeCab::ENCODING, "あぁ、酒が飲みたい飲みたい。そんな日もあるよね。あはは" ) );
my @threads;

{ 
    note( "before thread spawning" );
    foreach(my $n = $node; $n; $n = $n->next) {
        note("node = " . encode_utf8( decode( &Text::MeCab::ENCODING, $n->surface) ) );
    }
}

for (1..5) {
    push @threads, threads->create(sub{
        note( "spawned thread : " . threads->tid() );
        foreach(my $n = $node; $n; $n = $n->next) {
            if ( defined $n->surface ) {
                note("node = " . encode_utf8( decode( &Text::MeCab::ENCODING, $n->surface) ) );
            }
        }
    });
}

foreach my $thr (@threads) {
    note( "joining thread : " . $thr->tid );
    $thr->join;
}

ok(1);
done_testing();