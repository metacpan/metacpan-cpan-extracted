use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'WAP::wbxml',
    'VERSION_FROM'  => 'lib/WAP/wbxml.pm', # finds $VERSION
    'ABSTRACT'      => 'Binarization of XML file used by Wireless Application Protocol',
    'PREREQ_PM'     => {
                        'XML::DOM'      => '1.25',
                        'I18N::Charset' => '1.15',
    },
    'EXE_FILES'     => ['bin/wbxmlc'],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

sub MY::install {
    package MY;
    my $script = shift->SUPER::install(@_);
    $script =~ s/install :: (.*)$/install :: all compile_rules $1/m;
    $script .= <<"INSTALL";

compile_rules :
\t\$(PERLRUNINST) \$(INST_SCRIPT)/wbxmlc -p \$(INST_LIB)/WAP/wbxml/wap.wbrules.xml samples/personal.xml
\t\$(RM_F) samples/personal.wbxml
\t\$(PERLRUNINST) \$(INST_SCRIPT)/wbxmlc -p \$(INST_LIB)/WAP/wbxml/wv.wbrules.xml samples/personal.xml
\t\$(RM_F) samples/personal.wbxml
\t\$(PERLRUNINST) \$(INST_SCRIPT)/wbxmlc -p \$(INST_LIB)/WAP/wbxml/syncml.wbrules.xml samples/personal.xml
\t\$(RM_F) samples/personal.wbxml
\t\$(PERLRUNINST) \$(INST_SCRIPT)/wbxmlc -p \$(INST_LIB)/WAP/wbxml/activesync.wbrules.xml samples/airsync.xml
\t\$(RM_F) samples/airsync.wbxml

INSTALL

    return $script;
}

