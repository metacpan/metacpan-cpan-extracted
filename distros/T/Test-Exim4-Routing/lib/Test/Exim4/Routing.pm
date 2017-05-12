package Test::Exim4::Routing;
use strict;
use Test::Builder;
use parent 'Exporter';

=head1 NAME

Test::Exim4::Routing - test how exim4 routes mails

=head1 SYNOPSIS

  use strict;
  use Test::More;
  use Test::Exim4::Routing;

  plan tests => 18;

  # Set a custom mailer program
  #$Test::Exim4::Routing::mailer = '/opt/usr/sbin/exim4';

  config_ok;

  routes_ok 'postmaster2@test.internal';

  # Check that the router names resolve as we want them:
  routes_as 'postmaster2@test.internal', 'virtual_local_mailbox';
  routes_as 'outbound@example.com', 'dnslookup';

  routes_as 'corion', 'virtual_local_mailbox'; # because ~corion/.forward contains corion@corion.net
  routes_as 'corion@corion.net', 'virtual_local_mailbox';

  # Check our local domains
  for my $domain (qw( corion.net datenzoo.de )) {
    routes_as "postmaster\@$domain", 'virtual_local_mailbox';
  };

  # Check that our exim4 blacklists work:
  discards_ok 'vacation@corion.net';
  discards_ok 'michael.traven@corion.net';

  undeliverable_ok 'does-not-exist@corion.net';

=head1 NOTES

This module uses C<exim4> to verify how C<exim4> will route mails.
This is less a module to test your program and more a module to test
your system configuration, especially after changes to the mail
configuration.

No mails are sent by this module, as C<exim4> can tell us the routing
of mails without actually sending a mail. This means that we don't
need to clean up after testing the routing, but it also means that
other problems, like not enough diskspace or mail directories that
don't exist will not be detected by this test.

You will need a working copy of C<exim4> on the machine running these
tests.

So far, the module only checks against the default config
file and does not allow specifying a different configuration file
except in the C<config_ok> check.

=cut

use vars qw'@ISA $mailer @EXPORT_OK $VERSION';
$VERSION = '0.02';
BEGIN { @EXPORT_OK = qw(&routes_ok &routes_as &discards_ok &undeliverable_ok &config_ok) };
$mailer = '/usr/sbin/exim4';

=head1 EXPORTED TESTS

=head2 C<< config_ok $config_file >>

Checks that C<exim4> considers the configuration file
as syntactically valid. If C<$config_file> is not given,
the default config file of C<exim4> is used.

=cut

sub config_ok {
    my ($config_file) = (@_,'');
    my @output = `$mailer -bV $config_file 2>&1`;
    chomp @output;
    my $Test = Test::Builder->new;
    $config_file ||= 'default config';
    $Test->is_num($?, 0, "$config_file is valid")
        or $Test->diag(@output);
};

=head2 C<< routes_ok $address, $name >>

Checks that C<exim4> knows how to route the
email address C<$address>.

=cut

sub routes_ok {
    my ($address,$name) = @_;
    $name ||= "$address is routable";
    my @output = `$mailer -bt '$address' 2>&1`;
    chomp @output;
    my $Test = Test::Builder->new;
    $Test->is_num($?, 0, $name)
        or $Test->diag(@output);
};

=head2 C<< routes_as $address, $rule, $name >>

Checks that C<exim4> routes C<$address>
using the C<exim4> rule named C<$rule>.

=cut

sub routes_as {
    my ($address,$rule,$name) = @_;
    $name ||= "$address routes via rule '$rule'";
    my @output = `$mailer -bt '$address' 2>&1`;
    my $result = $?;
    chomp @output;
    my $Test = Test::Builder->new;
    if ($result == 0) {
        (my $router) = grep /router = /, @output;
        $Test->like( $router, qr/router = \Q$rule\E/, $name )
            or $Test->diag( join "\n", @output );
    } else {
        $Test->is_num( $result, 0, $name )
            or $Test->diag( join "\n", @output );
    };
}

=head2 C<< discards_ok $address, $name >>

Checks that C<exim4> discards mails
with C<$address> as a recipient.

=cut

sub discards_ok {
    my ($address,$name) = @_;
    $name ||= "$address gets discarded";
    my @output = `$mailer -bt '$address' 2>&1`;
    my $result = $?;
    chomp @output;
    my $Test = Test::Builder->new;
    if ($result == 0) {
        (my $router) = reverse grep /\Q$address\E/, @output;
        $Test->like( $router, qr/\bis discarded\b/, $name )
            or $Test->diag( join "\n", @output );
    } else {
        $Test->is_num( $result, 0, $name )
            or $Test->diag( join "\n", @output );
    };
};

=head2 C<< undeliverable_ok $address, $name >>

Checks that C<exim4> rejects mails
with C<$address> as a recipient
as undeliverable.

=cut

sub undeliverable_ok {
    my ($address,$name) = @_;
    $name ||= "$address is undeliverable";
    my @output = `$mailer -bt '$address' 2>&1`;
    my $Test = Test::Builder->new;
    (my $router) = grep /\Q$address\E is undeliverable/, @output;
    $Test->like( $router, qr/\bis undeliverable\b/, $name )
        or $Test->diag( join "\n", @output );
};

sub import {
    my($self,$other_mailer) = shift;
    my $pack = caller;

    if ($other_mailer) {
        $mailer = $other_mailer;
    };

    my $Test = Test::Builder->new;
    $Test->exported_to($pack);
    #$Test->plan(@_);

    $self->export_to_level(1, $self, @EXPORT_OK);
}

1;

__END__

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2008-2009 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

