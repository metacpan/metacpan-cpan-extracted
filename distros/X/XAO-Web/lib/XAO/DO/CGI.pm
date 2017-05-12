=head1 NAME

XAO::DO::CGI - CGI interface for XAO::Web

=head1 DESCRIPTION

This is an extension of the standard CGI package that overrides its param()
method. If the current site has a 'charset' parameter in siteconfig then
parameters received from CGI are decoded from that charset into Perl
native unicode strings.

=over

=cut

###############################################################################
package XAO::DO::CGI;
use strict;
use Encode;
use XAO::Utils;
use XAO::Objects;
use CGI;

use base qw(CGI);

###############################################################################

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $cgi;
    if($args->{'query'}) {
        $cgi=CGI->new($args->{'query'});
    }
    elsif($args->{'no_cgi'}) {
        $cgi=CGI->new('foo=bar');
    }
    else {
        $cgi=CGI->new();
    }

    bless $cgi,ref($proto) || $proto;
}

###############################################################################

sub cookie ($@) {
    my $self=shift;
    if(@_) {
        my @c1=caller(1);
        if(!@c1 || $c1[3]!~/get_cookie/) {
            my @c0=caller(0);
            eprint "Using CGI::cookie() method is deprecated, consider switching to \$config->get_cookie() in ".join(':',map { $_ || '<undef>' } ($c0[1],$c0[2]));
        }
    }
    return $self->SUPER::cookie(@_);
}

###############################################################################

sub set_param_charset($$) {
    my ($self,$charset)=@_;

    my $old=$self->{'xao_param_charset'};
    $self->{'xao_param_charset'}=$charset;

    return $old;
}

###############################################################################

sub get_param_charset($$) {
    my $self=shift;
    return $self->{'xao_param_charset'};
}

###############################################################################

sub param ($;$) {
    my $self=shift;

    my $charset=$self->{'xao_param_charset'};

    if(!$charset) {
        if(wantarray) {
            return $self->SUPER::multi_param(@_);
        }
        else {
            return $self->SUPER::param(@_);
        }
    }
    else {
        if(wantarray) {
            return map {
                ref($_) ? $_ : Encode::decode($charset,$_)
            } $self->SUPER::multi_param(@_);
        }
        else {
            my $value=$self->SUPER::param(@_);
            return ref($value) ? $value : Encode::decode($charset,$value);
        }
    }
}

###############################################################################

sub multi_param ($;$) {
    my $self=shift;
    return $self->param(@_);
}

###############################################################################
1;
__END__

=over

=head1 AUTHORS

Copyright (c) 2006 Ejelta LLC
Andrew Maltsev, am@ejelta.com
