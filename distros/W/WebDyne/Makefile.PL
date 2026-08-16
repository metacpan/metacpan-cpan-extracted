use 5.006;
use strict;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use File::Spec;
use Cwd qw(abs_path);
use Tie::File;

BEGIN {

    if (-d '.venv') {

        # ExtUtils::Manifest in some Perl versions walks the tree with symlink
        # following enabled before MANIFEST.SKIP is applied. A local Python venv can
        # therefore abort Makefile.PL when its python symlinks resolve twice.
        require ExtUtils::Manifest;
        require File::Find;

        no warnings 'redefine';
        *ExtUtils::Manifest::manifind = sub {
            my $found = {};

            my $wanted = sub {
                my $name = ExtUtils::Manifest::clean_up_filename($File::Find::name);
                return if -d $File::Find::name;
                $found->{$name} = '';
            };

            File::Find::find(
                {
                    wanted     => $wanted,
                    no_chdir   => 1,
                    preprocess => sub { grep { $_ ne '.venv' } @_ },
                },
                '.'
            );

            return $found;
        };
    }

}


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
            'bin/wdlint',
            'bin/webdyne.psgi',
            'bin/webdyne.pagi',
            'bin/webdyne.apache'
        ]
    },
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'CGI::Simple'       => 0,
        'Capture::Tiny'     => 0,
        'File::Temp'        => 0,
        'HTML::Element'     => 0,
        'HTML::Entities'    => 0,
        'HTML::Tiny'        => 0,
        'JSON'              => 0,
        'IO::String'        => 0,
        'Digest::MD5'       => 0,
        'HTTP::Request'     => 0,
        'HTTP::Request::Common' => 0,
        'HTTP::Status'      => 0,
        'HTTP::Negotiate'   => 0,
        'HTTP::AcceptLanguage' => 0,
        'HTTP::Headers::Util'  => 0,
        'HTTP::Headers::Fast'  => 0,
        'HTML::Tagset'      => 0,
        'HTML::TreeBuilder' => 0,
        'Storable'          => 0,
        'Tie::IxHash'       => 0,
        'Devel::Confess'    => 0,
        'Router::Simple'    => 0,
        'Hash::MultiValue'  => 0,
        'Time::HiRes'       => 0,
        'Sub::Util'         => 0,
        'Term::ANSIColor'   => 0,
        'Crypt::URandom'    => 0,
        'URI'               => 0,
        

        #  Needed for installer - can be ignored if not using installer
        'Text::Template' => 0,
        'Env::Path'      => 0,

    },
    BUILD_REQUIRES  => {
        'Algorithm::Diff'   => 0,
        'Test::Simple'      => 0.44,
        'Test::More'        => 0,
        'Capture::Tiny'     => 0,
        'Test::Deep'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Text::Diff'        => 0
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2
        },
        "prereqs" => {
            "runtime" => {
                "suggests" => {
                    # Optional server/runtime bundles.
                    'Task::WebDyne::Plack'  => 0,
                    'Task::WebDyne::PAGI'   => 0,
                    'Task::WebDyne::Apache' => 0,
                    'Task::WebDyne::Starman'=> 0,

                    # Optional development/runtime helpers.
                    'HTML::Tidy5'                    => 0,
                    'Module::Reload'                 => 0,
                    'Syntax::Highlight::Engine::Kate'=> 0,
                    'Text::Diff'                     => 0,
                },
            },
        },
        resources => {
            homepage   => 'https://github.com/aspeer/WebDyne',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/WebDyne.git',
                web  => 'https://github.com/aspeer/WebDyne'
            }, 
            bugtracker => {
                web => 'https://github.com/aspeer/WebDyne/issues'
            }
        },
        x_authority => 'cpan:ASPEER'
    },
    PM_FILTER => ($ENV{'PM_DEBUG'} || $ENV{'WEBDYNE_DEBUG'}) ? '$(PERL) -pe 1' : do {
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


#  Extend Makefile
#
sub MY::dist_basics {
    my $mm_or=shift();
    my $out=$mm_or->MY::SUPER::dist_basics(@_);
    return $out unless -d '.venv';
    my $replacement=<<'END';
manifest :
	$(NOECHO) $(ECHO) "Refusing to regenerate MANIFEST while .venv exists; remove .venv and rerun Makefile.PL first."
	$(NOECHO) $(FALSE)
END
    $out=~s{^manifest\s*:\s*\n(?:\t[^\n]*\n)+}{$replacement}m ||
        die "unable to replace MakeMaker manifest target";
    return $out;
}


sub MY::post_initialize {

    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';


    #  Add git ref if needed
    #
    if (grep {$mm_or->{'VERSION_FROM'} eq $_} @{$mm_or->{'EXE_FILES'}}) {
        push @{$mm_or->{'EXE_FILES'}}, $mm_or->{'VERSION_FROM'}.'.sha';
    }
    
    
    #  Don't install docs/tmp files etc.
    #
    my %pm=map { $_=>$mm_or->{'PM'}{$_} } grep { !/\.(?:md|xml|pod|bak|tmp|0)$/ } keys %{$mm_or->{'PM'}};
    $mm_or->{'PM'}=\%pm;
    

    #  Update Git Ref in file if needed/available
    #
    my $devnull=File::Spec->devnull();
    if (my $git_version=qx(git rev-parse --short HEAD 2>$devnull)) {
        chomp $git_version;
        tie my @lines, 'Tie::File', $mm_or->{'VERSION_FROM'} . '.sha' || die "error on Tie::File, $!";
        $lines[0]=$git_version;
    }
    $mm_or->MY::SUPER::post_initialize;

}


#  Get ExtUtils::Git postamble if we are using it
#
sub MM::postamble {
    my $mm_or=shift();
    my $postamble;
    eval {ExtUtils::Git->import(); $postamble=&MY::postamble($mm_or)};
    $postamble.=<<'END';


SRC_DIR := doc
TMP_DIR := $(SRC_DIR)/build
PSP_DIR := $(SRC_DIR)/example
# doc/example is intentionally developer-only and is not shipped in CPAN
# tarballs, so guard the scan to keep install/smoke-test make invocations quiet.
PSP_FILES := $(shell test -d $(PSP_DIR) && find $(PSP_DIR) -type f -name '*.psp')
BIN_DOC_FILES := $(wildcard bin/*.md)
LIB_DOC_FILES := $(shell find lib -type f -name '*.md' ! -name '._*' | sort)

DOC_DIR := docs
SCRIPTS_DIR := scripts
GH_PAGES_DOMAIN := webdyne.org

DOCKER_DIR := mkdocs/docker
DOCKER_IMAGE := webdyne-mkdocs:latest
DOCKER_STAMP := $(DOCKER_DIR)/.built


$(SRC_DIR)/webdyne.md : $(SRC_DIR)/webdyne.xml $(BIN_DOC_FILES) $(LIB_DOC_FILES)
	mkdir -p $(TMP_DIR)
	xmllint --xinclude --noent $< -o $(TMP_DIR)/$(notdir $<)
	xsltproc $(SCRIPTS_DIR)/promote-title-ids.xsl $(TMP_DIR)/$(notdir $<) | sponge $(TMP_DIR)/$(notdir $<)
	pandoc -f docbook -t markdown-smart --lua-filter=$(SCRIPTS_DIR)/admonition-advanced.lua --resource-path=$(SRC_DIR) --extract-media=$(DOC_DIR) -o $(TMP_DIR)/$(notdir $@) $(TMP_DIR)/$(notdir $<)
	perl -pi -e 's/[\\]+</\&lt;/g; s/[\\]+>/\&gt;/g' $(TMP_DIR)/$(notdir $@)
	# Fix image placeholders from pandoc
	perl -pi -e 's{\Qdocs/images\E}{images}g' $(TMP_DIR)/$(notdir $@)
	perl -0pi -e 's/\{\.manual-page-new-tab\s+role="manual-page-new-tab"\}/{target="_blank" rel="noopener"}/g' $(TMP_DIR)/$(notdir $@)
	perl -pi -e 's/[ \t]+$$//' $(TMP_DIR)/$(notdir $@)
	cp $(TMP_DIR)/$(notdir $@) $@
	rm -f $(DOC_DIR)/*.md
	perl $(SCRIPTS_DIR)/mdsplit.pl $(TMP_DIR)/$(notdir $@) $(DOC_DIR)
	mkdir -p $(DOC_DIR)/utilities
	rm -f $(DOC_DIR)/utilities/*.md
	cp $(BIN_DOC_FILES) $(DOC_DIR)/utilities/
	rm -rf $(DOC_DIR)/modules
	mkdir -p $(DOC_DIR)/modules
	perl -MFile::Copy=copy -e 'for my $$src (@ARGV) { (my $$dst=$$src)=~s{^lib/}{}; $$dst=~s{\.pm\.md$$}{.md}; $$dst=~s{/}{_}g; $$dst="$(DOC_DIR)/modules/$$dst"; copy($$src,$$dst) or die "$$src -> $$dst: $$!" }' $(LIB_DOC_FILES)

gh-deploy : $(SRC_DIR)/webdyne.md
	find $(DOC_DIR) -type f -name '*._*' -delete
	printf '%s\n' $(GH_PAGES_DOMAIN) > $(DOC_DIR)/CNAME
	mkdocs gh-deploy -f mkdocs.gh.yml

serve : $(SRC_DIR)/webdyne.md docker
	docker rm -f webdyne-mkdocs || true
	docker run -d --name webdyne-mkdocs -e PORT=5000 -p 5000:5000 webdyne-mkdocs
	mkdocs serve -f mkdocs.yml


mkdocs-docker: $(DOCKER_STAMP)

$(DOCKER_STAMP) : $(PSP_FILES) $(DOCKER_DIR)/Dockerfile.alpine
	docker build  -t $(DOCKER_IMAGE) -f ($DOCKET_DIR)/Dockerfile.alpine .
	touch $(DOCKER_STAMP)



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

filter_scripts :
	@for f in $(EXE_FILES); do \
		echo "Installing script $$f via PM_FILTER..."; \
		$(PM_FILTER) $$f > blib/script/`basename $$f`; \
	done

pure_all :: filter_scripts

git_version_increment0 ::
	cd docker && $(PERL) build.pl

docker_update ::
	cd docker && $(PERL) build.pl

END
    #return $mm_or->SUPER::postamble . $postamble;
    return $mm_or->MY::SUPER::postamble . $postamble;
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
    $mm_or->MM::SUPER::init_main();

}
