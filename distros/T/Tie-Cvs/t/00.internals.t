# -*- cperl -*-

use Test::More tests => 1 + 2 * 25;

BEGIN { use_ok('Tie::Cvs') }

# norm and norminv are inverse one from the other

my %data = (
	    # NORMAL
	    "teste"       => "teste",

	    # SPACE
	    "foo bar"     => 'foo_bar',
            ' '           => '_',

	    # UNDERSCORE
	    '_'           => '%_',
	    '%_'          => '%%%_',
	    ' _'          => '_%_',
	    '_ '          => '%__',
	    '  '          => '__',
	    '__'          => '%_%_',
	    ' % _% %_'    => '_%%_%_%%_%%%_',

	    # PERCENT
	    'foo%bar'     => 'foo%%bar',
	    'foo%percent' => 'foo%%percent',
	    'foo %'       => 'foo_%%',
            '%'           => '%%',

	    # SLASH
            'foo/bar'     => 'foo%sbar',
            '/'           => '%s',
	    '%slash'      => '%%slash',

	    # CVS e CVSROOT
	    'CVS'         => '%CVS',
	    'CVSROOT'     => '%CVSROOT',
	    ' CVS'        => '_CVS',
            'aCVS'        => 'aCVS',
            '%CVS'        => '%%CVS',
            '%CVSROOT'    => '%%CVSROOT',
	    # TAB
            "\t"          => '%t',

	    # MISC
	    " %/\t"         => '_%%%s%t',
	   );

for $a (keys %data) {
  is(Tie::Cvs::norm($a),$data{$a});
  is(Tie::Cvs::norminv(Tie::Cvs::norm($a)), $a)
}


