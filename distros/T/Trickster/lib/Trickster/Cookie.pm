package Trickster::Cookie;

use strict;
use warnings;
use v5.14;

use URI::Escape qw(uri_escape uri_unescape);
use Digest::SHA qw(hmac_sha256_hex);

sub new {
    my ($class, %opts) = @_;
    
    return bless {
        secret => $opts{secret},
        default_options => {
            path => '/',
            httponly => 1,
            samesite => 'Lax',
            %{$opts{defaults} || {}},
        },
    }, $class;
}

sub get {
    my ($self, $req, $name) = @_;
    
    # Get raw cookie header to avoid double-decoding
    my $cookie_header = $req->env->{HTTP_COOKIE} || '';
    
    # Parse cookie manually to avoid Plack::Request's URI decoding
    my $value;
    if ($cookie_header =~ /(?:^|;\s*)$name=([^;]+)/) {
        $value = $1;
    } else {
        return undef;
    }
    
    # Verify signature if secret is set
    if ($self->{secret} && $value =~ /^(.+)\.([^.]+)$/) {
        my ($data, $sig) = ($1, $2);
        my $expected_sig = $self->_sign($data);
        
        return undef unless $sig eq $expected_sig;
        return uri_unescape($data);
    }
    
    return uri_unescape($value);
}

sub set {
    my ($self, $res, $name, $value, %opts) = @_;
    
    my %options = (%{$self->{default_options}}, %opts);
    
    # Sign the value if secret is set
    if ($self->{secret}) {
        my $escaped = uri_escape($value);
        my $sig = $self->_sign($escaped);
        $value = "$escaped.$sig";
    } else {
        $value = uri_escape($value);
    }
    
    my @cookie_parts = ("$name=$value");
    
    push @cookie_parts, "Path=$options{path}" if $options{path};
    push @cookie_parts, "Domain=$options{domain}" if $options{domain};
    push @cookie_parts, "Max-Age=$options{max_age}" if defined $options{max_age};
    push @cookie_parts, "Expires=$options{expires}" if $options{expires};
    push @cookie_parts, "Secure" if $options{secure};
    push @cookie_parts, "HttpOnly" if $options{httponly};
    push @cookie_parts, "SameSite=$options{samesite}" if $options{samesite};
    
    $res->header('Set-Cookie' => join('; ', @cookie_parts));
    
    return $res;
}

sub delete {
    my ($self, $res, $name, %opts) = @_;
    
    return $self->set($res, $name, '', %opts, max_age => 0);
}

sub _sign {
    my ($self, $data) = @_;
    
    return hmac_sha256_hex($data, $self->{secret});
}

1;

__END__

=head1 NAME

Trickster::Cookie - Secure cookie handling for Trickster

=head1 SYNOPSIS

    use Trickster::Cookie;
    
    my $cookie = Trickster::Cookie->new(
        secret => 'your-secret-key',
        defaults => {
            path => '/',
            httponly => 1,
            secure => 1,
        },
    );
    
    # Set a cookie
    $cookie->set($res, 'session_id', $session_id, max_age => 3600);
    
    # Get a cookie
    my $session_id = $cookie->get($req, 'session_id');
    
    # Delete a cookie
    $cookie->delete($res, 'session_id');

=head1 DESCRIPTION

Trickster::Cookie provides secure cookie handling with HMAC signing,
automatic escaping, and sensible defaults.

=cut
