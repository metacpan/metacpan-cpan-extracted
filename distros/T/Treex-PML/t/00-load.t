#!perl -T

use Test::More tests => 47;

BEGIN {
    use_ok( 'Treex::PML' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Alt' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::CSTS' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::FS' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::NTRED' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::PML' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::PMLTransform' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::Storable' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::TEIXML' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Backend::TrXML' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Container' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Document' ) || print "Bail out!
";
    use_ok( 'Treex::PML::FSFormat' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Factory' ) || print "Bail out!
";
    use_ok( 'Treex::PML::IO' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Instance' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Instance::Common' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Instance::Reader' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Instance::Writer' ) || print "Bail out!
";
    use_ok( 'Treex::PML::List' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Node' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Alt' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Attribute' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::CDATA' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Choice' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Constant' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Constants' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Container' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Copy' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Decl' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Derive' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Element' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Import' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::List' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Member' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Reader' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Root' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Seq' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Struct' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Template' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::Type' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Schema::XMLNode' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Seq' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Seq::Element' ) || print "Bail out!
";
    use_ok( 'Treex::PML::StandardFactory' ) || print "Bail out!
";
    use_ok( 'Treex::PML::Struct' ) || print "Bail out!
";
}

diag( "Testing Treex::PML $Treex::PML::VERSION, Perl $], $^X" );
