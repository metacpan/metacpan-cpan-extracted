package Test::Module::CheckDep::Version;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

sub ver {
    return $VERSION;
}
1;
__END__

=head1 NAME

Test::Module::CheckDep::Version - Unusable distribution to test Module::CheckDep::Version 

=head1 DESCRIPTION

This distribution does absolutely nothing but provide a reliable test case for
L<Module::CheckDep::Version>. It has no code whatsoever.

It is required due to the said distribution relying on L<MetaCPAN::Client>, and
fetching a distribution known to have a C<<PREREQ_PM>> which has a lower
version than the most up-do-date release.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
