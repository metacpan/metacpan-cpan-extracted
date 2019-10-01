package testcases::Catalogs::base;
use strict;
use CGI;
use XAO::Utils;
use XAO::Web;
use XAO::Projects qw(:all);

use base qw(XAO::testcases::base);

sub new ($) {
    my $proto=shift;
    my $self=$proto->SUPER::new(@_);

    my %d;
    if(1) {
        open(F,'.config') ||
            die "No .config found, run 'perl Makefile.PL'";
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }

    $self->{'skip_db_tests'}=$d{'test_dsn'} eq 'none' ? 1 : 0;

    return $self;
}

sub list_tests ($) {
    my $self=shift;

    my @tests=$self->SUPER::list_tests(@_);

    if($self->{'skip_db_tests'}) {
        @tests=();
    }

    return wantarray ? @tests : \@tests;
}

sub set_up {
    my $self=shift;

    $self->SUPER::set_up();

    my $site=XAO::Web->new(sitename => 'test');
    $site->set_current();

    my $cgi=CGI->new('foo=bar&test=1');

    $site->config->embedded('web')->enable_special_access();
    $site->config->cgi($cgi);
    $site->config->embedded('web')->disable_special_access();

    $self->{'siteconfig'}=$site->config;
    $self->{'web'}=$site;
    $self->{'cgi'}=$cgi;

    return $self;
}

1;
