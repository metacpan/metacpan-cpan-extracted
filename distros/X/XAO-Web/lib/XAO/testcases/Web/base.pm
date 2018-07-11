=head1 NAME

XAO::testcases::base - base class for easier XAO::Web project testing

=head1 DESCRIPTION

This class extends XAO::testcases::base for easier testing of Web based
projects. It adds a CGI variable to the setup.

=cut

###############################################################################
package XAO::testcases::Web::base;
use strict;
use IO::File;
use XAO::Utils;
use XAO::Base;
use XAO::Objects;
use XAO::Web;
use XAO::Projects qw(:all);

use base qw(XAO::testcases::base);

sub new ($) {
    my $proto=shift;
    my $self=$proto->SUPER::new(@_);

    # Site root is not set up yet at this point, so can't use the data
    # from the test site configuration.
    #
    # Nearly identical code is in t/xao/projects/test/objects/Config.pm
    #
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
        @tests=grep { ! /_db_/ } @tests;
    }

    return wantarray ? @tests : \@tests;
}

sub set_up {
    my $self=shift;

    $self->SUPER::set_up();

    my $site=XAO::Web->new(sitename => 'test');
    $site->set_current();

    my $cgi=$self->cgi_object;

    if(my $charset=$site->config->get('charset')) {
        if($cgi->can('set_param_charset')) {
            $cgi->set_param_charset($charset);
        }
        else {
            eprint "CGI object we have does not support set_param_charset";
        }
        $site->config->header_args(
            -Charset   => $charset,
        );
    }

    $site->config->embedded('web')->enable_special_access();
    $site->config->cgi($cgi);
    $site->config->embedded('web')->disable_special_access();

    $self->{'siteconfig'}=$site->config;
    $self->{'web'}=$site;
    $self->{'cgi'}=$cgi;

    return $self;
}

sub cgi_object {
    XAO::Objects->new(
        objname => 'CGI',
        query   => 'foo=bar&ucode=%D1%82%D0%B5%D1%81%D1%82&bytes=%01%02%03%04&test=1',
    );
}

sub web {
    my $self=shift;
    return $self->{'web'};
}

sub cgi {
    my $self=shift;
    return $self->{'cgi'};
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2006 Ejelta LLC
Andrew Maltsev, am@ejelta.com
