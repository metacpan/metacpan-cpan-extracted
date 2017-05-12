use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Sig',
    'VERSION_FROM'	=> 'lib/XML/Sig.pm',
    'ABSTRACT'  => "An XML Digital Signature Toolkit",
    'AUTHOR'    => 'Byrne Reese <byrne@majordojo.com>',
    'DISTNAME'  => 'XML-Sig',
    'LICENSE'   => 'perl',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM' => {
        'Test::Exception' => 0,
        'File::Which' => 0,
        'Class::Accessor' => 0,
        'XML::XPath' => 0,
        'Digest::SHA1' => 0,
        'MIME::Base64' => 0,
        'Crypt::OpenSSL::X509' => 0,
        'Crypt::OpenSSL::RSA' => 0,
        'Crypt::OpenSSL::DSA' => 0,
        'XML::CanonicalizeXML' => 0,
    },
);
__END__
