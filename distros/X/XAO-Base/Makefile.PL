#!/usr/bin/perl -w
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
    $homedir='/usr/local/xao' unless $homedir;
    print <<EOT;
XAO::Base needs a directory for project specific configuration values,
objects, templates etc.$notes

EOT
    print "Directory name ? [$homedir] ";
    (my $hd=<STDIN>) =~ s/[\s\n\r]//sg;
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
    print "Is that OK? [Y/n] ";
    (my $answer=<STDIN>) =~ s/[\s\r\n]//sg;
    last unless lc(substr($answer,0,1)) eq 'n';
}

if(!$config_version || $config_version ne $version) {
    open(F,"> .config") || die "Cannot write .config: $!\n";
    print F "homedir $homedir\n";
    print F "version $version\n";
    close(F);
    print "\nConfiguration saved into .config\n\n";
}

##
# This rather stupid workaround is here because for some reason
# MakeMaker excludes /Config/ files from MAN3PODS
#
my %man3pods;
foreach my $n (keys %{ExtUtils::Manifest::maniread()}) {
    next unless $n =~ '^(\w+)\.(pm|pod)$' ||
                $n =~ '^lib/XAO/(.*)\.(pm|pod)$';
    my $man=$1;
    $man=~s/\/+/::/g;
    $man='XAO::' . $man;

    open(F,$n) || die "Can't read $n: $!";
    my $pod=0;
    while(<F>) {
        if(/^=(\w+)/) {
            $pod=1;
            last;
        }
    }
    $pod || die "$n ($man) does not have documentation";

    $man3pods{$n}='$(INST_MAN3DIR)/' . $man . '.3';
}

WriteMakefile(
    'NAME'          => 'XAO::Base',
    'AUTHOR'        => 'Andrew Maltsev, http://ejelta.com/xao/',
    'ABSTRACT'      => 'Base support modules for the XAO Suite',
    'VERSION_FROM'  => 'Base.pm',
    'PREREQ_PM'     => {
        'Error'         => '0.13',
        'Test::Unit'    => '0.14',
        'Clone'         => '0.34',
        'Storable'      => '2.39',
    },
    'PL_FILES'      => {
        'BaseConfig.PL' => '$(INST_LIB)/XAO/BaseConfig.pm',
    },
    'MAN3PODS'      => \%man3pods,
    'MIN_PERL_VERSION'  => '5.10.0',
);

sub MY::postamble
{ <<EOT;

config::	README

README: Base.pm
	pod2text Base.pm > README

install::
	[ -d $homedir ] || mkdir $homedir && chmod 755 $homedir

EOT
}
