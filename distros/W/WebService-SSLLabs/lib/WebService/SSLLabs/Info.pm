package WebService::SSLLabs::Info;

use strict;
use warnings;

our $VERSION = '0.30';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub version {
    my ($self) = @_;
    return $self->{version} || $self->{engineVersion};
}

sub current_assessments {
    my ($self) = @_;
    return $self->{currentAssessments};
}

sub messages {
    my ($self) = @_;
    return @{ $self->{messages} };
}

sub max_assessments {
    my ($self) = @_;
    return $self->{maxAssessments};
}

sub criteria_version {
    my ($self) = @_;
    return $self->{criteriaVersion};
}

sub new_assessment_cool_off {
    my ($self) = @_;
    return $self->{newAssessmentCoolOff};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Info - Info object

=head1 VERSION

Version 0.30

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Info> object, accepts a hash ref as it's parameter.

=head2 version

SSL Labs software version as a string (e.g., "1.11.14")

=head2 criteria_version

rating criteria version as a string (e.g., "2009f")

=head2 max_assessments

the maximum number of concurrent assessments the client is allowed to initiate.

=head2 current_assessments

the number of ongoing assessments submitted by this client.

=head2 new_assessment_cool_off

the cool-off period after each new assessment; you're not allowed to submit a new assessment before the cool-off expires, otherwise you'll get a 429.

=head2 messages

a list of messages (strings). Messages can be public (sent to everyone) and private (sent only to the invoking client). Private messages are prefixed with "[Private]".

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Info requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Info requires no non-core modules

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-ssllabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SSLLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SSLLabs::Info


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SSLLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SSLLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SSLLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SSLLabs/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ivan Ristic and the team at L<https://www.qualys.com> for providing the service at L<https://www.ssllabs.com>

POD was extracted from the API help at L<https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
