use strict;
use warnings;
package WWW::Saucelabs;
$WWW::Saucelabs::VERSION = '0.0201';
# ABSTRACT: An incomplete, wip perl client to the Saucelabs REST API
use Net::HTTP::Knork;
use Carp qw/croak/;
use JSON qw/to_json/;
use Moo;
use namespace::clean;


has user => (
    is => 'ro',
    default => sub {
        if (exists $ENV{SAUCE_USERNAME} && $ENV{SAUCE_USERNAME}) {
            return $ENV{SAUCE_USERNAME};
        }
        else {
            croak 'You must specify a user, or set the environment variable SAUCE_USERNAME';
        }
    }
);


has access_key => (
    is => 'ro',
    default => sub {
        if (exists $ENV{SAUCE_ACCESS_KEY} && $ENV{SAUCE_ACCESS_KEY}) {
            return $ENV{SAUCE_ACCESS_KEY};
        }
        else {
            croak 'You must specify an access_key, or set the environment variable SAUCE_ACCESS_KEY';
        }
    }
);

my $methods = {};


$methods->{get_job_assets} = {
    method => 'GET',
    required_params => [ 'user', 'job_id' ],
    path => '/:user/jobs/:job_id/assets',
};


$methods->{get_job_status} = {
    method => 'GET',
    required_params => [ 'user', 'job_id' ],
    path => '/:user/jobs/job_id'
};


$methods->{get_jobs} = {
    method => 'GET',
    required_params => [ 'user' ],
    optional_params => [ 'limit' ],
    path => '/:user/jobs',
};


$methods->{set_job_status} = {
    method => 'PUT',
    required_params => [ 'user', 'job_id' ],
    required_payload => [ 'status' ],
    path => '/:user/jobs/:job_id'
};


$methods->{get_sauce_status} = {
    method => 'GET',
    base_url => 'http://saucelabs.com/rest/v1',
    path => '/info/status',
};

my $spec = {
    name => 'Saucelabs REST API',
    formats => [ 'json' ],
    version => '0.1',
    methods => $methods
};

has _base_url => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => sub {
        my ($self) = @_;

        my $base_url = 'https://' . $self->user . ':' . $self->access_key;
        $base_url .= '@saucelabs.com/rest/v1';

        return $base_url;
    }
);

has _spec => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my ($self) = @_;
        $spec->{base_url} = $self->_base_url;
        return $spec;
    }
);

has _client => (
  is => 'ro',
  lazy => 1,
  handles => [ keys %{ $spec->{methods} } ],
  builder => sub {
      my ($self) = @_;

      my $knork = Net::HTTP::Knork->new(
          spec => to_json($self->_spec),
          client => $self->_ua,
          default_params => {
              user => $self->user
          }
      );

      return $knork;
  }
);

has _ua => (
    is => 'ro',
    default => sub { LWP::UserAgent->new }
);


sub fail_job {
    my ($self, $job) = @_;
    croak 'We need a job to fail' unless $job;

    $self->set_job_status({
        job_id => $job,
        status => JSON::false
    });
}


sub pass_job {
    my ($self, $job) = @_;
    croak 'We need a job to pass' unless $job;

    $self->set_job_status({
        job_id => $job,
        status => JSON::true
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Saucelabs - An incomplete, wip perl client to the Saucelabs REST API

=for markdown [![Build Status](https://travis-ci.org/gempesaw/saucerest-perl.svg?branch=master)](https://travis-ci.org/gempesaw/saucerest-perl)

=head1 VERSION

version 0.0201

=head1 SYNOPSIS

    my $sauce = WWW::Saucelabs->new;

    my $jobs = $sauce->get_jobs({limit => 5 });
    map { say $_->{id} } @$jobs;

=head1 DESCRIPTION

This module is an incomplete perl client for the L<Saucelabs REST
API|https://docs.saucelabs.com/reference/rest-api/>. Saucelabs
provides webdriver instances for automated testing in the cloud for
CI.

This module is perilously incomplete and we'd love for you to
contribute. (We have no affiliation with Saucelabs other than we love
using their services :D)

=head1 ATTRIBUTES

=head2 user

REQUIRED: pass in your Saucelabs user. Alternatively, you can
export it to the environment variable SAUCE_USERNAME in place of
specifying it during construction.

If there's no SAUCE_USERNAME environment variable, and you neglect to
specify the user during construciton, we will croak.

=head2 access_key

REQUIRED: pass in your Saucelabs access key. Alternatively, you can
export it to the environment variable SAUCE_ACCESS_KEY in place of
specifying it during construction.

If there's no SAUCE_ACCESS_KEY environment variable, and you neglect to
specify the access_key during construciton, we will croak.

=head1 METHODS

=head2 fail_job( $job_id )

Shortcut to set the status of a job to failure. C<$job_id> should be a
string.

=head2 pass_job( $job_id )

Shortcut to set the status of a job to success. C<$job_id> should be a
string.

=head1 IMPLEMENTED ENDPOINTS

=head2 get_job_assets({ job_id => $job_id })

Retrieve the assets for a given job id.

=head2 get_job_status({ job_id => $job_id })

Retrieve the status of a given job by its job_id.

=head2 get_jobs

Retrieve a list of available jobs

=head2 set_job_status({ job_id => $job_id, status => JSON::true|JSON::false })

Set the status of a given job to success or failure.

=head2 get_sauce_status

Get the current status of the Saucelabs service.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/saucerest-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
