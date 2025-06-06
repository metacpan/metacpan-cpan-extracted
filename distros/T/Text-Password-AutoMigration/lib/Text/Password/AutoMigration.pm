package Text::Password::AutoMigration;
our $VERSION = "0.43";

use autouse 'Carp' => qw(croak carp);
use Moo;
use strictures 2;
extends 'Text::Password::SHA';

=encoding utf-8

=head1 NAME

Text::Password::AutoMigration - generate and verify Password with any contexts

=head1 SYNOPSIS

 my $pwd = Text::Password::AutoMigration->new();
 my( $raw, $hash ) = $pwd->generate();          # list context is required
 my $input = $req->body_parameters->{passwd};　 # in Plack
    $input = $req->param('passwd');             # in CGI
    $input = $raw;                              # in CLI
 my $data = $pwd->encrypt($input);              # you don't have to care about salt
 my $flag = $pwd->verify( $input, $data );

=head1 DESCRIPTION

Text::Password::AutoMigration is a module for some lasy Administrators.

It would help you to migrate old hash what has vulnerability
such as encrypted by perl, MD5, SHA-1 or even if it was with SHA-256 to SHA-512.

The method I<verify()>  automatically detects the algorithm which is applied to the hash
with B<CORE::crypt>, B<MD5>, B<SHA-1 by hex>, B<SHA-256> and of course B<SHA-512>.

And every I<verify()> B<returns a brand new hash> generated by using B<with SHA-512>.

Therefore all you have to do is to replace the old hash with the new one on your Databases.

=head2 Constructor and initialization

=head3 new()

No arguments are required. But you can set some parameters.

=over

=item default( I<Int> )

You can set default length with using 'default' argument like below:

$pwd = Text::Password::AutoMiglation->new( default => 8 );


It must be an Int, defaults to 10.

=item readablity( I<Bool> )

You can set default strength for password with usnig 'readablity' argument like below:

$pwd = Text::Password::AutoMiglation->new( readability => 0 );


It must be a Boolean, defaults to 1.

If it was false, I<generate()> starts to return stronger passwords with charactors hard to read.

=item migrate( I<Bool> )

It must be a Boolean, defaults to 1.

If you've already replaced all hash or started to make new applications with this module,

you can call the constructor with I<migrate =E<gt> 0>.

Then I<verify()> would not return a new hash but always 1.

It may help you a little faster without any change of your code.

=cut

use Types::Standard qw(Bool);
has migrate => ( is => 'rw', isa => Bool, default => 1 );

=back

=head2 Methods and Subroutines

=head3 verify( $raw, $hash )

To tell the truth, this is the most useful method of this module.

it Returns a true strings instead of boolean if the verification succeeds.

Every value is B<brand new hash from SHA-512>
because it is actually true in Perl anyway.

So you can replace hash in your Database easily like below:

 my $pwd = Text::Password::AutoMigration->new();

 my $dbh = DBI->connect(...);
 my $db_hash_ref = $dbh->fetchrow_hashref(...);
 my $param = $req->body_parameters;

 my $hash = $pwd->verify( $param->{passwd} || $raw, $db_hash_ref->{passwd} );
 my $verified = length $hash;
 if ( $verified ) { # don't have to execute it every time
    my $sth = $dbh->prepare('UPDATE DB SET passwd=? WHERE uid =?') or die $dbh->errstr;
    $sth->excute( $hash, $param->{uid} ) or die $sth->errstr;
 }

New hash length is 100 (if it defaults).
So you have to change the Table with like below:

 ALTER TABLE User MODIFY passwd VARCHAR(100);

=cut

around verify => sub {
    my ( $orig, $self ) = ( shift, shift );
    return 0 unless $self->$orig(@_);
    return $self->migrate() ? $self->encrypt(@_) : 1;
};

=head3 nonce( I<Int> )

generates the random strings with enough strength.

the length defaults to 10 || $self->default().

=head3 encrypt( I<Str> )

returns hash with unix_sha512_crypt()

enough strength salts will be made automatically.

=head3 generate( I<Int> )

generates pair of new password and its hash.

less readable characters(0Oo1Il|!2Zz5sS$6b9qCcKkUuVvWwXx.,:;~-^'"`) are forbidden
unless $self->readability is 0.

the length defaults to 10 || $self->default().

B<DON'T TRUST> this method.

According to L<Password expert says he was wrong|https://www.usatoday.com/story/news/nation-now/2017/08/09/password-expert-says-he-wrong-numbers-capital-letters-and-symbols-useless/552013001/>,
it's not a safe way. So, I will rewrite this method as soon as I find the better way.

=cut

1;

__END__

=head1 SEE ALSO

=over

=item L<GitHub|https://github.com/worthmine/Text-Password-AutoMigration>

=item L<CPAN|http://search.cpan.org/perldoc?Text%3A%3APassword%3A%3AAutoMigration>

=item L<https://shattered.io/>

=back

=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida E<lt>worthmine@users.noreply.github.comE<gt>
