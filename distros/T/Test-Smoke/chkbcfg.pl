#! /usr/bin/perl -w
use strict;

# $Id$
use vars qw ( $VERSION );
$VERSION = '0.002';

use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke::Util qw( skip_config );
use Test::Smoke::BuildCFG;

=head1 NAME

chkbcfg.pl - Check the buildconfigfile specified on the commandline

=head1 SYNOPSIS

    $ ./ chkbcfg.pl <buildcfg>

=head1 DESCRIPTION

F<chkbcfg.pl> simply reads and parses the specified build
configurations file and shows which configurations are actually smoked
and which are skipped.

=cut

my $myusage = "Usage: $0 <buildcfg>";
my $cfg_nm = shift or do_pod2usage(verbose => 1, myusage => $myusage );

my $cfgs = Test::Smoke::BuildCFG->new( $cfg_nm );

my( $skips, $smokes ) = ( 0, 0 );
for my $cfg ( $cfgs->configurations ) {
    if ( skip_config( $cfg ) ) {
        print " skip: '$cfg'\n";
        $skips++;
    } else {
        print "smoke: '$cfg'\n";
        $smokes++;
    }
}
my $total = $skips + $smokes;
print "Smoke $smokes; skip $skips (total $total)\n";

=head1 SEE ALSO

L<Test::Smoke::BuildCFG>, L<Test::Smoke::Util>

=head1 AUTHOR

Abe Timmerman C<< <abeltje@cpan.org> >>

=head1 COPYRIGHT + LICENSE

Copyright MMV Abe Timmerman, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
