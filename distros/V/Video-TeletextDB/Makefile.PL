use 5.006001;
use strict;
use warnings;
use ExtUtils::MakeMaker qw(WriteMakefile prompt);
use Config qw(%Config);

# Allows to suppress all program installation with -n (library only)
use Getopt::Std;
our $opt_n;
getopts("n") || die "Usage: $0 [-n]\n";

my @programs_to_install;

unless ($opt_n) {
    print <<EOT

This package comes with some sample programs that I can try
to install in $Config{installscript}.

   Note that you can avoid these questions by passing
   the '-n' option to 'Makefile.PL'.

EOT
;
    push @programs_to_install, "bin/TeleCollect" if
        prompt("Install TeleCollect, a teletext collector for linux ?", "y") =~ /^y/i;
    push @programs_to_install, "fcgi-bin/TeleFcgi" if
        prompt("Install TeleFcgi, a simple FastCGI program to view teletext ?", "y") =~ /^y/i;
}

WriteMakefile
    (NAME       	=> 'Video::TeletextDB',
     VERSION_FROM	=> 'lib/Video/TeletextDB.pm', # finds $VERSION
     PREREQ_PM  => {
         "DB_File"		=> 1.75,
         "Exporter::Tidy"	=> 0.05,
         "Test::More"		=> 0.11,	# For the tests only
         "HTML::Entities"	=> 0.00,	# Only needed for html output
     },
     (AUTHOR   => 'Ton Hospel <Video-TeletextDB@ton.iguana.be>'),
     EXE_FILES  => \@programs_to_install,
);
