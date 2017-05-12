use strict;
use XML::Atom::Lifeblog;
use XML::Atom::Lifeblog::Media;

use Test::More;

unless ($ENV{LIFEBLOG_API}) {
    Test::More->import(skip_all => "LIFEBLOG_API not set");
    exit;
}

# XXX This is not testing, but for debugging :)
plan 'no_plan';

my($uri, $user, $pass) = split /\|/, $ENV{LIFEBLOG_API};

my $client = XML::Atom::Lifeblog->new();
$client->username($user);
$client->password($pass);

use LWP::Simple qw(mirror);
my $tmp = "t/me.jpg";
mirror "http://blog.bulknews.net/me.jpg" => $tmp;

my $entry = $client->postLifeblog($uri, "Hello", "This is me", $tmp);
ok $entry->link->href, $entry->link->href;

## test XML::Atom::Lifeblog::Media
$tmp = "t/me.jpg";
my $content = slurp($tmp);
open my($fh), $tmp;

my @tests = (
    { filename => $tmp }, { type => "image/jpeg", title => "me.jpg" },
    { content  => $content }, { type => "image/jpeg", title => qr/^XML::Atom.*\.jpeg/ },
    { content  => $content, type => "image/gif" }, { type => "image/gif", title => qr/^XML::Atom.*\.gif/ },
    { content  => $content, title => "foobar.jpg" }, { type => "image/jpeg", title => "foobar.jpg" },
    { filehandle => $fh }, { type => "image/jpeg", title => qr/^XML::Atom.*\.jpeg/ },
);

while (my($in, $out) = splice @tests, 0, 2) {
    my $media = XML::Atom::Lifeblog::Media->new(%$in);
    for my $test (keys %$out) {
        if (ref($out->{$test}) && ref($out->{$test}) eq 'Regexp') {
            like $media->$test(), $out->{$test}, $test;
        } else {
            is $media->$test(), $out->{$test}, $test;
        }
    }
}

sub slurp { open my $fh, shift; join '', <$fh> }

END { unlink $_ for qw(t/me.jpg t/jedi.3gp) };



