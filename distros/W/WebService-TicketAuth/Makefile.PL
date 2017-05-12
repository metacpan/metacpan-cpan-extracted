use ExtUtils::MakeMaker;
require 5.006000;
use strict;

use Config;

my %args = (
            DESTDIR   => undef
            );

my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

my %opts = (
            'NAME'	   => 'WebService::TicketAuth',
            'VERSION_FROM' => 'lib/WebService/TicketAuth.pm',
	    'EXE_FILES'    => [],
            'PREREQ_PM' => {
                'Digest::MD5'      => 0,
                },
            'AUTHOR'       => 'Bryce Harrington <bryce@osdl.org>',
            'ABSTRACT_FROM'=> 'lib/WebService/TicketAuth.pm',
);

# This puts us in the site_perl directory, not dependant on any version
# of perl.
if (defined($Config{'sitelib_stem'}) && $Config{'sitelib_stem'} ne "") {
    print "stem is: $Config{'sitelib_stem'}\n";
    $opts{'INSTALLSITELIB'} = "";
    $opts{'INSTALLSITELIB'} = $args{'DESTDIR'}
                if ($] >= 5.008 ||
                    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
    $opts{'INSTALLSITELIB'} .= $Config{'sitelib_stem'};
}

WriteMakefile( %opts );

# vi:set ai ts=4 sw=4 expandtab:
