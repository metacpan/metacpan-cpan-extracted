# Aug 27 2012
# blogger interface
package WWW::BloggerWeb;
our $VERSION = '1.0';
use Moose;
use Data::Dumper;
use Net::SSL (); # From Crypt-SSLeay
use LWP::UserAgent;
use HTTP::Request::Common;

$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL for proxy compatibility

{
has 'username', is => 'rw', isa => 'Str',default => '' ;	
has 'password', is => 'rw', isa => 'Str',default => '' ;
has 'blog_id', is => 'rw', isa => 'Str',default => '' ;
has 'blog', is => 'rw', isa => 'Str',default => '' ;

has proxy_host      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_port      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_user      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_pass      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_env      => ( isa => 'Str', is => 'rw', default => '' );

has browser  => ( isa => 'Object', is => 'rw', lazy => 1, builder => '_build_browser' );

###################################### blog  functions ###################

### login ###
sub login
{
my $self = shift;
my %options = @_;
my $username = $self->username;
my $password = $self->password;

my $post_data = {Email => $username, 
				Passwd => $password, 
				service => 'blogger'};				


my $response = $self->dispatch(url =>"https://www.google.com/accounts/ClientLogin", method => 'POST',post_data =>$post_data);

# Check success, parsing Google error message, if available.
unless ($response->is_success) 
{
  my $error_msg = ($response->content =~ /\bError=(.+)/)[0] || 'Google error message unavailable';
  die 'HTTP error when trying to authenticate: ' . $response->status_line . " ($error_msg)";
}

# Parse authentication token and set it as default header for user agent object.
my ($auth_token) = $response->content =~ /\bAuth=(.+)/
  or die 'Authentication token not found in the response: ' . $response->content;
$self->browser->default_header(Authorization => "GoogleLogin auth=$auth_token");

return 1;
}

# post to blog
sub post
{
my $self = shift;
my ($title,$content) = @_;
#my $post_data = $options{ post_data };
my $blog_id = $self->blog_id;
                                
my $xml_post = '<entry xmlns="http://www.w3.org/2005/Atom"><title type="text">TITLE</title><content type="html">CONTENT</content></entry>';
$xml_post =~ s/TITLE/$title/; 
$xml_post =~ s/CONTENT/$content/; 
                                      
my $response = $self->dispatch(url =>"https://www.blogger.com/feeds/".$blog_id."/posts/default",method => 'POST_FILE',post_data =>$xml_post);

my $raw_response = $response->content;

open (SALIDA,">post.xml") || die "ERROR: No puedo abrir el fichero post.xml\n";
print SALIDA $raw_response;
close (SALIDA);

my $url = `egrep -o 'http://[[:alnum:].\/-]{1,50}blogspot.com[[:alnum:].\/-]{1,100}.html' post.xml | head -1`;
$url =~ s/\r|\n//g; # Remove Carrier Return

return $url;
}    


###################################### internal functions ###################
sub dispatch {    
my $self = shift;
my %options = @_;

my $method = $options{ method };
my $url = $options{ url };
my $post_data = $options{ post_data };

my $response = '';
if ($method eq 'GET')
  { $response = $self->browser->get($url);}
  
if ($method eq 'POST')
  {       
   my $post_data = $options{ post_data };     
   $response = $self->browser->post($url,$post_data);    
  }  
  
if ($method eq 'POST_FILE')
  {         	    
    $response = $self->browser->post( $url, Content_Type => 'application/atom+xml', Content => $post_data );                 
  }  
  
return $response;
}


sub _build_browser {    
my $self = shift;

my $proxy_host = $self->proxy_host;
my $proxy_port = $self->proxy_port;
my $proxy_user = $self->proxy_user;
my $proxy_pass = $self->proxy_pass;
my $proxy_env = $self->proxy_env;

my $browser = LWP::UserAgent->new;
$browser->show_progress(1);
print "proxy_env $proxy_env \n";

if ( $proxy_env eq 'ENV' )
{
$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
$ENV{HTTPS_PROXY} = "http://".$proxy_host.":".$proxy_port;
}
else
{
  if (($proxy_user ne "") && ($proxy_host ne ""))
  {
   $browser->proxy(['http', 'https'], 'http://'.$proxy_user.':'.$proxy_pass.'@'.$proxy_host.':'.$proxy_port); # Using a private proxy
  }
  elsif ($proxy_host ne "")
    { $browser->proxy(['http', 'https'], 'http://'.$proxy_host.':'.$proxy_port);} # Using a public proxy
  else
    { $browser->env_proxy;} # No proxy       
} 
    
return $browser;
}

}

1;


__END__

=head1 NAME

WWW::BloggerWeb - Blogger interface

=head1 SYNOPSIS


Usage:

   use WWW::BloggerWeb;
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
   
   my $blogger = WWW::BloggerWeb->new( username =>  'anything@gmail.com' ,
					password => 'YOUR_BLOGGER_PASS',
					blog_id => "YOUR_BLOG_ID");	
					
					

=head1 DESCRIPTION

Blogger interface 

=head1 FUNCTIONS

=head2 constructor

       my $blogger = WWW::BloggerWeb->new( username =>  'anything@gmail.com' ,
					password => 'YOUR_BLOGGER_PASS',
					blog_id => "YOUR_BLOG_ID");	
					

To get your blog ID go to https://www.blogger.com/home and click to your blog and extract it

https://www.blogger.com/blogger.g?blogID= YOUR_BLOG_ID #overview/src=dashboard


=head2 login

   $blogger->login;
   
Login to the site. You MUST call this function before to do anything

=head2 post

    my $title = "my new title ";
	my $content = "my content"; 
	$url = $blogger->post($title,$content);
	print "url $url \n";

Submit post an entry
   
=head2 dispatch

 Internal function         
                  
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
=cut
