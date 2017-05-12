package WWW::Twittervision;

use 5.008000;
use strict;
use warnings;
use Carp;
use LWP;
use JSON;
use URI::Escape;

use vars qw($VERSION $DEBUG $TVURL);

our $VERSION = '0.02';
$TVURL = 'http://api.twittervision.com';

sub new {
    my $class = shift;
    my $self = shift;
    my %hash = @_;

    (exists($hash{url})) ? $self->{url} = $hash{url} : $self->{url} = $TVURL;
    (exists($hash{debug})) ? $DEBUG = $hash{debug} : 0;
    
    bless $self, $class;
    return $self;
}

sub current_status {
    my $self = shift;
    my %hash = @_; 

    my $screen_name = "";
    (exists($hash{screen_name})) ? $screen_name = $hash{screen_name} : croak('Needs a screen name');

    my $req_url = $self->{url} . '/user/current_status/' . $screen_name . '.json';
    my $req = HTTP::Request->new(GET => $req_url);
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
 
    if (!$res->is_success) {
        carp('Unable to access ' . $req_url);
        return undef;
    }
 
    my $json = new JSON;
    my $data = $json->decode($res->content);
    return $data;
}

sub update_status {
    my $self = shift;
    my %hash = @_; 

    my $screen_name;
    my $password;
    my $location;
    (exists($hash{screen_name})) ? $screen_name = $hash{screen_name} : croak('Needs a screen name');
    (exists($hash{password})) ? $password = $hash{password} : croak('Needs a password');
    (exists($hash{location})) ? $location = $hash{location} : croak('Needs a location');

    $location = uri_escape($location);
    
    my $req_url = $self->{url} . '/user/update_location.json?location=' . $location;
    print "$req_url\n";
    my $req = HTTP::Request->new(POST => $req_url);#, [location => $location]);
    
    my $ua = LWP::UserAgent->new;
    push @{ $ua->requests_redirectable }, 'POST';
    $ua->credentials(
        'twittervision.com:80',
        'Web Password',
        $screen_name,
        $password
    );
    my $res = $ua->request($req);
 
    if (!$res->is_success) {
        carp('Unable to access ' . $req_url . ": " . $res->status_line . ": " . $res->header('WWW-Authenticate'));
        return undef;
    }
 
    my $json = new JSON;
    my $data = $json->decode($res->content);
    return $data;
    
}

sub parse_location {
    my $self = shift;
    my %hash = @_; 

    my $message = "";
    (exists($hash{message})) ? $message = $hash{message} : croak('Needs a message string');
    
    my @locations = ();
    while($message =~ s/[lL]:([a-zA-Z]+=)?\s*([^:]+)?:?//) {
        push(@locations, $2);
    }
    return @locations;
}

sub strip_location {
    my $self = shift;
    my %hash = @_; 

    my $message = "";
    (exists($hash{message})) ? $message = $hash{message} : croak('Needs a message string');
    
    my @locations = ();
    $message =~ s/[lL]:([a-zA-Z]+=)?\s*([^:]+)?:?//g;
    $message =~ s/\s\s*/ /g;
    $message =~ s/^\s*//;
    $message =~ s/\s*$//;
    
    return $message;
}

1;
__END__

=head1 NAME

WWW::Twittervision - Perl extension to the Twittervision API

=head1 SYNOPSIS

  use WWW::Twittervision;
  
  my $tv = new WWW::Twittervision();
  
  my $result = $tv->current_status(screen_name =>'screen name');
  
  $result = $tv->update_status(screen_name =>'screen name',
                               password => 'somepassword',
                               location => 'some place in the world');
                               
  my @locations = $tv->parse_location(message => $message);

=head1 DESCRIPTION

This module is a simple perl wrapper for the API provided
by twittervision.com.


=head1 METHODS

=over 4

=item new 

  $tv = WWW::Twittervision->new()
  $tv = WWW::Twittervision(url => $url)

Constructor for WWW::Twittervision. It returns a reference to a WWW::Twittervision object.
You may also pass the url of the webservice to use. The default value is
http://api.twittervision.com and is the only url, to my knowledge, that provides
the services needed by this module.

=item current_status

This function returns the current location and the last twitter
message for a given screen name (twitter handle). The returned
data structure is a HASHREF. Use Data::Dumper to inspect it or
look at the module tests (found in t/*) for examples.

=item update_status

This function update the location for a twitter screen name. It
returns a HASHREF which contains the new location along with the
last twitter information. Use Data::Dumper to inspect the HASHREF
or look at the module tests (found in t/*) for examples.
  
=item parse_location

This function inspects a string for location patterns on
the form l:<location>[:] (see also http://twittervision.com/maps/location_examples.html)
The found locations are returned in an array. If none is found, the
array is empty.

=item strip_location

This function removes location patterns from the message string and returns
the result.

=head1 BUGS

Please report any bugs found or feature requests to
http://code.google.com/p/www-twittervision/issues/list

=head1 SEE ALSO

Net::Twitter
http://twittervision.com/maps/location_examples.html
http://twittervision.com/api

=head1 SOURCE AVAILABILITY

The source code for this module is available from SVN
at http://code.google.com/p/www-twittervision

=head1 AUTHOR

Per Henrik Johansen, E<lt>per.henrik.johansen@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Per Henrik Johansen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
