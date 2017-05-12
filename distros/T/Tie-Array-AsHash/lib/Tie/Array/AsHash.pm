package Tie::Array::AsHash;

use strict;
use warnings;

# use warnings;
use Carp qw/croak/;

use Tie::Hash ();
use Params::Util qw(_REGEX _STRING);

use base qw(Tie::StdHash);

our $VERSION = '0.200';

my $usage = 'usage: tie %hash, \'Tie::Array::AsHash\', array => \@array, '
      . "split => ':' [, join => '#', 'Tie::File option' => value, ... ]\n";

sub TIEHASH
{
    croak( $usage ) unless ( scalar(@_) % 2 );

    my ( $obj, %opts ) = @_;

    # set array to use
    my $array = delete( $opts{array} ) or croak( $usage );

    # set delimiter and croak if none was supplied
    my $split = delete( $opts{split} ) or croak( $usage );

    # set join, an optional argument
    my $join = delete( $opts{join} );

    # if split's value is a regex and join isn't specified, croak
    croak( "Tie::Array::AsHash error: no 'join' option specified and 'split' option is a regular expression\n",
           $usage )
      if ( _REGEX($split) and not _STRING($join) );

    # the rest of the options can feed right into Tie::File
    # Tie::File can worry about checking the arguments for validity, etc.
    #tie my @file, 'Tie::File', $filename, %opts or return;

    my $self = bless(
                      {
                         split   => $split,
                         join    => $join,
                         array   => $array,
			 splitrx => qr/^(.*?)$split/s,
                      },
                      $obj
                    );

    return $self;
}

sub FETCH
{
    my ( $self, $key ) = @_;
    my $fetchrx = qr/^$key$self->{split}(.*)/s;

    # find the key and get corresponding value
    foreach my $line ( @{ $self->{array} } )
    {
        return $1 if ( $line =~ $fetchrx );
    }

    return;
}

sub STORE
{
    my ( $self, $key, $val ) = @_;
    my $existsrc = qr/^$key$self->{split}/s;

    # look for $key in the file and replace value if $key is found
    foreach my $line ( @{ $self->{array} } )
    {
        if ( $line =~ $existsrc ) # found the key? good. replace the entire line with the correct key, delim, and values
        {

            # Marco Poleggi <marco.poleggi@cern.ch> supplied a patch that changed exists
            # to defined in the next line of code.  Thanks Macro!
            my $rc = $line = $key . ( defined( $self->{join} ) ? $self->{join} : $self->{split} ) . $val;
            return $val;
        }
    }

    # if key doesn't exist in the file, append to end of file
    push( @{ $self->{array} }, $key . ( defined( $self->{join} ) ? $self->{join} : $self->{split} ) . $val );

    return $val;
}

