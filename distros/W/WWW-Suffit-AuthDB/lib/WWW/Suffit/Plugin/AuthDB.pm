package WWW::Suffit::Plugin::AuthDB;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::AuthDB - The Suffit plugin for Suffit Authorization Database

=head1 SYNOPSIS

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('AuthDB', {
            ds => "sqlite:///tmp/auth.db?sqlite_unicode=1",
        });

        # . . .
    }

=head1 DESCRIPTION

The Suffit plugin for Suffit Authorization Database

=head1 OPTIONS

This plugin supports the following options

=head2 cached

    cached => 1
    cached => 'yes'
    cached => 'on'
    cached => 'enable'

This option defines status of caching while establishing of connection to database

See L<WWW::Suffit::AuthDB/cached>

Default: false (no caching connection)

=head2 ds

    ds => "sqlite:///tmp/auth.db?sqlite_unicode=1"

Data source URI. See L<WWW::Suffit::AuthDB::Model>

See L<WWW::Suffit::AuthDB/"ds, dsuri">

Default: 'sponge://'

=head2 expiration

    expiration => 300

The expiration time

See L<WWW::Suffit::AuthDB/expiration>

Default: 300 (5 min)

=head2 max_keys

    max_keys => 1024

The maximum keys number in cache

See L<WWW::Suffit::AuthDB/max_keys>

Default: 1024*1024 (1`048`576 keys max)

=head2 sourcefile

    sourcefile => '/tmp/authdb.json'

Path to the source file in JSON format

See L<WWW::Suffit::AuthDB/sourcefile>

Default: none

=head1 HELPERS

This plugin implements the following helpers

=head2 authdb

    my $authdb = $self->authdb;

This helper returns the L<WWW::Suffit::AuthDB> instance

=head1 METHODS

This plugin inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

    $plugin->register(Mojolicious->new, {
        ds => "sqlite:///tmp/auth.db?sqlite_unicode=1",
    });

Register plugin in L<Mojolicious> application

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Server>, L<WWW::Suffit::AuthDB>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

use WWW::Suffit::AuthDB;

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $opts //= {};

    # Ok
    return $app->helper(authdb => sub {
        state $authdb = WWW::Suffit::AuthDB->new(%$opts)
    });
}

1;

__END__
