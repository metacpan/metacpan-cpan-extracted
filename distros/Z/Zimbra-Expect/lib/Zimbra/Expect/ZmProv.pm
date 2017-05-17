package Zimbra::Expect::ZmProv;
use strict;
use warnings;
use base 'Zimbra::Expect';

sub new {
    my $class = shift;
    my $opt = { @_ };
    return $class->SUPER::new(cmd=>['zmprov','-l'],prompt=>'prov',verbose=>$opt->{verbose},noaction=>$opt->{noaction},debug => $opt->{debug});
}

1;

__END__

=head1 NAME

Zimbra::Expect::ZmProv - Interact with zmprov

=head1 SYNOPSIS

 use Zimbra::Expect::ZmProv;
 my $cmd = Zimbra::Expect::ZmProv->new(verbose=>1,nocation=>1);
 my $accounts = $cmd->cmd('gaa');
 
=head1 DESCRIPTION

See L<Zimbra::Expect> for description.

=head1 COPYRIGHT

Copyright (c) 2017 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2017-05-16 to Initial Version

=cut
