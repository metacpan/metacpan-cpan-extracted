package MooX::Role::DBIConnection;
use Moo::Role;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;

our $VERSION = '0.01';

=head1 NAME

MooX::Role::DBIConnection - handy mixin for objects with a DB connection

=head1 SYNOPSIS

    { package My::Example;
      use Moo 2;
      with 'MooX::Role::DBIConnection';
    };

    # Connect using the parameters
    my $writer = My::Example->new(
        dbh => {
            dsn  => '...',
            user => '...',
            password => '...',
            options => '...',
        },
    );

    # ... or alternatively if you have a connection already
    my $writer2 = My::Example->new(
        dbh => $dbh,
    );

This module enhances your class constructor by allowing you to pass in either
a premade C<dbh> or the parameters needed to create one.

It will create the C<dbh> accessor

=head1 NOTE

This module will likely be spun out of the Weather::MOSMIX distribution


=cut

has 'dbh' => (
    is => 'lazy',
    default => \&_connect_db,
    coerce => sub {
        my $dbh = $_[0];
        if( ref($dbh) eq 'HASH' ) {
            $dbh = DBI->connect( @{$dbh}{qw{dsn user password options}});
        }
        $dbh
    }
);

#has 'dsn' => (
#    is => 'ro',
#);
#
#has 'user' => (
#    is => 'ro',
#);
#
#has 'password' => (
#    is => 'ro',
#);
#
#has 'options' => (
#    is => 'ro',
#);
#
#sub _connect_db( $self ) {
#    my $dbh = DBI->connect(
#        $self->dsn, $self->user, $self->password, $self->options
#    );
#}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/weather-mosmix>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-MOSMIX>
or via mail to L<www-Weather-MOSMIX@rt.cpan.org|mailto:Weather-MOSMIX@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019-2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
