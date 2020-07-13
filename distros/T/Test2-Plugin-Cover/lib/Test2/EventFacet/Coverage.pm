package Test2::EventFacet::Coverage;
use strict;
use warnings;

our $VERSION = '0.000009';

BEGIN { require Test2::EventFacet; our @ISA = qw(Test2::EventFacet) }
use Test2::Util::HashBase qw{ files };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::EventFacet::Coverage - File coverage information.

=head1 DESCRIPTION

This facet has a list of files covered by the test run.

=head1 FIELDS

=over 4

=item $string = $about->{details}

=item $string = $about->details()

Summary of files run.

=item $arrayref = $about->{files}

=item $arrayref = $about->files()

=back

=head1 SOURCE

The source code repository for Test2-Plugin-Cover can be found at
F<https://github.com/Test-More/Test2-Plugin-Cover>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
