use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    my $parsed = Wiki::JSON->new->parse(q/[[Funny Article]]/);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'Funny Article',
        }
    ], 'Simple url test';
}

{
    my $parsed = Wiki::JSON->new->parse(q/[[Funny Article|funny article]]/);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article',
        }
    ], 'Simple url test with title';
}

{
    my $parsed = Wiki::JSON->new->parse(q/This is the funny article: [[Funny Article|funny article]]. It is cool./);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'This is the funny article: ',
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article',
        },
        '. It is cool.',
    ], 'Simple url test with text wrapping it';
}

{
    my $parsed = Wiki::JSON->new->parse(q/This is the funny article: [[Funny Article|funny article<nowiki>]]<\/nowiki>]]. It is cool./);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'This is the funny article: ',
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article]]',
        },
        '. It is cool.',
    ], 'Simple url test with text wrapping it and a nowiki caption';
}
{
    my $parsed = Wiki::JSON->new->parse(q/[[Funny Article]] [[Not Funny Article]]/);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'Funny Article',
        },
        ' ',
        {
            type => 'link',
            link => 'Not Funny Article',
            title => 'Not Funny Article',
        }
    ], 'URLs spaciated between them';
}
done_testing;
