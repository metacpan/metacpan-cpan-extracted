package TheEye::Plugin::Notify::Oncall;

use 5.010;
use Mouse::Role;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;

# ABSTRACT: Plugin for TheEye to raise alerts in OnCall
#
our $VERSION = '0.5'; # VERSION

has 'oncall_token' => (
    is  => 'rw',
    isa => 'Str',
    lazy     => 1,
    required => 1,
    default => 123,
);

has 'oncall_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://localhost:3000/add/',
    lazy     => 1,
    required => 1,
);

has 'oncall_host' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { my $host = qx{hostname}; chomp($host); return $host },
    lazy     => 1,
    required => 1,
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {
                my $message = 'Test: ' . $test->{file} . "\n";
                $message .= $step->{message} . "\n";
                $message .= $step->{comment} if $step->{comment};
                push(@errors, $message);
            }
        }
    }
    if($errors[0]){
        my $msg = join("\n\n--~==##\n\n", @errors);
        $self->oncall_send({message => $msg});
    }
};

sub oncall_send {
    my ($self, $message) = @_;

    $message->{host} = $self->oncall_host unless exists $message->{host};
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->post(
        $self->oncall_url . $self->oncall_token,
        Content_Type => 'form-data',
        Content      => { payload => to_json($message) });
    print Dumper($message)
        if $self->debug;
    return $res->is_success;
}

1;

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Notify::Oncall - Plugin for TheEye to raise alerts in OnCall

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

=for Pod::Coverage oncall_send
