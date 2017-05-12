package XAS::Logmon::Format::Logstash;

our $VERSION = '0.01';

use Try::Tiny;
use Hash::Merge;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation dotid trim',
  constants => 'HASHREF',
  codec     => 'JSON',
  accessors => 'hm',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub dt2ls {
    my $self = shift;
    my ($dt, $zone) = validate_params(\@_, [
        { isa => 'DateTime' },
        { optional => 1, default => 'local' },
    ]);

    try {

        $dt->set_time_zone($zone);

    } catch {

        my ($package, $file, $line) = caller(1);
        my $ex = XAS::Exception->new({
            type => dotid($self->class) . '.dt2ls.badzone',
            info => $self->message('logmon_badzone', $package, $line, $zone)
        });

        $ex->throw;

    };

    return $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

}

sub format {
    my $self = shift;
    my ($data) = validate_params(\@_, [
        { type => HASHREF,
              callbacks => {'no datetime' => sub {defined($_[0]->{datetime}); }}
        },
    ]);

    my $event = {
        '@timestamp' => $self->dt2ls($data->{'datetime'}, 'UTC'),
        '@version'   => 1,
    };

    delete($data->{'datetime'});
    delete($data->{'level'});
    delete($data->{'task'});

    $event = $self->hm->merge($data, $event);    

    return encode($event);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'hm'} = Hash::Merge->new('RIGHT_PRECEDENT');

    return $self;

}

1;

__END__

=head1 NAME

XAS::Log::Format::Logstash - A formatting class for log file handling

=head1 SYNOPSIS

 use XAS::Log::Format::Logstash;

 my $formatter = XAS::Log::Format::Logstash->new();
 my $event = $formatter->format($data);

=head1 DESCRIPTION

This package will take a hash and format it into a json_event for 
L<Logstash|https://www.elastic.co/products/logstash>.

=head1 METHODS

=head2 format($data)

This method will add the key fields, convert the @timestamp field into a
UTC date while formatting the datetime field into a local date. It returns
a json_event string.

=over 4

=item B<$data>

The hash to format.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon|XAS::Logmon>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
