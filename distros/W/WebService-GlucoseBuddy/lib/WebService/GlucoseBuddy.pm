package WebService::GlucoseBuddy;
{
  $WebService::GlucoseBuddy::VERSION = '1.113540';
}
# ABSTRACT: Interface to a glucosebuddy.com account

use Moose 1.24;
use namespace::autoclean 0.13;
use MooseX::Iterator 0.11;
use WWW::Mechanize 1.70;
use Readonly 1.03;
use Text::CSV 1.21;
use DateTime::Format::Strptime 1.5;
use Carp 1.20;

use WebService::GlucoseBuddy::Log;
use WebService::GlucoseBuddy::Log::Reading;

Readonly my $SERVICE_URI    => 'https://www.glucosebuddy.com';
Readonly my $DT_FORMAT      => '%m/%d/%Y %T';


has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has password => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has _mech => (
    is          => 'ro',
    isa         => 'WWW::Mechanize',
    lazy_build  => 1,
);

sub _build__mech {
    my $self = shift;

    my $mech = WWW::Mechanize->new;
    $mech->get($SERVICE_URI . '/login');

    unless ($mech->success) {
        croak 'Could not connect to glucosebuddy.com';
    }

    $mech->submit_form(
        with_fields => {
            login       => $self->username,
            password    => $self->password,
        }
    );

    unless ($mech->uri->path eq '/logs/new') {
        croak 'Log in failed';
    }

    return $mech;
}

has _logs => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
);

{
    my $dt_formatter = DateTime::Format::Strptime->new(
        pattern     => $DT_FORMAT,
        on_error    => 'croak',
    );

    sub _build__logs {
        my $self = shift;

        my $mech = $self->_mech;
        $mech->get('/logs/MyExportedGlucoseBuddyLogs.csv');

        my $logs_file = $mech->content;
        open my $logs_fh, '<', \$logs_file;

        my $csv = Text::CSV->new;

        my @logs;

        # throw away header
        <$logs_fh>;

        while (my $row = $csv->getline($logs_fh)) {
            # change time column to DT object so we can filter it later
            $row->[5] = $dt_formatter->parse_datetime($row->[5]);

            push @logs, $row;
        }

        return \@logs;
    }
}


sub logs {
    my $self = shift;
    my %args = @_;
    
    my @logs = @{ $self->_logs };

    if ($args{from}) {
        @logs = grep { $_->[5] >= $args{from} } @logs;
    }

    if ($args{to}) {
        @logs = grep { $_->[5] <= $args{to} } @logs;
    }

    my @log_objects;

    for (@logs) {
        my $reading = WebService::GlucoseBuddy::Log::Reading->new(
            type    => $_->[0],
            value   => $_->[1],
            unit    => $_->[2],
        );

        push @log_objects => WebService::GlucoseBuddy::Log->new(
            reading => $reading,
            time    => $_->[5],
            name    => $_->[3],
            event   => $_->[4],
            notes   => $_->[6],
        );
    }

    return MooseX::Iterator::Array->new(collection => \@log_objects);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WebService::GlucoseBuddy - Interface to a glucosebuddy.com account

=head1 VERSION

version 1.113540

=head1 METHODS

=head2 logs [%args]

Returns an L<MooseX::Iterator> iterator of L<WebService::GlucoseBuddy::Log> objects, each 
representing a log

Args can contain:

=over 1

=item from

A L<DateTime> object to search logs on or after this time

=item to

A L<DateTime> object to search logs on or before this time

=back

=head1 CONSTRUCTOR

=head2 new

Constructor requires these arguments:

=over 1

=item username

Your glucosebuddy.com username

=item password

Your glucosebuddy.com password

=back

=head1 AUTHOR

Pete Smith <pete@cubabit.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Pete Smith.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

