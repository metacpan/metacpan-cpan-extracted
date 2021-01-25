#!/usr/bin/perl

# Check Test::Inline::Script support for older test styles

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use Path::Tiny;
use Test::More tests => 7;
use Test::Inline ();





#####################################################################
# Test the examples from Inline.pm
{
	my $content = path(catfile( 't', 'data', '10_legacy_extract', 'Inline.pm' ))->slurp;
	my $inline_file = \$content;
	is( ref($inline_file), 'SCALAR', 'Loaded Inline.pm examples' );

	# Create the Inline object
	my $Inline = Test::Inline->new();
	isa_ok( $Inline, 'Test::Inline' );	

	# Add the sample source code
	ok( $Inline->_add_source( $inline_file ), 'Inline.pm examples added' );

	# Check the results
	my $Script = $Inline->class('My::Pirate');
	isa_ok( $Script, 'Test::Inline::Script' );
	is( $Script->class, 'My::Pirate', '->class returns as expected' );
	is( $Script->filename, 'my_pirate.t', '->filename gets set as expected' );
	is( $Inline->_content('My::Pirate'), <<'END_SCRIPT', '->_content gets set as expected' );
#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
my @p = is_pirate('Blargbeard', 'Alfonse', 'Capt. Hampton', 'Wesley');
is(@p,  2,   "Found two pirates.  ARRR!");
}



# =for example begin
$::__tc = Test::Builder->new->current_test;
{
eval q{
  my $example = sub {
    local $^W = 0;
    use LWP::Simple;
    getprint "http://www.goats.com";
  };
};
is($@, '', 'Example 1 compiles cleanly');
}
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );




1;
END_SCRIPT

}
