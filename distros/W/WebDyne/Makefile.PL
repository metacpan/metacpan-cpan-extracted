use 5.006;
use strict;
use ExtUtils::MakeMaker;
my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver=~/_/) {    # dev version
    $mm_ver=eval $mm_ver;
    die $@ if $@;
}
my %WriteMakefile=(
    NAME          => 'WebDyne',
    VERSION_FROM  => 'lib/WebDyne.pm',
    ABSTRACT_FROM => 'lib/WebDyne.pm',
    EXE_FILES     => do {
        [
            'bin/wdcompile',
            'bin/wdrender',
            'bin/wddump',
            'bin/wdapacheinit',
            'bin/wddebug',
            'bin/webdyne.psgi',
        ]
    },
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'Test::Simple'      => 0.44,
        'CGI::Simple'       => 0,
        'HTML::Tiny'        => 0,
        'JSON'              => 0,
        'IO::String'        => 0,
        'Digest::MD5'       => 0,
        'HTTP::Status'      => 0,
        'HTML::Tagset'      => 0,
        'HTML::TreeBuilder' => 0,
        'Storable'          => 0,
        'Test::More'        => 0,
        'Capture::Tiny'     => 0,
        'Tie::IxHash'       => 0,
        'Devel::Confess'    => 0,

        #  Needed for installer - can be ignored if not using installer
        'Text::Template' => 0,
        'Env::Path'      => 0,

    },
    META_MERGE => {
        'meta-spec' => {
            version => 2
        },
        resources => {
            homepage   => 'https://github.com/aspeer/pm-WebDyne',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-WebDyne.git',
                web  => 'https://github.com/aspeer/pm-WebDyne'
            }
        }
    },
    PM_FILTER => $ENV{'PM_DEBUG'} || $ENV{'WEBDYNE_DEBUG'} || do {
        use IO::File;
        my $fn='.pm_filter.pf';
        my $fh=IO::File->new($fn, O_WRONLY | O_CREAT | O_TRUNC) ||
            die("unable to write filter file '$fn', $!");
        print $fh 's/^(\s*)debug\\(/${1}0 && debug\\(/m; print';
        $fh->close();
        my $pm_filter="\$(PERL) -nl $fn";
    },
    'depend' => {
        Makefile => '$(VERSION_FROM)',
    },
    'dist' => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => '.gz'
    },
);
my %MM_Compat=(
    '5.46'   => [q(PM_FILTER)],
    '6.31'   => [q(LICENSE)],
    '6.46'   => [q(META_MERGE)],
    '6.48'   => [q(MIN_PERL_VERSION)],
    '6.52'   => [q(CONFIGURE_REQUIRES)],
    '6.5503' => [q(BUILD_REQUIRES)],
    '6.64'   => [q(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $ar)=each %MM_Compat) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete @WriteMakefile{@{$ar}};
    }
}
WriteMakefile(%WriteMakefile);

package MY;
use File::Copy qw(copy);
use File::Spec;
use Cwd qw(abs_path);
use Tie::File;


sub post_initialize {

    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';


    #  Update Git Ref in file if needed/available
    #
    my $devnull=File::Spec->devnull();
    if (my $git_version=qx(git rev-parse HEAD 2>$devnull)) {
        chomp $git_version;
        $git_version=substr($git_version, 0, 10);
        tie my @lines, 'Tie::File', $mm_or->{'VERSION_FROM'} . '.tmp' || die "error on Tie::File, $!";
        $lines[0]=$git_version;
    }
    $mm_or->SUPER::post_initialize;

}


sub postamble {
    my $mm_or=shift();
    my $postamble;
    eval {ExtUtils::Git->import(); $postamble=&MY::postamble($mm_or)};
    $postamble.=<<'END';
doc_xml:
	@echo Generating doc
	docbook-convert --markdown -o .md *.xml
	docbook-convert --markdown --recursedir=./bin -o .md
	docbook-convert --markdown --recursedir=./lib -o .md
	docbook-convert --pod --recursedir=./bin --merge
	docbook-convert --pod --recursedir=./lib --merge
	pandoc  --defaults=plain -f docbook -t plain README.xml > README

XML_TIDY = sh -c 'xmlstarlet fo "$$1" | sponge "$$1"'
doc_xml_tidy:
	find bin -type f -name '*.xml' -exec $(XML_TIDY) _ {} \;
	find lib -type f -name '*.xml' -exec $(XML_TIDY) _ {} \;

END
    return $postamble;
}


sub MM::init_main {

    #  Strip .pl, .sh extension from script files before installing
    #
    my $mm_or=shift();
    my @fn;
    foreach my $fn (@{$mm_or->{'EXE_FILES'}}) {
        (my $fn_new=$fn)=~s/\.(?:pl|sh)$//;
        if ($fn_new ne $fn) {
            -f $fn_new || do {
                eval {symlink(abs_path($fn), $fn_new)} || copy(abs_path($fn), $fn_new)
            }
        }
        push @fn, $fn_new;
    }
    $mm_or->{'EXE_FILES'}=\@fn;
    $mm_or->SUPER::init_main();

}
