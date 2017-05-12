package XPlanner;

use strict;
use base qw(XPlanner::Object);
our $VERSION = 0.01;


use SOAP::Lite;
use YAML;
use URI;


=head1 NAME

XPlanner - an interface to XPlanner (www.xplanner.org)


=head1 SYNOPSIS

  use XPlanner;

  my $xp = XPlanner->login($url, $user, $pass);

  my $people   = $xp->people;
  my $projects = $xp->projects;


=head1 DESCRIPTION

This is an interface to XPlanner, an XP project management tool.

=cut

sub _init {
    my $class = shift;
    bless {}, $class;
}


sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;
    my($method) = $AUTOLOAD =~ /::([^:]+)$/;

    return $self->{_proxy}->$method(@_);
}


sub login {
    my($class, $url, $user, $pass) = @_;

    $url = URI->new($url);
    $url->userinfo("$user:$pass");

    my $self = $class->_init;

    my $proxy = SOAP::Lite->proxy($url);
    $self->{_proxy} = $proxy;

    # Register deserializers for XPlanner types
    foreach (qw(ProjectData IterationData UserStoryData TaskData 
                TimeEntryData NoteData PersonData)) 
    {    
        $proxy->maptype->{$_} = 'http://xplanner.org/soap';
    }

    # Register an automatic serializer for DateTime types
    $proxy->typelookup->{dateTime} =
                     [11,
                      sub { $_[0] =~ 
                              m/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/ 
                          },    
                      sub {
                          my($val, $name, $type, $attr) = @_;
                          return [$name, 
                                  {'xsi:type' => 'xsd:dateTime', %$attr},
                                  $val];
                      }
                     ];

    $proxy->xmlschema('http://www.w3.org/2001/XMLSchema');

    return $self;
}


sub people {
    my $self = shift;

    return $self->_map_from_soap('userId', 'getPeople', 'XPlanner::Person');
}


sub projects {
    my $self = shift;

    return $self->_map_from_soap('name', 'getProjects', 'XPlanner::Project');
}


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 COPYRIGHT

Copyright 2004 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 HISTORY

Authored for Grant Street Group (grantstreet.com)

Based on the XPlanner Perl SOAP examples available here
http://cvs.sourceforge.net/viewcvs.py/xplanner/xplanner/doc/soap-examples/perl/xplanner.pl?view=markup

=cut

1;
