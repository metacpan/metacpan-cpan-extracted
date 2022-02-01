# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 02-core.t".
#
# Without 'Build' file it could be called with "perl -I../lib 02-core.t" or
# "perl -Ilib t/02-core.t".  This is also the command needed to find out
# what specific tests failed in a "./Build test" as the later only gives you
# a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More tests => 94;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], log => 'WARNING'}); # testing the alias here

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/sub_perl.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_msg_tail_core = qr/ at .*lib\/UI\/Various\/core.pm line \d{2,}\.?$/;

#####################################
# language tests (+lookup of texts):
$_ = UI::Various::language();
is($_, 'en', 'found initial language');

warning_like
{   $_ = UI::Various::language('XX');   }
{   carped => qr/^unsupported language 'XX'$re_msg_tail/   },
    'unsupported language creates error';
is($_, 'en', 'language unchanged for unsupported language');

$_ = UI::Various::core::msg('unknown_option__1');
is($_, "unknown option '%s'", 'found correct English test message');

$_ = UI::Various::language('de');
is($_, 'de', 'can change language');

$_ = UI::Various::core::msg('unknown_option__1');
is($_, "unbekannte Option '%s'", 'found correct German test message');

warning_like
{   $_ = UI::Various::core::msg('zz_unit_test');   }
{   carped => qr/^text 'zz_unit_test' fehlt in 'de'$re_msg_tail/   },
    'missing message creates warning';

warnings_like
{   $_ = UI::Various::core::msg('zz_not_existing');   }
    [ { carped => qr/^text 'zz_not_existing' fehlt in 'de'$re_msg_tail/ },
      { carped => qr/^text 'zz_not_existing' fehlt in 'en'$re_msg_tail/ } ],
    'missing message creates errors';
# Note that an error is identical to a warning, except for the level.

$_ = UI::Various::language('en');
is($_, 'en', 'can change back language');

warning_like
{   $_ = UI::Various::core::msg('zz_not_existing');   }
{   carped => qr/^message 'zz_not_existing' missing in 'en'$re_msg_tail/   },
    "missing message in 'en' creates error";

warning_like
{   $_ = UI::Various::core::msg('zz_unit_test_empty');   }
{   carped => qr/^message 'zz_unit_test_empty' missing in 'en'$re_msg_tail/   },
    "empty message in 'en' creates error";

#####################################
# logging tests:
$_ = UI::Various::logging();
is($_, 'WARN', 'found initial logging');

warning_like
{   $_ = UI::Various::logging('NOT');   }
{   carped => qr/^undefined logging level 'NOT'$re_msg_tail/   },
    'undefined logging level creates error';
is($_, 'WARN', 'logging unchanged for unsupported logging level');

$_ = UI::Various::logging('FATAL');
is($_, 'FATAL', 'can change logging level to FATAL');

warning_like
{   $_ = UI::Various::language('XX');   }
    undef,
    'unsupported language creates NO error in FATAL logging level';

warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    undef,
    'info is suppressed in FATAL logging level';

$_ = UI::Various::logging('ERROR');
is($_, 'ERROR', 'can change logging level to ERROR');
warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    undef,
    'info is suppressed in ERROR logging level';

$_ = UI::Various::logging('WARN');
is($_, 'WARN', 'can change logging level to WARN');
warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    undef,
    'info is suppressed in WARN logging level';

$_ = UI::Various::logging('INFO');
is($_, 'INFO', 'can change logging level to INFO');
warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    qr/^using 'Something' as UI$/,
    'info is not suppressed in INFO logging level';
warnings_like
{   UI::Various::core::info('zz_not_existing');   }
    [ { carped => qr/^message 'zz_not_existing' missing in 'en'$re_msg_tail/ },
      qr|^zz_not_existing at .*/UI/Various/core.pm line \d{3}\.$|],
    'missing message creates error and is reported as key';
warning_like
{   UI::Various::core::error('invalid_selection');   }
    qr/^invalid selection$/,
    'error message with new-line does not use carp';

warning_like
{   UI::Various::core::debug(1, 'debug-1');   }
    undef,
    'debug-1 is suppressed in INFO logging level';
warning_like
{   UI::Various::core::debug(2, 'debug-2');   }
    undef,
    'debug-2 is suppressed in INFO logging level';

$_ = UI::Various::logging('DEBUG_1');
is($_, 'DEBUG_1', 'can change logging level to DEBUG_1');
warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    qr/^using 'Something' as UI$/,
    'info is not suppressed in DEBUG_1 logging level';
