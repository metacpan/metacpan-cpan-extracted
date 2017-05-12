package WWW::BackpackTF::User;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002001';

sub new{
	my ($class, $content) = @_;
	bless $content, $class
}

sub steamid          { shift->{steamid} }
sub name             { shift->{name} }
sub reputation       { shift->{backpack_tf_reputation} }
sub group            { shift->{backpack_tf_group} }
sub positive         { shift->{backpack_tf_trust}->{for} // 0 }
sub negative         { shift->{backpack_tf_trust}->{against} // 0 }
sub scammer          { shift->{steamrep_scammer} }
sub banned_backpack  { shift->{backpack_tf_banned} }
sub banned_economy   { shift->{ban_economy} }
sub banned_community { shift->{ban_community} }
sub banned_vac       { shift->{ban_vac} }
sub notifications    { shift->{notifications} // 0 }
sub value            { shift->{backpack_value}->{shift // WWW::BackpackTF::TF2} }
sub update           { shift->{backpack_update}->{shift // WWW::BackpackTF::TF2} }

sub banned {
	my ($self) = @_;
	$self->banned_backpack || $self->banned_community || $self->banned_economy || $self->banned_vac
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF::User - Class representing user profile information

=head1 SYNOPSIS

  my $user = $bp->get_users($user_id);
  say 'Steam ID: ',                             $user->steamid;
  say 'Name: ',                                 $user->name;
  say 'Reputation: ',                           $user->reputation;
  say 'Part of backpack.tf Steam Group: ',     ($user->group ? 'YES' : 'NO');
  say 'Positive trust ratings: ',               $user->positive;
  say 'Negative trust ratings: ',               $user->negative;
  say 'Scammer (according to steamrep.com): ', ($user->scammer ? 'YES' : 'NO');
  say 'Banned from backpack.tf: ',             ($user->banned_backpack ? 'YES' : 'NO');
  say 'Economy banned: ',                      ($user->banned_economy ? 'YES' : 'NO');
  say 'Community banned: ',                    ($user->banned_community ? 'YES' : 'NO');
  say 'VAC banned: ',                          ($user->banned_vac ? 'YES' : 'NO');
  say 'Banned on any of the previous: ',       ($user->banned ? 'YES' : 'NO');
  say 'Unread notifications: ',                 $user->notifications;
  say 'Value of TF2 backpack: ',                $user->value(WWW::BackpackTF::TF2);
  say 'Value of Dota 2 backpack: ',             $user->value(WWW::BackpackTF::DOTA2);
  say 'Last TF2 backpack update: ',             $user->update(WWW::BackpackTF::TF2);
  say 'Last Dota 2 backpack update: ',          $user->update(WWW::BackpackTF::DOTA2);


=head1 DESCRIPTION

WWW::BackpackTF::User is a class representing user profile information.

=head2 METHODS

=over

=item B<steamid>

Returns this user's Steam ID.

=item B<name>

Returns this user's persona name.

=item B<reputation>

Returns this user's backpack.tf reputation.

=item B<group>

Returns true if this user is part of the backpack.tf Steam group.

=item B<positive>

Returns the number of positive trust ratings this user has.

=item B<negative>

Returns the number of negative trust ratings this user has.

=item B<scammer>

Returns true if this user is a scammer according to L<http://steamrep.com/>

=item B<banned_backpack>

Returns true if this user is banned from backpack.tf.

=item B<banned_economy>

Returns true if this user is economy banned.

=item B<banned_community>

Returns true if this user is community banned.

=item B<banned_vac>

Returns true if this user is banned by Valve Anti-Cheat.

=item B<banned>

Returns true if any of the B<banned_*> methods returns true.

=item B<notifications>

Returns the number of unread notifications this user has.

=item B<value>([I<game>])

Returns the total value of this user's backpack for the specified game, in the lowest currency. I<game> defaults to C<WWW::BackpackTF::TF2>.

=item B<update>([I<game>])

Returns the UNIX timestamp of this user's last backpack update for the specified game. I<game> defaults to C<WWW::BackpackTF::TF2>

=back

=head1 SEE ALSO

L<http://backpack.tf/api/users>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
