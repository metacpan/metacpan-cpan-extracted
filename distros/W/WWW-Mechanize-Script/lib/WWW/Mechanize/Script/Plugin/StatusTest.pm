package WWW::Mechanize::Script::Plugin::StatusTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

# ABSTRACT: prove expected HTTP status of the response

our $VERSION = '0.100';

use 5.014;


sub check_value_names
{
    return qw(response);
}


sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $response_code = 0 + $self->get_check_value( $check, "response" );

    if ( $response_code != $mech->status() )
    {
        my $err_code = $self->get_check_value( $check, "response_code" ) // 1;
        return ( $err_code, "response code " . $mech->status() . " != $response_code" );
    }

    return (0);
}

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script::Plugin::StatusTest - prove expected HTTP status of the response

=head1 VERSION

version 0.101

=head1 METHODS

=head2 check_value_names()

Returns qw(response).

=head2 check_response(\%check,$mech)

This methods proves whether the HTTP status code of the response matches the
value configured in I<response> and accumulates I<response_code> into I<$code>
when not.

Return the accumulated I<$code> and appropriate constructed message, if
coparisation failed.

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
