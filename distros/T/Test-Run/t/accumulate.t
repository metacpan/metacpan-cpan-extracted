use strict;
use warnings;

use Test::More tests => 2;

package Base1;

use Moose;

extends("Test::Run::Base");

sub people
{
    my $self = shift;

    return [(ref($self) eq "" ? () : ($self->{'p1'})), "Sophie", "Jack"];
}

package Son1;

our @ISA = (qw(Base1));

sub people
{
    return ["Gabor", "Offer", "Shlomo"];
}

package Son2;

our @ISA = (qw(Base1));

sub people
{
    return ["Esther", "Xerces", "Mordeakhai"];
}

package Grandson1;

our @ISA = (qw(Son1));

sub people
{
    return ["David", "Becky", "Lisa"];
}

package main;

{
    my $grandson = Grandson1->new();

    $grandson->{'p1'} = "Yuval";

    # TEST
    is_deeply(
        $grandson->accum_array(
            {
                method => "people",
            },
        ),
        [qw(David Becky Lisa Gabor Offer Shlomo Yuval Sophie Jack)],
        "First Accum Array (Object)",
    );
}

{
    # TEST
    is_deeply(
        "Grandson1"->accum_array(
            {
                method => "people",
            },
        ),
        [qw(David Becky Lisa Gabor Offer Shlomo Sophie Jack)],
        "Second Accum Array (Class)",
    );
}

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
