use strict;
use warnings;

package WebService::TVDB::Servertime;
{
  $WebService::TVDB::Servertime::VERSION = '1.133200';
}

# ABSTRACT: Gets and saves the TVDB servertime

use XML::Simple qw(:strict);
use LWP::Simple;

use constant SERVERTIME_URL => 'http://thetvdb.com/api/Updates.php?type=none';

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    bless( $self, $class );
    return $self;
}

sub fetch_servertime {
    my ($self) = @_;

    my $xml = LWP::Simple::get(SERVERTIME_URL);
    $self->{parsed_xml} =
      XML::Simple::XMLin( $xml, ForceArray => 0, KeyAttr => [] );
}

sub get_servertime {
    my ($self) = @_;

    if ( defined $self->{parsed_xml} ) {
        return $self->{parsed_xml}->{Time};
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Servertime - Gets and saves the TVDB servertime

=head1 VERSION

version 1.133200

=head1 SYNOPSIS

  my $servertime = WebService::TVDB::Servertime->new();
  $servertime->fetch_servertime();
  my $previous_time = $servertime->get_servertime();

=head1 DESCRIPTION

This is not used by default, but would be handy if you are keeping a cache and want to know when to update it.

=head1 METHODS

=head2 new()

Create new object. Takes no arguments.

=head2 fetch_servertime()

Fetches the servertime from thetvdb.com.

=head2 get_servertime()

Gets the servertime. You will need to have called fetch_servertime() before.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
