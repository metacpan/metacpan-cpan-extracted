use strict;
eval { require warnings; };
use Data::Dumper;
use Test::More tests => 13;
use Text::CPP qw(:all);

my ($reader, @token);
$reader = new Text::CPP(Options => {
				NoStandardIncludes	=> 1,
				IncludeMacros		=> [ 'imacros.h' ],
				Include				=> [ 'include.h' ],
				IncludePath			=> [ '.', './t' ],
					});
ok($reader, 'Created a reader');
ok($reader->read('t/iflags.c'), 'Read a source file');
ok(! $reader->errors, 'Reader got no errors reading file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'HeaderToken', 'First token seen is header token');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'FileToken', 'Got first token out of file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'ValOfFirstImacro', 'Expanded first imacro');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'ValFirstHeaderMacro', 'Expanded first header macro');
$reader = undef;

$reader = new Text::CPP(Options => {
				NoStandardIncludes	=> 1,
				IncludePath			=> [ '.', './t' ],
					});
ok($reader, 'Created a reader');
ok($reader->read('t/include.c'), 'Read a source file');
ok(! $reader->errors, 'Reader got no errors reading file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'HeaderToken', 'First token seen is header token');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'FileToken', 'Got first token out of file');
do { @token = $reader->token; } while($token[1] == CPP_PADDING);
ok($token[0] eq 'ValFirstHeaderMacro', 'Expanded first header macro');
$reader = undef;
