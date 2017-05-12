package XAS::Service::CheckParameters;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation dotid',
  codec     => 'JSON',
  constants => 'HASHREF',
  mixins    => 'check_parameters',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub check_parameters {
    my $self = shift;
    my ($params, $type) = validate_params(\@_, [
        { type => HASHREF },
        1,
    ]);

    my @errors;
    my $results = $self->profile->check($params, $type);
    my $valids  = $results->valid();

    if ($results->has_missing) {

        for my $f ($results->missing) {

            my $error = {
                id  => $f,
                msg => $results->msgs->{'missing'} || 'is missing',
            };

            push(@errors, $error);

        }

    }

    if ($results->has_invalid) {

        for my $f ($results->invalid) {

            my $error = {
                id  => $f,
                msg => $results->msgs->{$f} || 'is invalid',
            };

            push(@errors, $error);

        }

    }

    if (scalar(@errors) > 0) {

        $self->throw_msg(
            dotid($self->class) . '.check_parameters.' . $type,
            'errors',
            encode(@errors)
        );

    }

    return $valids;

}

1;

__END__

=head1 NAME

XAS::Service::CheckParameters - A mixin to check parameters.

=head1 SYNOPSIS

 my $valids;
 my $params = {
     start => 1,
     limit => 25
 };

 if ($valids = $self->check_parameters($params, 'pager')) {

     while (my ($key, $value) = each(%$valids)) {

         printf("key: %s, value: %s\n", $key, $value);

     }

 }

=head1 DESCRIPTION

This is a mixin routine to help with checking L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator>
parameters. It expects a "profile" method to be defined. Exceptions are thrown,
and the message is a JSON data structure of the errors.

=head2 check_parameters($params, $type)

A basic validation routine. It returns a hashref of valid parmeters and there
values. It accepts these parameters.

=over 4

=item B<$params>

A hashref of parameters to check.

=item B<$type>

The profiles type to check against.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
