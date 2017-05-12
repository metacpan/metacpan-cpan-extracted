package WWW::SourceForge::Project;
use strict;
use WWW::SourceForge;
use WWW::SourceForge::User;
use LWP::Simple;
use Data::Dumper;

our $VERSION = '0.40';
our $DEFAULT_ICON = 'http://a.fsdn.com/con/img/project_default.png';

=head2 new

 Usage: 
 
    my $proj = new WWW::SourceForge::Project( id => 1234 );
    my $proj2 = new WWW::SourceForge::Project( name => 'flightics' );

    my @admins = $proj->admins(); # WWW::SourceForge::User objects
    my @developers = $proj->developers(); # Ditto

 Returns: WWW::SourceForge::Project object;

=cut

sub new {

    my ( $class, %parameters ) = @_;
    my $self = bless( {}, ref($class) || $class );

    my $api = new WWW::SourceForge;
    $self->{api} = $api;

    my $json;
    if ( $parameters{id} ) {
        $json = $api->call(
            method => 'project',
            id     => $parameters{id}
        );
    } elsif ( $parameters{name} ) {
        $json = $api->call(
            method   => 'project',
            name => $parameters{name}
        );
    } else {
        warn('You must provide an id or name. Bad monkey.');
        return 0;
    }

    $self->{data} = $json->{Project};
    return $self;
}

=head2 admins

  @admins = $project->admins();

Returns a list of WWW::SourceForge::User objects which are the admins on this
project.

=cut

sub admins { 
    my $self = shift;
    return @{ $self->{data}->{_admins} } if ref( $self->{data}->{_admins} );

    my @admins;

    my $a_ref = $self->{data}->{maintainers};
    foreach my $u_ref ( @$a_ref ) {
        my $user = new WWW::SourceForge::User( username => $u_ref->{name} );
        push @admins, $user;
    }

    $self->{data}->{_admins} = \@admins;
    return @admins;
}

=head2 developers

  @devs = $project->devs();

Returns a list of WWW::SourceForge::User objects which are the developers on
the project. This does not include the admins.

=cut

sub developers { # not admins
    my $self = shift;
    return @{ $self->{data}->{_developers} } if ref( $self->{data}->{_developers} );

    my @devs;

    my $a_ref = $self->{data}->{developers};
    foreach my $u_ref ( @$a_ref ) {
        my $user = new WWW::SourceForge::User( username => $u_ref->{name} );
        push @devs, $user;
    }

    $self->{data}->{_developers} = \@devs;
    return @devs;
}

=head2 users

All project users - admins and non-admins.

=cut

sub users {
    my $self = shift;

    my @users = ( $self->admins(), $self->developers() );
    return @users;
}

=head2 files

List of recent released files

=cut

sub files {
    my $self = shift;

    return @{ $self->{data}->{files} } if $self->{data}->{files};
    my %args = @_;
    
    my $api = new WWW::SourceForge;
    # http://sourceforge.net/api/file/index/project-id/14603/crtime/desc/rss

    # Passing a full uri feels evil, but it's necessary because the file
    # api cares about argument order.
    my $files = $self->{api}->call(
        uri    => '/file/index/project-id/' . $self->id() . '/crtime/desc/rss',
        format => 'rss',
    );

    my @files;
    foreach my $f ( @{ $files->{entries} } ) {
        push @files, $f->{entry};
    }
    $self->{data}->{files} = \@files;
    return @files;
}

=head2 latest_release 

Date of the latest released file. It's a string. The format is pretty
much guaranteed to change in the future. For example, it'll probably be
a DateTime object.

=cut

sub latest_release {
    my $self = shift;
    my @files = $self->files();
    return $files[0]->{pubDate}; # TODO This is an object, and
                                 # presumably I should be calling
                                 # object methods.
}

=head2 downloads

Download counts for the specified date range. If no date range is
supplied, assume the 7 days leading up to today.

WARNING: This API is subject to change any moment. The downloads API
gives us a LOT more information than just a count, and it may be that we
want to expose all of it later one. Right now I just want a count.

    my $dl_count = $project->downloads( 
        start_date => '2012-07-01',
        end_date -> '2012-07-25' 
    );

