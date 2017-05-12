use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::FrontMatter::YAML' ) || print "Bail out!
";
}

diag( "Testing Text::FrontMatter::YAML $Text::FrontMatter::YAML::VERSION, Perl $], $^X" );
