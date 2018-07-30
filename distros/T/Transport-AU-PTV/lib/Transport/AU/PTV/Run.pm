package Transport::AU::PTV::Run;
$Transport::AU::PTV::Run::VERSION = '0.01';
use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;


sub new {
    my $class = shift;
    my ($api, $run) = @_;

    return bless { api => $api, run => $run }, $class;
}



sub run_id { return $_[0]->{run}{run_id} }


sub status { return $_[0]->{run}{status} }


sub direction_id { return $_[0]->{run}{direction_id} }


sub run_sequence { return $_[0]->{run}{run_sequence} }




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Run

=head1 VERSION

version 0.01

=head1 NAME

=head1 METHODS

=head2 new

=head2 run_id

    my $id = $run->run_id;

Returns the ID for the run

=head2 status

Returns the status of the route. Can be 'scheduled', 'added' or 'cancelled'

=head2 direction_id

The direction ID for the run.

=head2 run_sequence 

The sequence of stops for the run

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
