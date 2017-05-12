package WWW::Mechanize::Script::Plugin::ContentSizeTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

# ABSTRACT: check for size of received content

our $VERSION = '0.100';

use 5.014;


sub check_value_names
{
    return qw(min_bytes max_bytes);
}


sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $code = 0;
    my $msg;

    my $min_bytes = 0 + $self->get_check_value( $check, "min_bytes" );
    my $max_bytes = 0 + $self->get_check_value( $check, "max_bytes" );
    my $content_len = length $mech->response()->content();

    if ( defined($min_bytes) and $min_bytes > $content_len )
    {
        my $err_code = $self->get_check_value( $check, "min_bytes_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        $msg = "received $content_len bytes exceeds lower threshold ($min_bytes)";
    }

    if ( defined($max_bytes) and $max_bytes < $content_len )
    {
        my $err_code = $self->get_check_value( $check, "max_bytes_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        if ($msg)
        {
            $msg .= " and upper threshold ($max_bytes )";
        }
        else
        {
            $msg = "received $content_len bytes exceeds upper limit ($max_bytes)";
        }
    }

    return ( $code, ( $msg ? ($msg) : () ) );
}

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script::Plugin::ContentSizeTest - check for size of received content

=head1 VERSION

version 0.101

=head1 METHODS

=head2 check_value_names()

Returns qw(min_bytes max_bytes)

=head2 check_response(\%check,$mech)

Proves whether I<min_bytes> is greater than length of received content
(and accumulate I<min_bytes_code> into I<$code> when true) or
I<max_bytes> is lower than length of received content (and accumulate
I<max_bytes_code> into I<$code> when true).

Return the accumulated I<$code> and appropriate constructed message, if
any coparisation failed.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
