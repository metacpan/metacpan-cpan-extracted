#===============================================================================
#
#  DESCRIPTION:  controller
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WebDAO::CV;
our $VERSION = '0.03';
use URI;
use Data::Dumper;
use strict;
use warnings;
use HTTP::Body;
use WebDAO::Base;
use WebDAO::Util;
use base qw( WebDAO::Base );

__PACKAGE__->mk_attr(status=>200, _parsed_cookies=>undef);

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self->{headers} = {};
    $self
}

=head2 url (-options1=>1)

from url: http://testwd.zag:82/Envs/partsh.sd?23=23
where options:
    
    -path_info  -> /Envs/partsh.sd
    -base       -> http://example.com:82 

defaul http://testwd.zag:82/Envs/partsh.sd?23=23
    
=cut

sub url {
    my $self = shift;
    my %args = @_;
    my $env  = $self->{env};

    if ( exists $env->{FCGI_ROLE} ) {
        ( $env->{PATH_INFO}, $env->{QUERY_STRING} ) =
          $env->{REQUEST_URI} =~ /([^?]*)(?:\?(.*)$)?/s;
    }
    my $path  = $env->{PATH_INFO} || '';       # 'PATH_INFO' => '/Env'
    my $host  = $env->{HTTP_HOST} || 'example.org';       # 'HTTP_HOST' => '127.0.0.1:5000'
    my $query = $env->{QUERY_STRING}|| '';    # 'QUERY_STRING' => '434=34&erer=2'
    my $proto     = $env->{'psgi.url_scheme'} || 'http';
    my $full_path = "$proto://${host}${path}?$query";
    #clear / at end
    $full_path =~ s!/$!! if $path =~ m!^/!;
    my $uri = URI->new($full_path);

    if ( exists $args{-path_info} ) {
        return $uri->path();
    }
    elsif ( exists $args{-base} ) {
        return "$proto://$host";
    }
    return URI->new($full_path)->canonical;
}

=head2 method - HTTP method

retrun HTTP method

=cut

sub method {
    my $self = shift;
    $self->{env}->{REQUEST_METHOD} || "GET";
}

=head2 accept

return hashref

    {
           'application/xhtml+xml' => undef,
           'application/xml' => undef,
           'text/html' => undef
      };

=cut

sub accept {
    my $self = shift;
    my $accept = $self->{env}->{HTTP_ACCEPT} || return {};
    my ($types) = split( ';', $accept );
    my %res;
    @res{ split( ',', $types ) } = ();
    \%res;
}

=head2 param  - return GET and POST params

return params 

=cut

sub param {
    my $self = shift;
    my $params = $self->{parsed_params};
    unless ($params) {
    #init by POST params
    $params = $self->_parse_body;
    my @get_params = $self->url()->query_form;
    while (my ($k, $v) = splice(@get_params,0,2 )) {
        unless ( exists  $params->{ $k } ) {
            $params->{ $k } = $v
        } else {
            my $val = $params->{ $k };
            #if array ?
            if ( ref $val ) {
                push @$val, $v
            } else {
                $params->{ $k } = [$val, ref($v) ? @$v : $v]
            }
        }
    }
    $self->{parsed_params} = $params;
    }
    return keys %$params unless @_;
    return undef unless exists  $params->{$_[0]};
    my $res = $params->{$_[0]};
    if ( ref($res) ) {
       return  wantarray ?  @$res : $res->[0]
    }
    return $res;
}

#parse body
sub _parse_body {
    my $self = shift;

    my $content_type  = $self->{env}->{CONTENT_TYPE};
    my $content_length  = $self->{env}->{CONTENT_LENGTH};
    if (!$content_type && !$content_length) {
        return {};
    }

    my $body = HTTP::Body->new($content_type, $content_length);
    $body->cleanup(1);

    my $input = $self->{env}->{'psgi.input'};
    if ( $input ) {
        #reset IO
        $input->seek(0,0);
    }
    else {
       # for FCGI, Shell
       $input = \*STDIN 
    }
    my $spin = 0;

    while ($content_length) {
        $input->read(my $chunk, $content_length < 8192 ? $content_length : 8192);
        my $read = length $chunk;
        $content_length -= $read;
        $body->add($chunk);
        if ($read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($content_length bytes remaining)";
        }
    }
    $self->{'http.body'} = $body;
    return $body->param
}

=head2 body - HTTP body file descriptor ( see get-body for get content)

Return HTTP body file descriptor 

    my $body;
    {
        local $/;
        my $fd = $request->body;
        $body = <$fd>;
     }

