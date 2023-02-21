package main;

use 5.008;

use strict;
use warnings;

use Config;
use Test::More 0.88;	# Because of done_testing();
use Test::Pod::LinkCheck::Lite;

my $t = Test::Pod::LinkCheck::Lite->new();

$t->pod_file_ok( \<<'EOD' );

=pod

And a link to a section which has an C<< XE<lt>E<gt> >> formatting code
that must be ignored: L<perlpod/Ordinary Paragraph>.

=cut

EOD

foreach my $dir ( map { $Config{$_} } qw{ archlibexp privlibexp } ) {
    foreach my $sub ( qw{ pods pod } ) {
	my $path = "$dir/$sub/perlpod.pod";
	-e $path
	    or next;

	$t->pod_file_ok( $path );

	done_testing;

	exit;

    }
}

diag 'Unable to find perldoc.pod';

done_testing;

1;

# ex: set textwidth=72 :
