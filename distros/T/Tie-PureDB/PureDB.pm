=head1 NAME

Tie::PureDB - Perl extension for pure-db

=head1 SYNOPSIS

  use Tie::PureDB;
  my $file = 'foo.db';
  {
      tie my %db, 'Tie::PureDB::Write', "$file.index", "$file.data", $file
          or die "Couldn't create database ($!)";

      $db{createtime} = scalar gmtime;
      $db{$_} = rand($_) for 1..100;

      untie %db;

      tie %db, 'Tie::PureDB::Read', $file
          or die "Couldn't read database ($!)";

      print "This database was created on $db{createtime}\n";
      print " 1 => $db{1}\n 6 => $db{6}\n\n";

      untie %db;
  }
  {
      my $db = Tie::PureDB::Write->new( "$file.index", "$file.data", $file )
          or die "Couldn't create database ($!)";

      $db->puredbw_add( createtime => scalar gmtime );
      $db->add( $_ => rand($_)) for 1..100;

      undef $db;

      $db = Tie::PureDB::Read->($file)
          or die "Couldn't read database ($!)";

      print "This database was created on ",
          $db->read( $db->puredb_find('createtime') ), \n";

      print " 1 => ", $db->FETCH(1) || "EEEK!($!)", "\n";
      print " 1 => ", $db->FETCH(9) || "EEEK!($!)", "\n";

      undef $db;
  }

=head1 DESCRIPTION

This is the perl interface to PureDB.
If you wanna know what PureDB is, visit the
PureDB home page at http://www.pureftpd.org/puredb/ .

Now go read the examples ;)

=cut


package Tie::PureDB;

use strict;

use DynaLoader();

use vars qw[ @ISA $VERSION ];
@ISA = qw( DynaLoader );

$VERSION = '0.04';

bootstrap Tie::PureDB $VERSION;

package Tie::PureDB::Write;
use Carp qw[ carp croak ];
use strict;

=head1 Tie::PureDB::Write

This is the interface to libpuredb_write.

If you use the tie interface, you can only use it to store values
(C<$db{foo}=1;> aka C<(tied %db)-E<gt>STORE(foo =E<gt> 1);> ).
It is highly reccomended that you use the tie interface.

If you use the function interface, you'll wanna use the following functions.

=head2 puredbw_open

Also known as C<open>, or C<new>.
It takes 3 arguments: file_index, file_data, file_final.

On success, returns a Tie::PureDB::Write object.
On failure, returns nothing while setting $!.

=cut

{ no strict 'refs'; *open = *puredbw_open = *new; }
sub new {
    my $package = shift;

    croak "Usage error : 3 arguments expected (file_index, file_data, file_final)"
        unless
            @_ == 3
        and length $_[0]
        and length $_[1]
        and length $_[2];

    my $it = xs_new(@_);
    return bless \$it, $package if defined $it;
    return();
}

=head2 add

Also known as C<open>, or C<puredbw_add>.
It takes 2 arguments: key,value.

On success, returns a true value.
On failure, returns nothing while setting $!.

=cut

{ no strict 'refs'; *add = *puredbw_add; }
sub puredbw_add {
    my( $self, $key, $value ) = @_;
    return xs_puredbw_add($$self, $key, $value);
}

=head2 CAVEATS(undefined functions)

Don't try to use the following functions, they are not defined
(for example: C<keys %db>.  See L<perltie|perltie> for more info details.).

    # these would require an extension to libpuredb_write, which I ain't ready for
    sub FIRSTKEY(){}
    sub NEXTKEY(){}

    # these are NO-NOs (libpuredb_write don't know this)
    sub FETCH(){}
    sub EXISTS(){}
    sub DELETE(){}
    sub CLEAR(){}

=cut

sub STORE {
    my( $self, $key, $value ) = @_;
    return $value if xs_puredbw_add($$self, $key, $value);
    return();
}


sub TIEHASH { goto &new;  }

sub UNTIE {
    my ($obj,$count) = @_;
    carp "untie attempted while $count inner references still exist" if $count;
    return();
}

sub DESTROY {
    my $self = shift;
    xs_free($$self);
}


package Tie::PureDB::Read;
use Carp qw[ carp croak ];
use strict;

=head1 Tie::PureDB::Read

This is the interface to libpuredb_read.

