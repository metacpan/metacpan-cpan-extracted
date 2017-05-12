use ExtUtils::MakeMaker;

WriteMakefile( (MM->can('signature_target') ? (SIGN => 1) : ()),
               NAME         => "Wiki::Toolkit::Formatter::Pod",
               VERSION_FROM => "lib/Wiki/Toolkit/Formatter/Pod.pm",
               PREREQ_PM    => { 'IO::Scalar'      => 0,
				 'Pod::Tree' => '1.10' # for link map
                               }
             );
