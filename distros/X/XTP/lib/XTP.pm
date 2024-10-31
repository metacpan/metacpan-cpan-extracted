package XTP 0.001;

use 5.016;
use warnings;
use XTP::Client;

1;

__END__


=head1 NAME

XTP - XTP Perl SDK

=head1 DESCRIPTION

XTP L<https://www.getxtp.com/> is a platform built on-top of the Extism
L<https://extism.org/> (L<Extism>) cross-language framework for building
with WebAssembly. This distribution provides an API client, to invite
guests and fetch Extism plugins so Perl programmers can easily and
safely run multi-tenant code within their Perl application using
WebAssembly.

=head1 SYNOPSIS

    use XTP;
    my $client = XTP::Client->new({
        token =>  $ENV{XTP_TOKEN},
        appId => 'app_01j9w5k56wf9ev69z1h158axjc',
        extism => {wasi => 1}
    });
    my $invite = $client->inviteGuest({
        guestKey => 'guestkey',
        deliveryMethod => 'link'
    });
    my $plugin = $client->getPlugin('on email', 'guestkey');
    my $result = $plugin->call('onEmail', \%email);

=head1 EXAMPLES

See <https://github.com/dylibso/xtp-email-demo/blob/main/autoresponder.pl>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc XTP

Additional documentation can be found on the XTP docs site
L<https://docs.xtp.dylibso.com/>

XTP support can be found on the support page
L<https://docs.xtp.dylibso.com/docs/support/>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Dylibso.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
