package Text::Password::CoreCrypt;
our $VERSION = "0.16";

require 5.008_008;
use Carp qw(croak carp);

use Moose;
use Moose::Util::TypeConstraints;

has minimum => ( is => 'ro', isa => 'Int', default => 4 );

subtype 'Default', as 'Int', where { $_ >= 4 }, message {"The Default must be 4 or higher."};
has default     => ( is => 'rw', isa => 'Default', default => 8 );
has readability => ( is => 'rw', isa => 'Bool',    default => 1 );

__PACKAGE__->meta->make_immutable;
no Moose;

my @ascii = (
    '!', '#', qw! " $ % & ' ( ) * + !, ',', qw! - . / !,

    0 .. 9,     qw( : ; < = > ? @ ),
    'A' .. 'Z', qw( [ \ ] ^ _ ` ),     # to void syntax highlighting -> `
    'a' .. 'z', qw( { | } ~ ),
);

=encoding utf-8

=head1 NAME

Text::Password::CoreCrypt - generate and verify Password with perl CORE::crypt()

=head1 SYNOPSIS

 my $pwd = Text::Password::CoreCrypt->new();
 my( $raw, $hash ) = $pwd->genarate();          # list context is required
 my $input = $req->body_parameters->{passwd};
 my $data = $pwd->encrypt($input);              # salt is made automatically
 my $flag = $pwd->verify( $input, $data );

=head1 DESCRIPTION

Text::Password::CoreCrypt is base module for Text::Password::AutoMigration.

B<DON'T USE> directly.

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
    warn "CORE::crypt makes 13bytes hash strings. Your data must be wrong: $data"
        if $data !~ /^[ !-~]{13}$/;

    return $data eq CORE::crypt( $input, $data );
}

=head3 nonce($length)

generates the random strings with enough strength.

the length defaults to 8($self->default).

=cut

sub nonce {
    my $self   = shift;
    my $length = shift || 8;
    croak "Unvalid length for nonce was set" unless $length =~ /^\d+$/ and $length >= 4;

    my $n = '';
    my @w = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' );
    do {    # redo unless it gets enough strength
        $n = $w[ rand @w ];
        $n .= $ascii[ rand @ascii ] until length $n >= $length;
    } while $n =~ /^\w+$/ or $n =~ /^\W+$/ or $n !~ /\d/ or $n !~ /[A-Z]/ or $n !~ /[a-z]/;
    return $n;
}

=head3 encrypt($raw)

returns hash with CORE::crypt().

salt will be made automatically.

=cut

sub encrypt {
    my $self  = shift;
    my $input = shift;
    my $min   = $self->minimum();
    carp __PACKAGE__ . " requires at least $min length"          if length $input < $min;
    carp __PACKAGE__ . " ignores the password with over 8 bytes" if length $input > 8;
    carp __PACKAGE__ . " doesn't allow any Wide Characters or white spaces\n" if $input =~ /[^ -~]/;

    return CORE::crypt( $input, $self->_salt() );
}

=head3 generate($length)

genarates pair of new password and it's hash.

less readable characters(0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`) are forbidden
unless $self->readability is 0.

the length defaults to 8($self->default).

=cut

sub generate {
    my $self   = shift;
    my $length = shift || $self->default();
    my $min    = $self->minimum();

    croak "unvalid length was set"                        unless $length =~ /^\d+$/;
    croak ref($self) . "::generate requires list context" unless wantarray;
    croak ref($self) . "::generate requires at least $min length" if $length < $min;

    my $raw;
    do {    # redo unless it gets enough readability
        $raw = $self->nonce($length);
        return $raw, $self->encrypt($raw) unless $self->readability();
    } while ( $raw =~ /[0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]/i );

    return $raw, $self->encrypt($raw);
}

sub _salt {
    my $self  = shift;
    my @seeds = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, '.', '/' );
    my $salt  = '';
    $salt .= $seeds[ rand @seeds ] until length $salt == 2;
    return $salt;
}

1;

__END__

=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(worthmine) E<lt>worthmine!at!gmail.comE<gt>