=cut

# https://sourceforge.net/projects/xbmc/files/stats/json?start_date=2010-05-01&end_date=2010-05-11
sub downloads {
    my $self = shift;
    my %args = @_;

    my $data_api = $self->{data_api} || WWW::SourceForge->new( api => 'download' );
    $self->{data_api} = $data_api;

    my $json = $data_api->call( %args, project => $self->shortdesc() );

    return $json->{summaries}->{time}->{downloads};
}

=head2 logo

For Allura projects, the logo is at https://sourceforge.net/p/PROJECT/icon
For Classic projects, who the heck knows?

WARNING WARNING WARNING
This method will break the next time SF redesigns the project summary
page. On the other hand, by then all projects will be Allura projects,
and the else clause will never execute.
WARNING WARNING WARNING

=cut

sub logo {
    my $self = shift;
    my %args = @_;

    if ( $self->type == 10 ) {
        my $icon = 'http://sourceforge.net/p/' . $self->shortdesc() . '/icon';

        # Need to verify that it's actually there
        my $verify = get( $icon );
        return $verify
            ? $icon
            : $DEFAULT_ICON;
    } else {

        # Screen scrape to get the icon
        # my $psp_content = get( $self->psp() );
        my $psp_content = $self->_psp_content();

        my $m = $1 if $psp_content =~ m/img itemscope.*? Icon" src="(.*?)"/s;
        my $icon =
          $m
          ? 'http:' . $m
          : $DEFAULT_ICON;
        return $icon;
    }
}

# Fetch and cache PSP contents
sub _psp_content {
    my $self = shift;
    unless ( $self->{psp_content} ) {
        $self->{psp_content} = get( $self->psp() ) || '';
    }
    return $self->{psp_content};
}

# Alias
sub icon {
    my $self = shift;
    return $self->logo( @_ );
}

=head2 summary

Returns summary statement of project, if any.

WARNING WARNING WARNING
This method relies on particular HTML IDs, and so will break the next
time the site is redesigned. Hopefully by then this will be directly
available in the API.
WARNING WARNING WARNING

=cut

sub summary {
    my $self = shift;
    my $psp_content = $self->_psp_content();

    my $summary = $1 if $psp_content =~ m!id="summary">(.*?)</p>!s;
    $summary =~ s/^\s+//; $summary =~ s/\s+$//;
    return $summary;
}

# Project Summary Page URL
sub psp {
    my $self = shift;
    return 'http://sourceforge.net/projects/'.$self->shortdesc();
}

# Alias to shortdesc
sub unix_name {
    my $self = shift;
    return $self->shortdesc();
}

=head2 activity

Contents of the project activity RSS feed. It's an array, and each item
looks like 

  {
    'pubDate' => 'Tue, 12 Jun 2012 19:33:05 +0000',
    'title'   => 'sf-robot changed the public information on the Flight ICS project',
    'link'    => 'http://sourceforge.net/projects/flightics',
    'description' => 'sf-robot changed the public information on the Flight ICS project'
  }

=cut

sub activity {
    my $self = shift;

    # Cached
    return @{ $self->{data}->{activity} } if $self->{data}->{activity};

    my $rss  = $self->{api}->call(
        method  => 'proj_activity',
        project => $self,
    );
    
    my @activity;
    foreach my $e ( @{ $rss->{entries} } ) {
        push @activity, $e->{entry};
    }
    $self->{data}->{activity} = \@activity;
    return @activity;
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

WWW::SourceForge::Project - SourceForge project objects

=head1 SYNOPSIS

Uses the SourceForge API to load project details. This is a work in
progress, and the interface will change. Mostly I'm just poking about to
see what this needs to support. Please feel free to play along.

http://sf.net/projects/sfprojecttools/

=head1 DESCRIPTION

Implements a Perl interface to SourceForge projects. See http://sourceforge.net/p/forge/documentation/API/

=head1 USAGE

  use WWW::SourceForge::Project;
  my $project = WWW::SourceForge::Project->new( name => 'moodle' );
  print $project->id();
  print $project->type();
  print $project->status();
  print $project->latest_release();

See the 'project_details.pl' script in scripts/perl/ for more details.

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
