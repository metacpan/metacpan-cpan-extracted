use strict;
eval { require warnings; };
use Data::Dumper;
use Test::More tests => 6;
use Text::CPP qw(:all);

my @token;
my $reader = new Text::CPP(
		Language	=> CLK_GNUC99,
		Builtins	=> {
						foo	=> 1,
						bar	=> 2,
						baz	=> '"string"',
						},
			);
ok($reader, 'Created a reader');
ok($reader->read('t/builtin0.c'), 'Read a source file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] =~ /builtin/, '__FILE__ expands to a filename');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] =~ /[0-9]/, '__LINE__ expands to a line number');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq '1', '"foo" expands to 1');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq '2', '"bar" expands to 2');
