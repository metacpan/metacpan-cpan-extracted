use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME   => 'XML::Sig::OO',
    LICENSE=>'perl_5',
    VERSION_FROM=>'lib/XML/Sig/OO.pm',
    EXE_FILES=>[
     qw(
       bin/xmlsig
      )
    ],
    PREREQ_PM=> {
      qw(
        Modern::Perl 1.20181021
        Moo 2.003004
        MooX::Types::MooseLike::Base 0.29
        MIME::Base64 3.15
        XML::LibXML 2.0200
        XML::LibXML::XPathContext 2.0200
        Crypt::OpenSSL::X509 1.812
        Crypt::OpenSSL::RSA 0.31
        Crypt::OpenSSL::Bignum 0.09
        Crypt::OpenSSL::DSA 0.19
        Crypt::OpenSSL::VerifyX509 0.10
        Digest::SHA 5.96
        Ref::Util 0.204
        Data::Result 1.0003
        Carp 1.38
        Scalar::Util 0
        namespace::clean 0.27
        Getopt::Long 2.49
      )
    },
    ABSTRACT_FROM  => 'lib/XML/Sig/OO.pm', # retrieve abstract from module
    AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>',
    META_MERGE=>{
      "meta-spec" => { version => 2 },
      repository => {
                type => 'git',
                url => 'https://github.com/akalinux/xml-sig-oo.git',
                web => 'https://github.com/akalinux/xml-sig-oo',

      },
    },
    "TEST_REQUIRES" => {
          "Test::More" => "0.88",
          "File::Spec"=>0,
    },

);
