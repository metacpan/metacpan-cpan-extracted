package WebDAO::Sessionco;

=head1 NAME

WebDAO::Sessionco - Session with store session id in cookie

=head1 DESCRIPTION

WebDAO::Sessionco - Session with store session id in cookie

=cut

our $VERSION = '0.02';
use WebDAO;
use WebDAO::Session;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);
use base qw( WebDAO::Session );
use strict 'vars';
use warnings;
mk_attr ( Cookie_name=>undef, Db_file=>undef );

sub _init {

    #Parametrs is realm => [string] - for http auth
    #		id =>[string] - name of cookie
    #		db_file => [string] - path and filename
    #
    my ( $self, %param ) = @_;
    $self->SUPER::_init(%param);
    my $id = $param{id} || "stored";
    Cookie_name $self (
        {
            name    => "$id",
            expires =>  defined($param{expires}) ? $param{expires} :  "+3M",
            path    => "/",
            value   => "0",
            secure  => defined($param{secure}) ? $param{secure} : 0,
            httponly => 1
        }
    );
    my $cv = $self->Cgi_obj();
    my $coo = $cv->get_cookie->{ $id };
    unless ($coo) {
        $coo = md5_hex(time ^ $$, rand(999)) ;
    }
     U_id $self ( $coo );
    $self->Cookie_name()->{value} = $coo;
    $cv->set_header('Set-Cookie', $self->Cookie_name());
    1
}

sub get_id {
    my $self = shift;
    my $coo  = U_id $self;
    return $coo;
}

1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2017 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

