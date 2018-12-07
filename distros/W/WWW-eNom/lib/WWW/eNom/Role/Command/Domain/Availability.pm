package WWW::eNom::Role::Command::Domain::Availability;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool HashRef Int Str Strs );

use WWW::eNom::DomainAvailability;

use Carp;

use Readonly;
Readonly my $SUGGESTABLE_TLDS => [ qw( com net tv cc ) ];

requires 'submit';

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Domain Availability API Calls

sub check_domain_availability {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        slds        => { isa => Strs },
        tlds        => { isa => Strs },
        suggestions => { isa => Bool, default => 0 },
    );

    if( ( scalar @{ $args{slds} } * @{ $args{tlds} } ) > 30 ) {
        croak 'The combination of slds and tlds you provided would require more than 30 checks.  Please reduce your search.';
    }

    my @domains_to_check;
    for my $sld (@{ $args{slds} }) {
        for my $tld (@{ $args{tlds} }) {
            push @domains_to_check, sprintf( '%s.%s', $sld, $tld );
        }
    }

    my $response = $self->submit({
        method => 'Check',
        params => {
            DomainList => join( ',', @domains_to_check ),
        }
    });

    my @domain_availabilities;
    for( my $domain_index = 0; $domain_index < ( scalar @{ $response->{Domain} } ); $domain_index++ ) {
        push @domain_availabilities, WWW::eNom::DomainAvailability->new(
            name         => $response->{Domain}->[ $domain_index ],
            is_available => ( $response->{RRPCode}->[ $domain_index ] == 210 )
        );
    }

    if( $args{suggestions} ) {
        for my $sld (@{ $args{slds} }) {
            my $suggestions_domain_availabilities = $self->suggest_domain_names({
                phrase  => $sld,
                tlds    => $args{tlds},
                related => 1,
            });

            push @domain_availabilities, @{ $suggestions_domain_availabilities };
        }
    }

    return \@domain_availabilities;
}

sub suggest_domain_names {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        phrase      => { isa => Str  },
        tlds        => { isa => Strs },
        related     => { isa => Bool, default => 0 },
        num_results => { isa => Int,  default => 10 },
    );

    my @suggestable_tlds = grep {
        my $valid_tld = $_;
        grep { $_ eq $valid_tld } @{ $args{tlds} };
    } @{ $SUGGESTABLE_TLDS };

    if( scalar @suggestable_tlds == 0 ) {
        # No suggestions since none of the specified TLDs are support it
        return [ ];
    }

    my $response = $self->submit({
        method => 'NameSpinner',
        params => {
            SLD        => $args{phrase},
            TLDList    => join( ',', @{ $args{tlds} } ),
            Related    => ( $args{related} ? 'High' : 'Off' ),
            MaxResults => $args{num_results},
        }
    });

    my @domain_availabilities;
    for my $sld ( keys %{ $response->{namespin}{domains}{domain} } ) {
        my $domain_response = $response->{namespin}{domains}{domain}{$sld};

        for my $tld (@{ $args{tlds} }) {
            if( !exists $domain_response->{$tld} ) {
                next;
            }

            push @domain_availabilities, WWW::eNom::DomainAvailability->new(
                name         => sprintf('%s.%s', lc $sld, $tld ),
                is_available => ( $domain_response->{$tld} eq 'y' ),
            );
        }
    }

    return \@domain_availabilities;
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Domain::Availability - Domain Availability Related Operations

=head1 SYNOPSIS

    use WWW::eNom;

    my $eNom = WWW::eNom->new( ... );

    # Check If Domains Are Available
    my $domain_availabilities = $eNom->check_domain_availability(
        slds => [qw( cpan drzigman brainstormincubator )],
        tlds => [qw( com net org )],
        suggestions => 0,
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if( $domain_availability->is_available ) {
            print 'Domain ' . $domain_availability->name . " is available!\n";
        }
        else {
            print 'Domain ' . $domain_availability->name . " is not available.\n";
        }
    }

    # Get Domain Suggestions
    my $domain_availabilities = $eNom->suggest_domain_names(
        phrase      => 'fast race cars',
        tlds        => [qw( com net tv cc )],
        related     => 1,  # Optional, Defaults to 0
        num_results => 10, # Optional, Defaults to 10
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if( $domain_availability->is_available ) {
            print 'Domain ' . $domain_availability->name . " is available!\n";
        }
        else {
            print 'Domain ' . $domain_availability->name . " is not available.\n";
        }
    }

=head1 REQUIRES

submit

=head1 DESCRIPTION

Implements domain availability related operations with the L<eNom's|http://www.enom.com/APICommandCatalog/> API.

=head1 METHODS

=head2 check_domain_availability

    use WWW::eNom;

    my $eNom = WWW::eNom->new( ... );

    # Check If Domains Are Available
    my $domain_availabilities = $eNom->check_domain_availability(
        slds => [qw( cpan drzigman brainstormincubator )],
        tlds => [qw( com net org )],
        suggestions => 0,
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if( $domain_availability->is_available ) {
            print 'Domain ' . $domain_availability->name . " is available!\n";
        }
        else {
            print 'Domain ' . $domain_availability->name . " is not available.\n";
        }
    }

Abstraction of the L<Check|http://www.enom.com/APICommandCatalog/API%20topics/api_Check.htm?Highlight=Check> eNom API Call.  Given an ArrayRef of slds and tlds returns an ArrayRef of L<WWW::eNom::DomainAvailability> objects.  Optionally takes suggestions params (defaults to false), if specified then additional domain suggestions will be returned using the slds (one at a time) as the search phrase.

B<NOTE> There is a hard limit of 30 "checks" for a given combination of SLDs and TLDs (excluding suggestions), if the cartesian product of the SLDs and TLDs provided is greater than 30 this method will croak with the error 'The combination of slds and tlds you provided would require more than 30 checks.  Please reduce your search.'

=head2 suggest_domain_names

    use WWW::eNom;

    my $eNom = WWW::eNom->new( ... );

    my $domain_availabilities = $eNom->suggest_domain_names(
        phrase      => 'fast race cars',
        tlds        => [qw( com net tv cc )],
        related     => 1,  # Optional, Defaults to 0
        num_results => 10, # Optional, Defaults to 10
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if( $domain_availability->is_available ) {
            print 'Domain ' . $domain_availability->name . " is available!\n";
        }
        else {
            print 'Domain ' . $domain_availability->name . " is not available.\n";
        }
    }

Abstraction of the L<NameSpinner|http://www.enom.com/APICommandCatalog/API%20topics/api_NameSpinner.htm> eNom API Call.

Accepts the following arguments:

=over 4

=item B<phrase>

A search phrase to be used for domain suggestions

=item B<tlds>

ArrayRef of Public Suffixes to return domains for.

B<NOTE> eNom will only generated suggestions for com, net, tv, cc.  No matter what TLDs are provided, only suggestions for these will provided.  If you do not include one of these TLDs, you will get no domain suggestion results.

=item related

Default false, if true will include related domains based on related keyboard (if you specify 'fast' you may get results with 'quick', 'instant' and 'hurry').

=item num_results

Default 10, number of results to return per provided (and supported) TLD.

=back

Return an ArrayRef of L<WWW::eNom::DomainAvailability> objects.

=cut