=cut

sub body {
    my $self = shift;
    unless ( exists $self->{'http.body'} ) {
        $self->_parse_body();
    }

    my $http_body = $self->{'http.body'} || return undef;
    return $http_body->body;
}

=head2 get-body - HTTP body content

Return HTTP body text

    my $body= $r->get_body;

=cut

sub get_body {
    my $self = shift;
    my $body;
    {
       local $/;
       if ( my $fd = $self->body ) {
           $body = <$fd>
	}
     }
    return $body
}


=head2 upload - return upload content 

        print Dumper $request->upload;

For command:

 curl -i -X POST -H "Content-Type: multipart/form-data"\
        -F "data=@UserSettings.txt"\
        http://example.org/Upload

output:

    {
      'data' => {
        'headers' => {
          'Content-Type' => 'text/plain',
          'Content-Disposition' => 'form-data; name="data"; filename="UserSettings.txt"'   
          },
        'tempname' => '/tmp/txBmaz5Bpf.txt',
        'size' => 6704,
        'filename' => 'UserSettings.txt',
        'name' => 'data'
      }
    };

=cut

sub upload {
    my $self = shift;
    unless ( exists $self->{'http.body'} ) {
        $self->_parse_body();
    }

    my $http_body = $self->{'http.body'} || return {};
    return $http_body->upload;
}

=head2 set_header

   $cv->set_header("Content-Type" => 'text/html; charset=utf-8')

=cut

sub set_header {
    my ( $self, $name, $par ) = @_;

    #collect -cookies
    if ( $name eq 'Set-Cookie' ) {
        push @{ $self->{headers}->{$name} }, $par;
    }
    else {
        $self->{headers}->{$name} = $par;
    }
}

=head3 print_headers [ header1=>value, ...]

Method for output headers

    $self->response->get_request->set_header(
        'Set-Cookie',
        {
            path    => '/',
            domain  => '.example.com',
            name    => 'userid',
            value   => $self->_current_user->id,
            expires => time() + 60 * 60 * 24 * 1,    # 1 day
            secure => 1,
            httpOnly = >1

        }
    );

=cut

sub print_headers {
    my $self = shift;
    #save cookie
    my $cookie = delete $self->{headers}->{"Set-Cookie"};
    #merge in and exists headers
    my %headers = ( %{ $self->{headers} } , @_ );
    #merge cookies
    if ( $cookie  ) {
        push @{ $headers{"Set-Cookie"} }, @$cookie;
    }
    my @cookies_headers = ();
    #format cookies
    if ( my $cookies = delete $headers{"Set-Cookie"} ) {
       foreach my $c ( @$cookies ) {
          my $hvalue;
          if (ref($c) eq 'HASH') {
#            Set-Cookie: srote=ewe&1&1&2; path=$path
            $hvalue = "$c->{name}=$c->{value}";
            my $path = $c->{path} || '/';
            $hvalue .="; path=$path";
            if ( my $domain = $c->{domain} ) {
                $hvalue .= "; domain=$domain"
            }
            if (my $expires = $c->{expires}) {
              $expires = WebDAO::Util::expire_calc($expires);
              my @MON  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
              my @WDAY = qw( Sun Mon Tue Wed Thu Fri Sat );
              my($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($expires);
              $year += 1900;
              $expires = sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
                       $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);
              $hvalue .="; expires=$expires";
            }
            if ( $c->{ secure } ) {
                $hvalue .= "; secure"
            }
            if ($c->{httponly}) {
                $hvalue .= "; HttpOnly"
            }
          } else { $hvalue = $c }
          push @cookies_headers, "Set-Cookie", $hvalue;
       } 
    }
    my $status = $self->status;
    my $fd = $self->{writer}->([$status||"200", [%headers, @cookies_headers], undef]);
    $self->{fd} = $fd;
}

sub print {
    my $self = shift;
    if (exists $self->{fd}) {
        foreach my $line (@_) {
        utf8::encode( $line) if utf8::is_utf8($line);
        $self->{fd}->write($line);
        }
    } else {
    print @_;
    }
}

=head2 get_cookie 

return hashref to {key=>value}

=cut

sub get_cookie {
    my $self = shift;
    my $str = $self->{env}->{HTTP_COOKIE} || return {};
    if ($self->_parsed_cookies) { return $self->_parsed_cookies };
    my %res;
    %res =
      map { URI::Escape::uri_unescape($_) } map { split '=',$_,2  } split(/\s*[;]\s*/,
      $str);
    $self->_parsed_cookies(\%res);
    \%res;
}


1;


