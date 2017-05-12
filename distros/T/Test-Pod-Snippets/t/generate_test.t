use strict;
use warnings;

use Test::More tests => 6;                      # last test to print

my $pod = join '', <DATA>;

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new;

ok $tps->generate_test( pod => $pod );
ok $tps->generate_test( file => 't/generate_test.t' );
ok $tps->generate_test( module => 'Test::Pod::Snippets' );
{
    open my $fh, '<', 't/generate_test.t';
    ok $tps->generate_test( fh => $fh );
}

ok $tps->generate_test( pod => $pod, standalone => 1 );

ok $tps->generate_test( pod => $pod, testgroup => 1 );

__DATA__
yadah yadah

=pod

=head1 Stuff

    $x = 3;

=head1 METHODS

=head2 foo

=head2 bar



END_POD
