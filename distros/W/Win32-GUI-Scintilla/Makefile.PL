use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Win32::GUI::Scintilla',
    'VERSION_FROM'      => 'Scintilla.pm.begin', # finds $VERSION
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    'PM' => {
        'Scintilla.pm'  => '$(INST_LIBDIR)/Scintilla.pm',
        'Perl.pm'       => '$(INST_LIBDIR)/Scintilla/Perl.pm',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Add Scintilla control to Win32::GUI',
       AUTHOR   => 'ROCHER Laurent (lrocher@cpan.org)') : ()),
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '', # e.g., '-DHAVE_SOMETHING'
        # Insert -I. if you add *.h files later:
    'INC'               => '', # e.g., '-I/usr/include/other'
        # Un-comment this if you add C files to link with later:
    # 'OBJECT'          => '$(O_FILES)', # link all the C files too
);

sub MY::postamble {

return <<'MAKE_FRAG';

Scintilla.pm : Scintilla.pm.begin Scintilla.pm.end include/Scintilla.iface include/autogen.pl
	$(PERL) ./include/autogen.pl

config :: $(INST_ARCHAUTODIR)/SciLexer.dll
	@$(NOOP)

$(INST_ARCHAUTODIR)/SciLexer.dll : include/SciLexer.dll
	$(CP) ./include/SciLexer.dll $(INST_ARCHAUTODIR)/SciLexer.dll

MAKE_FRAG
}
