package DB;
sub uplevel_args { my @foo = caller($_[0]+1); return @DB::args };

package rubyisms;

use strict;
use warnings;
use Carp;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( self super yield );
our $VERSION = '1.0';

sub import { 
    no strict 'refs';
    push @{(caller())[0]."::ISA"}, "Class" 
      unless (caller())[0] eq "Class"; # Although Perl should deal it anyway
    rubyisms->export_to_level(1, @_);
}

sub self () {
    my $call_pack = (caller())[0];

    # So we're looking for the first thing that ISA $call_pack
    my $level =1;
    while (caller($level)) {
        my @their_args = DB::uplevel_args($level);
        if (ref $their_args[0]
            and eval { $their_args[0]->isa($call_pack) }) {
            return $their_args[0];
        }
        $level++;
    }
    # Well, hey, maybe it's a class method.
    return $call_pack;
}

sub yield (@) {
    my @their_args = DB::uplevel_args(1);
    if ((!@their_args) or ref $their_args[0] ne "CODE") {
        croak "no block given (LocalJumpError)";
    }
    my @stuff = (@_||$_);
    $their_args[0]->(@stuff) 
        unless $stuff[0] == $their_args[0]; #Don't yield onto yourself.
}


sub super() {
    if (@_) {
        # Someone's trying to find SUPER's super. Blah.
        goto &UNIVERSAL::super;
    }
    @_ = DB::uplevel_args(1);
    my $self = $_[0];
    if (!$self) { carp "super called outside of method" }
    my $caller= (caller(1))[3];
    $caller =~ s/.*:://;
    goto &{$self->UNIVERSAL::super($caller)};
}

package Class;
rubyisms->import;

sub new { 
    my $class = shift;
    my $self = bless {}, $class;
    # Cheat.
    my @args = @_;
    @_ = $self;
    no strict 'refs';
    $self->initialize(@args);
    return self();
}

sub initialize { } # Just to be sure.

package UNIVERSAL;

sub super {
    my ($class, $method) = @_;

    if (ref $class) { $class = ref $class; }
    my $x;
    no strict 'refs';
    for (@{$class."::ISA"}, "UNIVERSAL") {
        return $x if $x = $_->can($method);
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

rubyisms - Steal some features from Ruby

=head1 SYNOPSIS

  package Foo;
  use rubyisms;
  sub initialize {             # We inherit a new from class Class
    self->{foo} = "bar";       # And we have a receiver, self
    __private_stuff(1,2,3,4);
  }

 sub __private_stuff { 
    self->{things} = [ @_ ];   # self is still around
    self->another_method;
 }
 
 sub my_method {
    if ($interesting) { ... }
    else { super }             # Despatch to superclass 
 }
  
 sub array_iterator (&@) {
    yield() for @_;
 } 

 array_iterator { print $_[0], "\n" } ("Hello", "World");

=head1 DESCRIPTION

If you can't beat 'em, join 'em. This module exports some functionality
to make Perl behave more like Ruby.

Additionally, all classes which C<use rubyisms> inherit from class
C<Class>, and take a basic C<new> method from there. (which creates a
blessed hash, calls your C<initialize> method on it and returns it.)

=head2 EXPORT

=over 3

=item self

This returns the current receiver of methods. This is defined as being
the first thing which is-a your class which comes first in some method's
C<@_>. For instance, in the following case:

    sub stuff { 
        my ($self, @args) = @_;
        print self;
    }

C<$self> and C<self> are equivalent here. However, in this case:

    sub stuff {
        my ($self, @args) = @_;
        _more_stuff("Hi!");
    }

    sub _more_stuff { print self }

The C<self> in C<_more_stuff> is equivalent to C<$self> in its caller:
we walk up the stack until we find something that looks like an object
we're interested in. If we don't find an object we're interested in, we
assume that C<self> is the current classs.

Obviously you need to be careful with this! Note that C<stuff> expects
to be called in the usual method call manner, with the object as the
first parameter; meanwhile, C<_more_stuff> expects the receiver to be
implicit. Be good and consistent and only use implicit recipients in
private methods called from within your class and you'll be all right.

=head2 super

When subclassing a class, you occasionally want to despatch control to
the superclass - at least conditionally and temporarily. The Perl syntax
for calling your superclass is ugly and unwieldy:
    
    $self->SUPER::method(@_);

Especially when compared with its Ruby equivalent:

    super;

This module provides that equivalent.

It has been pointed out that using C<super> doesn't let you pass
alternate arguments to your superclass's method. If you want to pass
different arguments, well, don't use C<super> then. D'oh.

=head2 yield

C<yield> provides iterators in Ruby, and now it does so in Perl too.
However, in Ruby, methods all take an optional block after their usual 
arguments. In Perl, we have to fake it. The C<&> subroutine prototype 
character allows us to take a block and have it passs in as a coderef,
but only if it's the first parameter to a subroutine. For instance,
here's how you'd normally code an iterator:

    sub each_array (&@) {
        my ($coderef, @args) = @_;
        for (@args) {
            $coderef->($_);
        }
    }

    each_array { print $_[0], "\n" } (10,20,30);

C<yield> just makes that a tiny bit easier, by working out which is 
the coderef and calling it with the right thing:

    sub each_array (&@) {
        yield for @_;
    }

C<yield> will call the coderef with C<$_> implicitly, or any arguments
you give it:

    sub each_with_index (&@) {
        yield ($_[$_], $_) for 0..$#_;
    }

    each_with_index { print "The $_[1]th element is $_[0]\n" } @stuff;

Note that this doesn't actually modify C<@_>: the coderef is still
C<$_[0]>, but C<yield> attempts to avoid yielding onto itself. That is
to say, C<yield> does nothing when the first argument passed is the same as
the coderef itself.

If you actually do want to call the coderef on itself, i) you're weirder
than I am, and ii) call it as something other than the first argument:

    yield ("dummy", $_) for @_;

will happily pass the coderef in.

=head1 NOTE

The module tries to do the right thing in all cases, and it B<does> do
the right thing in the vast majority of cases. But like all
labour-saving devices, you give up a little bit of control to gain a bit
of convenience. So maybe it'll do the wrong thing in pathological cases. 
Consider it karmic retribution.

=head1 SUPPORT

Beep... beep... this is a recorded announcement:

I've released this software because I find it useful, and I hope you
might too. But I am a being of finite time and I'd like to spend more of
it writing cool modules like this and less of it answering email, so
please excuse me if the support isn't as great as you'd like.

Nevertheless, there is a general discussion list for users of all my
modules, to be found at
http://lists.netthink.co.uk/listinfo/module-mayhem

If you have a problem with this module, someone there will probably have
it too.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

ruby(1)

=cut