warning_like
{   UI::Various::core::debug(1, 'debug-1');   }
    qr/^DEBUG\tdebug-1$/,
    'debug-1 is not suppressed in DEBUG_1 logging level';
warning_like
{   UI::Various::core::debug(2, 'debug-2');   }
    undef,
    'debug-2 is suppressed in DEBUG_1 logging level';

$_ = UI::Various::logging('DEBUG_2');
is($_, 'DEBUG_2', 'can change logging level to DEBUG_2');
warning_like
{   UI::Various::core::info('using__1_as_ui', 'Something');   }
    qr/^using 'Something' as UI$/,
    'info is not suppressed in DEBUG_2 logging level';
warning_like
{   UI::Various::core::debug(1, 'debug-1');   }
    qr/^DEBUG\tdebug-1$/,
    'debug-1 is not suppressed in DEBUG_2 logging level';
warning_like
{   UI::Various::core::debug(2, 'debug-2');   }
    qr/^DEBUG\t  debug-2$/,
    'debug-2 is indented and not suppressed in DEBUG_2 logging level';
warning_like
{   UI::Various::core::debug('x', 'invalid');   }
{   carped => qr/^bad debug-level 'x'$re_msg_tail/   },
    'invalid debug level causes error';
warning_like
{   UI::Various::core::debug(0, 'invalid');   }
{   carped => qr/^bad debug-level '0'$re_msg_tail/   },
    'debug level 0 causes error';

# TODO: Do we need to go back to WARN?

#####################################
# output tests:
$_ = UI::Various::stderr();
is($_, 0, 'found initial STDERR configuration');

warning_like
{   $_ = UI::Various::stderr(9);   }
{   carped => qr/^stderr not 0, 1, 2 or 3$re_msg_tail/   },
    'bad value for stderr causes error';

# Testing the various redirections is not possible with Test::Warn as that
# catches the output with a signal handler above our file-handler.  So we
# use sub-processes with minimal test scripts on the command line to work
# around that:
my $re_msg_tail_sp = qr/\sat\s-e\sline\s\d+\.?$/m;

$_ = _sub_perl(	<<'CODE');
		use UI::Various({log => "WARN", stderr => 3});
		UI::Various::core::error("zz_unit_test_text");
		$_ = UI::Various::stderr(0);
		$_ == 0  or  die "bad RC $0\n";
		$_ = UI::Various::stderr(3);
CODE
is($?, 0, 'RC 0 in sub-perl "switching off STDERR"');
is($_, '', 'switching off STDERR suppressed errors');

$_ = _sub_perl(	<<'CODE');
		use UI::Various({log => "WARN", stderr => 2});
		UI::Various::core::error("zz_unit_test_text");
		print "before stderr(0)\n";
		$_ = UI::Various::stderr(0);
		print STDERR "after stderr(0)\n"; # STDERR avoids race condition
CODE
is($?, 0, 'RC 0 in sub-perl "postponing STDERR"');
like($_,
     qr{^before\sstderr\(0\)\n
	dummy\stext$re_msg_tail_sp\n
	after\sstderr\(0\)\n}mx,
     'postponing STDERR printed correct output');

$_ = _sub_perl(	<<'CODE');
		use UI::Various({log => "WARN", stderr => 2});
		UI::Various::core::error("zz_unit_test_text");
		$_ = UI::Various::stderr(3);
CODE
is($?, 0, 'RC 0 in sub-perl "postponing/dropping STDERR"');
is($_, '', 'postponing/dropping STDERR printed correct output');

SKIP:
{
    skip 'closing STDERR not working in Perl <= 5.22', 2 if $^V lt 'v5.24';
    $_ = _sub_perl(	<<'CODE');
		use UI::Various({log => "WARN"});
		close STDERR;
		defined fileno(STDERR)  and
		    print "STDERR still defined (", fileno(STDERR), ")\n";
		$_ = UI::Various::stderr(2);
		print "We should not get here! ($_, ", fileno(STDERR), ")\n";
CODE
    is($?, 0x900, 'RC 9 (no signal or core-dump) in sub-perl "closed STDERR"');
    like($_,
	 qr{\n\*{5} can't duplicate STDERR: Bad file (descriptor|number) \*+\n},
	 'closed STDERR causes error');
}

#####################################
# constructor and accessor tests:
package Broken1
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub new($;\[@$])
    {	return construct([ attr => 1 ], '^attr$', @_);   }
};
package Broken2
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub new($;\[@$])
    {	return construct({ attr => 1 }, [], @_);   }
};
package UI::Various::PoorTerm::Class1
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr($)
    {   return access('attr', undef, @_);   }
    sub new($;\[@$])
    {	return construct({ attr => 1 }, '^attr$', @_);   }
};
package UI::Various::PoorTerm::Class2
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr1($)		# "public" getter
    {   return get('attr1', @_);   }
    sub _attr1($$)		# "private" setter
    {   return set('attr1', undef, @_);   }
    sub new($;\[@$])
    {	return construct({ attr1 => 1, attr2 => 2 }, '^attr[12]$', @_);   }
};