sub DELETE
{
    my ( $self, $key ) = @_;
    my $fetchrx = qr/^$key$self->{split}(.*)/s;

    # first, look for the key in the file
    # next, delete the line in the file
    # finally, return the value, which might not contain anything
    # perl's builtin delete() returns the deleted value, so emulate the behavior

    for my $i ( 0 .. $#{ $self->{array} } )
    {
        if ( $self->{array}->[$i] =~ $fetchrx )
        {
            splice( @{ $self->{array} }, $i, 1 );    # remove entry from file
            return $1;
        }
    }

    return;
}

sub CLEAR { @{ $_[0]->{array} } = (); return; }

sub EXISTS
{
    my ( $self, $key ) = @_;
    my $existsrc = qr/^$key$self->{split}/s;

    foreach my $line ( @{ $self->{array} } )
    {
        return 1 if ( $line =~ $existsrc );
    }

    return 0;
}

sub FIRSTKEY
{
    my ($self) = @_;

    # deal with empty files
    return unless ( exists( $self->{array}->[0] ) );

    my ($val) = $self->{array}->[0] =~ $self->{splitrx};

    # reset index for NEXTKEY
    $self->{index} = 0;

    return defined($val) ? $val : $self->NEXTKEY();
}

sub NEXTKEY
{
    my ($self) = @_;

    # keep track of what line of the file we are on
    # and the end of the file
    return if ( $self->{index} >= scalar( @{ $self->{array} } ) );

    my $val;
    while( !defined( $val ) )
    {
        last if ( ++$self->{index} >= scalar( @{ $self->{array} } ) );
        ($val) = $self->{array}->[ $self->{index} ] =~ $self->{splitrx};
    }

    return $val;
}

sub SCALAR
{
    my ($self) = @_;

    # can't think of any other good use for scalar %hash besides this
    return scalar( @{ $self->{array} } );
}

sub UNTIE
{
    my $self = shift;

    delete $self->{array};
}

sub DESTROY
{
    UNTIE(@_);
}

=head1 NAME

Tie::Array::AsHash - tie arrays as hashes by splitting lines on separator

=head1 SYNOPSIS

 use Tie::Array::AsHash;

 my $t = tie my %hash, 'Tie::Array::AsHash', array => \@array, split => ':'
 	or die "Problem tying %hash: $!";

 print $hash{foo};                  # access hash value via key name
 $hash{foo} = "bar";                # assign new value
 my @keys = keys %hash;             # get the keys
 my @values = values %hash;         # ... and values
 exists $hash{perl};                # check for existence
 delete $hash{baz};                 # delete line from file
 $hash{newkey} = "perl";            # entered at end of file
 while (($key,$val) = each %hash)   # iterate through hash
 %hash = ();                        # empty file

 untie %hash;                       # all done

Here is sample text that would work with the above code when contained in a
file:

 foo:baz
 key:val
 baz:whatever

=head1 DESCRIPTION

C<Tie::Array::AsHash> uses some practical extracting code so arrays can be tied
to hashes.

The module was initially written by Chris Angell <chris@chrisangell.com> for
managing htpasswd-format password files.

=head1 SYNOPSIS

 use Tie::Array::AsHash;
 tie %hash, 'Tie::Array::AsHash', array => \@array, split => ':'
 	or die "Problem tying %hash: $!";

 (use %hash like a regular ol' hash)

 untie %hash;  # changes saved to disk

Easy enough eh?

New key/value pairs are appended to the end of the file, C<delete> removes lines
from the file, C<keys> and C<each> work as expected, and so on.

C<Tie::Array::AsHash> will not die or exit if there is a problem tying a
file, so make sure to check the return value and check C<$!> as the examples do.

=head2 OPTIONS

The only argument C<Tie::Array::AsHash> requires is the "split" option, besides
a filename.  The split option's value is the delimiter that exists in the file
between the key and value portions of the line.  It may be a regular
expression, and if so, the "join" option must be used to tell
C<Tie::Array::AsHash> what to stick between the key and value when writing
to the file.  Otherwise, the module dies with an error message.

 tie %hash, 'Tie::Array::AsHash', array => \@array, split => qr(\s+), join => ' '
 	or die "Problem tying %hash: $!";

Obviously no one wants lines like "key(?-xism:\s+)val" in their files.

All other options are passed directly to C<Tie::File>, so read its
documentation for more information.

=head1 CAVEATS

When C<keys>, C<values>, or C<each> is used on the hash, the values are
returned in the same order as the data exists in the file, from top to
bottom, though this behavior should not be relied on and is subject to change
at any time (but probably never will).

C<Tie::Array::AsHash> doesn't force keys to be unique.  If there are multiple
keys, the first key in the file, starting at the top, is used. However, when
C<keys>, C<values>, or C<each> is used on the hash, every key/value combination
is returned, including duplicates, triplicates, etc.

Keys can't contain the split character.  Look at the perl code that
C<Tie::Array::AsHash> is comprised of to see why (look at the regexes).  Using
a regex for the split value may be one way around this issue.

C<Tie::Array::AsHash> hasn't been optimized much.  Maybe it doesn't need to be.
Optimization could add overhead.  Maybe there can be options to turn on and off
various types of optimization?

=head1 EXAMPLES

=head2 changepass.pl

C<changepass.pl> changes password file entries when the lines are of
"user:encryptedpass" format.  It can also add users.

 #!/usr/bin/perl -w

 use strict;
 use warnings;

 use Tie::Array::AsHash;

 die "Usage: $0 user password" unless @ARGV == 2;
 my ($user, $newpass) = @ARGV;

 tie my @userlist, 'Tie::File', '/pwdb/users.txt';
 tie my %users, 'Tie::Array::AsHash', array => \@userlist, split => ':'
     or die "Problem tying %hash: $!";

 # username isn't in the password file? see if the admin wants it added
 unless (exists $users{$user})
 {
     print "User '$user' not found in db.  Add as a new user? (y/n)\n";
     chomp(my $y_or_n = <STDIN>);
     set_pw($user, $newpass) if $y_or_n =~ /^[yY]/;
 }
 else
 {
     set_pw($user, $newpass);
     print "Done.\n";
 }

 sub set_pw { $users{$_[0]} = crypt($_[1], "AA") }

=head2 Using the join option

Here's code that would allow the delimiter to be ':' or '#' but prefers '#':

 tie my %hash, 'Tie::Array::AsHash', array => \@array, split => qr/[:#]/, join => "#" or die $!;

Say you want to be sure no ':' delimiters exist in the file:

 while (my ($key, $val) = each %hash)
 {
 	$hash{$key} = $val;
 }

=head1 TODO

=over 4

=item *

add supoort for comments and/or commented lines

=over 8

=item + RfC

new parameters: C<S<comment =E<gt> regex, comment_join =E<gt> ' #'>>
similar to split/join parameters?

=back

=back

=head1 AUTHOR

Chris Angell <chris@chrisangell.com>, Jens Rehsack <rehsack@cpan.org>

Feel free to email me with suggestions, fixes, etc.

Thanks to Mark Jason Dominus for authoring the superb Tie::File module.

=head1 COPYRIGHT

Copyright (C) 2004, Chris Angell, 2008-2013, Jens Rehsack. All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, including any version of Perl 5.

=head1 SEE ALSO

perl(1), perltie(1), Tie::File(3pm), Tie::File::AsHash(3pm)

=cut

# vim:ts=4

1;
