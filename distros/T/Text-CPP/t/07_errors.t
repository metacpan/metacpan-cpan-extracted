use strict;
eval { require warnings; };
use Data::Dumper;
use Test::More tests => 10;
use Text::CPP qw(:all);

my @token;
my $reader = new Text::CPP(
		Language	=> CLK_GNUC99,
			);
ok($reader, 'Created a reader');
ok($reader->read('t/errors0.c'), 'Read a source file');
ok($reader->tokens, 'Preprocessed the file');
my $errors = $reader->errors;
ok($errors, 'Got at least one error');
my @errors = $reader->errors;
print "Got $errors errors: " . Dumper(\@errors);
ok($errors + 1 == @errors, 'Library and Perl error counts match');
ok(length $errors[0], 'First error is nonempty');
ok($errors[0] =~ /MyWarning/, 'First error is MyWarning');
ok($errors[1] =~ /MyError/, 'Second error is MyError');
ok($errors[2] =~ /MyNewError/, 'Third error is MyNewError');
ok($errors[3] =~ /invalid/, 'Fourth error is an invalid directive');
