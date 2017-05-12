package WWW::Find;

use 5.006;
use strict;
use warnings;
use Carp;
use URI;
use URI::Heuristic;
use HTML::LinkExtor;

our $VERSION = '0.07';
my $depth = 0;
my %seen;

# Default URL matching subroutine 
sub match_sub {
    my($self) = shift;

## tests for URL's matching this REGEX
    if($self->{REQUEST}->uri =~ /html?$/io) {

## do something with matching URL's
## print to STDOUT is the default action 
        print $self->{REQUEST}->uri . "\n";
    }
    return
}

## Default URL follow subtroutine
## Should return true or false
sub follow_sub {
    my $self = shift;
    my $header = HTTP::Request->new(HEAD => $self->{REQUEST}->uri);
    my $response = $self->{AGENT}->request($header) || next;
    $response->content_type eq 'text/html' && ref($self->{REQUEST}->uri) eq 'URI::http'
    ? return 1   
    : return 0  
}

## Private methods

my $_rec;
$_rec = sub {
    my $find_obj = shift;
    my $uri = URI->new($find_obj->{REQUEST}->uri);
#    $seen{$uri}++;
#    return if($seen{$uri} > 1);
    return if($depth > $find_obj->{MAX_DEPTH});
    $depth++;

## Request HTML Document
    my $html = $find_obj->{AGENT}->request($find_obj->{REQUEST});

## Parse out HREF links
    my $parser = HTML::LinkExtor->new(undef);
    $parser->parse($html->content);
    my @links = $parser->links;
    foreach my $ln (@links)
    {
       my @element = @$ln;
       my $type = shift @element;
       next unless($type =~ /^a/io);
       while(@element)
       {
           my ($name, $value) = splice(@element, 0, 2);

## Make URL absolute
           $find_obj->{REQUEST}->uri(URI->new_abs($value, $uri));
           my $url = $find_obj->{REQUEST}->uri;

## Check recursion depth
           next if($depth > $find_obj->{MAX_DEPTH});

## Skip if duplicate  
	   $seen{$url}++;
	   next if($seen{$url} > 1);
## User defined matching subroutine
           $find_obj->{MATCH_SUB}($find_obj);

## Check recursion depth
#           next if($depth > $find_obj->{MAX_DEPTH});

## Modify request object for next request
           if(ref($find_obj->{REQUEST}->uri)) 
           {
               $find_obj->{REQUEST}->uri(URI::Heuristic::uf_urlstr($find_obj->{REQUEST}->uri));

## User defined follow subroutine
               &$_rec($find_obj) if ($find_obj->{FOLLOW_SUB}($find_obj));
           }
       }
   }
   $depth--;

};

# constructor
sub new
{
    my($class, %parm) = @_;
    croak 'Expecting a class' if ref $class;
    my $self = { MAX_DEPTH => 2,
                 DIRECTORY => '.',
                 MATCH_SUB => \&match_sub,
                 FOLLOW_SUB => \&follow_sub
    };
## Parms should be validated, but I'm feeling lazy 
    while(my($k, $v) = each(%parm)) { $self->{$k} = $v};
    bless $self, $class;
    return $self;
}

## Public methods
sub go {
    my($self, %parm) = @_;
    $self->{REQUEST}->uri(URI::Heuristic::uf_urlstr($self->{REQUEST}->uri)); 
    &$_rec($self);
}

sub set_match {
   my($self, $sub_ref) = @_;
   $self->{MATCH_SUB} = $sub_ref;
   return $self->{MATCH_SUB};
}

sub set_follow {
   my($self, $sub_ref) = @_;
   $self->{FOLLOW_SUB} = $sub_ref;
   return $self->{FOLLOW_SUB};
}

1;

__END__

=head1 NAME

WWW::Find - Web Resource Finder 

=head1 SYNOPSIS

use LWP::UserAgent;
use HTTP::Request;
use WWW::Find;

$agent = LWP::UserAgent->new;

$request = HTTP::Request->new(GET => 'http://begin.url');

$find = WWW::Find->new(AGENT => $agent,
                       REQUEST => $request,
                       MAX_DEPTH => 2,
                       MATCH_SUB => \&match, 
                       FOLLOW_SUB => \&follow 
                      );

$find->go;

=head1 DEPENDENCIES

HTML::LinkExtor
LWP::UserAgent
HTTP::Request
URI

=head1 DESCRIPTION

WWW::Find simplifies the task of searching the web for specific types of information.  The inspiration for this project came from the recursive website mirroring program, w3mir.  WWW::Find is similar to w3mir, but with a more general feature set. 

In a nutshell, a WWW::Find object extracts all the HREF links from an HTML document, creates a HTTP::Request object for each link, matches the HTTP::Response object against user specified criteria, and then does something with the matching links (possibly performing the entire operation all over again on certain links).  Be careful not to set the MAX_DEPTH parameter too high, otherwise you could easily begin the endless task of requesting every page on the net!         

In addition to a LPW::UserAgent and a HTTP::Request object, you'll need to create two subroutines: a &match subroutine and a &follow subroutine.  

The &follow subroutine should attempt to match the HTTP::Response object against user defined criteria.  If a match is found, the entire operation is performed all over again on the matching link.  For example, the following subroutine matches links where the header content-type matches the regular expression /text/.  

sub follow {
    my $find_obj = shift;
    my $header = HTTP::Request->new(HEAD => $find_obj->{REQUEST}->uri);
    my $response = $find_obj->{AGENT}->request($header) || next;
    $response->content_type =~ /text/io
    ? return 1 
    : return 0;
}

The &match subroutine should perform some operation on links matching user defined criteria.  For example, the following subroutine simply prints out the URL of all links matching the regular expression /html?$/ 

sub match {
    my $find_obj = shift;
    if($find_obj->{REQUEST}->uri =~ /html?$/io) {
        print $find_obj->{REQUEST}->uri . "\n";
    }
    return;
}

=head1 SEE ALSO

HTTP::Request
LPW::UserAgent

=head1 AUTHOR

Nathaniel Graham, E<lt>broom@cpan.org<gt>
http://www.gnusto.net is the offical home page of WWW::Find

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Nathaniel Graham

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
