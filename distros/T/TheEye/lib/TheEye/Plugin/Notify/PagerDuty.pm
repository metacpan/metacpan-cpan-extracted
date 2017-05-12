package TheEye::Plugin::Notify::PagerDuty;

use 5.010;
use Mouse::Role;
use LWP::UserAgent;
use URI::Escape;
use JSON;
use Data::Dumper;

# ABSTRACT: Plugin for TheEye to raise alerts in Pager Duty
#
our $VERSION = '0.5'; # VERSION

has 'pd_token' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => '',
);

has 'pd_host' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => ''
);

has 'pd_url' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'https://events.pagerduty.com/generic/2010-04-15/create_event.json',
);

has 'pd_err' => (
    is        => 'rw',
    isa       => 'HashRef',
    required  => 0,
    default   => 0,
    predicate => 'has_pd_err',
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {

                if($step->{message} =~ m{^(not ok \d+ -) ([^\s]+) (.*)$}){
                    $step->{lead_in} = $1;
                    $step->{node} = $2;
                    $step->{test_error} = $3;
                }
                my $message = {
                    service_key => $self->pd_token,
                    incident_key => $step->{node} || $test->{node},
                    event_type => 'trigger',
                    description => $step->{message},
                    details => {
                        node => $step->{node},
                        test => $test->{file},
                        result => $step->{comment},
                        host => $self->pd_host,
                        delta => $step->{delta},
                    },
                };
                my $res = $self->pd_send($message);
                print Dumper $res if $self->is_debug;
            }
        }
    }
};

sub pd_send {
    my ( $self, $content ) = @_;

    my $req = HTTP::Request->new();
    $req->method('POST');
    $req->uri($self->pd_url);
    $req->header('Content-Type' => 'application/json');

    $req->content( to_json($content) ) if ($content);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    print STDERR "Result: " . $res->decoded_content . "\n" if $self->is_debug;
    if ( $res->is_success ) {
        return from_json( $res->decoded_content );
    }
    else {
        if ( my $_err = from_json( $res->decoded_content ) ) {
            $self->pd_err($_err);
        }
        else {
            $self->pd_err( $res->status_line );
        }
    }
    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Notify::PagerDuty - Plugin for TheEye to raise alerts in Pager Duty

=head1 VERSION

version 0.5

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

=for Pod::Coverage pd_send
