use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package WebService::WTFIsMyIP 0.01 {

    # ABSTRACT: Client for wtfismyip.com


    use Ref::Util qw( is_blessed_ref );
    use JSON::MaybeXS qw( decode_json );
    use Class::Tiny {
        ua => sub {
            require HTTP::Tiny;
            return HTTP::Tiny->new;
        },
        base_url => "https://wtfismyip.com/",
    };

    sub BUILD ($self, $) {
        unless(is_blessed_ref $self->ua) {
            die "ua must be an instance of HTTP::AnyUA or a user agent supported by HTTP::AnyUA";
        }
        unless($self->ua->isa("HTTP::AnyUA")) {
            require HTTP::AnyUA;
            $self->ua(HTTP::AnyUA->new($self->ua));
        }

        unless(is_blessed_ref $self->base_url && $self->base_url->isa("URI")) {
            require URI;
            $self->base_url(URI->new("@{[ $self->base_url ]}"));
        }
    }


    sub json ($self) {

        my $url = $self->base_url->clone;
        $url->path("/json");

        my $res = $self->ua->get($url);
        if($res->{success}) {
            my %hash = decode_json($res->{content})->%*;
            foreach my $key (keys %hash) {
                my $new_key = $key =~ s/^YourFucking//r;
                $hash{$new_key} = delete $hash{$key} if $key ne $new_key;
            }
            return \%hash;
        } else {
            die sprintf("%s %s: %s", $res->{status}, $res->{reason}, $url);;
        }
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::WTFIsMyIP - Client for wtfismyip.com

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use WebService::WTFIsMyIP;
 
 my $wtfismyip = WebService::WTFIsMyIP->new;
 say "your IP is", $wtfismyip->json->{IPAddress};

=head1 DESCRIPTION

This class provides an interface to the L<wtfismyip|https://wtfismyip.com> service.

=head1 CONSTRUCTOR

 my $wtfismyip = WebService::WTFIsMyIP->new(%attributes);

Create a new instance of the client.  Attributes available:

=over 4

=item ua

Should be an instance of L<HTTP::AnyUA>, or any class supported by L<HTTP::AnyUA>.
L<HTTP::Tiny> is used by default.

=item base_url

The base URL to use.  C<https://wtfismyip.com/> is used by default.

=back

=head1 METHODS

=head2 json

 my %hash = $wtfismyip->json->%*;

Returns a hash that contains fields such as C<IPAddress> and C<ISP>.  The method
is so named after the endpoint that it calls, although the return value is converted
into a Perl hash ref.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
