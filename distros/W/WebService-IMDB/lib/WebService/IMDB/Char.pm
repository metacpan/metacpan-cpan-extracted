# $Id: Char.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Char

=head1 DESCRIPTION

Returns a L<WebService::IMDB::Name::Stub> if an nconst is available.

=cut

package WebService::IMDB::Char;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::Name);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

use WebService::IMDB::Name::Stub;

__PACKAGE__->mk_accessors(qw(
    char
));


=head1 METHODS

=head2 char

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    if (exists $data->{'nconst'}) { 
	return WebService::IMDB::Name::Stub->_new($ws, $data);
    } else {
	my $self = {};

	bless $self, $class;

	$self->char($data->{'char'});

	return $self;
    }

}

1;
