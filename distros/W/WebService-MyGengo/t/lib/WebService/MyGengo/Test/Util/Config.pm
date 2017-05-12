package WebService::MyGengo::Test::Util::Config;

use strict;
use warnings;

use Exporter;

use vars qw(@ISA @EXPORT);
use base qw(Exporter);

@EXPORT = qw(config);

=head1 NAME

WebService::MyGengo::Test::Util::Config - Basic API configuration

=head1 SYNOPSIS

    # t/some-test.t
    use WebService::MyGengo::Test::Util:Config;:

    # $config == { public_key => 'pubkey', private_key => 'privkey', use_sandbox => 1 };
    my $config = config();

=head1 DESCRIPTION

=over

=item public_key - Your API public key

=item private_key - Your API private key

=item use_sandbox - 0 = production, 1 = sandbox, 2 = mock

* Defaults to 2

* See L<WebService::MyGengo::Test::Util::Client>

=back

=cut
sub config {
    return {
        public_key      => 'pubkey'
        , private_key   => 'privkey'
        , use_sandbox   => $ENV{WS_MYGENGO_USE_SANDBOX} // 2
        };
}


1;

=head1 TODO

Read config data from a nice, happy config file somewhere sane.

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
