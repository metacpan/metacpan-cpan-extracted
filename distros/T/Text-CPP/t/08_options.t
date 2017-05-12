use strict;
eval { require warnings; };
use Data::Dumper;
use Test::More tests => 23;
use Text::CPP qw(:all);

my ($reader, @token);
$reader = new Text::CPP(Options => {
				WarnTrigraphs	=> 1,
				WarningsAreErrors	=> 1,
					});
ok($reader, 'Created a reader');
ok($reader->read('t/options_simple.c'), 'Read a source file');
ok($reader->tokens, 'Preprocessed the file');
my $errors = $reader->errors;
ok($errors, 'Got at least one error');
my @errors = $reader->errors;
ok($errors == @errors, 'Library and Perl error counts match');
ok(length $errors[0], 'First error is nonempty');
ok($errors[0] =~ /trigraph/, 'First error mentions trigraphs');
$reader = undef;

$reader = new Text::CPP(Options => {
				-Wtrigraphs	=> 1,
				-Werror	=> 1,
					});
ok($reader, 'Created a reader using cpp-style flags');
ok($reader->read('t/options_simple.c'), 'Read a source file');
ok($reader->tokens, 'Preprocessed the file');
$errors = $reader->errors;
ok($errors, 'Got at least one error');
@errors = $reader->errors;
ok($errors == @errors, 'Library and Perl error counts match');
ok(length $errors[0], 'First error is nonempty');
ok($errors[0] =~ /trigraph/, 'First error mentions trigraphs');
$reader = undef;

$reader = new Text::CPP(Options => {
				Define	=> [ 'foo=arrFOOay', 'bar=arrBARay' ],
					});
ok($reader, 'Created a reader with array Defines');
ok($reader->read('t/options_define.c'), 'Read a source file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'arrFOOay', 'Define option works as expected');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'arrBARay', 'Multiple definitions work');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'baz', 'Nondefined tokens are OK');
$reader = undef;

$reader = new Text::CPP(Options => {
				Define	=> { foo => 'arrFOOay', bar => 'arrBARay' },
					});
ok($reader, 'Created a reader with hash Defines');
ok($reader->read('t/options_define.c'), 'Read a source file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'arrFOOay', 'Define option works as expected');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'arrBARay', 'Multiple definitions work');
$reader = undef;
