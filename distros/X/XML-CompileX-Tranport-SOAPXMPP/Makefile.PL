use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME              => 'XML::CompileX::Tranport::SOAPXMPP',
   VERSION_FROM      => 'lib/XML/CompileX/Transport/SOAPXMPP.pm',
   PREREQ_PM         => { XML::Compile::SOAP => 0.73,
                          Net::XMPP2 => 0, Event => 0, AnyEvent => 0,
                        },
   ABSTRACT       => 'Send SOAP messages through XMPP',
   AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>',
  );
