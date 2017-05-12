package WebDAO::Session;
#$Id$

=head1 NAME

WebDAO::Session - Session interface to protocol specific function

=head1 DESCRIPTION

Session interface to device(HTTP protocol) specific function

=cut


our $VERSION = '0.02';
use WebDAO;
use WebDAO::CV;
use WebDAO::Response;
use Encode qw(encode decode is_utf8);
use strict;
use warnings;

mk_attr(
    Cgi_obj => undef, # request object
    Cgi_env => undef, 
    U_id=> undef,
    Params => undef,
    _response_obj=> undef, #deprecated ? 
    _is_absolute_url =>undef #deprecated ?
);

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    $self->_init(@_);
    return $self;
}


sub _init {
    #Parametrs is realm
    my $self = shift;
    my %args = @_;
    U_id $self undef;
    Cgi_obj $self $args{cv}
      || new WebDAO::CV::;    #create default controller
    my $cv = $self->Cgi_obj;           # Store Cgi_obj in local var
                                      #create response object
    $self->_response_obj(
        new WebDAO::Response::
        cv => $cv
    );

    Cgi_env $self (
        {
            url => $cv->url( -base => 1 ),    #http://eng.zag
            path_info         => $cv->url( -absolute => 1, -path_info => 1 ),
            path_info_elments => [],
            file              => "",
            base_url     => $cv->url( -base => 1 ),    #http://base.com
            accept       => $cv->accept,
        }
    );

    Params $self ( $self->_get_params() );
    $self->Cgi_env->{path_info_elments} = $self->call_path($self->Cgi_env->{path_info});
    #set default header
    $cv->set_header("Content-Type" => 'text/html; charset=utf-8');
}


#Get cgi params;
sub _get_params {
    my $self = shift;
    my $_cgi = $self->Cgi_obj();
    my %params;
    foreach my $i ( $_cgi->param()  ) {
        my @all = $_cgi->param($i);
        foreach my $value (@all) {
            next if ref $value;
            $value = decode( 'utf8', $value ) unless is_utf8($value);
        }
        $params{$i} = scalar @all > 1 ? \@all : $all[0];
    }
    return \%params;
}


#Can be overlap if you choose another
#alghoritm generate unique session ID (i.e cookie,http_auth)
sub get_id {
    my $self = shift;
    my $coo  = U_id $self;
    return $coo if ($coo);
    return rand(100);
}

=head2 call_path [$url]

Return ref to array of element from $url or from CGI ENV

=cut

sub call_path {
    my $self = shift;
    my $url = shift || return $self->Cgi_env->{path_info_elments};
    $url =~ s%^/%%;
    $url =~ s%/$%%;
    return [ grep { defined $_ } split( /\//, $url ) ];

}

=head2  set_absolute_url 1|0

Set flag for build absolute pathes. Return previus value.

=cut

sub set_absolute_url {
    my $self       = shift;
    my $value      = shift;
    my $prev_value = $self->_is_absolute_url;
    $self->_is_absolute_url($value) if defined $value;
    return $prev_value;
}

sub get_request {
    my $self = shift;
    return $self->Cgi_obj;
}

#deprecated ??? use WebDAO::Engine::response
sub response_obj {
    my $self = shift;
    return $self->_response_obj;
}

sub print {
    my $self = shift;
    $self->Cgi_obj->print(@_);
}

sub ExecEngine {
    my ( $self, $eng_ref,$path ) = @_;
    $eng_ref->_execute($self, $path);
    $eng_ref->__send_event__("_sess_ended"); # TODO: deprecated : delete this line
    $eng_ref->_commit();
    $eng_ref->_destroy;
}

sub destroy {
    my $self = shift;
    $self->_response_obj(undef);
}
1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

