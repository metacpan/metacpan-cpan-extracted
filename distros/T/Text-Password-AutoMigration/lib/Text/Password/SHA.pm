package Text::Password::SHA;
our $VERSION = "0.16";

use Moose;
extends 'Text::Password::MD5';

__PACKAGE__->meta->make_immutable;
no Moose;

use Carp;
use Digest::SHA qw(sha1_hex);
use Crypt::Passwd::XS;

=encoding utf-8

=head1 NAME

Text::Password::SHA - generate and verify Password with SHA

=head1 SYNOPSIS

 my $pwd = Text::Password::SHA->new();
 my( $raw, $hash ) = $pwd->genarate();          # list context is required
 my $input = $req->body_parameters->{passwd};
 my $data = $pwd->encrypt($input);              # salt is made automatically
 my $flag = $pwd->verify( $input, $data );

=head1 DESCRIPTION

Text::Password::SHA is the part of Text::Password::AutoMigration.

=head2 Constructor and initialization

=head3 new()

No arguments are required. But you can set some parameters.

=over

=item default

You can set default length with param 'default' like below:

 $pwd = Text::Pasword::AutoMiglation->new( default => 12 );

=item readablity

Or you can set default strength for password with param 'readablity'.

It must be a boolean, default is 1.

If it was set as 0, you can generate stronger passwords with generate().

$pwd = Text::Pasword::AutoMiglation->new( readability => 0 );
 
=back

=head2 Methods and Subroutines

=head3 verify( $raw, $hash )

returns true if the verification succeeds.

=cut

sub verify {
    my $self = shift;
    my ( $input, $data ) = @_;

    carp "Empty data strings" unless length $data;

     return $data eq Crypt::Passwd::XS::unix_sha512_crypt( $input, $data )
    if $data =~ /^\$6\$[!-~]{1,8}\$[!-~]{86}$/;
     return $data eq Crypt::Passwd::XS::unix_sha256_crypt( $input, $data )
    if $data =~ /^\$5\$([!-~]{1,8})\$[!-~]{43}$/;
    return $data eq sha1_hex($input) if $data =~ /^[0-9a-f]{40}$/i;
    return 0;
}

=head3 nonce($length)

generates the random strings with enough strength.

the length defaults to 8($self->default).

=head3 encrypt($raw)

returns hash with unix_sha512_crypt().

salt will be made automatically.
 
=cut

sub encrypt {
    my $self = shift;
    my $input = shift;
    my $min = $self->minimum();
    croak ref($self) ." requires at least $min length" if length $input < $min;
    croak ref($self). " doesn't allow any Wide Characters or white spaces\n" if $input =~ /[^ -~]/;

    return Crypt::Passwd::XS::unix_sha512_crypt( $input, $self->_salt() );
}

1;

__END__

=head3 generate($length)

genarates pair of new password and it's hash.

less readable characters(0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`) are forbidden
unless $self->readability is 0.

the length defaults to 8($self->default).
 
=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(worthmine) E<lt>worthmine!at!gmail.comE<gt>
