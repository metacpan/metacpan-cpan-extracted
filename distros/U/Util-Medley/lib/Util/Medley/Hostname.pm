package Util::Medley::Hostname;
$Util::Medley::Hostname::VERSION = '0.041';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

=head1 NAME

Util::Medley::Hostname - Utilities for dealing with hostnames.

=head1 VERSION

version 0.041

=cut

########################################################

=head1 SYNOPSIS

  $util = Util::Medley::Host->new;
  
  $bool = $util->isFqdn('foobar.example.com');
  ($hostname, $domain) = $util->parseHostname('foobar.example.com');
  $shortHostname = $util->stripDomain('foobar.example.com');
    
=cut

########################################################

=head1 DESCRIPTION

Utility module for slicing and dicing hostnames.

All methods confess on error.

=cut

########################################################

=head1 METHODS

=head2 isFqdn

Checks if a given hostname is fully qualified.

=over

=item usage:

  $bool = $util->isFqdn('foobar.example.com');
  
  $bool = $util->isFqdn(hostname => 'foobar.example.com');
  
=item args:

=over

=item hostname [Str]

Hostname to be checked.

=back

=back

=cut

multi method isFqdn (Str :$hostname!) {

    my ($h, $d) = $self->parseHostname(hostname => $hostname);
    if ($h and $d) {
        return 1;   
    } 
    
    return 0;
}

multi method isFqdn (Str $hostname) {

    return $self->isFqdn(hostname => $hostname); 
}

=head2 parseHostname

Parses the specified hostname into hostname and domain (if exists).

=over

=item usage:

  ($hostname, $domain) = 
      $util->parseHostname('foobar.example.com');
  
  ($hostname, $domain) = 
      $util->parseHostname(hostname => 'foobar.example.com');
  
=item args:

=over

=item hostname [Str]

Hostname you wish to parse.

=back

=back

=cut

multi method parseHostname (Str :$hostname!) {

    my @a = split(/\./, $hostname);
    if (@a) {
        my $host = shift @a;
        my $domain = join '.', @a;
     
        return ($host, $domain); 	
    }
    
    return $hostname;
}

multi method parseHostname (Str $hostname) {

    return $self->parseHostname(hostname => $hostname);	
}


=head2 stripDomain

Returns short-hostname for the provided hostname.

=over

=item usage:

  $hostname = $util->stripDomain('foobar.example.com');
  
  $hostname = $util->stripDomain(hostname => 'foobar.example.com');
  
=item args:

=over

=item hostname [Str]

Hostname to be stripped.

=back

=back

=cut

multi method stripDomain (Str :$hostname!) {

    my ($h, $d) = $self->parseHostname(hostname => $hostname);
    return $h;
}

multi method stripDomain (Str $hostname) {

    return $self->stripDomain(hostname => $hostname); 
}

1;
