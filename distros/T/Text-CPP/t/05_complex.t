use strict;
eval { require warnings; };
use Test::More tests => 8;
use Text::CPP qw(:all);

my $reader = new Text::CPP(Language => CLK_GNUC99);
ok($reader, 'Created a reader');
ok($reader->read("t/complex0.c"), 'Read a source file');
my @token = $reader->token;
ok(@token == 3, 'Got a token from the reader');
ok($token[0] eq "for", 'Got the first keyword "for"');
ok($token[1] eq CPP_NAME, 'Token is of type CPP_NAME');
ok($token[2] == TF_BOL, 'Token was at the beginning of a line');
my ($text, $type, $flags) = $reader->token;
ok($text eq "(", 'Got the first keyword "for"');
ok($flags & TF_PREV_WHITE, 'Token had preceding whitespace');
