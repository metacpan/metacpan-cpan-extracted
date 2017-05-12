### Makefile.PL --- Build the head-r package  -*- Perl -*-

## FIXME: just don't know how portable this code is
require 5.010;
use strict;
use English qw (-no_match_vars);
use ExtUtils::MakeMaker;

if (open (my $fh, "-|", $EXECUTABLE_NAME, "check-lo")) {
    open (my $l, ">", "+localhost")
        or die ("+localhost: ", $!);
    $l->print (<$fh>);
} else {
    unlink ("+localhost");
}

WriteMakefile (
    NAME => 'head-r',
    VERSION_FROM => 'lib/App/HeadR.pm',
    # ABSTRACT_FROM => 'lib/App/HeadR.pm',
    ## FIXME: insists on a hyphen in the NAME section
    ABSTRACT => 'Recurse through Web pages and issue HEAD requests',
    AUTHOR => 'Ivan Shmakov <oneingray@gmail.com>',
    LICENSE => "gpl_3",
    ## FIXME: just don't know how portable this code is
    MIN_PERL_VERSION => 5.010,
    EXE_FILES   => [ 'head-r' ],
    META_MERGE  => {
        "meta-spec" => {
            "version"   => 2
        },
        "resources" => {
            repository => {
                type    => 'git',
                url     => 'http://am-1.org/~ivan/archives/git/head-r-2013.git/',
                web     => 'http://am-1.org/~ivan/archives/git/gitweb.cgi?p=head-r-2013.git',
            }
        }
    },
    PREREQ_PM => {
        "Carp"      => 1.11,
        "common::sense" => 3.3,
        "English"   => 1.04,
        "Getopt::Long"  => 2.38,
        "HTML::TreeBuilder" => 3.23,
        "IO::Uncompress::AnyUncompress" => 2.020,
        "LWP::UserAgent"    => 5.835,
        "List::Util"    => 1.21,
        "Scalar::Util"  => 1.21,
        "URI"       => 1.54
    }
);

## Local variables:
## indent-tabs-mode: nil
## End:
### Makefile.PL ends here
