BEGIN {
    my @missing;
    my @required = qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::Repository
        Module::Install::XSUtil
    );
    foreach my $module (@required) {
        eval <<EOM;
            require $module;
            $module->import;
EOM
        if ($@) {
            push @missing, $module;
        }
    }

    if (@missing) {
        print "You don't seem to have some modules required for building this module.\nPlease install the following modules first:\n\n";
        foreach my $module (@missing) {
            $module =~ s/^inc:://;
            print " + $module\n";
        }
        print "\nBail out\n";
        exit 1;
    }
}

sub cc_append_to_libs_mine ($);


my $RUNNING_IN_HELL = $^O eq 'MSWin32';

my $config = run_probes();
check_lib($config);
define_symbols($config);

do 'tools/genfiles.pl';
die if $@;
MeCabBuild::write_files($config->{version});

name 'Text-MeCab';
all_from 'lib/Text/MeCab.pm';

requires 'Class::Accessor::Fast';
requires 'Encode';
requires 'Exporter';
requires 'File::Spec';
use_ppport;
cc_append_to_ccflags $config->{cflags};
cc_append_to_inc $config->{include};
cc_libs $config->{libs};
cc_define @{ $config->{define} };
cc_src_paths 'xs';
cc_warnings;
auto_set_repository;

build_requires 'Devel::CheckLib';
test_requires 'Test::More', 0.84;
test_requires 'Test::Requires';
tests 't/*.t t/*/*.t';
author_tests 'xt';
WriteAll;

sub cc_append_to_libs_mine ($) {
    my $ma = makemaker_args;
    if ($ma->{LIBS}) {
        $ma->{LIBS} .= " $_[0]";
    } else {
        $ma->{LIBS} = $_[0];
    }
}

sub run_probes
{
    my $config = do 'tools/probe_mecab.pl';
    die if $@;

    for(my $i = 0; $i < @ARGV; $i++) {
        if ($ARGV[$i] =~ /^--debugging$/) {
            splice(@ARGV, $i, 1);
            $config->{debugging} = 1;
            $i--;
        }
    }

    $config->{cflags} ||= '';
    $config->{cflags} .= ' -I src';

    print
        "Detected the following mecab information:\n",
        "   version: $config->{version}\n",
        "   cflags: $config->{cflags}\n",
        "   libs: $config->{libs}\n",
        "   include: $config->{include}\n",
    ;
    return $config;
}

sub check_lib
{
    my $config = shift;

    if (! $RUNNING_IN_HELL) {
        checklibs(
            lib  => 'mecab',
            LIBS => $config->{libs},
        );
    }
}

sub define_symbols
{
    my $config = shift;
    my @define;

    if ($RUNNING_IN_HELL) { # save us, the Win32 puppies
        # XXX - Note to self: 
        #  (1) first there was the need to to protect the symbol value
        #      from being garbled by the shell
        #  (2) then the Redmond camp apparently decided that they don't like
        #      my quoting.
        #  (3) So charsbar provided this patch.
        @define = (
            qq(-DTEXT_MECAB_ENCODING=\\"$config->{encoding}\\"),
            qq(-DTEXT_MECAB_CONFIG=\\"$config->{config}\\"),
        );
    } else {
        @define = (
            "-DTEXT_MECAB_ENCODING='\"$config->{encoding}\"'",
            "-DTEXT_MECAB_CONFIG='\"$config->{config}\"'",
        );
    }

    if ($config->{debugging}) {
        push @define, "-DTEXT_MECAB_DEBUG=1";
    }
    $config->{define} = \@define;
}

## Legacy code.
##
## When the time comes, this will be deleted
## sub prepare_makefile
## {
##     # Hack. I don't like the layout where .xs files are on the top level.
##     link("lib/Text/MeCab.xs", "MeCab.xs");
## 
##     # if no inc directory is found, I'm being executed via the author.
##     # I'm going to create inc, and add Devel::CheckLib there
##     if (! -d './inc' and ! $RUNNING_IN_HELL) {
##         mkdir('inc') or die "Could not make inc directory: $!";
##         mkdir('inc/Devel') or die "Could not make inc/Devel directory: $!";
##         require Devel::CheckLib;
## 
##         link($INC{'Devel/CheckLib.pm'}, 'inc/Devel/CheckLib.pm') or
##             die "Failed to copy Devel::CheckLib: $!";
##     }
## 
## 
##     my $config = run_probes();
##     check_lib($config);
##     define_symbols($config);
##     extract_constants($config);
## 
##     # XXX For debug
##     # use Data::Dumper;
##     # print Dumper($config);
##     my %INFO = (
##         ABSTRACT     => 'Alternative Interface To libmecab',
##         AUTHOR       => 'Daisuke Maki <daisuke@endeworks.jp>',
##         CCFLAGS      => $config->{cflags},
##         DEFINE       => join( " ", @{ $config->{define} } ),
##         DISTNAME     => 'Text-MeCab',
##         INSTALLDIRS  => 'site',
##         LIBS         => $config->{libs},
##         LICENSE      => 'perl',
##         NAME         => 'Text::MeCab',
##         OBJECT       => '$(O_FILES)',
##         PREREQ_PM    => {
##             'Class::Accessor::Fast' => 0,
##             'Encode'                => 0,
##             'Exporter'              => 0,
##             'File::Spec'            => 0,
##             'Test::More'            => 0,
##             'Path::Class'           => 0,
##         },
##         VERSION_FROM => 'lib/Text/MeCab.pm',
##         clean        => {
##             FILES => 'lib/typemap MeCab.xs'
##         },
##         test         => {
##             TESTS    => 't/*.t t/*/*.t'
##         }
##     );
##     $INFO{OPTIMIZE} = '-g' if $config->{debugging};
## 
##     WriteMakefile(%INFO);
## }

