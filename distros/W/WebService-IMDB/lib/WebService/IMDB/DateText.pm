# $Id: DateText.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::DateText

=cut

package WebService::IMDB::DateText;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name WebService::IMDB::Title);

use WebService::IMDB::Date;

__PACKAGE__->mk_accessors(qw(
    date
    text
));


=head1 METHODS

=head2 date

=head2 text

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    if (exists $data->{'date'}) { $self->date(WebService::IMDB::Date->_new($ws, $data->{'date'})); }
    $self->text($data->{'text'});

    return $self;
}

1;
