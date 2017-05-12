#!/use/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;

BEGIN {
  use_ok('PerlTidy::Options');
}

require_ok('PerlTidy::Options');

can_ok('PerlTidy::Options', qw(getSections
			       getEntries
			       getValueType
			       getType
			      ));

use Log::Log4perl qw(:levels get_logger);

Log::Log4perl->init_and_watch('bin/log.conf', 10);

my $logger = get_logger((caller(0))[3]);

## TODO - just get one small section working as generically as possible, then re-enable the others

is_deeply([PerlTidy::Options->getSections()],
	  [
	   '1. Basic formatting options',
 	   '2. Code indentation control',
	   '3. Whitespace control',
	   '4. Comment controls',
	   '5. Linebreak controls',
	   '6. Controlling list formatting',
	   '7. Retaining or ignoring existing line breaks',
	   '8. Blank line control',
	   '9. Other controls',
	   '10. HTML options',
	   '11. pod2html options',
	   '12. Controlling HTML properties',
 	  ],
	  'required sections',
);

is(PerlTidy::Options->getSection(), undef, 'no name, no section');

is(PerlTidy::Options->getSection(name => ''), undef, 'name, empty value, no section');

is(PerlTidy::Options->getSection(name => 'No Such Section'), undef, 'name, wrong value, no section');

is(PerlTidy::Options->getSection(name => 'add-newlines'), '5. Linebreak controls', 'name, value, section');

is_deeply([PerlTidy::Options->getEntries(section => '1. Basic formatting options')],
	  [
	   'indent-columns',
	   'check-syntax',
	   'maximum-line-length',
	   'perl-syntax-check-flags',
	  ],
	  'required entries',
);

is(PerlTidy::Options->getValueType(
				   section => '5. Linebreak controls',
				   entry   => 'opening-brace-always-on-right',
				  ), '!', "bug reported by Steve 02072006");

is(PerlTidy::Options->getValueType(
				   section => '5. Linebreak controls',
				   entry   => 'add-newlines',
				  ), '!', "coverage of bug fix");

is(PerlTidy::Options->getValueType(
				   section     => '5. Linebreak controls',
				   entry       => 'opening-brace-always-on-right',
				   asReference => 0,
				  ), '!', "coverage of bug fix");

isa_ok(PerlTidy::Options->getValueType(
				   section     => '2. Code indentation control',
				   entry       => 'closing-brace-indentation',
				   asReference => 1,
				  ), 'ARRAY'); # coverage of bug fix

is(PerlTidy::Options->getValueType(
				   section     => '2. Code indentation control',
				   entry       => 'closing-brace-indentation',
				   asReference => 0,
				  ), 'ARRAY', 'coverage of bug fix');

is(PerlTidy::Options->getDefaultValue(), undef, 'no entry, no default');

is(PerlTidy::Options->getDefaultValue(entry => ''), undef, 'entry, no value, no default');

is(PerlTidy::Options->getDefaultValue(entry => 'no such entry'), undef, 'entry, wrong value, no default');

is(PerlTidy::Options->getDefaultValue(entry => 'add-newlines'), '1', 'integer default value');

is(PerlTidy::Options->getDefaultValue(entry => 'indent-columns'), '4', 'integer default value');

is(PerlTidy::Options->getDefaultValue(entry => 'perl-syntax-check-flags'), '-c -T', 'string default value');

# test get default for range entries

# test for any platform

is(PerlTidy::Options->getDefaultValue(entry => 'output-line-ending'),
   ($^O =~ m/(?:dos)/i  ) ? 'dos' :
   ($^O =~ m/(?:win32)/i) ? 'win' :
   ($^O eq 'MacOS'      ) ? 'mac' : 'unix',
   'test platform default line ending');

# test specific platforms

{
  local $^O = 'dos';

  is(PerlTidy::Options->getDefaultValue(entry => 'output-line-ending'), 'dos', 'fake a dos platform');

  $^O = 'win32';

  is(PerlTidy::Options->getDefaultValue(entry => 'output-line-ending'), 'win', 'fake a win platform');

  $^O = 'MacOS';

  is(PerlTidy::Options->getDefaultValue(entry => 'output-line-ending'), 'mac', 'fake a mac platform');

  $^O = 'Linux';

  is(PerlTidy::Options->getDefaultValue(entry => 'output-line-ending'), 'unix', 'fake a unix platform');
}

is(PerlTidy::Options->getDefaultValue(entry => 'closing-token-indentation'), 0, 'default token indentation');

# test getType

# get one of each type and a fail

is(PerlTidy::Options->getType(entry => 'check-syntax'), '!', 'checkbox');

is(PerlTidy::Options->getType(entry => 'opening-brace-always-on-right'), '!', 'checkbox');

is(PerlTidy::Options->getType(entry => 'indent-columns'), '=i', 'integer');

is(PerlTidy::Options->getType(entry => 'perl-syntax-check-flags'), '=s', 'string');



