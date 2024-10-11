package Text::Password::SHA;
our $VERSION = "0.31";

use Moo;
use strictures 2;
use Crypt::Passwd::XS;

use autouse 'Carp'        => qw(croak carp);
use autouse 'Digest::SHA' => qw(sha1_hex);

use Types::Standard qw(Int);
use constant Min => 4;

extends 'Text::Password::MD5';
has default => ( is => 'rw', isa => Int->where('$_ >= 10'), default => sub {10} );

=encoding utf-8

=head1 NAME

Text::Password::SHA - generate and verify Password with SHA

=head1 SYNOPSIS

 my $pwd = Text::Password::SHA->new();
 my( $raw, $hash ) = $pwd->generate();          # list context is required
 my $input = $req->body_parameters->{passwd};
 my $data = $pwd->encrypt($input);              # you don't have to care about salt
 my $flag = $pwd->verify( $input, $data );

=head1 DESCRIPTION

Text::Password::SHA is the last part of Text::Password::AutoMigration.

=head2 Constructor and initialization

=head3 new()

No arguments are required. But you can set some arguments.

=over

=item default( I<Int> )

You can set other length to 'default' like below:

 $pwd = Text::Password::AutoMiglation->new( default => 8 );

=item readablity( I<Bool> )

It must be a boolean, default is 1.

less readable characters(I<0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`>) are forbidden
while $self->readability is 1.

You can let passwords to be more secure with setting I<readablity =E<lt> 0>.

Then you can generate stronger passwords with I<generate()>.

$pwd = Text::Password::AutoMiglation->new( readability => 0 );

# or $pwd->readability(0);


=back

=head2 Methods and Subroutines

=head3 verify( $raw, $hash )

returns true if the verification succeeds.

=cut

sub verify {
    my ( $self, $input, $data ) = ( shift, @_ );
    my $m = $self->default();
    carp 'Invalid input' unless length $input;
    carp 'Invalid hash'  unless length $data;

    return $data eq Crypt::Passwd::XS::unix_sha512_crypt( $input, $data )
        if $data =~ m|^\$6\$[!-~]{1,$m}\$[\w/\.]{86}$|;
    return $data eq Crypt::Passwd::XS::unix_sha256_crypt( $input, $data )
        if $data =~ m|^\$5\$[!-~]{1,$m}\$[\w/\.]{43}$|;
    return $data eq sha1_hex($input) if $data =~ /^[\da-f]{40}$/i;
    carp __PACKAGE__, " doesn't support this hash: ", $data;
    return;
}

=head3 nonce( I<Int> )

generates the random strings with enough strength.

the length defaults to 10 || $self->default().

=head3 encrypt( I<Str> )

returns hash with unix_sha512_crypt().

salt will be made automatically.

=cut

sub encrypt {
    my ( $self, $input ) = @_;
    croak ref $self, " requires a strings longer than at least ", Min if length $input < Min;
    croak ref $self, " doesn't allow any Wide Characters or control codes" if $input =~ /[^ -~]/;
    return Crypt::Passwd::XS::unix_sha512_crypt( $input, $self->nonce() );
}

=head3 generate( I<Int> )

generates pair of new password and its hash.

less readable characters(I<0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`>) are forbidden
unless $self->readability is 0.

the length defaults to 10 || $self->default().

=cut

1;

__END__

=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@users.noreply.github.comE<gt>
