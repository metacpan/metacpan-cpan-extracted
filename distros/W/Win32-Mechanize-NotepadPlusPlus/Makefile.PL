use ExtUtils::MakeMaker;
use 5.010;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'Win32::Mechanize::NotepadPlusPlus',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'lib/Win32/Mechanize/NotepadPlusPlus.pm',
    'ABSTRACT_FROM' => 'lib/Win32/Mechanize/NotepadPlusPlus.pm',
    'PREREQ_PM'     => {
        'Exporter'          => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'           => 0.77,
        'warnings'          => 0,
        'strict'            => 0,
        'constant'          => 0,
        'Carp'              => 0,
        'Encode'            => 0,
        'IPC::Open2'        => 0,
        'Win32::GuiTest'    => 1.64,    # version needed for 64-bit ::SendMessage retval
        'Win32::API'        => 0.71,    # version needed for WINAPI calling convention
        'Win32::GUI'        => 0,       # for now, needed for notepad()->prompt; need to look for alternative
        'Win32'             => 0,
        'File::Which'       => 0,
        'Config'            => 0,       # needed in Notepad.pm::getFiles for $Config{ptrsize}
    },
);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.46' ) {
        $mm_args{META_MERGE} = {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    mailto  => 'bug-Win32-Mechanize-NotepadPlusPlus@rt.cpan.org',
                    web     => 'https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues',
                },
                repository => {
                    url     => 'https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus.git',
                    web     => 'https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus',
                    type    => 'git',
                },
            },
            keywords => [ 'Notepad++', 'automation'],
        };
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        #   => this comes out right when printed... but MYMETA.* shows values that look wrong
        my $v = MM->parse_version( $mm_args{VERSION_FROM} );
        $mm_args{META_MERGE}{provides} = {
            'Win32::Mechanize::NotepadPlusPlus' => {
                file => 'lib/Win32/Mechanize/NotepadPlusPlus.pm',
                version => $v,
            },
            'Win32::Mechanize::NotepadPlusPlus::Notepad' => {
                file => 'lib/Win32/Mechanize/NotepadPlusPlus/Notepad.pm',
                version => $v,
            },
            'Win32::Mechanize::NotepadPlusPlus::Editor' => {
                file => 'lib/Win32/Mechanize/NotepadPlusPlus/Editor.pm',
                version => $v,
            }
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.10.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.52' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            'ExtUtils::MakeMaker' => '6.52',
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
            'Win32' => 0,
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
            'Path::Tiny' => 0.058,          # 0.018 needed for rootdir and cwd; 0.058 needed for sibling
            'Win32' => 0,
            'Win32::API' => 0,
            'Win32::GuiTest'    => 1.64,    # version needed for 64-bit ::SendMessage retval
            'Encode' => 0,
            'FindBin' => 0,
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return <<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# run a test coverage report
testcover ::
	$(NOECHO) cover -test -report html

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# addition to realclean: also delete coverage database, if testcover was run
realclean ::
	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: skip "rm -rf cover_db"
	$(NOECHO) ( $(TEST_F) LICENSE.pod && $(RM_RF) LICENSE.pod ) || $(ECHO) realclean:: LICENSE.pod intermediary
	$(NOECHO) ( $(TEST_F) README.pod && $(RM_RF) README.pod ) || $(ECHO) realclean:: README.pod intermediary
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: MYMETA.json.lock temp file

# veryclean: runs realclean, then deletes .bak, .old, .orig, and similar

# auto-populate the VERSION in the submodules from $(VERSION), which comes from main module
populateversion :: lib/Win32/Mechanize/NotepadPlusPlus.pm
	$(NOECHO) $(ECHO) want to auto-populate VERSION in all sub-modules: $(VERSION)
	$(PERL) -pi -e "s/^(\s*our\s+.VERSION\s*=).*?;.*?$$/\1 '$(VERSION)'; # auto-populated from W::M::NPP/" lib/Win32/Mechanize/NotepadPlusPlus/Notepad.pm lib/Win32/Mechanize/NotepadPlusPlus/Editor.pm

#config :: populateversion
#	$(NOECHO) $(NOOP)

# auto-generate the README from the lib/Win32/Mechanize/NotepadPlusPlus.pm
README.md :: lib/Win32/Mechanize/NotepadPlusPlus.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(SYNOPSIS),qq(DESCRIPTION),qq(LIMITATIONS),qq(INSTALLATION),qq(TODO),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)]});$$p->parse_file(qq(lib/Win32/Mechanize/NotepadPlusPlus.pm));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/Win32/Mechanize/NotepadPlusPlus.pm
LICENSE :: lib/Win32/Mechanize/NotepadPlusPlus.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(lib/Win32/Mechanize/NotepadPlusPlus.pm));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: README.md LICENSE populateversion

