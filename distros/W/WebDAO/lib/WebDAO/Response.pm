package WebDAO::Response;

=head1 NAME

WebDAO::Response - Response class

=head1 SYNOPSYS

        new WebDAO::Response:: cv => $cv

=head1 DESCRIPTION

Class for make HTTP response

=cut

our $VERSION = '0.01';
use Data::Dumper;
use WebDAO::Base;
use IO::File;
use DateTime;
use DateTime::Format::HTTP;
use base qw( WebDAO::Base );

__PACKAGE__->mk_attr( 
    _headers => undef,
    _is_headers_printed =>0,
    _cv_obj => undef,
    _is_file_send => 0,
    _is_need_close_fh => 0,
    __fh => undef,
    _is_flushed => 0,
    _call_backs => undef,
    _is_modal => 0,
    _forced_want_format => undef,
    _is_empty=>0,
    status => 200 #default HTTP status
    );

use strict;
use warnings;

=head1 METHODS

=cut

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    return $self->init(@_);
}

sub init {
    my $self = shift;
    my %par  = @_;
    $self->_headers( {} );
    $self->_call_backs( [] );
    $self->_cv_obj( $par{cv} );
    return 1;
}

=head2 get_request

Return ref to request object (WebDAO::CV)

=cut

sub get_request {
    my $self = shift;
    return $self->_cv_obj;
}

=head2 set_status INT

set response HTTP status

    $r->set_status(200)

return C<$self>

=cut

sub set_status {
    my $self = shift;
    $self->status(@_);
    $self 
}


=head2 set_header NAME, VALUE

Set out header:

        $response->set_header('Location', $redirect_url);
        $response->set_header( 'Content-Type' => 'text/html; charset=utf-8' );

return $self reference

=cut

sub set_header {
    my ( $self, $name, $par ) = @_;
    #translate CGI headers
    if ( $name =~ /^-/) {
            my $UKey = uc $name;
            
            if ( $UKey eq '-STATUS' ) {
                my ($status) = $par =~ m/(\d+)/;
                $self->status($status);
                return $self;
            }
            warn "Deprecated header name $name !";
    } elsif ( $name eq 'Set-Cookie') {
        push @{ $self->_headers->{ $name } }, $par;
        return $self
    }
        
    $self->_headers->{ $name } = $par;
    $self;
}



=head2 get_header NAME

return value for  header NAME:

=cut

sub get_header {
    my ( $self, $name ) = @_;
    return $self->_headers->{ $name };
}

=head2 aliases for headers

=head3 content_type

  $r->content_type('text/html; charset=utf-8');

=cut

sub content_type {
    my $self = shift;
    unless ($#_ > 0 ) {
        $self->set_header('Content-Type', @_)
    }
    $self->get_header('Content-Type');
}

=head3 content_length

A decimal number indicating the size in bytes of the message content.

=cut

sub content_length {
    my $self = shift;
    unless ($#_ > 0 ) {
      $self->set_header('Content-Length' , @_)
    } 
    $self->get_header('Content-Length');
}

=head3  

=head2 get_mime_for_filename <filename>

Determine mime type for filename (Simple by ext);
return str

=cut

sub get_mime_for_filename {
    my $self          = shift;
    my $filename      = shift;
    my $no_default_flag = shift;
    my %types_for_ext = (
        avi  => 'video/x-msvideo',
        bmp  => 'image/bmp',
        css  => 'text/css',
        gif  => 'image/gif',
        gz   => 'application/gzip',
        html => 'text/html',
        htm  => 'text/html',
        jpg  => 'image/jpeg',
        jpeg => 'image/jpeg',
        js   => 'application/javascript',
        midi => 'audio/midi',
        mp3  => 'audio/mpeg',
        mpeg => 'video/mpeg',
        mpg  => 'video/mpeg',
        mov  => 'video/quicktime',
        pdf  => 'application/pdf',
        png  => 'image/png',
        ppt  => 'application/vnd.ms-powerpoint',
        rtf  => 'text/rtf',
        tif  => 'image/tif',
        tiff => 'image/tif',
        txt  => 'text/plain',
        xls  => 'application/vnd.ms-excel',
        xml  => 'appliction/xml',
        wav  => 'audio/x-wav',
        zip  => 'application/zip',
    );
    my ($ext) = $filename =~ /\.(\w+)$/;
    if ( my $type = $types_for_ext{ lc $ext } ) {
        return $type;
    }
    return $no_default_flag ? undef : 'application/octet-stream';
}

=head2 print_header

print header.return $self reference

=cut

sub print_header {
    my $self  = shift;
    my $pnted = $self->_is_headers_printed;
    return $self if $pnted;
    my $cv      = $self->get_request;
    $cv->status($self->status);
    $cv->print_headers(%{ $self->_headers });
    $self->_is_headers_printed(1);
    $self;
}

=head2  redirect2url <url for redirect to> [, $code]

Set headers for redirect to url.return $self reference

=cut

sub redirect2url {
    my ( $self, $redirect_url, $code ) = @_;
    $self->set_modal->set_status( $code || 302 );
    $self->set_header( 'Location', $redirect_url );
}

