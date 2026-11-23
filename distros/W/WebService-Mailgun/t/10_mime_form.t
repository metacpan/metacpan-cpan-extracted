use strict;
use warnings;
use Test::More 0.98;
use File::Temp;
use lib 't/lib';
use t::Form qw(mailgun fields values_of field);

my $mailgun = mailgun();

my $mime = "From: foo\@example.com\r\nTo: bar\@example.com\r\nSubject: s\r\n\r\nBody\r\n";

subtest 'a string goes as the content of a file' => sub {
    my $args = { to => 'bar@example.com', message => $mime };
    ok $mailgun->mime($args), 'returns the response';
    my $message = field('message');
    is $message->[1], $mime, 'the MIME message';
    is $message->[2], 'message.mime', 'as a file';
    is_deeply $args, { to => 'bar@example.com', message => $mime }, 'the hash reference is left as it is';
};

subtest 'the same hash reference can be passed again' => sub {
    my $args = { to => 'bar@example.com', message => \$mime };
    $mailgun->mime($args);
    $mailgun->mime($args);
    is field('message')->[1], $mime, 'the second call sends the same message';
};

subtest 'an object that turns into a string' => sub {
    {
        package t::MIME;
        use overload '""' => sub { $_[0]{mime} }, fallback => 1;
    }
    $mailgun->mime({ to => 'bar@example.com', message => bless({ mime => $mime }, 't::MIME') });
    is field('message')->[1], $mime;
};

subtest 'a file' => sub {
    my $file = File::Temp->new;
    print $file $mime;
    close $file;
    my $args = { to => 'bar@example.com', file => $file->filename };
    $mailgun->mime($args);
    is field('message')->[1], $mime, 'its content';
    ok !field('file'), 'file is not sent';
    is $args->{file}, $file->filename, 'the hash reference keeps file';
    $mailgun->mime($args);
    is field('message')->[1], $mime, 'and can be passed again';
};

subtest 'a file that is not there dies' => sub {
    eval { $mailgun->mime({ to => 'bar@example.com', file => '/no/such/file.mime' }) };
    like $@, qr/^cannot find file, \/no\/such\/file\.mime at \Q$0\E/, 'at the line of the caller';
};

subtest 'message and file together die before any request' => sub {
    t::Form::forget();
    eval { $mailgun->mime({ to => 'bar@example.com', message => $mime, file => '/tmp/x.mime' }) };
    like $@, qr/^mime\(\): give message or file, not both/;
    ok !t::Form::request(), 'nothing is requested';
};

subtest 'several recipients in an array reference' => sub {
    $mailgun->mime({ to => [ 'a@example.com', 'b@example.com' ], message => $mime });
    is_deeply values_of('to'), [ 'a@example.com', 'b@example.com' ];
};

subtest 'a decoded string is sent as UTF-8' => sub {
    $mailgun->mime({ to => 'bar@example.com', message => "Subject: \x{3042}\r\n\r\n", 'o:tag' => "\x{3044}" });
    is field('message')->[1], "Subject: \xe3\x81\x82\r\n\r\n", 'the MIME message';
    is field('o:tag')->[1], "\xe3\x81\x84", 'another key';
    my $latin1 = "Subject: caf\x{e9}\r\n\r\n";
    utf8::upgrade($latin1);
    $mailgun->mime({ to => 'bar@example.com', message => $latin1 });
    is field('message')->[1], "Subject: caf\xc3\xa9\r\n\r\n", 'below 0x100, with the UTF-8 flag';
};

subtest 'a message that is neither a string nor a reference to one dies' => sub {
    eval { $mailgun->mime({ to => 'bar@example.com', message => [$mime] }) };
    like $@, qr/^mime\(\): message must be a string or a reference to a string/;
};

done_testing;
