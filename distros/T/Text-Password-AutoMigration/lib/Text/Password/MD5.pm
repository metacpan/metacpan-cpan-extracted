package Text::Password::MD5;
our $VERSION = "0.18";

use Moo;
use strictures 2;
extends 'Text::Password::CoreCrypt';
use constant Min => 4;

use autouse 'Carp'             => qw(croak carp);
use autouse 'Crypt::PasswdMD5' => qw(unix_md5_crypt);

=encoding utf-8

=head1 NAME

Text::Password::MD5 - generate and verify Password with unix_md5_crypt()

=head1 SYNOPSIS

 my $pwd = Text::Password::MD5->new();
 my( $raw, $hash ) = $pwd->generate();          # list context is required
 my $input = $req->body_parameters->{passwd};
my $data = $pwd->encrypt($input);    # you don't have to care about salt

 my $flag = $pwd->verify( $input, $data );

=head1 DESCRIPTION

Text::Password::MD5 is the part of Text::Password::AutoMigration.

B<DON'T USE> directly.

=head2 Constructor and initialization

=head3 new()

No arguments are required. But you can set some parameters.

=over

=item default

You can set default length with param 'default' like below:

$pwd = Text::Password::AutoMiglation->new( default => 12 );


=item readablity

Or you can set default strength for password with param 'readablity'.

It must be a boolean, default is 1.

If it was set as 0, you can generate stronger passwords with generate().

$pwd = Text::Password::AutoMiglation->new( readability => 0 );


=back

=head2 Methods and Subroutines

=head3 verify( $raw, $hash )

returns true if the verification succeeds.

=cut

sub verify {
    my ( $self, $input, $data ) = ( shift, @_ );
    carp ref $self, " doesn't allow any Wide Characters or white spaces" if $input =~ /[^ -~]/;
    return $data eq unix_md5_crypt(@_);
}

=head3 nonce( I<Int> )

generates the random strings with enough strength.

the length defaults to 8 || $self->default().

=head3 encrypt( I<Str> )


returns hash with unix_md5_crypt().

salt will be made automatically.

=cut

sub encrypt {
    my ( $self, $input ) = @_;
    croak ref $self, " requires at least ", Min, " length" if length $input < Min;
    croak ref $self, " doesn't allow any Wide Characters or white spaces" if $input =~ /[^ -~]/;

    my $salt = '';
    do { $salt = $self->nonce() } until $salt !~ /\$/;

    return unix_md5_crypt( $input, $salt );
}

=head3 generate( I<Int> )

generates pair of new password and its hash.

less readable characters I<(0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`)>
are forbiddenunless $self->readability is 0.

the length defaults to 8 || $self->default().

=cut

1;

__END__

=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@users.noreply.github.comE<gt>
