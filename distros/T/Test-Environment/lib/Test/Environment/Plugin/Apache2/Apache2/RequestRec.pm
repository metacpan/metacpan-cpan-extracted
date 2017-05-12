package Test::Environment::Plugin::Apache2::Apache2::RequestRec;

our $VERSION = "0.07";

1;

package Apache2::RequestRec;

=head1 NAME

Test::Environment::Plugin::Apache2::Apache2::RequestRec - fake Apache2::RequestRec for Test::Environment

=head1 SYNOPSIS

    use Test::Environment qw{
        Apache2
    };
    
    my $request = Apache2::RequestRec->new(
        'headers_in' => {
            'Accept-Encoding' => 'xyz,gzip'
        },
        'hostname' => 'with.the.man.sk',
        'uri'      => '/index.html',
        'args'     => 'id=me',
    );
    is(
        My::App:Apache2::Index::handler($request),
        Apache2::Const::REDIRECT,
    );
    is(
        $request->headers_out->get('Location'),
        'http://with.the.man.sk/me/',
    );

=head1 DESCRIPTION

Will populate Apache2::RequestRec namespace with fake methods that can be used for
testing.

=cut

use warnings;
use strict;

our $VERSION = "0.07";

use APR::Pool;
use APR::Table;

use base 'Class::Accessor::Fast';


=head1 PROPERTIES

    hostname
    uri
    apr_pool
    args
    get_server_port
    dir_config
    status
    content_type
    method
    protocol

=cut

__PACKAGE__->mk_accessors(qw{
    hostname
    uri
    apr_pool
    args
    get_server_port
    dir_config
    status
    content_type
    method
    protocol
});


=head1 METHODS

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({
        'get_server_port' => 80,
        'apr_pool'        => APR::Pool->new,
        'method'          => 'GET',
        'protocol'        => 'HTTP/1.1',
        @_,
    });
    
    # initialize all apr tables
    foreach my $apt_table_name (qw(apr_table headers_in headers_out subprocess_env dir_config)) {
        my $apr_table = $self->{$apt_table_name} || APR::Table::make($self->apr_pool, 100);
        
        # if the parameter is plain HASH, convert it to APR::Table
        if (ref $apr_table eq 'HASH') {
            my $hash = $apr_table;
            $apr_table = APR::Table::make($self->apr_pool, 100);
            while (my ($key, $value) = each(%{$hash})) {
                $apr_table->add($key => $value);
            }
        }
        
        $self->{$apt_table_name} = $apr_table;
    }
    
    return $self;
}

=head2 notes

Get/Set notes.

=cut


sub notes {
    my $self      = shift;
    my $note_name = shift;

    if (@_ > 0) {
        $self->{'notes'}->{$note_name} = shift;
    }

    return $self->{'notes'}->{$note_name};
}

=head2 pnotes

Get/Set pnotes.

=cut

sub pnotes {
    my $self      = shift;
    my $note_name = shift;
    
    if (@_ > 0) {
        $self->{'pnotes'}->{$note_name} = shift;
    }
    
    return $self->{'pnotes'}->{$note_name};
}

sub unparsed_uri {
    my $self      = shift;
    
    return $self->uri.($self->args ? '?'.$self->args : '' );
}

=head2 APR::Table methods

=head3 apt_table()
=head3 subprocess_env()
=head3 headers_in()
=head3 headers_out()
=head3 dir_config()

=cut

sub apr_table      { return shift->_get_set('apr_table',      @_) };
sub subprocess_env { return shift->_get_set('subprocess_env', @_) };
sub headers_in     { return shift->_get_set('headers_in',     @_) };
sub headers_out    { return shift->_get_set('headers_out',    @_) };
sub dir_config     { return shift->_get_set('dir_config',     @_) };

sub err_headers_out {
    my $self   = shift;
    $self->headers_out(@_);
}

sub _get_set {
    my $self = shift;
    my $name = shift;
   
    if (@_ > 0) {
        my $key_name = shift;
        if (@_ > 0) {
            $self->{$name}->add($key_name => shift);
        }
        return $self->{$name}->get($key_name);
    }
    else {
        return $self->{$name};
    }
}


=head2 Apache2::Filter::r

just calls $self->request_rec(@_);

=cut

sub Apache2::Filter::r {
    my $self   = shift;
    $self->request_rec(@_);
}

=head2 Apache2::Filter::request_rec

Returns Apache2::RequestRec.

=cut

sub Apache2::Filter::request_rec {
    my $self   = shift;
    
    if (@_ > 0) {
        $self->{'request_rec'} = shift;
    }
    
    if (ref $self->{'request_rec'} ne __PACKAGE__) {
        $self->{'request_rec'} = bless $self->{'request_rec'}, __PACKAGE__;
    }
    
        
    return $self->{'request_rec'};
}

=head2 populate_env

Sets CGI %ENV variables based on current RequestRec object.

=cut

sub populate_env {
    my $self   = shift;

    $ENV{REQUEST_METHOD} = $self->method;
    $ENV{HTTP_HOST}      = $self->hostname;
    $ENV{REQUEST_URI}    = $self->uri;
    $ENV{QUERY_STRING}   = $self->args;
    my $cookie = $self->headers_in->get('cookie');
    $ENV{HTTP_COOKIE}    = $cookie
        if $cookie;
}

=head2 rflush

empty call

=cut

sub rflush { }


'writing on the wall';

__END__

=head1 AUTHOR

Jozef Kutej

=cut
