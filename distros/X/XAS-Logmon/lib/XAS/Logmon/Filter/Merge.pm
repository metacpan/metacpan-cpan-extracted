package XAS::Logmon::Filter::Merge;

our $VERSION = '0.01';

use Hash::Merge;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation',
  accessors => 'hm',
  constants => 'HASHREF',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub filter {
    my $self = shift;
    my ($data, $cfg) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF },
    ]);

    return $self->hm->merge($data, $cfg);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $self = shift;

    $self->{'hm'} = Hash::Merge->new('RIGHT_PRECEDENT');

    return $self;

}

1;

__END__

=head1 NAME

XAS::Logmon::Filter::Merge - A filter class for log file manipulation.

=head1 SYNOPSIS

 use XAS::Logmon::Filter::Merge;

  my $merge = XAS::Logmon::Filter::Merge->new();
  
  $data = $merge->filter($data, {field => 'value'});

=head1 DESCRIPTION

This package will provide a filter to merge one hash into another. This
can be used to add fields or override existing fields.

=head1 METHODS

=head2 filter($data)

This method will perform the merge. It takes these paramters.

=over 4

=item B<$data>

The hash to be merged with.

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
