# -*- perl -*-

use strict;

use CGI ();

package XML::EP::Request::CGI;

$XML::EP::Request::CGI::VERSION = '0.01';


sub new {
    my $proto = shift;
    my $path = $ENV{'PATH_TRANSLATED'} || shift;
    if ($path =~ /(.*)[\/\\]/) {
        chdir $1;
    }
    my $self = { 'PATH_TRANSLATED' => $path };
    bless($self, ref($proto) || $proto);
}


sub Param { my $self = shift; $self->{cgi}->param(@_) }
sub Client {
    my $self = shift;
    @_ ? ($self->{Client} = shift) :
	($self->{Client} || $ENV{HTTP_USER_AGENT});
}
sub Location {
    my $self = shift;
    @_ ? ($self->{Location} = shift) :
	($self->{Location} || $ENV{REQUEST_URI});
}
sub VirtualHost {
    my $self = shift;
    @_ ? ($self->{VirtualHost} = shift) :
	($self->{VirtualHost} || $ENV{SERVER_NAME});
}
sub PathInfo {
    my $self = shift;
    @_ ? ($self->{PathInfo} = shift) :
	($self->{PathInfo} || $ENV{PATH_INFO});
}
sub PathTranslated {
    my $self = shift;
    @_ ? ($self->{PathTranslated} = shift) :
	($self->{PathTranslated} || $ENV{PATH_TRANSLATED});
}
sub FileHandle {
    my $self = shift;
    @_ ? ($self->{FileHandle} = shift) : ($self->{FileHandle} || \*STDOUT);
}
sub Uri {
    my $self = shift;
    if (@_) {
	$self->{Uri} = shift;
    } else {
	$self->{Uri} ||= "http://$ENV{SERVER_NAME}/$ENV{REQUEST_URI}";
    }
}


1;
