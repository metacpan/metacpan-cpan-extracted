package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::SimpleHash;
use XAO::Objects;
use XAO::Errors qw(XAO::DO::Config);
use base XAO::Objects->load(objname => 'Config', baseobj => 1);

my %data = (
    base_url => 'http://xao.com',
    charset  => 'UTF-8',
    extra_urls => {
        'img'           => 'http://img.foo.com',
        'stat.insecure' => 'http://www.foo.com',
        'stat.secure'   => 'https://ssl.foo.com',
        'css.secure'    => '',
        'css.insecure'  => 'http://css.foo.com',
        'js.secure'     => 'https://js.foo.com',
        'js.insecure'   => '',
    },
    path_mapping_table  => {
        '/rawobj' => {
            type        => 'xaoweb',
            objname     => 'Page',
            objargs     => {
                path        => '/bits/rawobj-template',
            },
            urlstyle    => 'raw',
        },
        '/filesobj' => {
            type        => 'xaoweb',
            objname     => 'Page',
            objargs     => {
                path        => '/bits/rawobj-template',
            },
            urlstyle    => 'files',
        },
    },
);

sub init {
    my $self=shift;

    $self->embedded('hash')->fill(\%data);

    my %d;
    open(F,'.config') ||
        throw XAO::E::DO::Config "init - no .config found, run 'perl Makefile.PL'";
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
    $@ && throw XAO::E::DO::Config "init - error in .config file: $@";

    my $fsconfig=XAO::Objects->new(
        objname => 'FS::Config',
        odb_args => {
            dsn                 => $d{'test_dsn'},
            user                => $d{'test_user'},
            password            => $d{'test_password'},
            empty_database      => 'confirm',
            check_consistency   => 1,
        },
    );

    $self->embed(
        fs => $fsconfig,
    );

    return $self->SUPER::init();
}

1;
