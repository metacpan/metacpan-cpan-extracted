package WWW::Wolfram::DataDrop;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.03';

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw/Databin/;

use LWP::UserAgent;

sub Databin {
    my ($id, %opts) = @_;
    my $self = __PACKAGE__->new(bin => $id, %opts);
    return $self;
}

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    my $ua_opts = delete $self->{opts};
    $self->{ua} = LWP::UserAgent->new(%$ua_opts);
    return bless $self, $class;
}

sub add {
    my ($self, %values) = @_;
    $values{bin} = $self->{bin};
    return $self->_send(%values);
}

sub _send {
    my ($self, %values) = @_;
    my $res = $self->ua->post($self->url, [%values]);
    return $res->is_success;
}

sub ua {
    my $self = shift;
    return $self->{ua};
}

sub url {
    my $self = shift;
    return 'https://datadrop.wolframcloud.com/api/v1.0/Add';
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Wolfram::DataDrop - Access the Wolfram DataDrop API

=head1 SYNOPSIS

  use WWW::Wolfram::DataDrop;

  my $bin = Databin('id');
  $bin->add(name => 'Peter', age => 33);

=head1 DESCRIPTION

WWW::Wolfram::DataDrop allows you to write to the Wolfram DataDrop API.
It's not yet possible to create, remove or update DataDrops.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright 2017- Peter Stuifzand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
