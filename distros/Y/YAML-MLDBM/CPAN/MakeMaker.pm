# A custom generated version of CPAN::MakeMaker for YAML::MLDBM
package CPAN::MakeMaker;
$CUSTOM_VERSION = '0.11';
use strict;
*include = sub {};
use vars qw(@EXPORT @EXPORT_OK %ARGS @MANIFEST @CLEAN);
@EXPORT = qw(WriteMakefile include);
@EXPORT_OK = qw(script prereq bundle inline);
use base 'Exporter';
use ExtUtils::MakeMaker();
use File::Spec;
use Cwd;

# These should always be exported:
*main::WriteMakefile = \&CPAN::MakeMaker::WriteMakefile;
*main::prompt = \&ExtUtils::MakeMaker::prompt;
*main::include = \&CPAN::MakeMaker::include;

die "Please upgrade File::Spec. Version is too old to continue.\n"
  if $File::Spec::VERSION < 0.8;
die "CPAN::MakeMaker should only be used inside Makefile.PL\n"
  unless $0 =~ /Makefile\.PL$/i and -f 'Makefile.PL';


sub WriteMakefile {
    my %args = @_;
    %ARGS = ();

    $ARGS{NAME} = $args{NAME} if defined $args{NAME};
    $ARGS{VERSION} = $args{VERSION} if defined $args{VERSION};
    $ARGS{VERSION_FROM} = $args{VERSION_FROM} if defined $args{VERSION_FROM};
    $ARGS{NAME} = $main::NAME if defined $main::NAME;
    $ARGS{VERSION} = $main::VERSION if defined $main::VERSION;
    $ARGS{VERSION_FROM} = $main::VERSION_FROM if defined $main::VERSION_FROM;
    determine_NAME() unless defined $ARGS{NAME};
    determine_VERSION()
      unless defined $ARGS{VERSION} or defined $ARGS{VERSION_FROM};
    determine_CLEAN_FILES() 
      if defined $main::CLEAN_FILES or
         defined @main::CLEAN_FILES;
    $ARGS{ABSTRACT} = $main::ABSTRACT 
      if defined $main::ABSTRACT and $] >= 5.005;
    $ARGS{AUTHOR} = $main::AUTHOR 
      if defined $main::AUTHOR and $] >= 5.005;
    $ARGS{PREREQ_PM} = \%main::PREREQ_PM if defined %main::PREREQ_PM;
    $ARGS{PL_FILES} = \%main::PL_FILES if defined %main::PL_FILES;
    $ARGS{EXE_FILES} = \@main::EXE_FILES if defined @main::EXE_FILES;

    my %Args = (%ARGS, %args);
    ExtUtils::MakeMaker::WriteMakefile(%Args);
    fix_up_makefile();
}

sub determine_NAME {
    my $NAME = '';
    my @modules = glob('*.pm'), grep {/\.pm$/} find_files('lib');
    if (@modules == 1) {
        open MODULE, $modules[0] or die $!;
        while (<MODULE>) {
            next if /^\s*#/;
            if (/^\s*package\s+(\w[\w:]*)\s*;\s*$/) {
                $NAME = $1;
            }
            last;
        }
    }
    die <<END unless length($NAME);
Can't determine a NAME for this distribution.
Please pass a NAME parameter to the WriteMakefile function in Makefile.PL.
END
#'
    $ARGS{NAME} = $NAME;
}

sub find_files {
    my ($file, $path) = @_;
    $path = '' if not defined $path;
    $file = "$path/$file" if length($path);
    if (-f $file) {
        return ($file);
    }
    elsif (-d $file) {
        my @files = ();
        local *DIR;
        opendir(DIR, $file) or die "Can't opendir $file";
        while (my $new_file = readdir(DIR)) {
            next if $new_file =~ /^(\.|\.\.)$/;
            push @files, find_files($new_file, $file);
        }
        return @files;
    }
    return ();
}

sub determine_VERSION {
    my $VERSION = '';
    my @modules = glob('*.pm'), grep {/\.pm$/} find_files('lib');
    if (@modules == 1) {
        eval {
            $VERSION = ExtUtils::MM_Unix->parse_version($modules[0]);
        };
        print STDERR $@ if $@;
    }
    die <<END unless length($VERSION);
Can't determine a VERSION for this distribution.
Please pass a VERSION parameter to the WriteMakefile function in Makefile.PL.
END
#'
    $ARGS{VERSION} = $VERSION;
}

sub determine_CLEAN_FILES {
    my $clean_files = '';
    if (defined($main::CLEAN_FILES)) {
        if (ref($main::CLEAN_FILES) eq 'ARRAY') {
            $clean_files = join ' ', @$main::CLEAN_FILES;
        }
        else {
            $clean_files = $main::CLEAN_FILES;
        }
    }
    if (defined(@main::CLEAN_FILES)) {
        $clean_files = join ' ', ($clean_files, @main::CLEAN_FILES);
    }
    $clean_files = join ' ', ($clean_files, @CLEAN);
    $ARGS{clean} = {FILES => $clean_files};
}

sub fix_up_makefile {
    open MAKEFILE, '>> Makefile'
      or die "CPAN::MakeMaker::WriteMakefile can't append to Makefile:\n$!";

    print MAKEFILE <<MAKEFILE;
# Well, not quite. CPAN::MakeMaker is adding this:

realclean purge ::
	\$(RM_F) \$(DISTVNAME).tar\$(SUFFIX)

reset :: purge
	\$(RM_RF) CPAN

upload :: test dist
	cpan-upload -verbose \$(DISTVNAME).tar\$(SUFFIX)

grok ::
	perldoc CPAN::MakeMaker

# The End is here ==>
MAKEFILE

    close MAKEFILE;
}

1;
