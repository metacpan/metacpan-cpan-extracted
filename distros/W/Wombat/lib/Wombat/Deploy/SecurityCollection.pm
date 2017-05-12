# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Deploy::SecurityCollection;

=pod

=head1 NAME

Wombat::Deploy::SecurityCollection - web-resource-collection
deployment descriptor element class

=head1 SYNOPSIS

=head1 DESCRIPTION

Representation of a web resource collection for a web application's
security constraint, as specified in a I<web-resource-collection>
element in the deployment descriptor.

=cut

use fields qw(description methods name patterns);
use strict;
use warnings;

use URI::Escape ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Deploy::SecurityConstraint> instance,
initializing fields appropriately.

B<Parameters:>

=over

=item $name

the name of this SecurityCollection (optional)

=item $description

a description of this SecurityCollection (optional)

=back

=back

=cut

sub new {
    my $self = shift;
    my $name = shift;
    my $description = shift;

    $self = fields::new($self) unless ref $self;

    $self->{description} = $description;
    $self->{methods} = {};
    $self->{name} = $name;
    $self->{patterns} = {};

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getDescription()

Return the description of this web resource collection.

=cut

sub getDescription {
    my $self = shift;

    return $self->{description};
}

=pod

=item setDescription($description)

Set the description of this web resource collection.

B<Parameters:>

=over

=item $description

the description to set

=back

=cut

sub setDescription {
    my $self = shift;
    my $description = shift;

    $self->{description} = $description;

    return 1;
}

=pod

=item getName()

Get the name of this web resource collection.

=cut

sub getName {
    my $self = shift;

    return $self->{name};
}

=item setName($name)

Set the name of this web resource collection.

B<Parameters:>

=over

=item $name

the name to set

=back

=cut

sub setName {
    my $self = shift;
    my $name = shift;

    $self->{name} = $name;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item addMethod($method)

Add an HTTP request method to be part of this web resource collection.

B<Parameters:>

=over

=item $method

the method to add

=back

=cut

sub addMethod {
    my $self = shift;
    my $method = shift;

    return 1 unless $method;

    $self->{methods}->{$method} = 1;

    return 1;
}

=pod

=item hasMethod($method)

Return true if the specified HTTP request methodd is part of this web
resource collection.

B<Parameters:>

=over

=item $method

the method to be checked

=back

=cut

sub hasMethod {
    my $self = shift;
    my $method = shift;

    return $self->{methods}->{$method};
}

=pod

=item getMethods()

Return an array containing the names of the HTTP methods that are part
of this web resource collection.

=cut

sub getMethods {
    my $self = shift;

    my @methods = keys %{ $self->{methods} };

    return wantarray ? @methods : \@methods;
}

=pod

=item removeMethod($method)

Remove the specified HTTP request method from those that are part of
this web resource collection.

B<Parameters:>

=over

=item $method

the name of the method to be removed

=back

=cut

sub removeMethod {
    my $self = shift;
    my $method = shift;

    delete $self->{methods}->{$method};

    return 1;
}

=pod

=item addPattern($pattern)

Add a URL pattern to be part of this web resource collection.

B<Parameters:>

=over

=item $pattern

the pattern to be added

=back

=cut

sub addPattern {
    my $self = shift;
    my $pattern = shift;

    return 1 unless $pattern;

    $pattern = URI::Escape::uri_unescape($pattern);
    $self->{patterns}->{$pattern} = 1;

    return 1;
}

=pod

=item hasPattern($pattern)

Return true if the specified pattern is aprt of this web resource
collection.

B<Parameters:>

=over

=item $pattern

the pattern to be checked

=back

=cut

sub hasPattern {
    my $self = shift;
    my $pattern = shift;

    return $self->{patterns}->{$pattern};
}

=pod

=item getPatterns()

Return an array containing the URL patterns that are part of this web
resource collection.

=cut

sub getPatterns {
    my $self = shift;

    my @patterns = keys %{ $self->{patterns} };

    return wantarray ? @patterns : \@patterns;
}

=pod

=item removePattern($pattern)

Remove the specified URL pattern from those that are part of this web
resource collection.

B<Parameters:>

=over

=item $pattern

the pattern to be removed

=back

=cut

sub removePattern {
    my $self = shift;
    my $pattern = shift;

    return 1 unless $pattern;

    delete $self->{patterns}->{$pattern};

    return 1;
}

1;
__END__

=pod

=back

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut


