package WWW::Curl::UserAgent::Request;
{
  $WWW::Curl::UserAgent::Request::VERSION = '0.9.6';
}

use Moose;
use WWW::Curl::Easy;

has http_request => (
    is       => 'ro',
    isa      => 'HTTP::Request',
    required => 1,
);

has connect_timeout => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has timeout => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has keep_alive => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has followlocation => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has max_redirects => (
    is      => 'ro',
    isa     => 'Int',
    default => -1,
);

has curl_easy => (
    is         => 'ro',
    isa        => 'WWW::Curl::Easy',
    lazy_build => 1,
);

has header_ref => (
    is      => 'ro',
    isa     => 'Ref',
    default => sub { my $header; \$header },
);

has content_ref => (
    is      => 'ro',
    isa     => 'Ref',
    default => sub { my $content; \$content },
);

sub _build_curl_easy {
    my $self = shift;

    my $easy    = WWW::Curl::Easy->new;
    my $request = $self->http_request;

    $easy->setopt( CURLOPT_CONNECTTIMEOUT_MS, $self->connect_timeout );
    $easy->setopt( CURLOPT_HEADER,            0 );
    $easy->setopt( CURLOPT_NOPROGRESS,        1 );
    $easy->setopt( CURLOPT_TIMEOUT_MS,        $self->timeout );
    $easy->setopt( CURLOPT_URL,               $request->uri );
    $easy->setopt( CURLOPT_WRITEHEADER,       $self->header_ref );
    $easy->setopt( CURLOPT_WRITEDATA,         $self->content_ref );
    $easy->setopt( CURLOPT_FORBID_REUSE,      !$self->keep_alive );
    $easy->setopt( CURLOPT_FOLLOWLOCATION,    $self->followlocation );
    $easy->setopt( CURLOPT_MAXREDIRS,         $self->max_redirects );

    # see https://github.com/pauldix/typhoeus/blob/master/lib/typhoeus/easy.rb#L197
    if ( $request->method eq 'GET' ) {
        $easy->setopt( CURLOPT_HTTPGET, 1 );
    }
    elsif ( $request->method eq 'POST' ) {
        use bytes;
        my $content = $request->content;
        $easy->setopt( CURLOPT_POST,           1 );
        $easy->setopt( CURLOPT_POSTFIELDSIZE,  length $content );
        $easy->setopt( CURLOPT_COPYPOSTFIELDS, $content );
    }
    elsif ( $request->method eq 'PUT' ) {
        use bytes;
        my $content = $request->content;
        $easy->setopt( CURLOPT_UPLOAD,        1 );
        $easy->setopt( CURLOPT_INFILE,        \$content );
        $easy->setopt( CURLOPT_INFILESIZE,    length $content );
        $easy->setopt( CURLOPT_READFUNCTION,  \&_read_callback );
        $easy->setopt( CURLOPT_WRITEFUNCTION, \&_chunk_callback );
    }
    elsif ( $request->method eq 'HEAD' ) {
        $easy->setopt( CURLOPT_NOBODY, 1 );
    }
    else {
        $easy->setopt( CURLOPT_CUSTOMREQUEST, uc $request->method );
    }

    my @headers;
    foreach my $h ( +$request->headers->header_field_names ) {
        push( @headers, "$h: " . $request->header($h) );
    }
    push @headers, "Connection: close" unless $self->keep_alive;
    $easy->setopt( CURLOPT_HTTPHEADER, \@headers )
        if scalar(@headers);

    return $easy;
}

sub _read_callback {
    my ( $maxlength, $pointer ) = @_;
    my $data = substr( $$pointer, 0, $maxlength );
    $$pointer =
      length($$pointer) > $maxlength
      ? scalar substr( $$pointer, $maxlength )
      : '';
    return $data;
}

sub _chunk_callback {
    my ( $data, $pointer ) = @_;
    ${$pointer} .= $data;
    return length($data);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
