#!perl -T

use Test::More tests => 13;

BEGIN {
    use_ok( 'WordLists::Base' ) || print "Bail out!
";
    use_ok( 'WordLists::Common' ) || print "Bail out!
";
    use_ok( 'WordLists::Dict' ) || print "Bail out!
";
    use_ok( 'WordLists::Lookup' ) || print "Bail out!
";
    use_ok( 'WordLists::Sense' ) || print "Bail out!
";
    use_ok( 'WordLists::Sort' ) || print "Bail out!
";
    use_ok( 'WordLists::Tag' ) || print "Bail out!
";
    use_ok( 'WordLists::WordList' ) || print "Bail out!
";
    use_ok( 'WordLists::Parse::Simple' ) || print "Bail out!
";
    use_ok( 'WordLists::Inflect::Simple' ) || print "Bail out!
";
    use_ok( 'WordLists::Serialise::Simple' ) || print "Bail out!
";
    use_ok( 'WordLists::Sort::Typical' ) || print "Bail out!
";
    use_ok( 'WordLists::Tag::Tagger' ) || print "Bail out!
";
}

diag( "Testing WordLists::Base $WordLists::Base::VERSION, Perl $], $^X" );