eval {   $_ = Broken1->new();   };
like($@,
     qr/^invalid parameter '\$attributes' in call to .*$re_msg_tail/,
    "bad 'attributes' parameter causes error");

eval {   $_ = Broken2->new();   };
like($@,
     qr/^invalid parameter '\$re_allowed_parameters' in call to .*$re_msg_tail/,
    "bad 'allowed  parameters' causes error");

eval {   $_ = UI::Various::PoorTerm::Class1::new(undef);   };
like($@,
     qr/^Can't call method "isa" on an undefined value$re_msg_tail_core/,
    'undefined constructor call causes error');

eval {   $_ = UI::Various::PoorTerm::Class1::new('Broken1');   };
like($@,
     qr/^invalid object \(\) in call to .*::Class1::new$re_msg_tail/,
    'bad constructor call causes error');

eval {   $_ = UI::Various::PoorTerm::Class1->new([]);   };
like($@,
     qr/^invalid object \(ARRAY\) in call to .*::Class1::new$re_msg_tail/,
    'bad attributes parameter in constructor call causes error');

eval {   $_ = UI::Various::PoorTerm::Class1->new(1);   };
like($@,
     qr/^invalid scalar '1' in call to .*::Class1::new$re_msg_tail/,
    'wrong attributes parameter in constructor call causes error');

eval {   $_ = UI::Various::PoorTerm::Class2->new(attr1 => 1, 2);   };
like($@,
     qr/^odd number of parameters in init.* list of .*::Class2::new$re_msg_tail/,
    'bad attribute list in constructor call causes error');

eval {   $_ = UI::Various::PoorTerm::Class1->new(attr1 => 1);   };
like($@,
     qr/^invalid parameter 'attr1' in call to .*::Class1::new$re_msg_tail/,
    'invalid attribute in constructor call causes error');

$_ = UI::Various::PoorTerm::Class1->new();
ok(defined $_, 'simple construction is OK');
is($_->attr(), 1, 'default value correctly constructed');

$_ = $_->new();
ok(defined $_, 'construction from other object OK');

$_ = UI::Various::PoorTerm::Class1->new(attr => 42);
ok(defined $_, 'construction with attribute is OK');
is($_->attr(), 42, 'constructed value is correct');

$_ = UI::Various::PoorTerm::Class1->new({attr => 47});
ok(defined $_, 'construction with hashed attribute is OK');
is($_->attr(), 47, 'constructed value from HASH is correct');

$_ = UI::Various::PoorTerm::Class2->new(attr1 => 42);
ok(defined $_, 'construction using separate setter is OK');
is($_->attr1(), 42, 'value of separate getter is correct');

$_ = UI::Various::PoorTerm::Class2->new(attr2 => 42);
ok(defined $_, 'construction using simple assignment is OK');
is($_->{attr2}, 42, 'value of simple assignment is correct');

#####################################
# other accessor tests:
package UI::Various::PoorTerm::Broken3
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr($)
    {   return access('attr', 1, @_);   }
    sub new($;\[@$])
    {	return construct({ attr => 1 }, '^attr$', @_);   }
};
package UI::Various::PoorTerm::Broken4
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub _attr($$)		# 'private' setter
    {   return set('attr', 1, @_);   }
    sub new($;\[@$])
    {	return construct({ attr => 1 }, '^attr$', @_);   }
};
package UI::Various::PoorTerm::Class3
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr($)
    {   return access('attr', sub{ $_ *= 2; return $_ < 0 ? undef : 1; }, @_);  }
    sub new($;\[@$])
    {	return construct({ attr => 1 }, '^attr$', @_);   }
};
package UI::Various::PoorTerm::Class4
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr1($)		# 'public' getter
    {   return get('attr1', @_);   }
    sub _attr1($$)		# 'private' setter
    {   return set('attr1', sub{ $_ *= 2; return $_ < 0 ? undef : 1; }, @_);   }
    sub new($;\[@$])
    {	return construct({ attr1 => 1, attr2 => 2 }, '^attr[12]$', @_);   }
};

