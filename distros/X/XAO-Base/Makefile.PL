#!/usr/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

# Version needs to be known here, but it's also convenient to have it in
# XAO::Base to make it possible to check it in "require XAO::Base" for
# instance.
#
my $version;
open(F,'<Base.pm') || die "Can't open Base.pm: $!\n";
while(<F>) {
    if(/\$VERSION\s*=\s*'?([\d\.]+)'?\s*;/) {
        $version=$1;
        last;
    }
}
close(F);

$version ||
    die "Unable to find version in Base.pm\n";

# Trying to find out current configuration. If it is saved in file -
# retrieving and asking otherwise.
#
my ($homedir,$config_version);
my $ask=0;
if(open(F,"<.config")) {
    while(<F>) {
        next unless /^(\w+)\s+(.*?)[\s\r\n]+$/s;
        my ($cmd,$value)=($1,$2);
        if($cmd eq 'homedir') {
            $homedir=$value;
        }
        elsif($cmd eq 'version') {
            $config_version=$value;
        }
    }
    close(F);
}
$ask=1 unless $homedir;
while($ask) {
    my $notes='';
    if(!$homedir) {
        eval { require XAO::Base };
        if(!$@) {
            $homedir=$XAO::Base::homedir || $XAO::Base::homedir; # anti-warn :)
            my $version=$XAO::Base::VERSION;
            $notes=<<EOT;

The default choice is where the earlier version ($version) of XAO was installed.
It is recommended to use the same directory for all installations on the
same computer - otherwise you will need to move your projects to the new
directory.
EOT
        }
    }

    # Externally set variable
    #
    if(!$homedir) {
        $homedir=$ENV{'XAO_BASE_DIRECTORY'};
    }

    # In cpanm/Carton/docker it's easier to pre-create a directory as a
    # hint.
    #
    if(!$homedir) {
        my @dirs=qw(/opt/xao /usr/local/xao);
        my @dirh=$ENV{'HOME'} ? ($ENV{'HOME'}.'/perl5/xao',$ENV{'HOME'}.'/xao') : ();
        my @d=grep { -d $_ } @dirh,@dirs;
        $homedir=$d[0] || $dirs[0];
    }

    if($ENV{'PERL_MM_USE_DEFAULT'}) {
        last;
    }
    else {
        print <<EOT;
XAO::Base needs a directory for project specific configuration values,
objects, templates etc.
$notes
EOT
        my $hd=prompt('Directory name ?',$homedir);
        $hd=~s/^\s*(.*?)\s*$/$1/;
        $hd=~s/^~\//$ENV{HOME}\//;
        if($hd && substr($hd,0,1) ne '/') {
            print "\nBad path ($hd)!\n\n";
            next;
        }
        $homedir=$hd if $hd;

        print <<EOT;

The following directory structure will be used:

    $homedir/handlers  - web server handlers
    $homedir/projects  - projects root directory
    $homedir/templates - default templates

EOT
        my $answer=prompt('Is that OK?','y');
        last if lc(substr($answer,0,1)) eq 'y';
    }
}

if(!$config_version || $config_version ne $version) {
    open(F,"> .config") || die "Cannot write .config: $!\n";
    print F "homedir $homedir\n";
    print F "version $version\n";
    close(F);
    print "\nConfiguration saved into .config\n\n";
}

WriteMakefile(
    'NAME'          => 'XAO::Base',
    'AUTHOR'        => 'Andrew Maltsev, https://ejelta.com/xao/',
    'ABSTRACT'      => 'Base support modules for the XAO Suite',
    'VERSION_FROM'  => 'Base.pm',
    'PREREQ_PM'     => {
        'Clone'             => 0.39,
        'Digest::SHA'       => 5.47,
        'Encode'            => 2.42,
        'Error'             => 0.17,
        'File::Path'        => 2.09,
        'JSON'              => 2.94,
        'Storable'          => 2.53,
    },
    'PL_FILES'      => {
        'BaseConfig.PL'     => '$(INST_LIB)/XAO/BaseConfig.pm',
    },
    TEST_REQUIRES   => {
        'Test::Harness'     => '3.35',
        'Test::Unit::Lite'  => '0.1202',
    },
    'MIN_PERL_VERSION'  => '5.10.1',
);

sub MY::postamble
{ <<EOT;

all::
\t\@if [ -d .git ]; then (\\
\t\techo "https://github.com/amaltsev/XAO-Base";\\
\t\techo "------------------------------------";\\
\t\techo "";\\
\t\tgit log -n 10 --no-color 2>/dev/null;\\
\t\techo "") > CHANGES; fi

config:: README

README: Base.pm
\tpod2text Base.pm > README

install::
\t[ -d $homedir ] || mkdir -p $homedir && chmod 755 $homedir

clean::
\trm -f t/*.pl t/*.xt
EOT
}
