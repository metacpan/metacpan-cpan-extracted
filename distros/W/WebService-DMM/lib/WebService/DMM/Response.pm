package WebService::DMM::Response;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw/result_count total_count first_position items
                is_success cause/ ],
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Response - DMM response class

=head1 SYNOPSIS

=head1 DESCRIPTION

WebService::DMM::Response is

=head1 INTERFACE

=head2 Accessor

=over

=item result_count : Int

=item total_count : Int

=item first_position : Int

=item items : Int

=item is_success : Bool

=item cause : String

Cause of failing to request Web API,

=back

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
