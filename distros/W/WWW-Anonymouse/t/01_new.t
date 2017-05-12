use strict;
use warnings;
use Test::More tests=>8;
use WWW::Anonymouse;

{
    my $wa = eval { WWW::Anonymous->new };
    is($wa, undef, 'attempt to instantiate virtual class');
}

{
    my $wae = WWW::Anonymouse::Email->new;
    isa_ok($wae, 'WWW::Anonymouse', 'new()');
    my $wan = WWW::Anonymouse::News->new;
    isa_ok($wan, 'WWW::Anonymouse', 'new()');
}

{
    my $wae = WWW::Anonymouse::Email->new( ua => LWP::UserAgent->new );;
    isa_ok($wae, 'WWW::Anonymouse', 'new(ua=>$ua)');
    my $wan = WWW::Anonymouse::News->new( ua => LWP::UserAgent->new );;
    isa_ok($wan, 'WWW::Anonymouse', 'new(ua=>$ua)');
}

can_ok('WWW::Anonymouse', qw( error send ) );
can_ok('WWW::Anonymouse::Email', qw( error send _url _referer ) );
can_ok('WWW::Anonymouse::News', qw( error send _url _referer) );
