#!/usr/bin/perl -w
#
# abstract: CGI Test Harness for Test::FIT
# default: Y
#

$VERSION = '0.10';
use strict;

BEGIN {
    my $arg = shift(@ARGV) || '';
    if ($arg eq '--setup') {
        exit(0) if -e 'fit-run.cgi';
        require Config;
        my $sitebin = $Config::Config{sitebin};
        warn "ln -s $sitebin/fit-run.cgi fit-run.cgi\n";
        system "ln -s $sitebin/fit-run.cgi fit-run.cgi";
        exit(0);
    }
}

use lib '.';
use Test::FIT::Harness;
Test::FIT::Harness::run_cgi();

__END__

=head1 NAME

fit-run.cgi - A Test::FIT::Harness cgi script

=head1 SYNOPSIS

    > cd /usr/local/fit/mytest
    > fit-run.cgi --setup

=head1 DESCRIPTION

This little CGI program runs the fixtures in a FIT HTML testing
document. Just hyperlink to this CGI from your HTML testing document.

You can create a symbolic link to the installed version of the program,
by using the following invocation from the command line:

    fit-run.cgi --setup

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
