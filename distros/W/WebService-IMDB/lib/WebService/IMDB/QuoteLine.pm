# $Id: QuoteLine.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::QuoteLine

=cut

package WebService::IMDB::QuoteLine;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

use WebService::IMDB::Char;

__PACKAGE__->mk_accessors(qw(
    chars
    quote
    stage
));


=head1 METHODS

=head2 chars

=head2 quote

=head2 stage

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    my $self = {};

    bless $self, $class;

    if (exists $data->{'chars'}) {
	# TODO: Some entries don't have an nconst.  Need to decide whether to handle these differently.
	$self->chars( [ map { WebService::IMDB::Char->_new($ws, $_) } @{$data->{'chars'}} ] );
    } else {
	$self->chars([]);
    }
    if (exists $data->{'quote'}) { $self->quote($data->{'quote'}); }
    if (exists $data->{'stage'}) { $self->stage($data->{'stage'}); }

    return $self;
}

1;
