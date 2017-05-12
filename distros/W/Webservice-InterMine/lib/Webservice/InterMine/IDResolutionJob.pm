package Webservice::InterMine::IDResolutionJob;

use strict;
use Moose;

use MooseX::Types::Moose qw/Num Str Bool ArrayRef HashRef Maybe/;
use Webservice::InterMine::Types qw/Service/;

use Time::HiRes qw/gettimeofday/;
use Carp qw(croak confess);

require HTTP::Request::Common;

=head1 NAME

Webservice::InterMine::IDResolutionJob

=head1 SYNOPSIS

    use strict;
    use Webservice::InterMine;
    use Data::Dumper;

    my $service = Webservice::InterMine->get_service('www.flymine.org/query');

    my $job = $service->resolve_ids(
        identifiers => [qw/eve zen r bib Mad h/],
        type => 'Gene',
        extra => 'D. melanogaster'
    );

    $job->poll until ($job->completed);

    print Dumper($job->results);

=head1 DESCRIPTION

ID Resolution jobs are asynchronous requests to a web service to resolve a set of
identifiers to the objects available in the services data-store. This object records the
request made and provides mechanisms for checking the status of the request and retrieving
the results when they become available.

=head1 ATTRIBUTES

=head2 service

isa: L<Webservice::InterMine::Service>
is: ro
required: true

The service this request was made to.

=cut

has service => (
    isa => Service,
    required => 1,
    is => 'ro'
);

=head2 identifiers

isa: Array of Str
is: ro
required: true

The identifiers to resolve.

=cut

has identifiers => (
    isa => ArrayRef[Str],
    is  => 'ro',
    required => 1
);

=head2 uid

isa: Str
is: ro

The unique identifier of this job on the server.

=cut

has uid => (
    isa => Str,
    is => 'ro',
    builder => '_init_uid'
);

sub _init_uid {
    my $self = shift;
    my $service = $self->service;
    my $resp = $service->post(
        $service->build_uri($service->root . '/ids'),
        'Content-Type' => 'application/json',
        'Content' => $service->encode($self->as_submission)
    );
    if ( $resp->is_error ) {
        my $error = eval { $service->decode($resp->content)->{error} };
        $error ||= $resp->content;
        croak sprintf "%s: %s", $resp->status_line, $error;
    }
    my $data = $service->decode($resp->content);
    unless ($data->{wasSuccessful}) {
        confess $data->{error};
    }
    return $data->{uid};
}

=head2 type

isa: Str
is: ro
required: true

The type of objects these identifiers are meant to resolve to (eg. Gene).

=cut 

has type => (
    isa => Str,
    is  => 'ro',
    required => 1
);

=head2 extra

isa: Str
is: ro
required: false

An optional extra value used to disambiguate the ID resolution, such as the organism name.

=cut

has extra => (
    isa => Maybe[Str],
    is  => 'ro',
);

=head2 caseSensitive

isa: Bool
is: ro
required: false
default: false

Whether or not the identifiers should be treated case-sensitively or not.

=head2 wildCards 

isa: Bool
is: ro
required: false
default: false

Whether or not to interpret '*'s in identifiers as wildcards.

=cut

has [qw/caseSensitive wildCards/] => (
    isa => Maybe[Bool],
    is => 'ro'
);

=head2 completed

isa: Bool
is: ro
required: false
default: false

whether or not this job has been completed yet.

=cut

has completed => (
    isa => Bool,
    is => 'ro',
    writer => '_set_completed',
    default => 0
);

=head2 times_polled

isa: Num
is: ro
required: false
init: 0

The number of times this job has polled for results.

=cut

has times_polled => (
    isa => Num,
    traits => ['Counter'],
    is => 'ro',
    default => 0,
    handles => {_polled => 'inc'}
);

=head2 last_poll

isa: Num
is: ro
required: false

The timestamp of the last poll.

=cut

has last_poll => (
    isa => Num,
    required => 0,
    is => 'ro',
    writer => '_polled_at'
);

