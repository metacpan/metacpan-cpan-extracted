package testcases::Web::WebIdentifyUser;
use strict;
use XAO::Utils;
use CGI::Cookie;
use POSIX qw(mktime);
use Digest::SHA qw(sha1_base64 sha256_base64);
use Digest::MD5 qw(md5_base64);
use Error qw(:try);

use Data::Dumper;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_fail_blocking {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
                fail_max_count  => 3,                   # how many times allowed to fail
                fail_expire     => 2,                   # when to auto-expire failed status
                fail_time_prop  => 'failure_time',      # time of login failure
                fail_count_prop => 'failure_count',     # how many times failed
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
                failure_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                failure_count => {
                    type        => 'integer',
                    minvalue    => 0,
                    maxvalue    => 100,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t03     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 2,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t04     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 3,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t05     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 4,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => 1,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t06     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 4,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => 1,
                    '/IdentifyUser/member/fail_locked'              => 1,
                },
                text        => 'A',
            },
        },
        t07     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => 1,
                },
                text        => 'A',
            },
        },
        # Success after failures expire
        t08     => {
            sub_pre => sub { sleep(4) },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
        # Failing again, to see if counter drops to zero after success
        t09     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        # Success after single failure
        t10     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
        # failures, then success at the last moment
        t11     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t12     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 2,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t13     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 3,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t14     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_no_vf_key {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            key_charset => 'latin1',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12346',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },

        t03     => {
            sub_pre => sub {
                $m_list->get('m001')->put(password => 'qqqqq');
                $config->put('/identify_user/member/pass_encrypt','plaintext');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',
            },
        },

        t10     => {
            sub_pre => sub {
                $m_list->get('m001')->put(password => md5_base64('12345'));
                $config->put('/identify_user/member/pass_encrypt','md5');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },

        t11     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',
            },
        },

        t12     => {
            sub_pre => sub {
                delete $cjar{member_id};
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm003',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t13     => {
            args => {
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },
        #
        # Should not destroy existing cookie even if it can't recognize
        # the user
        #
        t14     => {
            cookies => {
                member_id   => 'm003',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm003',
                },
                text        => 'A',
            },
        },
        #
        # Should still be verified
        #
        t15     => {
            cookies => {
                member_id   => 'm001',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        # Adjusting the time and checking that verification expires, but
        # identification is still there.
        #
        t16     => {
            sub_pre => sub {
                $config->odb->fetch('/Members/m001')->put(verify_time => time - 125);
            },
            cookies => {
                member_id   => 'm001',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        #
        # Checking what's passed to the templates
        #
        t20     => {
            args => {
                mode        => 'check',
                type        => 'member',
                'identified.template' => '<$CB_URI$>|<$ERRSTR$>|<$TYPE$>|<$NAME$>|<$VERIFIED$>',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => '/IdentifyUser/member||member|m001|',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        #
        # Checking case translation
        #
        t21     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'M001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                },
                text        => 'V',
            },
        },
        t22     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_vf_key_simple {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t02     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t03     => {
            sub_pre => sub {
                $cjar{member_key_1}=$cjar{member_key};
                delete $cjar{member_key};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        t04     => {
            sub_pre => sub {
                $cjar{member_key}='1234';
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        t05     => {
            sub_pre => sub {
                $cjar{member_key}=$cjar{member_key_1};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t06     => {
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                    member_key  => undef,
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm001',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        t07     => {
            sub_pre => sub {
                $cjar{member_key}=$cjar{member_key_1};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        t08     => {
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },
        t09     => {
            sub_pre => sub {
                $cjar{member_key}=$cjar{member_key_1};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },
        t10     => {
            sub_pre => sub {
                $cjar{member_id}='m001',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_user_prop_list {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                user_prop       => 'Nicknames/nickname',
                id_cookie_type  => 'name',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                Nicknames => {
                    type        => 'list',
                    class       => 'Data::MemberNick',
                    key         => 'nickname_id',
                    structure   => {
                        nickname => {
                            type        => 'text',
                            maxlength   => '50',
                            index       => 1,
                            unique      => 1,
                            charset     => 'latin1',
                        },
                    },
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);
    my $n_list=$m_list->get('m001')->get('Nicknames');
    my $n_obj=$n_list->get_new;
    $n_obj->put(nickname    => 'n1');
    $n_list->put(id1 => $n_obj);
    $n_obj->put(nickname    => 'n2');
    $n_list->put(id2 => $n_obj);
    $n_obj->put(nickname    => 'n3');
    $n_list->put(id3 => $n_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n1',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n1',
                },
                text        => 'V',
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n4',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n1',
                },
                text        => 'A',
            },
        },
        t03     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n2',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001/id2',
                },
                text        => 'V',
            },
        },
        t04     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001/id2',
                },
                text        => 'V',
            },
        },
        t05     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'N3',        # Will break if collation is case-sensitive
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n3',
                },
                clipboard   => {
                    '/IdentifyUser/member/id'   => 'm001',
                    '/IdentifyUser/member/name' => 'n3',
                },
                text        => 'V',
            },
        },
        t06     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'n3',
                },
                clipboard   => {
                    '/IdentifyUser/member/id'   => 'm001',
                    '/IdentifyUser/member/name' => 'n3',
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_user_prop_hash {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                email => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
                acc_type => {
                    type        => 'text',
                    charset     => 'latin1',
                    maxlength   => 10,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        email       => 'foo@bar.org',
        password    => '12345',
        verify_time => 0,
        acc_type    => 'web',
    );
    $m_list->put(m001 => $m_obj);

    $m_obj->put(
        email       => 'two@bar.org',
        password    => '12345',
        verify_time => 0,
        acc_type    => 'foo',
    );
    $m_list->put(m002foo => $m_obj);

    $m_obj->put(
        email       => 'two@bar.org',
        password    => '12345',
        verify_time => 0,
        acc_type    => 'web',
    );
    $m_list->put(m002web => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        t03     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        t04     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'A',
            },
        },
        t05     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t06     => {
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop' => undef);
                $config->put('/identify_user/member/alt_user_prop' => 'email');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        # Multiple user props
        #
        t10a    => {            # by email, single email, returning name
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        t10b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        #
        t11a    => {            # by id, single email, returning name
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t11b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        t12a    => {            # by email, single email, returning id
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t12b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        t13a    => {            # by id, single email, returning id
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t13b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        t15a    => {            # by email, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',     # because this email is listed twice
            },
            ignore_stderr => 1,
        },
        #
        t16a    => {            # by id, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t16b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t17a    => {            # by id, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        t17b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        #
        t18a    => {            # by email, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'TWO@bar.org',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        t18b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        #
        t19a    => {            # by email, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'id');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@BAR.ORG',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t19b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t20a    => {            # by id, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                text        => 'V',
            },
        },
        t20b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t21a    => {            # by id, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                text        => 'A',     # condition is not satisfied
            },
        },
        t21b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'I',     # identification from previous login
            },
        },
        #
        t22a    => {            # by id, multi-email, complex condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ [ 'email','ne','' ],'and', [ 'acc_type','ne','foo' ] ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@bar.org',
                password    => '12345',
            },
            results => {
                text        => 'V',
            },
        },
        #
        t23a    => {            # by email, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@BAR.ORG',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id                       => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        t23b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id                       => 'two@bar.org',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23c    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
            },
        },
        t23d    => {            # by id#1, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t23e     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23f    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
            },
        },
        t23g    => {            # by id#2, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002foo',
                    '/IdentifyUser/member/id'       => 'm002foo',
                },
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        t23h     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002foo',
                    '/IdentifyUser/member/id'       => 'm002foo',
                },
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23i    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_key_list {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri            => '/Members',
                #
                id_cookie           => 'mid',
                #
                key_list_uri        => '/MemberKeys',
                key_ref_prop        => 'member_id',
                key_expire_prop     => 'expire_time',
                key_expire_mode     => 'auto',
                #
                pass_prop           => 'password',
                #
                vf_key_cookie       => 'mkey',
                vf_time_user_prop   => 'uvf_time',
                vf_time_prop        => 'verify_time',
                vf_expire_time      => 120,
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                uvf_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
            },
        },
        MemberKeys => {
            type        => 'list',
            class       => 'Data::MemberNick',
            key         => 'member_key_id',
            key_format  => '<$AUTOINC$>',
            structure   => {
                member_id => {
                    type        => 'text',
                    maxlength   => 30,
                    index       => 1,
                    charset     => 'latin1',
                },
                expire_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 0,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 0,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(password => '12345');
    $m_list->put(m001 => $m_obj);
    $m_obj->put(password => '23456');
    $m_list->put(m002 => $m_obj);

    my %cjar;
    my %cjar_a;
    my %cjar_b;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => 0,
                },
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => 1,       # ++mkey
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/1/verify_time' => '~NOW',
                    '/MemberKeys/1/expire_time' => '~NOW+120',
                },
            },
        },
        t03a     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => 1,
                },
                text        => 'V',
            },
        },
        t03b     => {
            cookies => {
                mkey        => undef,
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => 2,       # ++mkey
                },
                text        => 'V',
            },
        },
        t04     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'key');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 3,       # ++mkey
                    mkey        => 2,       # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/cookie_value' => '3',
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t05a     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 3,       # from the previous test
                    mkey        => 2,       # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '3',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t05b    => {            # second call in the same session
            sub_post_cleanup => sub {
                my $user=$config->odb->fetch('/Members/m001');
                my $key=$config->odb->fetch('/MemberKeys/3');
                $config->clipboard->put('/IdentifyUser/member/object' => $user);
                $config->clipboard->put('/IdentifyUser/member/key_object' => $key);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
                cookies     => {
                    mid     => 3,       # from the previous test
                    mkey    => 2,       # from the previous test
                },
            },
        },
        t06     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 3,   # from the previous test
                    mkey        => 2,   # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '3',     # mkey
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t07     => {
            cookies => {
                mid         => 2,
                mkey        => 123,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                cookies     => {
                    mid         => 2,
                    mkey        => 123, # from what's given
                },
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '2',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t08     => {        # Providing invalid key
            cookies => {
                mid         => 4,
                mkey        => 'FOO',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '4',
                    mkey        => 'FOO',
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        t09     => {        # Second user login
            cookies => {
                mid         => 7,
                mkey        => 'FOO',
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 4,
                    mkey        => 'FOO',   # Not changed because id_cookie_type==key
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/cookie_value' => '4',
                },
            },
        },
        t10     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '1',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/cookie_value' => 1,
                    '/IdentifyUser/member/id'           => 'm001',
                },
            },
        },
        t11     => {
            cookies => {
                mid         => 4,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '4',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 4,
                    '/IdentifyUser/member/id'       => 'm002',
                },
            },
        },
        #
        # Logging out, but should stay identified as it was previously
        # logged in and verified.
        #
        t12     => {
            cookies => {
                mid         => 2,
            },
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '2',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 2,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking that the other key is still verified (account from
        # another browser/computer).
        #
        t13     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '1',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 1,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking that it is still identified after soft logout
        #
        t14     => {
            cookies => {
                mid         => 2,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '2',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 2,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking hard logout
        #
        t15     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => undef,
                    '/IdentifyUser/member/id'       => undef,
                },
                fs          => {
                    '/MemberKeys/1' => undef,
                },
            },
        },
        #
        # key '3' should still yeald verification even after hard logout
        # on 1.
        #
        t16     => {
            cookies => {
                mid         => 3,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 3,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking timing out of sessions
        #
        t17 => {
            sub_pre => sub {
                $config->put('/identify_user/member/vf_expire_time' => 2);
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 3,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Switching back to name mode and checking expiration again. It
        # should keep verification key by default and with
        # expire_mode='keep'.
        #
        t18a    => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'V',
            },
        },
        t18b     => {
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18c     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18d   => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'V',
            },
        },
        t18e => {
            sub_pre => sub {
                $config->put('/identify_user/member/expire_mode' => 'clean');
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => undef,
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18f     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => undef,
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18g   => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '6',
                },
                text        => 'V',
            },
        },
        #
        # In 'key' mode along with expire_mode='clean' even the
        # id_cookie should get cleared.
        #
        t19a    => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'key');
                $config->put('/identify_user/member/expire_mode' => 'clean');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => '7',
                    mkey        => '6',
                },
                text        => 'V',
            },
        },
        t19b     => {
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => '6',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => '7',
                },
            },
        },
        t19c     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mkey        => '6',
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => undef,
                },
            },
        },
        #
        # Checking extended expiration
        #
        t20a => {       # Non-extended login
            sub_pre => sub {
                $config->odb->fetch('/MemberKeys')->get_new->add_placeholder(
                    name        => 'extended',
                    type        => 'integer',
                    minvalue    => 0,
                    maxvalue    => 1,
                );

                $config->put('/identify_user/member/id_cookie_type'     => 'id');
                $config->put('/identify_user/member/vf_expire_time'     => 2);
                $config->put('/identify_user/member/vf_expire_ext_time' => 6);
                $config->put('/identify_user/member/key_expire_ext_prop'=> 'extended');
                $config->put('/identify_user/member/expire_mode'        => 'keep');
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/8/verify_time' => '~NOW',
                    '/MemberKeys/8/expire_time' => '~NOW+2',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t20b => {       # Extended login
            cookie_jar => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 1,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t21a => {       # Make sure 'extended' is still OFF after 'check'ing.
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/8/verify_time' => '~NOW',
                    '/MemberKeys/8/expire_time' => '~NOW+2',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t21b => {       # Make sure 'extended' is still ON after 'check'ing.
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
                sleep(1);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t22a => {       # Timing out non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-3',
                    '/MemberKeys/8/verify_time' => '~NOW-3',
                    '/MemberKeys/8/expire_time' => '~NOW-1',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t22b => {       # Extended should not time out in 3 seconds
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t23a => {       # No change, just rechecking non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',     # depends on expire_mode=keep
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t22b
                    '/MemberKeys/8/verify_time' => '~NOW-3',
                    '/MemberKeys/8/expire_time' => '~NOW-1',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t23b => {       # Expiring extended key
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
                sleep(7);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => '~NOW-7',
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t24a => {       # No change, just rechecking non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => '~NOW-10',
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t24b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => '~NOW-7',
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t25a => {       # "Soft" logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',    # Default is "soft" logout, going to identified state
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => 0,
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t25b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => 0,
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t26a => {       # Checking after logging out
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => 0,
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t26b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => 0,
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t27a => {       # Hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t27b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t28a => {       # Check after hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t28b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t29a => {       # Login after hard logout
            sub_pre => sub {
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '10',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/10/verify_time'=> '~NOW',
                    '/MemberKeys/10/expire_time'=> '~NOW+2',
                    '/MemberKeys/10/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t29b => {       # Extended login
            cookie_jar => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 1,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '11',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/11/verify_time'=> '~NOW',
                    '/MemberKeys/11/expire_time'=> '~NOW+6',
                    '/MemberKeys/11/extended'   => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t30a => {       # Hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t30b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29b
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t31a => {       # Check after hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t31b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29b
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t32a => {       # Login for rolling check() testing
            sub_pre => sub {
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '12',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/12/verify_time'=> '~NOW',
                    '/MemberKeys/12/expire_time'=> '~NOW+2',
                    '/MemberKeys/12/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t32c => {       # Checks after "user browsing"
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
                sleep(1);
            },
            repeat => 10,
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '12',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'            => '~NOW',
                    '/MemberKeys/12/verify_time'        => '~NOW',
                    '/MemberKeys/12/expire_time'        => '~NOW+2',
                    '/MemberKeys/12/extended'           => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t33b => {       # Extended login for rolling check() testing
            cookie_jar => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 1,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '13',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/13/verify_time'=> '~NOW',
                    '/MemberKeys/13/expire_time'=> '~NOW+6',
                    '/MemberKeys/13/extended'   => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t33d => {       # Checks after "user browsing"
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
                sleep(5);
            },
            repeat => 4,
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '13',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'            => '~NOW',
                    '/MemberKeys/13/verify_time'        => '~NOW',
                    '/MemberKeys/13/expire_time'        => '~NOW+6',
                    '/MemberKeys/13/extended'           => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t40a => {       # Forced login without a password
            sub_pre => sub {
                %cjar_a=();
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                force       => 1,
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '14',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/14/verify_time'=> '~NOW',
                    '/MemberKeys/14/expire_time'=> '~NOW+2',
                    '/MemberKeys/14/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t41a => {       # Sequential login without password, reuse the key
            sub_pre => sub {
            },
            cookie_jar => \%cjar_a,
            repeat => 3,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                force       => 1,
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '14',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/14/verify_time'=> '~NOW',
                    '/MemberKeys/14/expire_time'=> '~NOW+2',
                    '/MemberKeys/14/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t42a => {       # Sequential login with password, reuse the key
            sub_pre => sub {
            },
            cookie_jar => \%cjar_a,
            repeat => 3,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '14',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/14/verify_time'=> '~NOW',
                    '/MemberKeys/14/expire_time'=> '~NOW+2',
                    '/MemberKeys/14/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_crypto {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'sha256,md5,plaintext',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_bcrypt => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'bcrypt,sha256',
                pass_encrypt_cost => 8,
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_md5_sha1 => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'md5,sha1',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_sha1_crypt => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'sha1,crypt',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_plaintext => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'plaintext',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_custom => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'custom',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_crypt => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'crypt',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
            member_pepper => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                pass_encrypt    => 'bcrypt,sha256,sha1,md5,crypt,plaintext',
                pass_pepper     => 'fubar,',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $password='qwerty12';

    my %etests=(
        #
        # Config type base encryption
        #
        t01_bcrypt => {
            repeat  => 9,
            args    => {
                type        => 'member_bcrypt',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$bcrypt\$\d{1,2}-.{22}\$/,
                    notsimple   => 1,
                    length      => [ 64,65 ],
                },
                salt        => {
                    length      => [ 24,25 ],
                },
            },
        },
        t01_sha256 => {
            repeat  => 9,
            args    => {
                type        => 'member',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$sha256\$/,
                    notsimple   => 1,
                    length      => [ 60,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t01_md5    => {
            repeat  => 9,
            args    => {
                type        => 'member_md5_sha1',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$md5\$/,
                    notsimple   => 1,
                    length      => [ 36,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t01_sha1    => {
            repeat  => 9,
            args    => {
                type        => 'member_sha1_crypt',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$sha1\$/,
                    notsimple   => 1,
                    length      => [ 42,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t01_plaintext => {
            args    => {
                type        => 'member_plaintext',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    equal       => $password,
                },
                salt        => {
                    empty       => 1,
                },
            },
        },
        t01_custom => {
            objname => 'Web::IdentifyUserC1',
            args    => {
                type        => 'member_custom',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    equal       => '[*C1*'.$password.'*]',
                },
                salt        => {
                    empty       => 1,
                },
            },
        },
        #
        # Explicitly specified encryption
        #
        t02_bcrypt1 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'bcrypt',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$bcrypt\$\d+/,
                    notsimple   => 1,
                    length      => [ 64,65 ],
                },
                salt        => {
                    length      => [ 24,25 ],
                },
            },
        },
        t02_bcrypt2 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'bcrypt',
                pass_encrypt_cost => 4,
                pass_pepper => 'barbaz',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$bcrypt\$4-/,
                    notsimple   => 1,
                    length      => [ 64,64 ],
                },
                salt        => {
                    length      => [ 24,24 ],
                },
            },
        },
        t02_bcrypt3 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'bcrypt',
                pass_encrypt_cost => 10,
                pass_pepper => 'barbaz',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$bcrypt\$10-/,
                    notsimple   => 1,
                    length      => [ 65,65 ],
                },
                salt        => {
                    length      => [ 25,25 ],
                },
            },
        },
        t02_sha256 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'sha256',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$sha256\$/,
                    notsimple   => 1,
                    length      => [ 60,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t02_md5 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'md5',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$md5\$/,
                    notsimple   => 1,
                    length      => [ 36,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t02_sha1 => {
            repeat  => 9,
            args    => {
                pass_encrypt=> 'sha1',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^\$sha1\$/,
                    notsimple   => 1,
                    length      => [ 42,100 ],
                },
                salt        => {
                    length      => [ 8,16 ],
                },
            },
        },
        t02_crypt => {
            repeat  => 3,
            args    => {
                pass_encrypt=> 'crypt',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    regex       => qr/^[a-zA-Z0-9\.\/]+$/,
                    notsimple   => 1,
                    length      => [ 13,13 ],
                },
                salt        => {
                    length      => [ 2,2 ],
                },
            },
        },
        t02_plaintext => {
            args    => {
                pass_encrypt=> 'plaintext',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    equal       => $password,
                },
                salt        => {
                    empty       => 1,
                },
            },
        },
        t02_custom => {
            objname => 'Web::IdentifyUserC1',
            args    => {
                pass_encrypt=> 'custom',
                password    => $password,
            },
            expect  => {
                encrypted   => {
                    equal       => '[*C1*'.$password.'*]',
                },
                salt        => {
                    empty       => 1,
                },
            },
        },
        #
        # Encryption with a stored password
        #
        (map { my ($c,$stored)=@$_; $stored=~/^\$(.*)\$(.*)\$(.*)$/; my ($alg,$salt,$bare)=($1,$2,$3);
            (
                't03_'.$c.'_type_'.$alg => {
                    args    => {
                        type            => 'member',
                        password        => $password,
                        password_stored => $stored,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $stored,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
                't03_'.$c.'_impl_'.$alg => {
                    args    => {
                        password        => $password,
                        password_stored => $stored,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $stored,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
                't03_'.$c.'_over_'.$alg => {
                    args    => {
                        pass_encrypt    => 'md5',
                        password        => $password,
                        password_stored => $stored,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $stored,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
            ) } (
            [ 'a', '$md5$ZRIRPJBT$b+IL1UmuERNMIsZ8qAFLWA' ],
            [ 'b', '$sha1$GREW9Y9Z$tWaQi1ypm8fo3HEP+xCo6aCWdw4' ],
            [ 'c', '$sha256$BJQO8RFZ$m+lmqY7Uhx2LZ/R9ZzpnQZaJtJB1OANixhj2wPlFPO0' ],
            [ 'd', '$bcrypt$3-86ZlOWBPQGwo7U42ahicJA$VIKbbqmspe65XUutq0rpslc+NKt9cTU' ],
            [ 'e', '$bcrypt$6-86ZlOWBPQGwo7U42ahicJA$0KVsPNfaivoQS1ljLyG8wtF2tOLA3Fk' ],
            [ 'f', '$bcrypt$10-86ZlOWBPQGwo7U42ahicJA$qZN2Mg7hXTmLjHG3pbUpR5SoVblzWcs' ],
        )),
        #
        # Encryption with a stored password and a defined pepper
        #
        (map { $_=~/^\$(.*)\$(.*)\$(.*)$/; my ($alg,$salt,$bare)=($1,$2,$3);
            (
                't04_type_'.$alg => {
                    args    => {
                        type            => 'member_pepper',
                        password        => $password,
                        password_stored => $_,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $_,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
                't04_impl_'.$alg => {
                    args    => {
                        pass_pepper     => [ 'fubar', 'qwerty' ],
                        password        => $password,
                        password_stored => $_,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $_,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
                't04_over_'.$alg => {
                    args    => {
                        pass_encrypt    => 'md5',
                        pass_pepper     => 'fubar,qqq,',
                        password        => $password,
                        password_stored => $_,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $_,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
            ) } qw(
            $md5$ZRIRPJBT$jhFwx5wFQSvCCjVxIonAIw
            $sha1$GREW9Y9Z$PdToM8a0OwzIQMhz7X0piiYkitk
            $sha256$BJQO8RFZ$qciWhJJQ6wS6qXTNtdB/xoM0J7P/OE5zkpkNL27hJ5Q
            $bcrypt$6-68lZWOPBGQowJU72ahic4A$UnM3ozuEydRhOUrZaDFi1th/eSl2Xlw
        )),
        #
        # Encryption with a stored bareword saltless password
        #
        (map { my ($c,$alg,$pepper,$bare)=@$_;
            (
                't05_bare_'.$c.'_'.$alg => {
                    args    => {
                        pass_encrypt    => $alg,
                        pass_pepper     => $pepper,
                        password        => $password,
                        password_stored => $bare,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $bare,
                        },
                        salt        => {
                            equal       => '',
                        },
                    },
                },
            ) } (
            [ 'a', 'md5',    undef,    'DjEeW5cE8otOhVfo+j++fQ' ],
            [ 'b', 'sha1',   undef,    'L3eiULBOfDkCcEAvtCAzECsosHE' ],
            [ 'c', 'sha256', undef,    'nG1AW7otskv70i/H/3Szm9nF6cbOZimcZRm+UX5u18Y' ],
            [ 'd', 'md5',    ['q','w'],'vGwWzsiAUi9yeLf/xjKcmw' ],
            [ 'e', 'sha1',   'qwerty', 'S5p8IR8msR7TM0k4DX412tFsDdw' ],
            [ 'f', 'sha256', '----',   '+0fLegXILbxD7JE0B4klaO2wlSPNekFeT8IpYKQRd9w' ],
        )),
        #
        # 'Crypt' based
        #
        (map { my $bare=$_; my $salt=substr($bare,0,2);
            (
                't06_crypt_'.$salt => {
                    args    => {
                        pass_encrypt    => 'crypt',
                        password        => $password,
                        password_stored => $bare,
                    },
                    expect  => {
                        encrypted   => {
                            equal       => $bare,
                        },
                        salt        => {
                            equal       => $salt,
                        },
                    },
                },
            ) } qw(
                Uavf0zRie4QGo
                lyhsMZlrEok4s
                gKFPxe5eEtYx6
                iL3a0WOArmN1.
        )),
    );

    foreach my $tname (sort keys %etests) {
        my $tconf=$etests{$tname};

        dprint "TEST '$tname'";

        my $args=$tconf->{'args'};

        my $obj=XAO::Objects->new(objname => ($tconf->{'objname'} || 'Web::IdentifyUser'));

        my $repeat=$tconf->{'repeat'} || 1;

        my %seen;

        for(my $step=1; $step<=$repeat; ++$step) {
            my $pwdata=$obj->data_password_encrypt($args);

            $self->assert(ref($pwdata) eq 'HASH',
                "Expected to receive a hash from data_password_encrypt, got '$pwdata'");

            my $pass_encrypt=$pwdata->{'pass_encrypt'};

            $self->assert(defined $pass_encrypt,
                "Expected to receive an encryption algorithm (pass_encrypt), got UNDEF");

            my $pwcrypt=$pwdata->{'encrypted'};

            ### dprint "..test '$tname', step $step/$repeat, pass_encrypt=$pass_encrypt, encrypted='$pwcrypt'";

            $self->assert(defined $pwcrypt,
                "Expected to receive an encrypted password, got UNDEF");

            $self->assert($pwcrypt=~/^[[:ascii:]]+$/,
                "Expected to receive plain ASCII digest, got '$pwcrypt'");

            # There is a VERY slight probability this might fail because of
            # two identical random salts generated. Rerun the test if there
            # is a suspicion of that :)
            #
            # Adding 'salt' into the check is a bad idea since then
            # we're not checking salt randomness.
            #
            $self->assert(!$seen{$pwcrypt},
                "Expected '$pwcrypt' to be unique, but got a repeat on step $step vs ".($seen{$pwcrypt} || '<UNDEF>'));

            $seen{$pwcrypt}=$step;

            # Checking returned values
            #
            while(my ($fname,$fexpect)=each %{$tconf->{'expect'}}) {
                my $value=$pwdata->{$fname};

                $value='' if !defined($value);

                while(my ($ckcode,$ckvalue)=each %{$fexpect}) {

                    if($ckcode eq 'length') {
                        $self->assert(!$ckvalue->[0] || length($value)>=$ckvalue->[0],
                            "Expected to receive at least $ckvalue->[0] characters, got ".length($value)." for '$fname' on '$tname'");
                        $self->assert(!$ckvalue->[1] || length($value)<=$ckvalue->[1],
                            "Expected to receive at most $ckvalue->[0] characters, got ".length($value)." for '$fname' on '$tname'");
                    }

                    elsif($ckcode eq 'regex') {
                        $self->assert(($value =~ $ckvalue ? 1 : 0),
                            "Expected '$value' to match '$ckvalue' for '$fname' on '$tname'");
                    }

                    elsif($ckcode eq 'equal') {
                        $self->assert($value eq $ckvalue,
                            "Expected '$value' to equal '$ckvalue' for '$fname' on '$tname'");
                    }

                    elsif($ckcode eq 'notsimple') {
                        my $pw=$args->{'password'} || '';

                        my @simple=(
                            $pw,
                            md5_base64($pw),
                            sha1_base64($pw),
                            sha256_base64($pw),
                        );

                        # Yes, there is a probability that this will
                        # match for a salted hash. But is minscule.
                        #
                        foreach my $sv (@simple) {
                            $self->assert(index($value,$sv)<0,
                                "Expected '$value' to not include '$sv' for '$fname' on '$tname'");
                        }
                    }

                    elsif($ckcode eq 'empty') {
                        $self->assert($value eq '',
                            "Expected '$value' to be empty for '$fname' on '$tname'");
                    }

                    else {
                        $self->assert(0,
                            "Unknown value checker '$ckcode' for '$fname' in test '$tname'");
                    }
                }
            }
        }
    }

    # Salted passwords for the database
    #
    my $iu=XAO::Objects->new(objname => 'Web::IdentifyUser');

    my $md5_bare=md5_base64($password);

    my $md5_salted=$iu->data_password_encrypt(
        pass_encrypt    => 'md5',
        password        => $password,
    )->{'encrypted'};

    my $md5_peppered=$iu->data_password_encrypt(
        type            => 'member_pepper',
        pass_encrypt    => 'md5',
        password        => $password,
    )->{'encrypted'};

    $self->assert($md5_salted ne $md5_peppered,
        "Expected md5 '$md5_salted' and '$md5_peppered' to differ");

    dprint "...md5:    bare='$md5_bare' salted='$md5_salted' peppered='$md5_peppered'";

    my $sha1_bare=sha1_base64($password);

    my $sha1_salted=$iu->data_password_encrypt(
        pass_encrypt    => 'sha1',
        password        => $password,
    )->{'encrypted'};

    my $sha1_peppered=$iu->data_password_encrypt(
        type            => 'member_pepper',
        pass_encrypt    => 'sha1',
        password        => $password,
    )->{'encrypted'};

    $self->assert($sha1_salted ne $sha1_peppered,
        "Expected sha1 '$sha1_salted' and '$sha1_peppered' to differ");

    dprint "...sha1:   bare='$sha1_bare' salted='$sha1_salted' peppered='$sha1_peppered'";

    my $sha256_bare=sha256_base64($password);

    my $sha256_salted=$iu->data_password_encrypt(
        pass_encrypt    => 'sha256',
        password        => $password,
    )->{'encrypted'};

    my $sha256_peppered=$iu->data_password_encrypt(
        type            => 'member_pepper',
        pass_encrypt    => 'sha256',
        password        => $password,
    )->{'encrypted'};

    $self->assert($sha256_salted ne $sha256_peppered,
        "Expected sha256 '$sha256_salted' and '$sha256_peppered' to differ");

    dprint "...sha256: bare='$sha256_bare' salted='$sha256_salted' peppered='$sha256_peppered'";

    my $crypt_salted=$iu->data_password_encrypt(
        pass_encrypt    => 'crypt',
        password        => $password,
    )->{'encrypted'};

    my $crypt_peppered=$iu->data_password_encrypt(
        type            => 'member_pepper',
        pass_encrypt    => 'crypt',
        password        => $password,
    )->{'encrypted'};

    $self->assert($crypt_salted ne $crypt_peppered,
        "Expected crypt '$crypt_salted' and '$crypt_peppered' to differ");

    dprint "...crypt:  salted='$crypt_salted' peppered='$crypt_peppered'";

    my $bcrypt_salted_1=$iu->data_password_encrypt(
        pass_encrypt    => 'bcrypt',
        password        => $password,
    )->{'encrypted'};

    my $bcrypt_salted_2=$iu->data_password_encrypt(
        type            => 'member_bcrypt',
        password        => $password,
    )->{'encrypted'};

    my $bcrypt_peppered=$iu->data_password_encrypt(
        type            => 'member_pepper',
        pass_encrypt    => 'bcrypt',
        password        => $password,
    )->{'encrypted'};

    $self->assert($bcrypt_salted_1 ne $bcrypt_peppered,
        "Expected bcrypt '$bcrypt_salted_1' and '$bcrypt_peppered' to differ");

    $self->assert($bcrypt_salted_2 ne $bcrypt_peppered,
        "Expected bcrypt '$bcrypt_salted_2' and '$bcrypt_peppered' to differ");

    dprint "...bcrypt: '$bcrypt_salted_1' / '$bcrypt_salted_2' / '$bcrypt_peppered'";

    # Actual login/check/logout tests
    #
    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                email => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;

    my $tnum=0;
    my %cjar;
    my %matrix=map {
        my ($code,$pwcrypt,$types)=@$_;

        my $email=$code.'@bar.org';

        $m_obj->put(
            email       => $email,
            password    => $pwcrypt,
            verify_time => 0,
        );
        my $m_id=$m_list->put($m_obj);

        ++$tnum;

        map { my $type=$_; (
            sprintf('t%02u_a_%s_%s',$tnum,$code,$type) => {
                args => {
                    mode        => 'login',
                    type        => $type,
                    username    => $email,
                    password    => $password,
                },
                results => {
                    cookies     => {
                        member_id   => $email,
                    },
                    text        => 'V',
                    clipboard   => {
                        "/IdentifyUser/$type/object"    => { },
                        "/IdentifyUser/$type/name"      => $email,
                        "/IdentifyUser/$type/verified"  => 1,
                    },
                },
            },
            sprintf('t%02u_b_%s_%s',$tnum,$code,$type) => {
                args => {
                    mode        => 'check',
                    type        => $type,
                },
                results => {
                    cookies     => {
                        member_id   => $email,
                    },
                    text        => 'V',
                    clipboard   => {
                        "/IdentifyUser/$type/object"    => { },
                        "/IdentifyUser/$type/name"      => $email,
                        "/IdentifyUser/$type/verified"  => 1,
                    },
                },
            },
            sprintf('t%02u_c_%s_%s',$tnum,$code,$type) => {
                args => {
                    mode        => 'login',
                    type        => $type,
                    username    => $email,
                    password    => substr($password,0,-1),
                },
                results => {
                    clipboard   => {
                        "/IdentifyUser/$type/object"    => undef,
                        "/IdentifyUser/$type/name"      => undef,
                        "/IdentifyUser/$type/verified"  => undef,
                    },
                },
            },
            sprintf('t%02u_d_%s_%s',$tnum,$code,$type) => {
                args => {
                    mode        => 'check',
                    type        => $type,
                },
                results => {
                    clipboard   => {
                        "/IdentifyUser/$type/object"   => { },
                        "/IdentifyUser/$type/name"     => $email,
                        "/IdentifyUser/$type/verified" => undef,
                    },
                    text        => 'I',
                },
            },
        ) } @$types;
    } (
        [ 'md5_bare',       $md5_bare,          [qw(member member_md5_sha1 member_pepper)] ],
        [ 'md5_salted',     $md5_salted,        [qw(member member_md5_sha1 member_custom member_pepper)] ],
        [ 'md5_peppered',   $md5_peppered,      [qw(member_pepper)] ],
        [ 'sha1_bare',      $sha1_bare,         [qw(member_md5_sha1 member_sha1_crypt member_pepper)] ],
        [ 'sha1_salted',    $sha1_salted,       [qw(member_md5_sha1 member_sha1_crypt member_custom member member_pepper)] ],
        [ 'sha1_peppered',  $sha1_peppered,     [qw(member_pepper)] ],
        [ 'sha256_bare',    $sha256_bare,       [qw(member member_pepper)] ],
        [ 'sha256_salted',  $sha256_salted,     [qw(member member_md5_sha1 member_crypt member_pepper)] ],
        [ 'sha256_peppered',$sha256_peppered,   [qw(member_pepper)] ],
        [ 'crypt_salted',   $crypt_salted,      [qw(member_crypt member_sha1_crypt member_pepper)] ],
        [ 'crypt_peppered', $crypt_peppered,    [qw(member_pepper)] ],
        [ 'bcrypt_salted_1',$bcrypt_salted_1,   [qw(member member_bcrypt)] ],
        [ 'bcrypt_salted_2',$bcrypt_salted_2,   [qw(member member_bcrypt)] ],
        [ 'bcrypt_peppered',$bcrypt_peppered,   [qw(member_pepper)] ],
        [ 'plaintext',      $password,          [qw(member member_plaintext member_pepper)] ],
    );

    ### dprint Dumper(\%matrix);

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub run_matrix {
    my ($self,$matrix,$cjar)=@_;

    my $config=$self->siteconfig;

    foreach my $tname (sort keys %$matrix) {
        my $tdata=$matrix->{$tname};

        my $repeat=$tdata->{'repeat'} || 1;

        for(my $iter=0; $iter<$repeat; ++$iter) {
            dprint "TEST $tname".($repeat>1 ? " (iteration ".($iter+1)." of $repeat)" : "");

            if($tdata->{'sub_pre'}) {
                &{$tdata->{'sub_pre'}}();
            }

            my $rcjar=$tdata->{'cookie_jar'} || merge_refs($cjar,$tdata->{'cookies'});
            my $wcjar=$tdata->{'cookie_jar'} || $cjar;

            my $cenv='';
            foreach my $cname (keys %$rcjar) {
                next unless defined $rcjar->{$cname};
                $cenv.='; ' if length($cenv);
                $cenv.="$cname=$rcjar->{$cname}";
                $wcjar->{$cname}=$rcjar->{$cname};
            }

            ### dprint "..cookies: $cenv";

            $ENV{'HTTP_COOKIE'}=$cenv;

            $config->embedded('web')->cleanup;
            $config->embedded('web')->enable_special_access;
            $config->embedded('web')->cgi(CGI->new('foo=bar&bar=foo'));
            $config->embedded('web')->disable_special_access;

            if($tdata->{sub_post_cleanup}) {
                &{$tdata->{sub_post_cleanup}}();
            }

            $self->catch_stderr() if $tdata->{'ignore_stderr'};

            my $iu=XAO::Objects->new(objname => 'Web::IdentifyUser');
            my $got=$iu->expand({
                'anonymous.template'    => 'A',
                'identified.template'   => 'I',
                'verified.template'     => 'V',
            },$tdata->{args});

            if($tdata->{'ignore_stderr'}) {
                my $stderr=$self->get_stderr();
                dprint "IGNORED(OK-STDERR): $stderr";
            }

            my $results=$tdata->{results};
            if(exists $results->{text}) {
                $self->assert($got eq $results->{text},
                              "$tname - expected '$results->{text}', got '$got'");
            }

            foreach my $cd (@{$config->cookies}) {
                next unless defined $cd;

                my $expires_text=$cd->expires;

                $self->assert($expires_text =~ /(\d{2})\W+([a-z]{3})\W+(\d{4})\W+(\d{2})\W+(\d{2})\W+(\d{2})/i,
                    "Invalid cookie expiration '".$expires_text." for name '".$cd->name."' value '".$cd->value."'");

                my $midx=index('janfebmaraprmayjunjulaugsepoctnovdec',lc($2));
                $self->assert($midx>=0,
                    "Invalid month '$2' in cookie '".$cd->name."' expiration '".$expires_text."'");

                my $expires;
                {
                    local($ENV{'TZ'})='UTC';
                    $expires=mktime($6,$5,$4,$1,$midx/3,$3-1900);
                }

                ### dprint "...cookie name='".$cd->name."' value='".$cd->value." expires=".$expires_text." (".localtime($expires)." - ".($expires<=time ? 'EXPIRED' : 'ACTIVE').")";

                if($expires <= time) {
                    $wcjar->{$cd->name}=undef;
                }
                else {
                    $wcjar->{$cd->name}=$cd->value;
                }
            }

            %$cjar=%$wcjar;

            if(exists $results->{cookies}) {
                foreach my $cname (keys %{$results->{cookies}}) {
                    my $expect=$results->{cookies}->{$cname};
                    if(defined $expect) {
                        $self->assert(defined($wcjar->{$cname}),
                                      "$tname - cookie=$cname, expected $expect, got nothing");
                        $self->assert($wcjar->{$cname} eq $expect,
                                      "$tname - cookie=$cname, expected $expect, got $wcjar->{$cname}");
                    }
                    else {
                        $self->assert(!defined($wcjar->{$cname}),
                                      "$tname - cookie=$cname, expected nothing, got ".($wcjar->{$cname} || ''));
                    }
                }
            }

            if(exists $results->{clipboard}) {
                my $cb=$config->clipboard;
                foreach my $cname (keys %{$results->{clipboard}}) {
                    my $expect=$results->{clipboard}->{$cname};
                    my $got=$cb->get($cname);
                    if(defined $expect) {
                        $self->assert(defined($got),
                                      "$tname - clipboard=$cname, expected $expect, got nothing");
                        if(ref($expect)) {
                            $self->assert(ref($got),
                                          "$tname - clipboard=$cname, expected a ref, got $got");
                        }
                        else {
                            $self->assert($got eq $expect,
                                          "$tname - clipboard=$cname, expected $expect, got $got");
                        }
                    }
                    else {
                        $self->assert(!defined($got),
                                      "$tname - clipboard=$cname, expected nothing, got ".($got || ''));
                    }
                }
            }

            my $parseval=sub($) {
                my $t=shift;
                if   ($t=~/^NOW\+(\d+)$/) { return time+$1; }
                elsif($t=~/^NOW-(\d+)$/)  { return time-$1; }
                elsif($t=~/^NOW$/)        { return time; }
                elsif($t=~/^\d+$/)        { return $t; }
                else { $self->assert(0,"Unparsable constant '$t'"); }
            };

            if(exists $results->{fs}) {
                my $odb=$config->odb;
                foreach my $uri (keys %{$results->{fs}}) {
                    my $expect=$results->{fs}->{$uri};
                    my $got;
                    try {
                        $got=$odb->fetch($uri);
                        ### dprint "...uri=$uri expect got=$got expect=$expect now=".time;
                    }
                    otherwise {
                        my $e=shift;
                        dprint "IGNORED(OK): $e";
                    };
                    if(!defined($expect)) {
                        $self->assert(!defined($got),
                                      "$tname - fs=$uri, expected nothing, got ".($got || ''));
                    }
                    elsif(!defined $got) {
                        $self->assert(0,
                                      "$tname - fs=$uri, expected $expect, got nothing");
                    }
                    elsif($expect =~ /^>(.*)$/) {
                        my $val=$parseval->($1);
                        $self->assert($got>$val,
                                      "$tname - fs=$uri, expected $expect ($val), got $got");
                    }
                    elsif($expect =~ /^<(.*)$/) {
                        my $val=$parseval->($1);
                        $self->assert($got=~/^[\d\.]+$/ && $got<$val,
                                      "$tname - fs=$uri, expected $expect ($val), got $got");
                    }
                    elsif($expect =~ /^~(.*)$/) {
                        my $val=$parseval->($1);
                        $self->assert($got=~/^[\d\.]+$/ && $got>=$val-2 && $got<=$val+2,
                                      "$tname - fs=$uri, expected $expect ($val+/-2), got $got");
                    }
                    else {
                        $self->assert($got eq $expect,
                                      "$tname - fs=$uri, expected $expect, got $got");
                    }
                }
            }
        }
    }
}

###############################################################################
1;
