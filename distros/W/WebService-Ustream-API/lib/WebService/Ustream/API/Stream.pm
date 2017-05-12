package WebService::Ustream::API::Stream;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use XML::Simple;

use version; our $VERSION = '0.03';

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(key ua));

sub new {
        my($class, @args) = @_;

	my $self = $class->SUPER::new(@args);
	if(!$self->key){
		croak 'key is required';
	}
	if(!$self->ua){
		$self->ua( LWP::UserAgent->new );
	}
	return $self;
}

sub recent {
        my($self) = @_;

	my $uri = "http://api.ustream.tv/xml/stream/all/getRecent?key=".$self->key;

	my $result = $self->_retrieve($uri);;
        return $result;
}

sub most_viewers {
	my($self) = @_;

	my $uri = "http://api.ustream.tv/xml/stream/all/getMostViewers?key=".$self->key;
        
	my $result = $self->_retrieve($uri);
	return $result;
}

sub random {
	my($self) = @_;

        my $uri = "http://api.ustream.tv/xml/stream/all/getRandom?key=".$self->key;

        my $result = $self->_retrieve($uri);
        return $result;
}

sub all_new {
	my($self) = @_;

        my $uri = "http://api.ustream.tv/xml/stream/all/getAllNew?key=".$self->key;

	my $result = $self->_retrieve($uri);
        return $result;
}

sub _retrieve {
	my($self,$uri) = @_;

	my $res = $self->ua->get($uri);
        if( !$res->is_success ) {
                carp $res->status_line;
                return;
        }

        my $content;
        eval{$content = XMLin($res->content)};
        croak('Failed reading user information : ' . $@) if $@;
        if( !$content ) {
                carp 'invalid XML';
                return;
        }

        if( index($content->{error},'ERR') >= 0 ) {
                carp(
                        sprintf "error: %s\ndescription: %s",
                        $content->{error},
                        $content->{msg}
                );
                return;
        }
	return $content->{results};
};

1;
__END__

=head1 NAME

WebService::Ustream::API::Stream - Perl interface to Ustream Stream API Service

=head1 SYNOPSIS

  use WebService::Ustream::API::Stream;
  
  $ust = WebService::Ustream::API::Stream->new( { key => YOUR_KEY } );
  my $ret = $ust->recent(); 

  print $ret->{array}->{id};
  print $ret->{array}->{userId};
  print $ret->{array}->{userName};
  print $ret->{array}->{title};
  print $ret->{array}->{description};
  print $ret->{array}->{streamStartedAt};
  print $ret->{array}->{url};
  print $ret->{array}->{embedTag};

  my $ret = $ust->most_viewers();
  
  print $ret->{array}->{id};
  ..
  . same properties accessible as first example
  ..
  print $ret->{array}->{embedTag};

  my $ret = $ust->random();
  
  print $ret->{array}->{id};
  ..
  . same properties accessible as first example
  ..
  print $ret->{array}->{embedTag};

  my $ret = $ust->all_new();

  print $ret->{array}->{0}->{id};
  ..
  . same properties accessible as first example
  ..
  print $ret->{array}->{0}->{embedTag};


=head1 DESCRIPTION

WebService::Ustream::API::User is a simple interface to Ustream's user information.

=head1 METHODS

=item new(\%fields)

$ust = WebService::Ustream::API::User->new( { key => YOUR_KEY } );

Creates an instace of WebService::Ustream::API::User.
KEY is required when you call Ustream API.

=item get([username or userid])

  my $ret = $ust->get('koba206');
  my $ret = $ust->get('19185'); #19185 is koba206's userid 

retrieve user account information

=item list_channels([username or userid])

 my $ret = $ust->list_channels('koba206');
 
retrieve all the channels belonging to a user

=item list_videos([username or userid])

  my $ret = $ust->list_videos('spacevidcast');

retrieve all the videos belonging to the user specified

=item get_comments([username or userid])

  my $ret = $ust->get_comments('koba206');

returns any comments for the user profile specified by username or userid

=head1 SEE ALSO

L<URI::Fetch>
http://developer.ustream.tv/

=head1 AUTHOR

Takeshi Kobayashi, E<lt>koba206@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Takeshi Kobayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