eval {   UI::Various::PoorTerm::Class1::attr('Broken1');   };
like($@,
     qr/^invalid object \(\) in call to .*::Class1::attr$re_msg_tail/,
    'bad accessor call causes error');

eval {   $_ = UI::Various::PoorTerm::Broken3->new(); $_->attr(2);   };
like($@,
     qr/^invalid parameter '\$sub_set' in call to .*::Broken3::attr$re_msg_tail/,
    'bad subroutine in accessor causes error');

eval {   UI::Various::PoorTerm::Class2::_attr1('Broken1', 1);   };
like($@,
     qr/^invalid object \(\) in call to .*::Class2::_attr1$re_msg_tail/,
    'bad setter call causes error');

eval {   UI::Various::PoorTerm::Class2::attr1('Broken1');   };
like($@,
     qr/^invalid object \(\) in call to .*::Class2::attr1$re_msg_tail/,
    'bad getter call causes error');

eval {   $_ = UI::Various::PoorTerm::Broken4->new(); $_->_attr(2);   };
like($@,
     qr/^invalid parameter '\$sub_set' in call to .*Broken4::_attr$re_msg_tail/,
    'bad subroutine in setter causes error');

$_ = UI::Various::PoorTerm::Class3->new();
is($_->attr(21), 42, 'subroutine in accessor is correct');
is($_->attr(-1), 42, 'subroutine in accessor ignores bad value correctly');

my $var = 21;
is($_->attr(\$var), 42, 'variable reference in accessor is set correctly');
is($_->attr(), 42, 'variable reference in accessor is returned correctly');
$var = 47;
is($_->attr(), 47, 'referenced variable can be changed correctly');

$_ = UI::Various::PoorTerm::Class4->new();
is($_->_attr1(21), 42, 'subroutine in setter is correct');
is($_->attr1(), 42, 'subroutine in setter was correct');
is($_->_attr1(-1), 42, 'subroutine in setter ignores bad value correctly');
is($_->attr1(), 42, 'subroutine in setter ignored bad value correctly');

is($_->_attr1(\$var), 94, 'variable reference in setter is set correctly');
is($_->attr1(), 94, 'variable reference in getter is returned correctly');
$var = 42;
is($_->attr1(), 42, 'referenced variable can be changed correctly');

#####################################
# specific variable reference tests:

my $ref1 = UI::Various::core::dummy_varref();
my $ref2 = UI::Various::core::dummy_varref();
is($$ref1, '', 'dummy reference 1 is empty');
is($$ref2, '', 'dummy reference 2 is empty');
isnt($ref1, $ref2, 'dummy references differ');
$$ref1 = 42;
$$ref2 = 47;
is($$ref1, 42, 'dummy reference 1 is now 42');
is($$ref2, 47, 'dummy reference 2 is now 47');

package UI::Various::PoorTerm::Class5
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr($)
    {   return access_varref('attr', @_);  }
    sub new($;\[@$])
    {	return construct({ attr => dummy_varref() }, '^attr$', @_);   }
    sub _reference($$) {}	# dummy for code coverage
};
package UI::Various::PoorTerm::Class6
{
    use UI::Various::core;
    require Exporter;
    our @ISA = qw(Exporter);
    sub attr($)			# "public" getter
    {   return get('attr', @_);   }
    sub _attr($$)		# "private" setter
    {   return set('attr', undef, @_);   }
    sub new($;\[@$])
    {	return construct({ attr => dummy_varref() }, '^attr$', @_);   }
    sub _reference($$) {}	# dummy for code coverage
};

eval {   UI::Various::PoorTerm::Class5::attr('Broken1');   };
like($@,
     qr/^invalid object \(\) in call to .*::Class5::attr$re_msg_tail/,
    'bad call to access_varref causes error');

stderr_like
{   $_ = UI::Various::PoorTerm::Class5->new({attr => 1});   }
    qr/^'attr' attribute must be a SCALAR reference$re_msg_tail/,
    'not-SCALAR in access_varref causes error';

$_ = UI::Various::PoorTerm::Class5->new();
is($_->attr(), '', 'default constructor creates empty dummy SCALAR reference');
$_ = UI::Various::PoorTerm::Class5->new();
is($_->attr(\$var), 42, 'created dummy SCALAR reference can be changed');
is($_->attr(), 42, 'changed SCALAR reference has correct value');

$_ = UI::Various::PoorTerm::Class6->new({ attr => \$var });
is($_->attr(), 42, 'constructor creates SCALAR correct reference');
