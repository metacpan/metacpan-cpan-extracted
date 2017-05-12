package Variable::Watcher;

require v5.6.0;

use strict;
use vars qw[$VERSION $AUTOLOAD $REPORT_FH $TRACE $VERBOSE];

use Attribute::Handlers;
use Carp;
use Data::Dumper;
use Log::Message    private => 1;
use Params::Check   qw[check allow];

use Tie::Scalar;
use Tie::Array;
use Tie::Hash;

$VERSION        = '0.01';
$VERBOSE        = 1;
$TRACE          = 1;

### file handles to print to
local $| = 1;
$REPORT_FH  = \*STDERR;

### list of names to use for the variables we're watching
my %Names   = ();

### log::message object to store actions in
my $Log     = new Log::Message;

### list of mappings of bless classes to tie classes
my %Map = (
    SCALAR  => 'Tie::StdScalar',
    ARRAY   => 'Tie::StdArray',
    HASH    => 'Tie::StdHash',
);


### add ourselves to the callers @INC, so we can use attributes that
### that are inherited.
sub import {
    my $self    = shift;
    my $class   = [caller]->[0];

    {   no strict 'refs';
        push @{"${class}::ISA"}, __PACKAGE__;
    }
}

=head1 NAME

Variable::Watcher -- Keep track of changes on C<my> variables

=head1 SYNOPSIS

    ### keep track of scalar changes
    my $scalar : Watch(s) = 1;

    ### keep track of array changes
    my @list : Watch(l) = (1);

    ### keep track of hash changes
    my %hash : Watch(h) = (1 => 2);


    ### retrieve individual mutations:
    my @stack = Variable::Watcher->stack;
    
    ### retrieve the mutation as a printable string
    my $string = Variable::Watcher->stack_as_string;

    ### flush the logs of all the mutations so far
    Variable::Watcher->flush;
    
    ### Set the default reporting filehandle (defaults to STDERR 
    ### -- see the C<GLOBAL VARIABLES> section
    $Variable::Watcher::REPORT_FH = \*MY_FH;
    
    ### Make Variable::Watcher not print to REPORT_FH when running
    ### You will have to use the stack/stack_as_string method to
    ### retrieve the logs. See the C<GLOBAL VARIABLES> section
    $Variable::Watcher::VERBOSE = 0;


=head1 DESCRIPTION

C<Variable::Watcher> allows you to keep track of mutations on C<my>
variables. It will record every mutation you do to a variable that
is being C<Watch>ed. You can retrieve these mutations as a list or
as a big printable string, filtered by a regex if you like.

This is a useful debugging tool when you find your C<my>
variables in a state you did not expect.

See the C<CAVEATS> section for the limitations of this approach.

=head1 Attributes

=head2 my $var : Watch([NAME])

In order to start C<Watch>ing a variable, you must tag it as being
C<Watch>ed at declaration time. You can optionally give it a name
to be used in the logs, rather than it's memory address (this is much
recommended).

You can do this for perls three basic variable types; 

=over 4

=item SCALAR

To keep track of a scalar, and it's mutations, you could for example,
do somethign like this:

    my $scalar : Watch(s) = 1;
    $scalar++;
    

The resulting output would be much like this:

   [Variable::Watcher s -> STORE] Performing 'STORE' on s passing 
   '1' at z.pl line 6
   [Variable::Watcher s -> FETCH] Performing 'FETCH' on s at z.pl 
   line 7
   [Variable::Watcher s -> STORE] Performing 'STORE' on s passing 
   '2' at z.pl line 7

Showing you when you did the first C<STORE>, when you retrieved the
value (C<FETCH>) and when you stored the increment (C<STORE>).

=item ARRAY

To keep track of an array, and it's mutation, you could for example,
do something like this:

    my @list : Watch(l) = (1);
    push @list, 2;
    pop @list;

The resulting output would be much like this:

   [Variable::Watcher l -> CLEAR] Performing 'CLEAR' on l at z2.pl
   line 6
   [Variable::Watcher l -> EXTEND] Performing 'EXTEND' on l 
   passing '1' at z2.pl line 6
   [Variable::Watcher l -> STORE] Performing 'STORE' on l passing 
   '0 1' at z2.pl line 6
   [Variable::Watcher l -> PUSH] Performing 'PUSH' on l passing 
   '2' at z2.pl line 7
   [Variable::Watcher l -> FETCHSIZE] Performing 'FETCHSIZE' on l 
   at z2.pl line 7
   [Variable::Watcher l -> POP] Performing 'POP' on l at z2.pl 
   line 8

Showing you that you initialized an empty array (C<CLEAR>), and 
extended it's size (C<EXTEND>) to fit your first assignment (C<STORE>),
followed by the C<PUSH> which adds another value to your list.
Then we attempt to remove the last value, showing us how perl fetches
its size (C<FETCHSIZE>) and C<POP>s the last value off.

=item HASH

To keep track of a hash, and it's mutation, you could for example,
do something like this:

    my %hash : Watch(h) = (1 => 2);
    $hash{3} = 4;
    delete $hash{3};

The resulting output would be much like this:
    
   [Variable::Watcher h -> CLEAR] Performing 'CLEAR' on h at z3.pl
   line 6
   [Variable::Watcher h -> STORE] Performing 'STORE' on h passing 
   '1 2' at z3.pl line 6
   [Variable::Watcher h -> STORE] Performing 'STORE' on h passing 
   '3 4' at z3.pl line 7
   [Variable::Watcher h -> DELETE] Performing 'DELETE' on h 
   passing '3' at z3.pl line 8

Showing you that you initialized an empty hash (C<CLEAR>), and 
C<STORE>d it's first key/value pair. Then we C<STORE> the second 
key/value pair, followed by a C<DELETE> of the key C<3>.

