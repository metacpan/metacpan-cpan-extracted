package WWW::LogicBoxes::Role::Command::Domain::Availability;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( Bool Int Str Strs );

use WWW::LogicBoxes::DomainAvailability;

use Data::Validate::Domain qw( is_domain );

use Carp;

requires 'submit';

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Domain Availability API Calls

sub check_domain_availability {
    my $self   = shift;
    my (%args) = validated_hash(
        \@_,
        slds        => { isa => Strs },
        tlds        => { isa => Strs },
        suggestions => { isa => Bool, default => 0 },
    );

    my $response = $self->submit({
        method => 'domains__available',
        params => {
            'domain-name' => $args{slds},
            'tlds'        => $args{tlds},
        }
    });

    my @domain_availabilities;
    for my $domain_name ( keys %{ $response }) {
        if( is_domain( $domain_name ) ) {
            # Standard Response Record
            push @domain_availabilities, WWW::LogicBoxes::DomainAvailability->new({
                name         => $domain_name,
                is_available => $response->{$domain_name}{status} eq "available" ? 1 : 0,
            });
        }
        else {
            # Suggestion Response Record
            for my $sld ( keys %{ $response->{ $domain_name } } ) {
                for my $tld ( keys %{ $response->{ $domain_name }{ $sld } } ) {
                    push @domain_availabilities, WWW::LogicBoxes::DomainAvailability->new({
                        name         => lc sprintf('%s.%s', $sld, $tld ),
                        is_available => $response->{$domain_name}{$sld}{$tld} eq "available" ? 1 : 0,
                    });
                }
            }
        }
    }

    if( $args{suggestions} ) {
        push @domain_availabilities, $self->suggest_domain_names(
            phrase  => join(' ', @{ $args{slds} } ),
            tlds    => $args{tlds},
            related => 1,
        );
    }

    return \@domain_availabilities;
}

sub suggest_domain_names {
    my $self   = shift;
    my (%args) = validated_hash(
        \@_,
        phrase      => { isa => Str  },
        tlds        => { isa => Strs },
        hyphen      => { isa => Bool, optional => 1 },
        related     => { isa => Bool, default => 0 },
        num_results => { isa => Int,  default => 10 },
    );

    exists $args{hyphen}  and carp 'The hyphen argument is deprecated, please see POD for more information';

    my $response = $self->submit({
        method => 'domains__v5__suggest_names',
        params => {
            keyword       => $args{phrase},
            'tld-only'    => $args{tlds},
            'exact-match' => !$args{related},
        }
    });

    my @domain_availabilities;
    for my $domain_name (keys %{ $response }) {
        push @domain_availabilities, WWW::LogicBoxes::DomainAvailability->new({
            name         => lc $domain_name,
            is_available => $response->{$domain_name}{status} eq "available" ? 1 : 0,
        });
    }

    return [ splice( @domain_availabilities, 0, $args{num_results} * scalar @{ $args{tlds} } ) ];
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Domain::Availability - Domain Availability Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Check If Domains Are Available
    my $domain_availabilities = $logic_boxes->check_domain_availability(
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
    my $domain_availabilities = $logic_boxes->suggest_domain_names(
        phrase      => 'fast race cars',
        tlds        => [qw( com net org )],
        hyphen      => 0,   # DEPRECATED!  Will Generate Warnings (see Method for more information)
        related     => 1,
        num_results => 10,
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

Implements domain availability related operations with the L<LogicBoxes's|http://www.logicboxes.com> API.

=head1 METHODS

=head2 check_domain_availability

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Check If Domains Are Available
    my $domain_availabilities = $logic_boxes->check_domain_availability(
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

Given an ArrayRef of slds and tlds returns an ArrayRef of L<WWW::LogicBoxes::DomainAvailability> objects.  Optionally takes suggestions params (defaults to false), if specified then additional domain suggestions will be returned using a search term of the list of slds concatenated together with spaces.

=head2 suggest_domain_names

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain_availabilities = $logic_boxes->suggest_domain_names(
        phrase      => 'fast race cars',
        tlds        => [qw( com net org )],
        hyphen      => 0,     # DEPRECATED!  Will Generate Warnings.
        related     => 0,
        num_results => 10,
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if( $domain_availability->is_available ) {
            print 'Domain ' . $domain_availability->name . " is available!\n";
        }
        else {
            print 'Domain ' . $domain_availability->name . " is not available.\n";
        }
    }

Accepts the following arguments:

=over 4

=item B<phrase>

A search phrase to be used for domain suggestions

=item B<tlds>

ArrayRef of Public Suffixes to return domains for.

=item hyphen

Default false, if true will include - hacks.

B<NOTE> THIS ATTRIBUTE IS DEPRECATED.  Passing it is still supported (for backwards compaitability) but it has not effect on the results.  Usage will generated the carp'ed warning 'The hyphen argument is deprecated, please see POD for more information''

=item related

Default false, if true will include related domains based on related keyboard (if you specify 'fast' you may get results with 'quick', 'instant' and 'hurry')

=item num_results

Default 10, number of results to return.

=back

Return an ArrayRef of L<WWW::LogicBoxes::DomainAvailability> objects.

=cut
