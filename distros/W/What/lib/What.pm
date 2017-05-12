#$ Id: $;
package What;
use strict;
use vars qw($VERSION);
use lib qw(lib);
use What::MTA;

$VERSION = "1.00";

=head1 NAME

What - Find out about running services

=head1 SYNOPSIS

  $what = What->new( 
             Host => my.domain.org, 
             Port => 28, 
          );  

  $what->mta;
  $what->mta_version;
  $what->mta_banner;

  
=head1 DESCRIPTION

The What class is interface to classes providing information about
running services. What::MTA is the only implementation so far.

=head1 What::MTA

MTA's supported are: B<Exim>, B<Postfix> (version only on localhost),
B<Sendmail>, B<Courier> (name only), B<XMail>, B<MasqMail>. 

See L<What::MTA> for details.

=head2 METHODS

=over 4

=item new 

  $obj = What->new( Host => "10.10.10.1", Port => 25 )

=item mta() 

Returns the name of the MTA running.

=item mta_banner()

Returns the banner message.

=item mta_version()

Returns the MTA version.

=back

=cut

sub new {
    my $self = shift;
    my $type = ref($self) || $self;
    if (defined(@_)) {
	my $arg  = 
	    defined $_[0] && UNIVERSAL::isa($_[0], 'HASH') 
	    ? shift 
	    : { @_ };
	return bless { arg => $arg }, $type;
    } else {
	return bless {}, $type;
    }
}

sub mta {
    my $self = shift;
    
    $self->{what} = What::MTA->new( %{$self->{arg}} );
    return $self->{what}->mta;
};

sub mta_version {
    my $self = shift;
    $self->{what} = What::MTA->new( %{$self->{arg}} )
	unless ref($self->{what});
    return $self->{what}->mta_version;
};

sub mta_banner {
    my $self = shift;
    $self->{what} = What::MTA->new( %{$self->{arg}} )
	unless ref($self->{what});
    return $self->{what}->mta_banner;
};

1;

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut
