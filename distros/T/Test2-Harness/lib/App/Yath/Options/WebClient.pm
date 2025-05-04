package App::Yath::Options::WebClient;
use strict;
use warnings;

our $VERSION = '2.000005';

use Getopt::Yath;

option_group {group => 'webclient', category => "Web Client Options"} => sub {
    option url => (
        type => 'Scalar',
        alt => ['uri'],
        description => "Yath server url",
        long_examples  => [" http://my-yath-server.com/..."],
        from_env_vars => [qw/YATH_URL/],
    );

    option api_key => (
        type => 'Scalar',
        description => "Yath server API key. This is not necessary if your Yath server instance is set to single-user",
        from_env_vars => [qw/YATH_API_KEY/],
    );

    option grace => (
        type => 'Bool',
        description => "If yath cannot connect to a server it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.",
        default => 0,
    );

    option request_retry => (
        type => 'Count',
        description => "How many times to try an operation before giving up",
        default => 0,
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::WebClient - FIXME

=head1 DESCRIPTION

=head1 PROVIDED OPTIONS

=head2 Web Client Options

=over 4

=item --api-key ARG

=item --api-key=ARG

=item --no-api-key

Yath server API key. This is not necessary if your Yath server instance is set to single-user

Can also be set with the following environment variables: C<YATH_API_KEY>


=item --grace

=item --no-grace

If yath cannot connect to a server it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --request-retry

=item --request-retry=COUNT

=item --no-request-retry

How many times to try an operation before giving up

Note: Can be specified multiple times, counter bumps each time it is used.


=item --url http://my-yath-server.com/...

=item --uri http://my-yath-server.com/...

=item --no-url

Yath server url

Can also be set with the following environment variables: C<YATH_URL>


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

