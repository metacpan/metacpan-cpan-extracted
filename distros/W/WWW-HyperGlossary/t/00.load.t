use Test::More tests => 5;

BEGIN {
use_ok( 'WWW::HyperGlossary::Base' );
use_ok( 'WWW::HyperGlossary' );
use_ok( 'WWW::HyperGlossary::Word' );
use_ok( 'WWW::HyperGlossary::Word::Definition' );
use_ok( 'WWW::HyperGlossary::Utils::YAML' );
}

diag( "Testing WWW::HyperGlossary::Base $WWW::HyperGlossary::Base::VERSION" );
diag( "Testing WWW::HyperGlossary $WWW::HyperGlossary::VERSION" );
diag( "Testing WWW::HyperGlossary::Word $WWW::HyperGlossary::Word::VERSION" );
diag( "Testing WWW::HyperGlossary::Word::Definition $WWW::HyperGlossary::Word::Definition::VERSION" );
diag( "Testing WWW::HyperGlossary::Utils::YAML $WWW::HyperGlossary::Utils::YAML::VERSION" );
