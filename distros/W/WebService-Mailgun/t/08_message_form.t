use strict;
use warnings;
use Test::More 0.98;
use File::Temp;
use lib 't/lib';
use t::Form qw(mailgun fields values_of field);

my $mailgun = mailgun();

subtest 'an array of values in a hash reference sends the key once for each' => sub {
    my $res = eval {
        $mailgun->message({
            from    => 'foo@example.com',
            to      => [ 'a@example.com', 'b@example.com' ],
            'o:tag' => [ 'x', 'y' ],
            text    => 'text',
        });
    };
    is $@, '', 'does not die';
    ok $res, 'returns the response';
    is_deeply values_of('to'), [ 'a@example.com', 'b@example.com' ];
    is_deeply values_of('o:tag'), [ 'x', 'y' ];
    is_deeply values_of('from'), ['foo@example.com'], 'a plain value as before';
};

subtest 'the same in an array reference of pairs' => sub {
    $mailgun->message([ from => 'foo@example.com', to => [ 'a@example.com', 'b@example.com' ], to => 'c@example.com' ]);
    is_deeply values_of('to'), [ 'a@example.com', 'b@example.com', 'c@example.com' ];
};

subtest 'attachment and inline still take an array reference as a file' => sub {
    my $file = File::Temp->new;
    print $file 'PDF';
    close $file;
    $mailgun->message([
        from       => 'foo@example.com',
        to         => 'a@example.com',
        attachment => [ $file->filename, 'a.pdf' ],
        inline     => [ $file->filename, 'b.png' ],
    ]);
    is field('attachment')->[2], 'a.pdf', 'attachment is a file';
    is field('attachment')->[1], 'PDF', 'with its content';
    is field('inline')->[2], 'b.png', 'inline is a file';
};

subtest 'several files in a hash reference' => sub {
    my $file = File::Temp->new;
    print $file 'PDF';
    close $file;
    $mailgun->message({
        from       => 'foo@example.com',
        to         => 'a@example.com',
        attachment => [ [ $file->filename, 'a.pdf' ], [ $file->filename, 'b.pdf' ] ],
    });
    is_deeply [ map { $_->[2] } grep { $_->[0] eq 'attachment' } fields() ], [ 'a.pdf', 'b.pdf' ];
};

subtest 'an empty array reference dies before any request' => sub {
    t::Form::forget();
    eval { $mailgun->message({ from => 'foo@example.com', to => [], text => 'text' }) };
    like $@, qr/^message\(\): 'to' is an empty array reference/;
    ok !t::Form::request(), 'nothing is requested';
};

subtest 'a decoded string is sent as UTF-8' => sub {
    my $latin1 = "caf\x{e9}";
    utf8::upgrade($latin1);
    $mailgun->message({
        from    => 'foo@example.com',
        to      => 'a@example.com',
        subject => "\x{3042}",
        text    => $latin1,
        'o:tag' => [ "\x{3044}" ],
    });
    is field('subject')->[1], "\xe3\x81\x82", 'above 0xFF';
    is field('text')->[1], "caf\xc3\xa9", 'below 0x100, with the UTF-8 flag';
    is field('o:tag')->[1], "\xe3\x81\x84", 'in an array reference';
};

subtest 'a string of bytes is sent as it is' => sub {
    $mailgun->message({ from => 'foo@example.com', to => 'a@example.com', text => "caf\xc3\xa9" });
    is field('text')->[1], "caf\xc3\xa9";
};

done_testing;
