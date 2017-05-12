use Test::More tests => 4;

BEGIN {
    use_ok('WWW::DomainTools::NameSpinner');
    use_ok('WWW::DomainTools::SearchEngine');
}

## calling new on this object should fail
my $o;

$o = WWW::DomainTools::NameSpinner->new();
ok( $o, "NameSpinner instantiated" );

$o = WWW::DomainTools::SearchEngine->new();
ok( $o, "SearchEngine instantiated" );

