use ExtUtils::MakeMaker;

$CVS_VERSION = sprintf '%s', q$Revision: 1.8 $ =~ /: ([0-9.]*)/;

WriteMakefile(
              'NAME'         => 'X::Osd',
              'VERSION_FROM' => 'Osd.pm',                       # finds $VERSION
              'LIBS'         => ['-L/usr/local/lib -lxosd'],    # e.g., '-lm'
              );

sub MY::dist_core
{
    return shift->MM::dist_core . <<"EOF";
    
signed_dist: README make_signature dist unlink_signature

README: Osd.pm
\t\@\$(PERL) -MPod::Text -e'Pod::Text->new->parse_from_file("Osd.pm","README")'

make_signature:
\t\@\$(PERL) -MModule::Signature -e'open(SIG,">SIGNATURE");close(SIG); Module::Signature::sign(overwrite => 1)'

unlink_signature:
\t\@\$(PERL) -e'unlink("SIGNATURE")'

EOF

}
