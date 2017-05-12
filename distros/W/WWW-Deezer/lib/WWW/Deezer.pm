package WWW::Deezer;

use strict;
use warnings;

use Carp();
use LWP::UserAgent;
use JSON;
use URI::Escape;

use WWW::Deezer::SearchResult;
use WWW::Deezer::Artist;

our $VERSION = '0.03';
our $API_VERSION = '2.0';

sub new {
    my ($class, $params) = @_;

#   Carp::croak("Options to WWW::Deezer should be in a hash reference")
#       if ref($params) ne ref {};

    my $self = {
        baseurl => "http://api.deezer.com/$API_VERSION/",
        ua      => LWP::UserAgent->new,
        json    => JSON->new->allow_nonref,
        debug   => 0,
    };

    $self->{ua}->agent("WWW::Deezer v".$VERSION);

    bless $self => $class;
    return $self;
}

sub album {
    my ($self, $p) = @_;
    my $uri = 'album';

    my $id = _is_hashref ($p) ? int ($p->{id}) : int ($p);

    my $res = $self->_get_url ({
        url     => $uri.'/'.$id,
        method  => 'GET'
    });

    $res = $self->{json}->decode ($res) unless _is_hashref ($res);
    $res->{deezer_obj} = $self;

    return WWW::Deezer::Album->new($res);
}

sub artist {
    my ($self, $p) = @_;
    my $uri = 'artist';

    my $id = _is_hashref ($p) ? int ($p->{id}) : int ($p);
    
    my $res = $self->_get_url ({
        url     => $uri.'/'.$id,
        method  => 'GET'
    });

    $res = $self->{json}->decode ($res) unless _is_hashref ($res);
    $res->{deezer_obj} = $self;
  
    return WWW::Deezer::Artist->new($res);
}

sub search { # http://developers.deezer.com/api/search
    # 2DO: limits? paging?
    my ($self, $p) = @_;

    my $uri = 'search';
    my ($q, $order, $index);

    if (_is_hashref ($p)) {
        $q = _to_string( $p->{q} );
        $order = $p->{order} || 'RANKING';
        $index = $p->{index} || 0;
    }
    else {
        $q = $p;
        $order = 'RANKING';
        $index = 0;
    }

    $q = uri_escape($q);

    my $res = $self->_get_url ({
        url     => $uri."?q=$q&order=$order&index=$index",
        method  => 'GET'
    });

    $res = $self->{json}->decode ($res) unless _is_hashref ($res);
    $res->{deezer_obj} = $self;

    return WWW::Deezer::SearchResult->new($res);
}

### private methods ###

sub _get_url {
    my ($self, $p) = @_;
    warn ('sending http request') if ($self->{debug});
    my $url = $p->{url} || return $self->_error('No URL given');
    my $method = $p->{method} || 'GET';

    my $request = HTTP::Request->new(
        $method => $self->{baseurl}.$url,
    );

    my $res = $self->{ua}->request( $request );
    
    return $res->is_success ? $res->content : $self->_error($res->status_line);
}

sub _error {
    my ($self, $text) = @_;
    return {error => $text};
}

### functions ###

sub _is_hashref {
    my $x = shift;
    return ref $x && ref $x eq ref {};
}

sub _to_string {
    my ($q) = @_;
	return $q unless ref($q);

    if (_is_hashref($q)) {
        my $res = join(" ", map { "$_:\"$q->{$_}\"" } keys %$q);
        return $res;
    }

    return '';
}

1;
__END__
=head1 NAME

WWW::Deezer - Perl interface to Deezer API

=head1 SYNOPSIS

  use WWW::Deezer;
  
  my $deezer = WWW::Deezer->new();
  my $rs1 = $deezer->search ('Spinal Tap');
  my $rs2 = $deezer->search ({ q => 'Antonio Vivaldi Concerto No. 4', order => 'RATING_DESC' });
  my $rs3 = $deezer->search ({ q => { artist => 'Metallica', album => 'Garage Inc.' } });

  while (my $record = $rs1->next) {
      $album_obj = $record->album;
      $artist = $record->artist;
      $name = $artist->name;

      warn ("$name has a radio channel!") if $artist->radio;

      $fans_count = $artist->nb_fan;
  }

  my $top_record = $rs2->first;
  warn $top_record->id;

=head1 DESCRIPTION

Module allows to interact with Deezer server via it's official API. Description to be added soon.


=head2 EXPORT

None by default.


=head1 SEE ALSO

Oficial Deezer API documentation:
L<http://developers.deezer.com/api>

=head1 AUTHOR

Michael Katasonov, E<lt>kabanoid@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Mike Katasonov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