=head2 results

The results of the job. Do not call for them before the job reports its completion.

=cut

has results => (
    is => 'ro',
    isa => HashRef,
    lazy_build => 1,
    builder => 'fetch_results'
);

=head1 METHODS

=head2 all_match_ids()

Get the ids reported as match ids.

=cut

sub all_match_ids {
    my $self = shift;
    if ($self->service->version >= 16) {
       my %ids;
       my $results = $self->results;
       for my $key (qw/MATCH DUPLICATE CONVERTED_TYPE OTHER/) {
           for my $id ($self->match_ids($key)) {
               $ids{$id} = 1;
           }
       }
       return keys %ids;
    } else {
        return keys %{$self->results};
    }
}

=head2 good_match_ids()

Get the ids of objects reported at good matches

=cut

sub good_match_ids {
    my $self = shift;
    return $self->match_ids('MATCH');
}

=head2 match_ids($reason)

Get the ids of objects reported as matches for the given reason.

=cut

sub match_ids {
    my $self = shift;
    my $reason = shift;

    if ($self->service->version >= 16) {
        return map {$_->{id}} @{ $self->results->{matches}{$reason} };
    } else {
        my @ids;
        while (my ($id, $match) = each %{$self->results}) {
            for my $reasons (values %{ $match->{identifiers} }) {
                if (grep {/$reason/} @$reasons) {
                    push @ids, $id;
                }
            }
        }
        return @ids;
    }
}

=head2 as_submission()

Get the data transmitted to the service to initialise the job.

=cut

sub as_submission {
    my $self = shift;
    return {
        identifiers   => $self->identifiers,
        type          => $self->type,
        extra         => ($self->extra || ''),
        caseSensitive => ($self->caseSensitive ? 'true' : 'false'),
        wildCards     => ($self->caseSensitive ? 'true' : 'false'),
    };
}

sub _register_poll {
    my $self = shift;
    $self->_polled();
    $self->_polled_at( gettimeofday() );
}

sub _backoff {
    my $self = shift;
    if (my $polls = $self->times_polled) {
        my $backoff = log $polls;
        my $elapsed = gettimeofday() - $self->last_poll();
        $backoff -= $elapsed;
        if ($backoff > 0) {
            sleep $backoff;
        }
    }
}

=head2 poll()

Check the status of the job on the server.

Returns true when the job is complete, and false if it is not ready yet. If the job has
resulted in an error on the server, that error message will be confessed here.

=cut

sub poll {
    my $self = shift;
    return 1 if $self->completed;
    $self->_backoff;
    my $data = $self->service->fetch_json('/ids/' . $self->uid . '/status');
    $self->_register_poll;
    my $status = $data->{status};
    if ($status eq 'ERROR') {
        confess($data->{message});
    } elsif ($status eq 'SUCCESS') {
        return $self->_set_completed(1);
    } else {
        return undef;
    }
}

=head2 fetch_results() 

Make a call to the server to fetch results for this job.

=cut

sub fetch_results {
    my $self = shift;
    my $data = $self->service->fetch_json('/ids/' . $self->uid . '/result');
    return $data->{results};
}

=head2 delete()

Delete this job from the server.

=cut

sub delete {
    my $self = shift;
    my $uri = $self->service->build_uri($self->service->root . '/ids/' . $self->uid);
    my $resp = $self->service->agent->request(HTTP::Request::Common::DELETE($uri));
    if ($resp->is_error) {
        my $error = eval {$self->decode($resp->content)->{error}}
            || $resp->status_line . $resp->content;
        confess $error;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 AUTHOR

Alex Kalderimis C<dev@intermine.org>

=head1 BUGS

Please report any bugs or feature requests to C<dev@intermine.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Webservice::InterMine::IDResolutionJob

You can also look for information at:

=over 4

=item * InterMine

L<http://www.intermine.org>

=item * Documentation

L<http://intermine.org/wiki/PerlWebServiceAPI>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2013 FlyMine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

