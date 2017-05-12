use strict;
use warnings;
use Test::Is qw/extended/;
use Test::More tests => 1;

my $builder = Test::More->builder;
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

use WWW::Pastebin::Sprunge::Create;
use WWW::Pastebin::Sprunge::Retrieve;

my $reader = WWW::Pastebin::Sprunge::Retrieve->new();
my $writer = WWW::Pastebin::Sprunge::Create->new();

SKIP: {
    skip 't/testfile is missing', 1 unless -r 't/testfile';
    my $id = $writer->paste('t/testfile', file => 1) or do {
        diag 'Got an error on ->paste(): ' . $writer->error;
        skip 'Got error', 1;
    };
    note $id;
    my $ret = $reader->retrieve($id) or do {
        diag 'Got an error on ->retrieve(): ' . $reader->error;
        skip 'Got error', 1;
    };
    open my $fh, '<:encoding(UTF-8)', 't/testfile' or die "Can't open for reading: $!";
    my $text = do { local $/; <$fh> };
    is($ret, "$text\n", 'file content pasted ok');
}
