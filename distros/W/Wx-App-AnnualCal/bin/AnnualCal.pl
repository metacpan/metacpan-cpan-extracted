#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Wx::App::AnnualCal;
use Wx::App::AnnualCal::MyFrame;

#my $ref = Wx::App::AnnualCal->new();
#$ref->MainLoop();
Wx::App::AnnualCal->new()->MainLoop();

#PODNAME: AnnualCal.pl - driver script for the AnnualCal application.



__END__
=pod

=head1 NAME

AnnualCal.pl - driver script for the AnnualCal application.

=head1 VERSION

version 0.92

=head1 SYNOPSIS

C<use Wx::App::AnnualCal;>

C<Wx::App::AnnualCal-E<gt>new()-E<gt>MainLoop();>

=head1 AUTHOR

Elliot Winston <exw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Elliot Winston.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

