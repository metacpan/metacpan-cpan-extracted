package Web::Solid::Auth::Agent;

use Moo;

extends 'LWP::UserAgent';

has auth => (
    is => 'ro' ,
    required => 1
);

sub get {
    my ($self, $url , %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'GET');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::get($url,%opts);
}

sub head {
    my ($self, $url , %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'HEAD');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::head($url,%opts);
}

sub options {
    require HTTP::Request::Common;
    my ($self, $url , %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'OPTIONS');
    %opts = (%opts, %$headers) if $headers;
    my @parameters = ($url, %opts);
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::OPTIONS( @parameters ), @suff );
}

sub delete {
    my ($self, $url , %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'DELETE');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::delete($url,%opts);
}

sub post {
    my ($self, $url ,$data, %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'POST');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::post($url,%opts, Content => $data);
}

sub put {
    my ($self, $url ,$data, %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'PUT');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::put($url,%opts, Content => $data);
}

sub patch {
    my ($self, $url ,$data, %opts ) = @_;
    my $headers = $self->auth->make_authentication_headers($url,'PATCH');
    %opts = (%opts, %$headers) if $headers;
    return $self->SUPER::patch($url,%opts, Content => $data);
}

1;