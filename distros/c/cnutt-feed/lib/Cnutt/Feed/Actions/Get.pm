package Cnutt::Feed::Actions::Get;

use strict;
use warnings;

=head1 NAME

Cnutt::Feed::Actions::Get - Directly put the content of a feed into a mailbox

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

This file is part of cnutt-feed. You should read its documentation.

=cut

use Cnutt::Feed::Mailbox;

=head2 get

Given an url and a mailbox, download the entries and output them as
email messages.

=cut

sub get {
    my ($rconfig, $url, $mb) = @_;

    my $count = Cnutt::Feed::Mailbox->fetch($url, $mb,
                                            $rconfig->{html},
                                            $rconfig->{delete},
                                            $rconfig->{verbose});

    print STDERR "Found $count new entries\n";
}

1;
