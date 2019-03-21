package WebService::HIBP::Breach;

use strict;
use warnings;

our $VERSION = '0.10';

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless {}, $class;
    foreach my $key ( sort { $a cmp $b } keys %parameters ) {
        if ( $key =~ /^Is/smx ) {
            $self->{$key} = $parameters{$key} ? 1 : 0;
        }
        else {
            $self->{$key} = $parameters{$key};
        }
    }
    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{Name};
}

sub title {
    my ($self) = @_;
    return $self->{Title};
}

sub domain {
    my ($self) = @_;
    return $self->{Domain};
}

sub description {
    my ($self) = @_;
    return $self->{Description};
}

sub breach_date {
    my ($self) = @_;
    return $self->{BreachDate};
}

sub modified_date {
    my ($self) = @_;
    return $self->{ModifiedDate};
}

sub is_retired {
    my ($self) = @_;
    return $self->{IsRetired};
}

sub is_sensitive {
    my ($self) = @_;
    return $self->{IsSensitive};
}

sub is_verified {
    my ($self) = @_;
    return $self->{IsVerified};
}

sub is_spam_list {
    my ($self) = @_;
    return $self->{IsSpamList};
}

sub is_fabricated {
    my ($self) = @_;
    return $self->{IsFabricated};
}

sub pwn_count {
    my ($self) = @_;
    return $self->{PwnCount};
}

sub added_date {
    my ($self) = @_;
    return $self->{AddedDate};
}

sub data_classes {
    my ($self) = @_;
    if ( defined $self->{DataClasses} ) {
        return @{ $self->{DataClasses} };
    }
    else {
        return ();
    }
}

sub logo_path {
    my ($self) = @_;
    return $self->{LogoPath};
}

1;    # End of WebService::HIBP::Breach
__END__

=head1 NAME

WebService::HIBP::Breach - An instance of a breach from the Have I Been Pwned webservice at haveibeenpwned.com

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

Check the security of your accounts/email addresses and passwords

    use WebService::HIBP();
    use v5.10;

    my $hibp = WebService::HIBP->new();
    foreach my $breach (sort { $a->added_date() cmp $b->added_date() } $hibp->breaches()) {
       say $breach->description();
    }

=head1 DESCRIPTION

Each breach contains a L<number of attributes|https://haveibeenpwned.com/API/v2#BreachModel> describing the incident.  In the future, these attributes may expand without the API being versioned.

=head1 SUBROUTINES/METHODS

=head2 new

A creation method that should only be called by L<WebService::HIBP|WebService::HIBP>.

=head2 name

A camel-cased name representing the breach which is unique across all other breaches. This value never changes and may be used to name dependent assets (such as images) but should not be shown directly to end users (see the L<title|WebService::HIBP::Breach#title> attribute instead). 

=head2 title

A descriptive title for the breach suitable for displaying to end users. It's unique across all breaches but individual values may change in the future (i.e. if another breach occurs against an organisation already in the system). If a stable value is required to reference the breach, refer to the L<name|WebService::HIBP::Breach#name> attribute instead. 

=head2 domain

The domain of the primary website the breach occurred on. This may be used for identifying other assets external systems may have for the site.

=head2 breach_date

The date (with no time) the breach originally occurred on in ISO 8601 format. This is not always accurate - frequently breaches are discovered and reported long after the original incident. Use this attribute as a guide only.

=head2 added_date

The date and time (precision to the minute) the breach was added to the system in ISO 8601 format. 

=head2 modified_date

The date and time (precision to the minute) the breach was modified in ISO 8601 format. This will only differ from the L<added_date|WebService::HIBP::Breach#added_date> attribute if other attributes represented here are changed or data in the breach itself is changed (i.e. additional data is identified and loaded). It is always either equal to or greater then the L<added_date|WebService::HIBP::Breach#added_date> attribute, never less than. 

=head2 pwn_count

The total number of accounts loaded into the system. This is usually less than the total number reported by the media due to duplication or other data integrity issues in the source data.

=head2 description

Contains an overview of the breach represented in HTML markup. The description may include markup such as emphasis and strong tags as well as hyperlinks.

=head2 data_classes

This attribute describes the nature of the data compromised in the breach and contains an alphabetically ordered string list of impacted data classes. 

=head2 is_verified

Indicates that the breach is considered L<unverified|https://haveibeenpwned.com/FAQs#UnverifiedBreach>. An unverified breach may not have been hacked from the indicated website. An unverified breach is still loaded into HIBP when there's sufficient confidence that a significant portion of the data is legitimate. 

=head2 is_fabricated

Indicates that the breach is considered L<fabricated|https://haveibeenpwned.com/FAQs#FabricatedBreach>. A fabricated breach is unlikely to have been hacked from the indicated website and usually contains a large amount of manufactured data. However, it still contains legitimate email addresses and asserts that the account owners were compromised in the alleged breach. 

=head2 is_sensitive

Indicates if the breach is considered L<sensitive|https://haveibeenpwned.com/FAQs#SensitiveBreach>. The public API will not return any accounts for a breach flagged as sensitive.

=head2 is_retired

Indicates if the breach has been L<retired|https://haveibeenpwned.com/FAQs#RetiredBreach>. This data has been permanently removed and will not be returned by the API. 

=head2 is_spam_list

Indicates if the breach is considered a L<spam list|https://haveibeenpwned.com/FAQs#SpamList>. This flag has no impact on any other attributes but it means that the data has not come as a result of a security compromise.

=head2 logo_path

No documentation for this yet. May be removed without notice.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::HIBP::Breach requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::HIBP requires no non-core modules

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

    perldoc WebService::HIBP

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

Copyright 2019 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
