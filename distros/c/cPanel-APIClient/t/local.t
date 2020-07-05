package t::local;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw(
  TestBase
);

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MockModule;

use JSON;

__PACKAGE__->new()->runtests() if !caller;

sub TRANSPORT { return ['CLISync'] }

sub AWAIT { return $_[1] }

sub _CP_REQUIRE {
    return sub {
        if ( !-e '/usr/local/cpanel/bin/uapi' ) {
            die "This server does not appear to run cPanel & WHM.\n";
        }
    };
}

sub _mock_ipc_run : Tests(startup) {
    my ($self) = @_;

    my %mock_prog = (
        _usr_local_cpanel_bin_uapi => sub {
            my (@args) = @_;

            my @prog_args = grep { m<\A--> } @args;
            my ( $mod, $fn, @api_args ) = grep { !m<\A--> } @args;

            die 'Wrong module!' if $mod ne 'Test';

            if ( $fn =~ m<fail> ) {
                $? = 22 << 8;    # exit 22
            }
            elsif ( $fn =~ m<sigterm> ) {
                require POSIX;
                $? = POSIX::SIGTERM();
            }
            elsif ( $fn =~ m<sigquit> ) {
                require POSIX;
                $? = POSIX::SIGQUIT() & 128;
            }
            else {
                return JSON::encode_json(
                    {
                        result => {
                            status => 1,
                            data   => {
                                program => \@prog_args,
                                api     => \@api_args,
                            },
                        },
                    }
                );
            }

            return undef;
        },
    );

    my $mm = Test::MockModule->new('IPC::Run');
    $mm->redefine(
        run => sub {
            my ( $cmd_ar, $in, $out_sr, $err, $xtra ) = @_;

            is( $$in, q<>, "Input should be empty string." );

            isa_ok( $out_sr, 'SCALAR', "Output should be a string ref." );

            is( $err, \*STDERR, 'Error out should be STDOUT.' );

            my ( $prog, @args ) = @$cmd_ar;
            $prog =~ tr</><_>;

            my $prog_cr = $mock_prog{$prog} or die "Bad program: $cmd_ar->[0]";

            return 1 if $$out_sr = $prog_cr->(@args);

            return undef;
        }
    );

    $self->{'_ipc_run_mock'} = $mm;

    return;
}

sub fail_sigterm : Tests(4) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username => 'johnny',
        },
    );

    my $got = exception {
        $self->AWAIT(
            $remote_cp->call_uapi( 'Test', 'sigterm' ),
        );
    };

    cmp_deeply(
        $got,
        all(
            Isa('cPanel::APIClient::X::CommandFailed'),
            re(qr<TERM>),
            re(qr<15>),
            re(qr<bin/uapi>),
            re(qr<Test>),
            re(qr<sigterm>),
        ),
        'expected error',
    );

    return;
}

sub invalid_authn : Tests(1) {
    my ($self) = shift;

    cmp_deeply(
        exception {
            $self->CREATE(
                service => 'cpanel',

                credentials => {
                    username  => 'johnny',
                    api_token => 'MYTOKEN',
                },
            );
        },
        re(qr<CLISync>),
        'failure when try to authenticate via API token',
    );

    return;
}

sub require_username_as_admin : Tests(1) {
    my ($self) = @_;

  SKIP: {
        skip 'Must be run as admin.', $self->num_tests() if $>;

        cmp_deeply(
            exception {
                $self->CREATE(
                    service => 'cpanel',
                );
            },
            re(qr<cpanel>),
            'failure when run for cPanel as admin but without username',
        );
    }

    return;
}

sub fail_undef_arg : Tests(1) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username => 'johnny',
        },
    );

    my $got = exception {
        $self->AWAIT(
            $remote_cp->call_uapi( 'Test', 'whatsit',  { foo => undef } ),
        );
    };

    cmp_deeply(
        $got,
        all(
            re(qr<undef>),
        ),
        'expected error',
    ) or diag explain $got;

    return;
}

sub fail_exit : Tests(4) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username => 'johnny',
        },
    );

    my $got = exception {
        $self->AWAIT(
            $remote_cp->call_uapi( 'Test', 'myfail' ),
        );
    };

    cmp_deeply(
        $got,
        all(
            Isa('cPanel::APIClient::X::CommandFailed'),
            re(qr<22>),
            re(qr<bin/uapi>),
            re(qr<Test>),
            re(qr<myfail>),
        ),
        'expected error',
    ) or diag explain $got;

    return;
}

sub simple : Tests(5) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username => 'johnny',
        },
    );

    my $got = $self->AWAIT(
        $remote_cp->call_uapi(
            'Test', 'normal',
            {
                foo => 1,
                bar => [ 2, 3, '"' ],
                '"' => '"',
            },
        ),
    );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::UAPI' ] => bool(1),
                succeeded                                      => 1,
                get_data                                       => {
                    program => bag(
                        '--output=json',
                        '--user=johnny',
                    ),
                    api => bag(
                        '%22=%22',
                        'bar=2',
                        'bar=3',
                        'bar=%22',
                        'foo=1',
                    ),
                },
            ),
            listmethods(
                get_errors   => [],
                get_warnings => [],
                get_messages => [],
            ),
        ),
        'UAPI response',
    ) or diag explain $got;

    like(
        join( ' ', @{ $got->get_data()->{'api'} } ),
        qr<bar=2.+bar=3.+bar=%22>,
        '“bar” arguments are in correct order',
    );

    return;
}

sub simple__no_username : Tests(5) {
    my ($self) = shift;

    local $> = 1;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',
    );

    my $got = $self->AWAIT(
        $remote_cp->call_uapi(
            'Test', 'normal',
            {
                foo => 1,
                bar => [ 2, 3, '"' ],
                '"' => '"',
            },
        ),
    );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::UAPI' ] => bool(1),
                succeeded                                      => 1,
                get_data                                       => {
                    program => bag(
                        '--output=json',
                    ),
                    api => bag(
                        '%22=%22',
                        'bar=2',
                        'bar=3',
                        'bar=%22',
                        'foo=1',
                    ),
                },
            ),
            listmethods(
                get_errors   => [],
                get_warnings => [],
                get_messages => [],
            ),
        ),
        'UAPI response',
    ) or diag explain $got;

    like(
        join( ' ', @{ $got->get_data()->{'api'} } ),
        qr<bar=2.+bar=3.+bar=%22>,
        '“bar” arguments are in correct order',
    );

    return;
}

1;