=head2 set_cookie ( name => <cookie_name>, value=><cookie_value> ...)

Set cookie.
return $self reference

=cut

sub set_cookie {
    my $self = shift;
    $self->set_header("Set-Cookie", { @_ });
    $self;
}


=head2 set_callback(sub1{}[, sub2{} ..])

Set callbacks for call after flush

=cut

sub set_callback {
    my $self = shift;
    push @{ $self->_call_backs }, @_;
    return $self;
}

=head2 send_file <filename>|<file_handle>|<reference to GLOB> [, -type=><MIME type string>]

Prepare headers and save 

    $respose->send_file($filename, -type=>'image/jpeg');

=cut

sub send_file {
    my $self = shift;
    my $file = shift;
    my %args = @_;
    my $file_handle;
    my $file_name;
    if ( ref $file
        and ( UNIVERSAL::isa( $file, 'IO::Handle' ) or ( ref $file ) eq 'GLOB' )
        or UNIVERSAL::isa( $file, 'Tie::Handle' ) )
    {
        $file_handle = $file;
    }
    else {
        $file_name   = $file;
        $file_handle = new IO::File::("< $file")
          or die "can't open file: $file" . $!;
        $self->_is_need_close_fh(1);
        $self->__fh($file_handle);
    }

    #set file headers
    my ( $size, $mtime ) = ( stat $file_handle )[ 7, 9 ];
    $self->content_length( $size );
    my $formated =
      DateTime::Format::HTTP->format_datetime(
        DateTime->from_epoch( epoch => $mtime ) );
    $self->set_header( 'Last-Modified', $formated );

    #Determine mime tape of file
    if ( my $predefined = $args{-type} ) {
        $self->content_type( $predefined );
    }
    else {
        ##
        if ($file_name) {
            $self->content_type(
                $self->get_mime_for_filename($file_name) );
        }
    }

    #set modal mode and flag for send file
    $self->set_modal->_is_file_send(1);
    $self;
}

sub print {
    my $self = shift;
    my $cv   = $self->get_request;
    $self->print_header;
    $cv->print(@_);
    return $self;
}

sub _print_dep_on_context {
    my ( $self, $session ) = @_;
    my $res = $self->html;
    $self->print( ref($res) eq 'CODE' ? $res->() : $res );
}

=head2 flush

Flush current state of response.

=cut

sub flush {
    my $self = shift;
    return $self if $self->_is_flushed;
    $self->print_header;

    #do self print file
    if ( $self->_is_file_send ) {
        my $fd = $self->__fh;
        $self->get_request->print(<$fd>);
        close($fd) if $self->_is_need_close_fh;
    }
    $self->_is_flushed(1);

    #do callbacks
    my $ref_calls = $self->_call_backs;
    while ( my $code = pop @$ref_calls ) {
        $code->();
    }

    #clear callbacks
    @{ $self->_call_backs } = ();
    $self;
}

=head2 set_modal

Set modal mode for answer

=cut

sub set_modal {
    my $self = shift;
    $self->_is_modal(1);
    $self;
}

=head2 error404

Set HTTP 404 headers

=cut

sub error404 {
    my $self = shift;
    $self->set_modal->set_status(404);
    $self->print(@_) if @_;
    return $self;
}

sub html : lvalue {
    my $self = shift;
    $self->{__html};
}

sub set_html {
    my $self = shift;
    my $data = shift;
    $self->html = $data;
    return $self;
}

sub json : lvalue {
    my $self = shift;
    $self->{__json};

}

sub set_json {
    my $self = shift;
    my $data = shift;
    $self->json = $data;
    return $self;
}

sub _destroy {
    my $self = shift;
    $self->{__html} = undef;
    #destroy called from Engine::execute2
    # destroy tests by cleared _cv_obj
#    $self->_cv_obj( undef );
    $self->_headers( {} );
    $self->_call_backs( [] );
}

=head2 wantformat ['format',['forse_set_format']]

Return expected output format: defauilt html
    
       # return string for format
       $r->wantformat()

Check if desired format is expected

  #$r->wantformat('html') return boolean
  if ($r->wantformat('html')) { 
      # 
  }

Force set desired format:

  $r->wantformat('html'=>1); #return $response object ref

=cut

sub wantformat {
    my $self = shift;
    if ( @_ > 1 ) {
        $self->_forced_want_format(shift);
        return $self;
    }
    my $desired = $self->_forced_want_format();
    my $default =
         $desired
      || $self->detect_wantformat( $self->get_request ) #call with CV object 
      || 'html';
    if ( scalar(@_) == 1 ) {
        return $default eq shift;
    }
    return $default;
}

=head2 detect_wantformat ($cv)

Method for detect output format when C<wantformat()> called

Must return :
    
        string  - output format, i.e. 'html', 'xml'
        undef - unknown ( use defaults )

=cut

sub detect_wantformat {
    return undef    #unknown by default
}


=head2 set_empty

Set flag for empty response. Headers are not printed.
return $self
=cut

sub set_empty { $_[0]->_is_empty(1); $_[0]}

=head2 is_empty

Check is response cleared.
Return 1|0

=cut

sub is_empty { return $_[0]->_is_empty() }

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

