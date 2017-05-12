#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

use strict;
$^W = 1;

use ExtUtils::Manifest;
use ExtUtils::MakeMaker qw( prompt WriteMakefile );
#use Data::Dumper;
use IO::File;
use Getopt::Long;

my %opts;
GetOptions( \%opts, 'no-prompts' );

# ------------------------------------------------------------------------
# Discover the home of ePortal
our $EPORTAL_HOME = $ENV{EPORTAL_HOME} || '/opt/ePortal';
for my $i(0 .. $#ARGV) {
    if ($ARGV[$i] =~ /HOME=(.*)/) {
        $EPORTAL_HOME = $1;
        delete $ARGV[$i];
    }
}
unless ( $opts{'no-prompts'} ) {
    $EPORTAL_HOME = prompt('Where to install ePortal WEB files', $EPORTAL_HOME);
}

# ------------------------------------------------------------------------
#
our %OPTIONS = (
    NAME        => 'ePortal',
    AUTHOR      => 'Sergey Rusakov <rusakov_sa@users.sourceforge.net>',
    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean       => { FILES => 'config.cache' },
    DIR => [],
#   INST_HTMLLIBDIR => 'comp_root/manual',
    PREREQ_PM       => {
        'Apache::Request'       => 0,
        'CGI'                   => 2.81,
        'Data::Dumper'          => 0,
        'Date::Calc'            => 5.0,
        'DBD::mysql'            => 0,
        'DBI'                   => 1.28,
        'Digest::MD5'           => 2.13,
        'Error'                 => 0,
        'HTML::Mason'           => 1.16,
        'Image::Size'           => 2.99,
        'List::Util'            => 0,
        'Mail::Sendmail'        => 0.78,
        'MIME::Base64'          => 0,
        'Net::LDAP'             => 0,
        'Params::Validate'      => 0.24,
        'Storable'              => 0,
        'Text::Wrap'            => 0,
        'Unicode::Map8'         => 0,
        'Unicode::String'       => 0,
        }, # e.g., Module::Name => 0 or 1.1
);

# ------------------------------------------------------------------------
# Known targets
our %KNOWN_TARGETS = (
    ePortal => {
        VERSION_FROM => 'lib/ePortal/Server.pm',
        ABSTRACT => 'Company wide WEB organizer (electronic portal)',
    },
    OffPhones => {
        VERSION_FROM => 'lib/ePortal/App/OffPhones.pm',
        ABSTRACT => 'ePortal application: Phone directory',
    },
    MsgForum => {
        VERSION_FROM => 'lib/ePortal/App/MsgForum.pm',
        ABSTRACT => 'ePortal application: Discussion forums',
    },
    CompInventory => {
        VERSION_FROM => 'lib/ePortal/App/CompInventory.pm',
        ABSTRACT => 'ePortal application: Computer inventory',
    },
    Diskoteka => {
        VERSION_FROM => 'lib/ePortal/App/Diskoteka.pm',
        ABSTRACT => 'ePortal application: Software archive',
    },
    Organizer => {
        VERSION_FROM => 'lib/ePortal/App/Organizer.pm',
        ABSTRACT => 'ePortal application: Personal Organizer',
    },
    SquidAcnt => {
        VERSION_FROM => 'lib/ePortal/App/SquidAcnt.pm',
        ABSTRACT => 'ePortal application: Squid accounting software',
    },
);


our $target;
if (my $infh = new IO::File "target") {
    $target = <$infh>;
    chomp($target);
}

if (! $target or !exists $KNOWN_TARGETS{$target}) {
    die "Unknown target [$target]. Bad distribution...\n";
}

# ------------------------------------------------------------------------
# Command line parsing complete
print "Using target: $target\n";
print "Using ePortal home dir: $EPORTAL_HOME\n";


# ------------------------------------------------------------------------
# Create Makefile
#
$OPTIONS{NAME} = "ePortal-$target" if $target ne 'ePortal';
foreach (keys %{ $KNOWN_TARGETS{$target} }) {
    $OPTIONS{$_} = $KNOWN_TARGETS{$target}{$_};
}
WriteMakefile( %OPTIONS);



# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
package MY;

sub constants {
    my $self = shift;

    my $result = $self->SUPER::constants(@_);
    $result .= "\nEPORTAL_HOME = $EPORTAL_HOME\n\n";
    $result;
}


sub top_targets {
   my $self = shift;
   my $result = $self->SUPER::top_targets(@_);

   # remove htmlifypods from ALL: target
   $result =~ s/^(all\s.*)htmlifypods(.*)$/$1$2/m;

   $result;
}


sub install {
    my $self = shift;
    my $result = $self->SUPER::install(@_);

    # Add target to 'install ::'
    $result =~ s/^install\s+:+.*$/$& eportal_home_install/im;

    $result .= "\neportal_home_install ::\n";

    # --------------------------------------------------------------------
    # INSTALL with -MExtUtils::Install
    #
    $result .= "\t\@\$(MKPATH) \$(EPORTAL_HOME)\n";
    $result .= "\t" . '$(PERL) "-I$(PERL_LIB)" -MExtUtils::Install \\' . "\n";
    $result .= "\t" . '-e "install({bin => \'$(EPORTAL_HOME)/bin\', comp_root => \'$(EPORTAL_HOME)/comp_root\', images => \'$(EPORTAL_HOME)/images\', samples => \'$(EPORTAL_HOME)/samples\'}, 1)"' . "\n";

    $result .= "\n";
    $result;
}


