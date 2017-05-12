# $Id: Trivium.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Trivium

=head1 DESCRIPTION

WebService::IMDB::Trivium isa L<WebService::IMDB::DateText>.

=cut

package WebService::IMDB::Trivium;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::DateText);

__PACKAGE__->mk_accessors(qw(
    spoiler
));

=head1 METHODS

=head2 spoiler

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;
    my $spoiler = shift;

    my $self = WebService::IMDB::DateText->_new($ws, $data);

    bless $self, $class;

    if (defined $spoiler) { $self->spoiler($spoiler); }

    return $self;

}

1;
