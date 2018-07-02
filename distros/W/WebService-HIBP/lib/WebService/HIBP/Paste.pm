package WebService::HIBP::Paste;

use strict;
use warnings;

our $VERSION = '0.06';

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless {}, $class;
    foreach my $key ( sort { $a cmp $b } keys %parameters ) {
        $self->{$key} = $parameters{$key};
    }
    return $self;
}

sub source {
    my ($self) = @_;
    return $self->{Source};
}

sub id {
    my ($self) = @_;
    return $self->{Id};
}

sub title {
    my ($self) = @_;
    return $self->{Title};
}

sub date {
    my ($self) = @_;
    return $self->{Date};
}

sub email_count {
    my ($self) = @_;
    return $self->{EmailCount};
}

1;    # End of WebService::HIBP::Paste
__END__

=head1 NAME

WebService::HIBP::Paste - An instance of a paste from the Have I Been Pwned webservice at haveibeenpwned.com

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

Check the security of your accounts/email addresses and passwords

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $paste ($hibp->pastes()) {
       say $paste->source();
    }

=head1 DESCRIPTION

Each paste contains a L<number of attributes|https://haveibeenpwned.com/API/v2#PasteModel> describing it.  In the future, these attributes may expand without the API being versioned.

=head1 SUBROUTINES/METHODS

=head2 new

A creation method that should only be called by L<WebService::HIBP|WebService::HIBP>.

=head2 source

The paste service the record was retrieved from. Current values are: Pastebin, Pastie, Slexy, Ghostbin, QuickLeak, JustPaste, AdHocUrl, OptOut

=head2 id

The ID of the paste as it was given at the source service. Combined with the "Source" attribute, this can be used to resolve the URL of the paste.

=head2 title

The title of the paste as observed on the source site. This may be null and if so will be omitted from the response.

=head2 date

The date and time (precision to the second) that the paste was posted. This is taken directly from the paste site when this information is available but may be null if no date is published.

=head2 email_count

The number of emails that were found when processing the paste. Emails are extracted by using the regular expression \b+(?!^.{256})[a-zA-Z0-9\.\-_\+]+@[a-zA-Z0-9\.\-_]+\.[a-zA-Z]+\b

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::HIBP::Paste requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::HIBP::Paste requires no non-core modules

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-webservice-hibp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HIBP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HIBP::Paste

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HIBP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-HIBP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HIBP>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HIBP/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Troy Hunt for providing the service at L<https://haveibeenpwned.com>

POD was extracted from the API help at L<https://haveibeenpwned.com/API/v2>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
