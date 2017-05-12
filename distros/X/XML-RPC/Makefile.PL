use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              =>  'Niek Albers',
    ABSTRACT            =>  'Pure Perl implementation for an XML-RPC client and server',
    NAME                =>  'XML-RPC',
    VERSION_FROM        =>  'lib/XML/RPC.pm',
    PREREQ_PM           =>  {
        'XML::TreePP'       =>  '0',
        'LWP::UserAgent'    =>  '0',
#       'HTTP::Lite'        =>  '0',
#       'Jcode'             =>  '0', # on Perl 5.005/5.6.x
        'Test::More'        => 0.17, #build
    },
    ($ExtUtils::MakeMaker::VERSION ge '6.31'? 
     ('LICENSE'		=> 'perl', ) : ()),
);
