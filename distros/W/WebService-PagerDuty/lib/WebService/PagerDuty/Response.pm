#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Response;
{
  $WebService::PagerDuty::Response::VERSION = '1.20131219.1627';
}
## use critic
use strict;
use warnings;

use base qw/ WebService::PagerDuty::Base /;
use JSON;
use Error qw/ :try /;

my @all_options = qw/
  code status message error
  incident_key
  total limit offset
  entries
  data
  /;

__PACKAGE__->mk_ro_accessors(@all_options);

sub new {
    my ( $self, $response, $options ) = @_;
    $options ||= {};

    if ($response) {
        $options->{code}    = $response->code();
        $options->{status}  = $response->status_line();
        $options->{message} = $response->message();
        $options->{errors}  = undef;

        try {
            $options->{data} = from_json( $response->content() ) if $response->content();
        }
        otherwise {
            my $error = shift;
            ## the only error that could happen and we care of - it's when $response->content can't
            ## be parsed as json (no difference why - because of bad request or something else)
            $options->{data} = {
                status  => 'invalid',
                message => $_,
            };
        };

        for my $option (@all_options) {
            $options->{$option} = delete $options->{data}{$option} if exists $options->{data}{$option};
        }

        # one extra-case
        $options->{entries} = delete $options->{data}{incidents} if exists $options->{data}{incidents};

        # translate HTTP codes to human-readable status
        if ( $options->{status} =~ /^(\d+)/ ) {
            if ( $1 eq '200' ) {
                $options->{status} = 'success';
            }
            else {
                $options->{status} = 'invalid';
            }
        }

        # eliminate uneeded fields
        delete $options->{data} unless %{ $options->{data} };
    }
    else {
        $options->{code}    = 599;
        $options->{status}  = 'invalid';
        $options->{message} = $options->{error} = 'WebService::PagerDuty::Response was created incorrectly';
    }

    $self->SUPER::new(%$options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Response

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    my $response = WebService::PagerDuty::Response->new( ... );

=head1 DESCRIPTION

For internal use only.

=head1 NAME

WebService::PagerDuty::Response - Aux object to represent PagerDuty responses.

=head1 SEE ALSO

L<WebService::PagerDuty>, L<http://PagerDuty.com>, L<oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=for Pod::Coverage     new

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
