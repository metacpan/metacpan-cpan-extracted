package Test::Sys::Info::Driver;
use strict;
use warnings;
use vars qw( $VERSION );
use Test::More;
use Carp qw( croak );
use constant DRIVER_MODULES => (
    'Sys::Info::OS',
    'Sys::Info::Device',
    'Sys::Info::Constants',
    'Sys::Info::Driver::%s',
    'Sys::Info::Driver::%s::OS',
    'Sys::Info::Driver::%s::Device',
    'Sys::Info::Driver::%s::Device::CPU',
);

$VERSION = '0.21';

sub new {
    my $class = shift;
    my $id    = shift || croak 'Driver ID is missing';
    my @suite = map { sprintf $_, $id } DRIVER_MODULES;
    foreach my $module ( @suite ) {
        require_ok( $module );
        ok( $module->import || 1, "$module imported" );
    }
    my $self  = {
        _id  => $id,
        _cpu => Sys::Info::Device->new('CPU'),
        _os  => Sys::Info::OS->new,
    };
    bless $self, $class;
    return $self;
}

sub run {
    my $self = shift;
    my @tests = grep { m{ \A test_ }xms } sort keys %Test::Sys::Info::Driver::;
    foreach my $test ( @tests ) {
        $self->$test();
    }
    return 1;
}

sub test_os {
    my $self = shift;
    my $os   = $self->os;
    my @methods;

    ok( defined $os->name                      , 'OS name is defined');
    ok( defined $os->name(qw(long 1 ) )        , 'OS long name is defined');
    ok( defined $os->name(qw(long 1 edition 1)), 'OS long name with edition is defined');
    ok( defined $os->version                   , 'OS Version is defined');
    ok( defined $os->build                     , 'OS build is defined');
    ok( defined $os->uptime                    , 'Uptime is defined');
    #ok( defined $os->login_name                , 'Login name is defined');
    #ok( defined $os->login_name( real => 1 )   , 'Real login name is defined');
    ok( defined $os->tick_count                , 'Tick count is defined');
    #ok( defined $os->ip                        , 'IP is defined');

    #these seem to fail on some environments disable defined test for now
    push @methods, qw( ip login_name );
    ok( $os->login_name( real => 1 ) || 1, 'Able to call login_name( real => 1 )' );

    push @methods, qw(
        edition
        bitness
        node_name   host_name
        domain_name workgroup
        is_windows  is_win32 is_win is_winnt is_win95 is_win9x
        is_linux    is_lin
        is_bsd
        is_unknown
        is_admin    is_admin_user is_adminuser
        is_root     is_root_user  is_rootuser
        is_su       is_superuser  is_super_user
        logon_server
        time_zone
        tz
        cdkey
        product_type
    );

    $self->just_test_successful_call( $os, @methods );
    ok( $os->cdkey( office => 1 ) || 1, 'cdkey() with office parameter called successfully');

    # TODO: test the keys
    ok( my %fs   = $os->fs  , 'FS is defined');
    ok( my %meta = $os->meta, 'Meta is defined');
    return;
}

sub test_device_cpu {
    my $self = shift;
    my $cpu  = $self->cpu;

    my @methods = qw(
        ht
        hyper_threading
        bitness
        load
        speed
        count
    );

    $self->just_test_successful_call( $cpu, @methods );

    # TODO: more detailed tests

    ok( $cpu->identify || 1, 'CPU identified' );
    ok( my @cpu = $cpu->identify or (), 'CPU identified in list context' );

    my $load_00 = $cpu->load(  );
    my $load_01 = $cpu->load(Sys::Info::Constants->DCPU_LOAD_LAST_01);
    my $load_05 = $cpu->load(Sys::Info::Constants->DCPU_LOAD_LAST_05);
    my $load_10 = $cpu->load(Sys::Info::Constants->DCPU_LOAD_LAST_10);
    return;
}

sub just_test_successful_call {
    my($self, $obj, @methods) = @_;
    foreach my $method ( @methods ) {
        ok( $obj->$method() || 1, "$method() called successfully");
    }
    return;
}

sub cpu { return shift->{_cpu} }
sub os  { return shift->{_os}  }
sub id  { return shift->{_id}  }

1;

__END__

=pod

=head1 NAME

Test::Sys::Info::Driver - Tests Sys::Info driver integrity.

=head1 SYNOPSIS

-

=head1 DESCRIPTION

This document describes version C<0.21> of C<Test::Sys::Info::Driver>
released on C<5 July 2016>.

Can not be used directly. See L<Test::Sys::Info> for more information.

=head1 METHODS

=head2 new

=head2 cpu

=head2 id

=head2 os

=head2 run

=head2 test_os

=head2 test_device_cpu

=head2 just_test_successful_call

=head1 SEE ALSO

L<Sys::Info>, L<Test::Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