If you use the tie interface, you can only use it to read values
(C<print $db{foo};> aka C<print (tied %db)-E<gt>FETCH('foo');> ).
It is highly reccomended that you use the tie interface.

If you use the function interface, you'll wanna use the following functions.

=head2 puredb_open

Also known as C<new>, or C<open>.
It takes 1 arguments: file_final.

On success, returns a Tie::PureDB::Read object.
On failure, returns nothing while setting $!.

=cut

{ no strict 'refs'; *open = *puredb_open = *new; }
sub new {
    my $package = shift;

    croak "Usage error : 1 argument of length greater than 0 expected"
        unless @_
            and defined $_[0]
            and length $_[0];

    my $it = xs_new(@_);
    return bless \$it, $package if defined $it;
}


=head2 getsize

Also known as C<puredb_getsize>.
Takes 0 arguments.
Returns the size of the database in bytes
(same number as C<-s $file>).

=cut

{ no strict 'refs'; *getsize = *puredb_getsize; }
sub puredb_getsize {
    my $self = shift;
    return xs_puredb_getsize($$self);
}


=head2 find

Also known as C<puredb_find>.
Takes 1 argument (the key to find),
On success, returns offset,length.
On failure, returns nothing while setting $!.

=cut

{ no strict 'refs'; *find = *EXISTS = *puredb_find; }
sub puredb_find {
    my $self = shift;

    return xs_puredb_find($$self,@_);
}

=head2 read

Also known as C<puredb_read>.
Takes 2 arguments (offset,length).
On success, returns the value.
On failure, returns nothing while setting $!.

B<**WARNING> --
It is highly discouraged that you use C<read> with invalid offsets.
Always use those returned by C<find>,
or simply use C<FETCH> or the tie interface.

=cut

{ no strict 'refs'; *read = *puredb_read; }
sub puredb_read {
    my $self = shift;
    return xs_puredb_read($$self,@_);
}


=head2 FETCH

A I<utiliy method>.
use C<$db-E<gt>FETCH('foo')> instead of C<$db-E<gt>read( $db-E<gt>find('foo') );>
Returns undef on failure.

=cut

sub FETCH  {
    my($self,$key) = @_;
    my @ret = xs_puredb_find($$self, $key);
    if(@ret){
        return xs_puredb_read($$self,@ret);
    } else {
        return undef;
    }
}

sub TIEHASH { goto &new;  }

sub DESTROY {
    my $self = shift;
    xs_free($$self);# if defined $self;
}


=head2  CAVEATS (undefined functions)

Don't try to use the following functions, they are not defined
(for example: C<keys %db>.  See L<perltie|perltie> for more info details.).

    # these would require an extension to libpuredb_read, which I ain't ready for
    sub FIRSTKEY(){}
    sub NEXTKEY(){}

    # these are NO-NOs (libpuredb_read don't know this)
    sub STORE(){}
    sub DELETE(){}
    sub CLEAR(){}

=cut


1;


=head1 THREAD SAFETY

AFAIK, this module and the underlying c library do not use
globally shared data, and as such, they are "thread-safe".


=head1 CAVEATS (The C<untie()> Gotcha)

If you aren't aware of the I<Gotcha>,
read about it before even attempting to use this module ;)

L<The untie Gotcha|perltie/The untie Gotcha> in L<perltie|perltie>.


=head1 Memoize

You could use Memoize with this module.
All you have to do is add the following lines to your program:

    use Tie::PureDB;
    BEGIN{
        package Tie::PureDB::Read;
        use Memoize();
        Memoize::memoize('puredb_read','puredb_find','FETCH');
        no strict 'refs';
        *read = *puredb_read;
        *find = *puredb_find;
        *EXISTS = *puredb_find;
        package main;
    }
    ## ... rest of your code follows


=head1 AUTHOR

D. H. E<lt>PodMaster@cpan.orgE<gt>
who is very thankful to I<tye and B<the perlmonks>>,
as well as Tim Jenness and Simon Cozens
(authors of Extending and Embedding Perl -- http://www.manning.com/jenness/ ).

=head1 SEE ALSO

L<perl>,
L<perltie>,
L<perldata>,
L<AnyDBM_File>,
L<DB_File>,
L<BerkeleyDB>.

=cut

## damn link targets podchecker
