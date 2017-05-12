# Test case framework for bin::flagnames

package t::TestHelp;

use 5.008007;
use strict;
use warnings;

our $VERSION = 0.01;

sub new
{
    my $class = shift;
    my ($expect) = @_;
    if ( ref($expect) ne 'HASH' )
    {
        $expect = {@_};
    }

    bless $expect,$class;
}

sub expectvalue
{
    my $expect = shift;
    my $expResult = 0;
    foreach my $key (@_)
        { $expResult |= $expect->{$key} if exists $expect->{$key} }
    $expResult;
}

1;