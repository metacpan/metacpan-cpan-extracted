package YottaDB;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        y_data
        y_killall
        y_kill_excl
        y_kill_node
        y_kill_tree
        y_set
        y_get
        y_get_croak
        y_next
        y_previous
        y_node_next
        y_node_previous
        y_incr
        y_zwr2str
        y_str2zwr
        y_lock
        y_lock_incr
        y_lock_decr
        y_trans

        y_tp_rollback
        y_tp_restart
        y_node_end 
        y_lock_timeout
        y_ok

        y_child_init
        y_exit

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.37';

sub AUTOLOAD {

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&YottaDB::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('YottaDB', $VERSION);

#
# perl crashes at destruction time without:
#       putenv ("ydb_callin_start");
#       putenv ("GTM_CALLIN_START")
#

END { YottaDB::fixup_for_putenv_crash (); }

1;
__END__

=head1 NAME

YottaDB - Perl extension for accessing L<YottaDB|https://yottadb.com>

=head1 SYNOPSIS

  use YottaDB ":all";

  y_set "^var", 1;      # s ^var=1
  y_set "var", 2, 3;    # s var(2)=3

  print y_get "var", 2; # w var(2)

  y_lock_incr (3.14, "a", 1) or die "timeout";

  y_trans (sub {
                ok (1 == y_get '$TLEVEL');
                y_trans (sub {
                                ok (2 == y_get '$TLEVEL');
                                y_ok;
                         },
                         "BATCH"
                );
                ok (1 == y_get '$TLEVEL');
                y_ok;
               },
               "BATCH"
  );


=head1 DESCRIPTION

This module gives you access to the YottaDB database engine
using YottaDB's simple API.
It requires that you install and setup
L<YottaDB|https://yottadb.com/product/get-started> first.

After installing the database, setting up the environment
is required for C<Mumps> and C<Perl>.
Environment-variable C<ydb_gbldir> is needed for C<Mumps> and C<Perl>.
If incorrectly/not set you can't access globals or use M-Style
locking and every attempt to do so will throw an exception.
The installation process itself does not need C<ydb_gbldir> by default;
but C<"make test TEST_DB=1"> needs it.

I highly recommend using:

  $ source "$(pkg-config --variable=prefix yottadb)"/ydb_env_set

and

  $ source "$(pkg-config --variable=prefix yottadb)"/ydb_env_unset

for basic setup of environment and databases.

Rule of the thumb: If it fails in C<Mumps> it will fail in C<Perl>, too.

Always try getting C<Mumps> working first.

Here we try to access a global without C<ydb_gbldir> set in C<Mumps> and -
just for reference - C<Perl>:

C<Mumps>:

 $ cd /tmp
 $ echo 'I $o(^foo(""))'|"$(pkg-config --variable=prefix yottadb)"/mumps -dir

 YDB>
 %YDB-E-ZGBLDIRACC, Cannot access global directory /tmp/$ydb_gbldir.gld.  Cannot continue.
 %SYSTEM-E-ENO2, No such file or directory

 YDB>

C<Perl>:

 $ cd /tmp
 $ perl -MYottaDB=:all -e 'y_next ("^foo","")'
 YottaDB-Error: -150374122 150374122,(SimpleAPI),%YDB-E-ZGBLDIRACC, Cannot access global directory /tmp/$ydb_gbldir.gld.  Cannot continue.,%SYSTEM-E-ENO2, No such file or directory at -e line 1.

Installing the YottaDB module from the git repository:

 $ # sudo apt install make libextutils-pkgconfig-perl libjson-perl
 $ git clone https://gitlab.com/oesiman/yottadb-perl.git
 $ cd yottadb-perl
 $ perl Makefile.PL
 $ make
 $ make test
 $ make test TEST_DB=1 # optional, accesses database
 $ sudo make install

DO NOT USE THIS MODULE ON PRODUCTION SYSTEMS.

=head1 FUNCTIONS

=over 4

=item   $data = y_data $var [, @subs]

The F<y_data> function returns in C<$data>:

         0  - no value and no subtree
         1  - has a value but no subtree
        10  - no value but a subtree
        11  - a value and a subtree exists

=item   y_killall ()

The F<y_killall> function kills all local variables.

=item   y_kill_excl [$var0 [,$var1 [,...]]]

The F<y_kill_excl> function deletes all local variables except the specified one(s).
F<y_kill_excl> without arguments is the same as F<y_killall>.

=item   y_kill_node $var [, @subs]

Deletes a node but not a subtree.

=item   y_kill_tree $var [, @subs]

Deletes a node and all subtrees.

=item   y_set $var, [@subs,] $value

Sets the variable to C<$value>

=item   $value = y_get $var [, @subs]

Sets C<$value> to the value of $var [, @subs].
Returns F<undef> if not defined.

=item   $value = y_get_croak $var [, @subs]

Sets C<$value> to the value of $var [, @subs].
Croaks if it is not defined. 

=item   $value = y_next $var [, @subs]

Returns the next subscript or F<undef>
if there is none.
Here a sample "order-loop":

        my $x = "";
        while (defined ($x = y_next "^global", "subscript", $x)) {
            # ... do something with $x ...
        }


=item   $value = y_previous $var [, @subs]

Returns the previous subscript or F<undef>
if there is none.

=item   (@subs) = y_node_next $var [, @subs]

Returns the next node or the empty list if there is none.

=item   (@subs) = y_node_previous $var [, @subs]

Returns the previous node or the empty list if there is none.

=item   $incval = y_incr $var [, @subs], $increment

Increments $var [, @subs] by C<$increment> and returns
the result in C<$incval>.

=item   $string = y_zwr2str $zwr_encoded_string

Decodes the C<$zwr_encoded_string>  to C<$string>.

=item   $zwrstring = y_str2zwr $string

Encodes C<$string> in zwr-format.

=item $status = y_lock $timeout [, \@glob1 [, \@glob2 [,...]]]

Release all locks held. If globals are specified lock
all and return 1 if succeed or 0 if it's not possible
to lock all references within $timeout, return 1 if
it fails.
Example:

        y_lock 0, ["^temp", 1, "two"],
                  ["^temp", 3] or die "can't lock";

=item   $status = y_lock_incr $timeout, $var [, @subs]

Try to gain lock on $var [, @subs] for C<$timeout> seconds
if not held. Increment lock counter otherwise. C<$timeout>
may be 0.0001 for example. Returns 1 on timeout 0 otherwise.

=item   y_lock_decr $var [, @subs]

Decrement lock count on $var [, @subs] and release the lock
if it goes 0.

=item   $status = y_trans (\&code, $tansid [, lvar0 [, lvar1 ...]])

Run a transaction. :)


=back

=head1 SEE ALSO

This module depends on 
L<JSON> for C<ydb_json_import>.
Install it on Debian:

        # apt-get install libjson-perl

or via CPAN:

        # cpan JSON

L<https://yottadb.com>

=head1 AUTHOR

Stefan Traby E<lt>stefan@hello-penguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, 2019, 2020 by Stefan Traby

This library is free software; you can redistribute it and/or modify
it under terms of the GNU Affero General Public License Version 3.

=cut
