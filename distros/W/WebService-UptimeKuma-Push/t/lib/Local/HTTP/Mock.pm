# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2026 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

package Local::HTTP::Mock;

our $VERSION = '0.001';

sub new {
    my ( $class, @responses ) = @_;

    return bless { _responses => [@responses], _urls => [] }, $class;
}

sub get {
    my ( $self, $url ) = @_;

    push @{ $self->{_urls} }, $url;

    my $response = shift @{ $self->{_responses} };
    die "No response left in mock\n" if !defined $response;
    die $response->{die}             if exists $response->{die};    ## no critic (ErrorHandling::RequireCarping)

    return $response;
}

sub urls {
    my ($self) = @_;

    return @{ $self->{_urls} };
}

sub ok {
    return { success => 1, status => 200, reason => 'OK', content => '{"ok":true}' };
}

sub not_found {
    return { success => q{}, status => 404, reason => 'Not Found', content => '{"ok":false,"msg":"Monitor not found or not active."}' };
}

1;
