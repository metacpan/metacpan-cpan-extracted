package Test2::EventFacet::Coverage;
use strict;
use warnings;

our $VERSION = '0.000013';

BEGIN { require Test2::EventFacet; our @ISA = qw(Test2::EventFacet) }
use Test2::Util::HashBase qw{ files submap openmap };

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

Arrayref of files touched during testing. This includes modules that were
loaded or had subroutines called. This also includes files opened via
C<open()>.

=item $hashref = $about->{submap}

=item $hashref = $about->submap()

    {
        'SomeModule.pm' => {
            # The wildcard is used when a proper sub name cannot be determined
            '*' => { ... },

            'SomeModule::subroutine' => {
                sub_package => 'SomeModule',
                sub_name    => 'subroutine',

                call_count => $INTEGER,

                # The items in this list can be anything, strings, numbers,
                # data structures, etc.
                # A naive attempt is made to avoid duplicates in this list,
                # so the same string or reference will not appear twice, but 2
                # different references with identical contents may appear.
                called_by => [
                    '*',     # The wildcard is used when no 'called by' can be determined
                    $FROM_A,
                    $FROM_B,
                    ...
                ],
            },
        },
        ...
    }


=item $hashref = $about->{openmap}

=item $hashref = $about->openmap()

    {
        # The items in this list can be anything, strings, numbers,
        # data structures, etc.
        # A naive attempt is made to avoid duplicates in this list,
        # so the same string or reference will not appear twice, but 2
        # different references with identical contents may appear.
        "some_file.ext" => [
            '*',        # The wildcard is used when no 'called by' can be determined
            $FROM_A,
            $FROM_b,
        ],
    }

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