=cut

sub Watch : ATTR {
    my ($package, $symbol, $ref, $attr, $data, $phase) = @_;
    my $reftype = ref $ref;

    my $obj;
    ### do we support this type of ref?
    unless( $Map{ $reftype } ) {

        ### report from the callers perspective, not from attribute.pm
        ### or attribute::handlers perspective
        local $Carp::CarpLevel += 2;

        carp("Cannot watch variable of type: '$reftype'" );
        return;

    ### if so, tie it to the appropriate class
    ### note that '$ref' is not the same as '$obj'!
    } elsif ( $reftype eq 'SCALAR' ) {
        tie $$ref, __PACKAGE__ .'::'. $reftype;
        $obj = tied $$ref;

    } elsif ( $reftype eq 'ARRAY' ) {
        tie @$ref, __PACKAGE__ .'::'. $reftype;
        $obj = tied @$ref;

    } elsif ( $reftype eq 'HASH' ) {
        tie %$ref,  __PACKAGE__ .'::'. $reftype;
        $obj = tied %$ref;
    }

    ### store the name which we will call this variable in the
    ### pretty print output
    $Names{ $obj } = ($data || "$obj");

    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    my $ref  = tied $self;

    ### figure out the method called, and the class we're
    ### blessed into
    my ($class,$method) = $AUTOLOAD =~ /::([^:]+)::([^:]+)$/;

    ### XXX we won't have a name yet at TIEFOO stage, but don't
    ### bother reporting that either
    if( my $name = $Names{ $self } ) {
        my $msg = "Performing '$method' on $name";
        $msg .= " passing '@_'" if @_;

        ### skip the call frames that are private to this module
        local $Carp::CarpLevel += 1;

        $Log->store(
                message => Carp::shortmess($msg),
                tag     => __PACKAGE__ . " $name -> $method",
                level   => 'report',
                extra   => [@_]
        );
    }

    ### get the coderef to the correpsonding function in
    ### the tie class
    my $func = $Map{$class}->can( $method );

    ### called the tie function, with ourselves as primary
    ### argument, and the rest of the args after that
    $func->($self, @_);
}


### tie packages, which inherit straight from base
{   package Variable::Watcher::SCALAR;
    use base 'Variable::Watcher';

    package Variable::Watcher::ARRAY;
    use base 'Variable::Watcher';

    package Variable::Watcher::HASH;
    use base 'Variable::Watcher';
}

=pod

=head1 CLASS METHODS

=head2 @stack = Variable::Watcher->stack( [name => $name, action => $action] );

Retrieves a list of C<Log::Message::Item> objects describing the 
mutations of the C<Watch>ed variables.

The optional C<name> argument lets you filter based on the name you 
have given the variables to be C<Watch>ed.

The optional C<action> argument lets you filter on the type of action 
you want to retrieve (C<STORE> or C<FETCH>, etc).

Refer to the C<Log::Message> manpage for details on how to work with 
C<Log::Message::Item> objects.

=cut

### report stack retrieval and manipulation
sub stack {
    my $self = shift;
    my %hash = @_;

    my($name,$action);
    my $tmpl = {
        name    => { default => '', store => \$name },
        action  => { default => '', store => \$action },
    };

    check( $tmpl, \%hash ) or return;

    my @rv;
    my $re = __PACKAGE__ . '\s(.+?)\s->\s(.+?)$';

    for my $item ( $Log->retrieve( chrono => 1 ) ) {
        my ($tagname,$tagaction) = $item->tag =~ /$re/;

        ### you want to do name based retrieving?
        if( $name ) {
            next unless allow( $tagname, $name );
        }

        ### you want to do action based retrieving?
        if( $action ) {
            next unless allow( $tagaction, $action);
        }

        push @rv, $item;
    }

    return @rv;
}

=head2 $string = Variable::Watcher->stack_as_string( [name => $name, action => $action] );

Returns the mutation log as a printable string, optionally filterd on
the criteria as described in the C<stack> method.

=cut

sub stack_as_string {
    my $class = shift;
    my @stack = $class->stack( @_ );

    return join '', map {
                    '[' . $_->tag . '] ' . $_->message;
                } @stack
}

=head2 @stack = Variable::Watcher->flush;

Flushes the logs of all mutations that have occurred so far. Returns
the stack, like the C<stack> method would, without filtering.

=cut


sub flush {
    return reverse $Log->flush;
}

### the function that pretty prints the actions performed on variables
{   package Log::Message::Handlers;
    use Carp ();

    sub report {
        my $self    = shift;

        ### so you don't want us to print the msg? ###
        return unless $Variable::Watcher::VERBOSE;

        ### store the old filehandle, select the one the user wants us
        ### to print to
        my $old_fh = select $Variable::Watcher::REPORT_FH;
        print '['. $self->tag (). '] ' . $self->message;

        ### restore the old filehandle
        select $old_fh;

        return;
    }
}

1;

__END__

=head1 GLOBAL VARIABLES

=head2 $Variable::Watcher::REPORT_FH

This is the filehandle that all mutations are printed to. It defaults
to C<STDERR> but you can change it to any (open!) filehandle you wish.

=head2 $Variable::Watcher::VERBOSE

By default, all the mutation are printed to C<REPORT_FH> when they 
occur. You can silence C<Variable::Watcher> by setting this variable to
C<false>. Note you will then have to retrieve mutation logs via the
C<stack> or C<stack_as_string> methods.

=head1 CAVEATS

This module can only operate on the three standard perl data types;
C<SCALAR>, C<ARRAY>, C<HASH>, and only C<Watch>es the first level of a
variable, but not nested ones; ie, a variable within a variable is not
C<Watch>ed.

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2005 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut


# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
