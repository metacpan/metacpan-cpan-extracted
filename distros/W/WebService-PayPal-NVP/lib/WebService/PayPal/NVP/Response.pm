package WebService::PayPal::NVP::Response;
$WebService::PayPal::NVP::Response::VERSION = '0.006';
use Moo;

has 'raw'     => ( is => 'rw', default => sub { {} } );
has 'success' => ( is => 'rw', default => sub { 0 } );
has 'errors'  => ( is => 'rw', default => sub { [] } );
has 'branch'  => (
    is  => 'rw',
    isa => sub {
        die "Response branch expects 'live' or 'sandbox' only\n"
            if $_[0] ne 'live' and $_[0] ne 'sandbox';
    }
);

sub express_checkout_uri {
    my ($self) = @_;
    if ( $self->can('token') ) {
        my $www = $self->branch eq 'live' ? 'www' : 'www.sandbox';
        return
            "https://${www}.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token="
            . $self->token
            . "&useraction=commit";
    }

    return;
}

sub has_arg {
    my ( $self, $arg ) = @_;
    return $self->can($arg);
}

sub has_errors {
    my $self = shift;
    return scalar @{ $self->errors } > 0;
}

sub args {
    my ($self) = @_;
    my @moothods = qw/
        around before can after
        import with new has
        options errors extends
        args has_arg has_errors
        /;
    my @options;
listmethods: {
        no strict 'refs';
        foreach my $key ( keys %{"WebService::PayPal::NVP::Response::"} ) {
            if ( $key =~ /^[a-z]/ and not grep { $_ eq $key } @moothods ) {
                push @options, $key;
            }
        }
    }

    return wantarray ? @options : \@options;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::NVP::Response - PayPal NVP API response object

=head1 VERSION

version 0.006

=head2 raw

raw response (HASHREF)

=head2 success

Returns true on success, false on failure.

=head2 branch

Returns either 'live' or 'sandbox'.

=head2 errors

Returns an C<ArrayRef> of errors.  The ArrayRef is empty when there are no
errors.

=head2 has_errors

Returns true if C<errors()> is non-empty.

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2017 by Brad Haywood.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# ABSTRACT: PayPal NVP API response object