# auto-generate the messages-modules for Notepad++ GUI and Scintilla Editor -- this is run by developer, not during the install suite

all_msgs ::
	$(TOUCH) src/*.h
	$(MAKE) msgs

msgs :: generate__npp_msgs generate__npp_idm generate__sci_msgs

generate__npp_msgs :: lib/Win32/Mechanize/NotepadPlusPlus/__npp_msgs.pm

generate__npp_idm :: lib/Win32/Mechanize/NotepadPlusPlus/__npp_idm.pm

generate__sci_msgs :: lib/Win32/Mechanize/NotepadPlusPlus/__sci_msgs.pm

lib/Win32/Mechanize/NotepadPlusPlus/__npp_msgs.pm :: src/Notepad_plus_msgs.h
	$(NOECHO) $(ECHO) # svn export --force https://github.com/notepad-plus-plus/notepad-plus-plus/trunk/PowerEditor/src/MISC/PluginsManager/Notepad_plus_msgs.h
	$(NOECHO) $(ABSPERLRUN) src/convertHeaders.pl "$<" "$@" "Win32::Mechanize::NotepadPlusPlus::__npp_msgs" "nppm"
	$(NOECHO) $(ABSPERLRUN) -Ilib -e "use warnings; use strict; use Win32::Mechanize::NotepadPlusPlus::__npp_msgs; print STDERR qq(# NPPMSG = $$nppm{NPPMSG}\n);"

lib/Win32/Mechanize/NotepadPlusPlus/__npp_idm.pm :: src/menuCmdID.h
	$(NOECHO) $(ECHO) # svn export --force https://github.com/notepad-plus-plus/notepad-plus-plus/trunk/PowerEditor/src/menuCmdID.h
	$(NOECHO) $(ABSPERLRUN) src/convertHeaders.pl "$<" "$@" "Win32::Mechanize::NotepadPlusPlus::__npp_idm" "nppidm"
	$(NOECHO) $(ABSPERLRUN) -Ilib -e "use warnings; use strict; use Win32::Mechanize::NotepadPlusPlus::__npp_idm; print STDERR qq(# IDM = $$nppidm{IDM}\n);"

lib/Win32/Mechanize/NotepadPlusPlus/__sci_msgs.pm :: src/Scintilla.h
	$(NOECHO) $(ECHO) # svn export --force https://github.com/notepad-plus-plus/notepad-plus-plus/trunk/scintilla/include/Scintilla.h
	$(NOECHO) $(ABSPERLRUN) src/convertHeaders.pl "$<" "$@" "Win32::Mechanize::NotepadPlusPlus::__sci_msgs" "scimsg"
	$(NOECHO) $(ABSPERLRUN) -Ilib -e "use warnings; use strict; use Win32::Mechanize::NotepadPlusPlus::__sci_msgs; print STDERR qq(# SCI_GETTEXT = $$scimsg{SCI_GETTEXT}\n);"

POSTAMBLE
}

if($ENV{W32MNPP_FORCE_WRONG_OS}) {
    $^O = 'WrongOS';
}

if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) {
    warn sprintf "I don't know whether it will work with Notepad++.exe in OS '%s'\n", $^O;
    warn << "EOW";

########################################
# However, it might work, so I don't want to FAIL on matrix.cpantesters.org.
#   Instead, don't create the Makefile by default, so it will show up as UNKNOWN
#
# If you'd like to try to make it work, please set the environment variable
#   W32MNPP_FORCE_NONWIN_TEST to a true value,
# then re-run perl Makefile.PL, and continue the standard test suite and
# installation procedure from there.
#
# If it works, feel free to create an issue explaining how to make it work:
#   https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues
########################################

EOW
    exit 0; # exit 0 without Makefile existing will cause UNKNOWN
}


WriteMakefile( %mm_args )
