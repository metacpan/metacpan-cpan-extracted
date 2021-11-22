use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'WWW::KeePassHttp',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'lib/WWW/KeePassHttp.pm',
    'ABSTRACT_FROM' => 'lib/WWW/KeePassHttp.pm',
    'PREREQ_PM'     => {
        'Exporter'              => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'               => 0.77,
        'warnings'              => 0,
        'strict'                => 0,
        'constant'              => 0,
        'Carp'                  => 0,
        'Encode'                => 0,
        'MIME::Base64'          => 0,
        'Crypt::Mode::CBC'      => 0.003,   # first with Crypt::Mode::CBC in CryptX
        'HTTP::Tiny'            => 0.041,   # keep_alive
        'JSON'                  => 0,
        'Time::HiRes'           => 0,
    },
    'realclean'     => {
        FILES => 'cover_db LICENSE.pod README.pod MYMETA.json.lock',
    },
    'META_MERGE'    => {            # EUMM 6.46
        'meta-spec' => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                web     => 'https://github.com/pryrt/WWW-KeePassHttp/issues',
            },
            repository => {
                url     => 'https://github.com/pryrt/WWW-KeePassHttp.git',
                web     => 'https://github.com/pryrt/WWW-KeePassHttp',
                type    => 'git',
            },
        },
        keywords => [ 'KeePass', 'KeePassHttp'],
        provides => {
            # versions will be added below, when I parse VERSION_FROM
            'WWW::KeePassHttp' => { file => 'lib/WWW/KeePassHttp.pm' },
            'WWW::KeePassHttp::Entry' => { file => 'lib/WWW/KeePassHttp/Entry.pm' },
        },
    },
    'LICENSE' => 'perl_5',          # EUMM 6.31
    'MIN_PERL_VERSION' => '5.12.0', # EUMM 6.48
    'CONFIGURE_REQUIRES' => {       # EUMM 6.52
        'ExtUtils::MakeMaker' => '6.52',
        'warnings' => 0,
        'strict' => 0,
        'Test::More' => 0.86,
        'Test::Exception' => 0,
        'constant' => 0,
        'Config' => 0,
    },
    'TEST_REQUIRES' => {            # EUMM 6.64
        'warnings' => 0,
        'strict' => 0,
        'Test::More' => 0.86,
        'Test::Exception' => 0,
        'Test::MockObject' => 0,
        'constant' => 0,
        'Config' => 0,
    },
);

{
    # in most cases, delete from %mm_args rather than adding to the hash like I used to do
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION < '6.46' ) {
        delete $mm_args{META_MERGE};
    } else {
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        my $v = MM->parse_version( $mm_args{VERSION_FROM} );
        for my $k ( keys %{ $mm_args{META_MERGE}{provides} } )
        {
            $mm_args{META_MERGE}{provides}{$k}{version} = $v;
        }
    }

    if( $ExtUtils::MakeMaker::VERSION < '6.31' ) {
        delete $mm_args{LICENSE};
    }
    if( $ExtUtils::MakeMaker::VERSION < '6.48' ) {
        delete $mm_args{MIN_PERL_VERSION};
    }
    if( $ExtUtils::MakeMaker::VERSION < '6.52' ) {
        $mm_args{PREREQ_PM} = (
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
            $mm_args{PREREQ_PM},
        ) if exists $mm_args{PREREQ_PM};            # merge TEST and CONFIG into PREREQ
        delete $mm_args{CONFIGURE_REQUIRES};
    }
    if( $ExtUtils::MakeMaker::VERSION < '6.64' ) {
        $mm_args{CONFIGURE_REQUIRES} = (
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
        ) if exists $mm_args{CONFIGURE_REQUIRES};   # merge TEST into CONFIG
        delete $mm_args{TEST_REQUIRES};
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    my $POSTAMBLE =<<'POSTAMBLE';
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

# veryclean: runs realclean, then deletes .bak, .old, .orig, and similar
# addition to realclean: also delete coverage database, if testcover was run
# to add to realclean target:: realclean => {FILES => 'space sep list of files and dirs'} in the hash

# auto-populate the VERSION in the submodules from $(VERSION), which comes from main module
populateversion :: lib/WWW/KeePassHttp.pm
	$(NOECHO) $(ECHO) want to auto-populate VERSION in all sub-modules: $(VERSION)
	$(PERL) -pi -e "s/^(\s*our\s+.VERSION\s*=).*?;.*?$$/\1 '$(VERSION)'; # auto-populated from W:KPH/" lib/WWW/KeePassHttp/Entry.pm

#config :: populateversion
#	$(NOECHO) $(NOOP)

# auto-generate the README from the lib/WWW/KeePassHttp.pm
README.md :: lib/WWW/KeePassHttp.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(SYNOPSIS),qq(DESCRIPTION),qq(INSTALLATION),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)]});$$p->parse_file(qq(lib/WWW/KeePassHttp.pm));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/WWW/KeePassHttp.pm
LICENSE :: lib/WWW/KeePassHttp.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(lib/WWW/KeePassHttp.pm));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: README.md LICENSE manifest populateversion

POSTAMBLE

    return $POSTAMBLE;

}

WriteMakefile( %mm_args )
