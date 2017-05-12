package WWW::SourceForge::User;
use strict;
use WWW::SourceForge;
use WWW::SourceForge::Project;

our $VERSION = '0.20';

=head2 new

 Usage: 
 
    my $user = new WWW::SourceForge::User( id => 1234 );
    my $user2 = new WWW::SourceForge::User( username => 'rbowen' );

 Returns: WWW::SourceForge::User object;

=cut

sub new {

    my ( $class, %parameters ) = @_;
    my $self = bless( {}, ref($class) || $class );

    my $api = new WWW::SourceForge;
    my $json;
    if ( $parameters{id} ) {
        $json = $api->call(
            method => 'user',
            id     => $parameters{id}
        );
    } elsif ( $parameters{username} ) {
        $json = $api->call(
            method   => 'user',
            username => $parameters{username}
        );
    } else {
        warn('You must provide an id or username. Bad monkey.');
        return 0;
    }

    $self->{data} = $json->{User};
    return $self;

}

sub email { return shift->sf_email(); }

=head2 projects

Returns an array of Project objects

=cut

sub projects {
    my $self = shift;

    return @{ $self->{data}->{_projects} } if $self->{data}->{_projects};
    my $p_ref = $self->{data}->{projects};
    my @projects;

    foreach my $p ( @$p_ref ) {
        my $proj = new WWW::SourceForge::Project( id => $p->{id} );
        push (@projects, $proj );
    }

    $self->{data}->{_projects} = \@projects;
    return @projects;
}

=head2 Data access AUTOLOADER

Handles most of the data access for the Project object. Some parts of
the data require special treatment.

=cut

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $sub = $AUTOLOAD;
    $sub =~ s/^.*:://;
    ( my $method = $sub ) =~ s/.*:://;
    return $self->{data}->{$sub};
}

=head1 NAME

WWW::SourceForge::User - SourceForge user objects

=head1 SYNOPSIS

Uses the SourceForge API to load user details. This is a work in
progress, and the interface will change. Mostly I'm just poking about to
see what this needs to support. Please feel free to play along.

http://sf.net/projects/sfprojecttools/

=head1 DESCRIPTION

Implements a Perl interface to SourceForge users. See http://sourceforge.net/p/forge/documentation/API/

=head1 USAGE

  use WWW::SourceForge::User;
  my $user = WWW::SourceForge::User->new( username => 'rbowen' );
  print $user->timezone;
  print Dumper( $user->projects );

=head1 BUGS

None

=head1 SUPPORT

http://sourceforge.net/p/sfprojecttools/tickets/

=head1 AUTHOR

    Rich Bowen
    CPAN ID: RBOW
    SourceForge
    rbowen@sourceforge.net
    http://sf.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

