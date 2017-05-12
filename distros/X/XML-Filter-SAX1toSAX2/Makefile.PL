require 5.00503;
use ExtUtils::MakeMaker;

# NOTE: Not putting these in PREREQ_PM because thier installs
#       fail on perl 5.6.1

unless (eval { require XML::Parser::PerlSAX }) {
    print "XML::Filter::SAX1toSAX2 tests require XML::Parser::PerlSAX\n";
    print "Instead we will skip these tests because the install\n";
    print "fails on some perls\n";
}

unless (eval { require XML::Handler::YAWriter }) {
    print "XML::Filter::SAX2toSAX1 tests require XML::Handler::YAWriter\n";
    print "Instead we will skip these tests because the install\n";
    print "fails on some perls\n";
}

WriteMakefile(
    'NAME'	=> 'XML::Filter::SAX1toSAX2',
    'VERSION_FROM' => 'SAX1toSAX2.pm', # finds $VERSION
    'PREREQ_PM' => { 
                'XML::SAX::Base' => 0, 
                'XML::NamespaceSupport' => 0,
                'XML::SAX::ParserFactory' => 0,
                'XML::SAX::Writer' => 0,
                },
    'AUTHOR' => 'Matt Sergeant',
    'ABSTRACT_FROM' => 'SAX1toSAX2.pm',
);
