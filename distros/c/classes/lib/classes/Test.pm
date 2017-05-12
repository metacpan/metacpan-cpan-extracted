package classes::Test;

# $Id: Test.pm 147 2008-03-08 16:04:33Z rmuhle $

# these two are just really brain dead
# when using more advanced perl stuff
no strict;
no warnings;

use Scalar::Util 'blessed';

use base 'Exporter';
our @EXPORT_OK = qw(
    can_new
    can_set_get
    has_decl
    has_class_const
    has_mixins
    has_mixins_hash
    is_classes
    is_throwable
    is_classes_exc
    has_tree
);

our %EXPORT_TAGS = ( 'all' => [qw(
    can_new
    can_set_get
    has_decl
    has_class_const
    has_mixins
    has_mixins_hash
    is_classes
    is_throwable
    is_classes_exc
 )]);

use Test::Builder;
use Test::More;
my $t = Test::Builder->new();

sub can_new (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
           $this->can('new'),
         "'$this' has new constructor method" 
    ) ||
    $t->diag(
    "     '$this' missing new constructor"
    );
}

sub can_set_get (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
           $this->can('set')
        && $this->can('get')
        , "'$this' can set, get"
    ) ||
    $t->diag("     '$this' missing set, get");
}

# should have a DECL hash ref package variable and method
sub has_decl (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
        $this->can('DECL') &&
        defined ${$this.'::DECL'},
        "'$this' has DECL"
    )
    || $t->diag("    '$this' does not have a DECL declaration");
}

sub has_class_const (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
        $this->can('CLASS') &&
        defined ${$this.'::CLASS'},
        "'$this' has CLASS constant"
    )
    || $t->diag("    '$this' does not have a CLASS constant");
}

sub has_mixins (*) {
    my $this = blessed $_[0] || $_[0];
    no strict 'refs';
    return $t->ok(
        $this->can('MIXIN') &&
        scalar %{${$this.'::MIXIN'}},
        "'$this' has MIXINs"
    )
    || $t->diag("    '$this' does not have a CLASS constant");
}

sub has_mixins_hash (*) {
    my $this = blessed $_[0] || $_[0];
    no strict 'refs';
    return $t->ok(
        $this->can('MIXIN') &&
        ref ${$this.'::MIXIN'} eq 'HASH',
        "'$this' has MIXIN hash defined"
    )
    || $t->diag("    '$this' does not have a MIXIN hash");
}

sub is_classes (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
         can_new($this) &&
         has_class_const($this) &&
         has_decl($this),
        "'$this' is a classes class"
    )
    || $t->diag("    '$this' does not look like a classes class");
}

sub is_throwable (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
        $this->can('throw') &&
        $this->can('rethrow') &&
        $this->can('send') &&
        $this->can('catch') &&
        $this->can('caught') &&
        $this->can('capture'),
        "'$this' fulfills the classes::Throwable interface"
    )
    || $t->diag("    '$this' does not fulfill the classes::Throwable interface");
}

sub is_classes_exc (*) {
    my $this = blessed $_[0] || $_[0];
    return $t->ok(
         is_classes($this) &&
         $this->can('as_string') &&
         like( $this->new->as_string, qr/^$this/,
            'as_string matches' ) &&
        is_throwable($this),
        "'$this' is a classes::Exception class"
    )
    || $t->diag("    '$this' does not look like a classes::Exception class");
}

1;

__END__

=pod

=head1 NAME

classes::Test - functions to help with classes pragma testing

=head1 SYNOPSIS

    can_new
    can_set_get
    has_decl
    has_class_const
    has_mixins
    has_mixins_hash

    is_classes MyClass;
    is_classes main;

    is_throwable X::Mine;
    is_classes_exc X::Mine;

=head1 DESCRIPTION

Generic tests based on L<Test::Builder> designed to help write unit
tests for code that uses the B<C<classes>> pragma.

=head1 FUNCTIONS

Most of the functions that accept a class argument will accept an
object argument in place of the class and will look up the class
of that object to use.

=over 4

=item can_new

Class has a required C<new> constructor method.

=item can_set_get

Class has the C<set> and C<get> public attribute accessor dispatch
methods defined as well as the private C<_set> and C<_get> pair
for internal use.

=item has_decl

Class has the L<DECL> declaration method and hash ref defined. 

=item has_class_const

Class has the L<CLASS> constant and method defined.

=item has_mixins

Class has the L<MIXIN> method defined.

=item has_mixins_hash

Class has the L<MIXIN> method defined and it is a C<HASH> ref.

=item is_classes

Class is a class created or compatible with B<C<classes>>.

=item is_throwable

Class fulfills the L<classes::Throwable> interface.

=item is_classes_exc

Class fulfills the L<classes::Exception> interface.

=back

=head1 SEE ALSO

L<classes>

=cut
