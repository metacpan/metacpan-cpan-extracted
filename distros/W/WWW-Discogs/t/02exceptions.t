#!perl
use strict;
use warnings;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use FindBin qw( $Bin );
use File::Slurp qw( read_file );

use Test::More tests => 33;
use Test::Exception;

BEGIN {
    use_ok 'WWW::Discogs';
    use_ok 'WWW::Discogs::HasMedia';
    use_ok 'WWW::Discogs::ReleaseBase';
}

my $rt = read_file("$Bin/../requests/error.res");
my $response = HTTP::Response->parse($rt);
$mock_ua->map('http://api.discogs.com/label/1foobar2', $response);

my $client = new_ok('WWW::Discogs' => [], '$client');
dies_ok { $client->label(name => '1foobar2') } 'error response';

dies_ok { WWW::Discogs::HasMedia->new } 'new WWW::Discogs::HasMedia';
dies_ok { WWW::Discogs::ReleaseBase->new } 'new WWW::Discogs::ReleaseBase';

my @methods = qw( artist release master label search );
my %hash = ( foo => 1, bar => 2 );
for (@methods) {
    dies_ok { $client->$_(\%hash) } "hash ref as arg";
}

for (@methods) {
    dies_ok { $client->$_  } "no args for $_";
}

for(@methods) {
    next if $_ eq 'search';
    dies_ok { $client->$_(foo => 1) } "missing req args for $_";
}

dies_ok { $client->search(foo => 'bar') } 'missing req args for search';
dies_ok { $client->search('q' => '') } 'search query empty';
dies_ok { $client->search('q' => '  ') } 'search query empty';
dies_ok { $client->search('q' => "\n\t\r\f") } 'search query empty';

for (qw/ master release /) {
    dies_ok { $client->$_(id => 'abc') } 'id not a number';
    dies_ok { $client->$_(id => '   ') } 'id not a number';
}

for (qw/ artist label /) {
    dies_ok { $client->$_(name => '  ') } 'name empty';
    dies_ok { $client->$_(name => '') } 'name empty';
}
