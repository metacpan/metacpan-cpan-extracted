package VM::EC2::KeyPair;

=head1 NAME

VM::EC2::KeyPair - Object describing an Amazon EC2 ssh key pair

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  @pairs   = $ec2->describe_key_pairs();

  foreach (@pairs) {
      $fingerprint = $_->keyFingerprint;
      $name        = $_->keyName;
  }

  $newkey = $ec2->create_key_pair("fred's key");
  print $newkey->privateKey;

=head1 DESCRIPTION

This object represents an Amazon EC2 ssh key pair, and is returned
by VM::EC2->describe_key_pairs().

=head1 METHODS

These object methods are supported:

 keyName         -- Name of the key, e.g. "fred-default"
 name            -- Shorter version of keyName()

 keyFingerprint  -- Key's fingerprint
 fingerprint     -- Shorter version of keyFingerprint()

 keyMaterial     -- PEM encoded RSA private key (only available when
                    creating a new key)
 privateKey      -- More intuitive version of keyMaterial()

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
keyName.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub primary_id {shift->keyName}

sub valid_fields {
    my $self = shift;
    return qw(requestId keyName keyFingerprint keyMaterial);
}

sub name        { shift->keyName        }
sub fingerprint { shift->keyFingerprint }
sub privateKey  { shift->keyMaterial    }

1;
