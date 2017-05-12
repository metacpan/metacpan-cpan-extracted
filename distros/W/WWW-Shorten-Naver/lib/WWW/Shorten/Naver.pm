package WWW::Shorten::Naver;
use strict;
use warnings;
use Carp ();
use JSON::MaybeXS;
use URI ();
use Scalar::Util qw(blessed);
use parent qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw(new VERSION);

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use constant NAVER_SHORTEN_API_ENDPOINT => $ENV{NAVER_SHORTEN_API_URL} || 'https://openapi.naver.com/v1/util/shorturl';

sub _attr {
    my $self = shift;
    my $attr = lc(_trim(shift) || '');
    # attribute list is small enough to just grep each time. meh.
    Carp::croak("Invalid attribute") unless grep {$attr eq $_} @{_attrs()};
    return $self->{$attr} unless @_;

    my $val = shift;
    unless (defined($val)) {
        $self->{$attr} = undef;
        return $self;
    }
    $self->{$attr} = $val;
    return $self;
}

# _attrs (static, private)
{
    my $attrs; # mimic the state keyword
    sub _attrs {
        return [@{$attrs}] if $attrs;
        $attrs = [
            qw(username password access_token client_id client_secret),
        ];
        return [@{$attrs}];
    }
}

sub _request {
    my ($self, $url) = @_;
    
    Carp::croak("Invalid URI object") unless $url && blessed($url) && $url->isa('URI');
    
    my $ua = __PACKAGE__->ua();
    $ua->default_header( 'X-Naver-Client-ID'     => $self->client_id     );
    $ua->default_header( 'X-Naver-Client-Secret' => $self->client_secret );

    my $res = $ua->get($url);
    Carp::croak("Invalid response") unless $res;
    unless ($res->is_success) {
        Carp::croak($res->status_line);
    }

    my $content_type = $res->header('Content-Type');
    my $content = $res->decoded_content();
    unless ($content_type && $content_type =~ m{application/json}) {
        Carp::croak("Unexpected response: $content");
    }
    my $json = decode_json($content);
    Carp::croak("Invalid data returned: $content") unless $json;
    return $json->{result};
}

# _parse_args (static, private)
sub _parse_args {
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to method could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif (@_==1 && !ref($_[0])) {
        $args = {single_arg => $_[0]};
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("Method got an odd number of elements");
    }
    return $args;
}

# _trim (static, private)
sub _trim {
    my $input = shift;
    return $input unless defined $input && !ref($input) && length($input);
    $input =~ s/\A\s*//;
    $input =~ s/\s*\z//;
    return $input;
}

sub new {
    my $class = shift;
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to $class->new() could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("$class->new() got an odd number of elements");
    }

    my $attrs = _attrs();
    my $href = {};
    for my $key (%{$args}) {
        $href->{$key} = $args->{$key};
    }
    return bless $href, $class;
}


sub client_id { return shift->_attr('client_id', @_); }

sub client_secret { return shift->_attr('client_secret', @_); }

sub makeashorterlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Naver')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    $self ||= __PACKAGE__->new(@_);
    my $res = $self->shorten( url => $url, @_);
    return $res->{url};
}

sub makealongerlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Bitly')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makealongerlink');
    $self ||= __PACKAGE__->new(@_);
    my $longer_url = $self->expand( url => $url );
    return $longer_url;
}

sub expand {
    my $self = shift; 
    my $args = _parse_args(@_);
    my $short_url = $args->{url};
    unless ($short_url) {
        Carp::croak("A shortUrl parameter is required.\n");
    }
 
    my $url = URI->new($short_url);
    my $ua = __PACKAGE__->ua();
    my $res = $ua->get($url);
    my $longer_url = $res->header('Location');
    return $longer_url;    
}

sub shorten {
    my $self = shift;

    my $args = _parse_args(@_);

    my $long_url = $args->{url};
    unless ($long_url) {
        Carp::croak("A longUrl parameter is required.\n");
    }

    my $url = URI->new(NAVER_SHORTEN_API_ENDPOINT);
    $url->query_form(
        url => $long_url,
    );
    return $self->_request($url, $args);
}

1; # End of WWW::Shorten::Naver
__END__
=head1 NAME

WWW::Shorten::Naver - Interface to shortening URLs using Naver Shorten URL API

=head1 SYNOPSIS

The traditional way, using the L<WWW::Shorten> interface:

    use strict;
    use warnings;
    use WWW::Shorten::Naver;
    # use WWW::Shorten 'Naver';  # or, this way

    my $short = makeashorterlink('http://www.foo.com/some/long/url', {
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
        ...
    });

Or, the Object-Oriented way:

    use strict;
    use warnings;
    use Data::Dumper;
    use WWW::Shorten::Naver;

    my $shortener = WWW::Shorten::Naver->new(
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
    );

    my $res = $shortener->shorten( url => 'http://google.com/');
    say Dumper $res;

    # {
    #   hash => "GyvykVAu",
    #   orgUrl => "http://me2.do/GyvykVAu",
    #   url => "http://d2.naver.com/helloworld/4874130"
    # }

=head1 DESCRIPTION

A Perl interface to the L<Naver Shorten URL API|https://developers.naver.com/docs/utils/shortenurl>.
You can either use the traditional (non-OO) interface provided by L<WWW::Shorten>.
Or, you can use the OO interface that provides you with more functionality.

=head1 FUNCTIONS

In the non-OO form, L<WWW::Shorten::Naver> makes the following functions available.

=head2 makeashorterlink

    my $short_url = makeashorterlink('https://some_long_link.com', {
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret'
    });    

The function C<makeashorterlink> will call the Naver Shorten URL API,
passing it your long URL and will return the shorter version.
It requires the use of Client ID and Client Secret to shorten links.

=head1 METHODS

In the OO form, L<WWW::Shorten::Naver> makes the following methods available.

=head2 new

    my $shortenr = WWW::Shorten::Naver->new(
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
    );

Any or all of the attributes can be set in your configuration file. If you have
a configuration file and you pass parameters to C<new>, the parameters passed
in will take precedence.

=head2 shorten

    my $short = $shortenr->shorten(
        url => "http://www.example.com", # required.
    );
    say $short->{url};

Shorten a URL using L<https://developers.naver.com/docs/utils/shortenurl>. Returns a hash reference or dies.

=head1 AUTHOR

Jeen Lee <F<jeen@perl.kr>>

=head1 SEE ALSO

L<WWW::Shorten>, L<WWW::Shorten::Bitly>, L<https://developers.naver.com/docs/utils/shortenurl>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
