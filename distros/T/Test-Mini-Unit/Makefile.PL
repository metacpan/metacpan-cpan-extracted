use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;
use ExtUtils::Manifest  1.56;

my $SKIP_FILES = <<SKIP;
SKIP

my %WriteMakefileArgs = (
    'NAME'       => 'Test::Mini::Unit',
    'ABSTRACT'   => 'Declarative Sugar for Test::Mini',
    'VERSION'    => 'v1.0.3',
    'AUTHOR'     => 'Pieter van de Bruggen <pvande@cpan.org>',
    'LICENSE'    => 'perl',
    'META_MERGE' => {
        'resources' => {
            'homepage'   => 'http://github.com/pvande/Test-Mini-Unit',
            'repository' => 'git://github.com/pvande/Test-Mini-Unit.git',
            'bugtracker' => 'http://github.com/pvande/Test-Mini-Unit/issues',
        },
    },
    'PREREQ_PM' => {
        'version'        => '0.77',
        'Test::Mini'     => 'v1.1.3',
        'Devel::Declare' => 'v0.6.0',
        'Sub::Name'      => '0.05',
    },
    'BUILD_REQUIRES' => { },
    'CONFIGURE_REQUIRES' => {
         'ExtUtils::MakeMaker' => '6.31',
         'ExtUtils::Manifest'  => '1.56',
    },
#   'DIST_REQUIRES' => {
#       'ShipIt'                 => '0.55',
#   },
    'test' => {
        'TESTS' => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t',
    },
    'dist' => {
        'PREOP'  => 'RUBYLIB=:../yard-perl-plugin/lib:../yard-pod-plugin/lib yard -e yard-perl-plugin.rb -e yard-pod-plugin.rb',
        'POSTOP' => 'make realclean; rm MANIFEST',
    },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.56) }) {
    my $REQS = delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM}->{$_} = $REQS->{$_} for keys %$REQS;
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
    my $REQS = delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM}->{$_} = $REQS->{$_} for keys %$REQS;
}

(my $DISTNAME = $WriteMakefileArgs{NAME}) =~ s/::/-/g;
my $DISTDIR = "$DISTNAME-$WriteMakefileArgs{VERSION}";
my $LIBDIR = "$DISTDIR/lib";
$WriteMakefileArgs{dist}->{PREOP} .= " -o $LIBDIR; ";
$WriteMakefileArgs{dist}->{PREOP} .= "(cd $DISTDIR; find lib -name '*.pod' -type f >> MANIFEST)";

# Create a MANIFEST.SKIP file.
open(GITIGNORE, '<.gitignore');
open(SKIP, '>MANIFEST.SKIP');
print SKIP "#!include_default\n";
print SKIP "MANIFEST.SKIP.*\n";
print SKIP "^$DISTNAME.*\n";
print SKIP "^\\..*\n";
print SKIP <GITIGNORE>;
print SKIP $SKIP_FILES;
close SKIP;
close GITIGNORE;

# Create a new MANIFEST.
ExtUtils::Manifest::mkmanifest();

# Write the new Makefile.
WriteMakefile(%WriteMakefileArgs);

# Cleanup the MANIFEST.SKIP files.
unlink glob 'MANIFEST.{,SKIP}*';
