#!perl -w

use Test::More tests => 9;
use Date::Parse;

use_ok('WWW::Topica');
use_ok('Email::Simple');


my %opts = ( 
                list       => 'bogus', 
                email      => 'something@examples.com', 
                password   => 'foo',
                local      => 1,
                debug      => 0,
                
            );

my $topica;
my @mails;
ok($topica = WWW::Topica->new(%opts), "create new topica");

while (my $mail = $topica->mail) {
	push @mails, $mail;
}
is(scalar @mails, 300, "Got 300 mails");

my $email;
my $date;
ok( $email = Email::Simple->new($mails[0]), "Created new Email::Simple");
ok( $date  = $email->header('date'), "Found date");

my $got_date      = str2time($date);
my $expected_date = str2time('Tue, 5 Mar 2002 13:42:00 +0000');


is( $email->header('subject'), 'Re: Yahoo down?', 'Got correct subject');
is( $got_date, $expected_date, 'Got correct date');
is( $email->header('from'), 'Clive Barker <light-@example.com>', 'Got correct from');


