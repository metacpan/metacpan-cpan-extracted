=head1 NAME

Text::Indent - simple indentation of text shared among modules

=head1 SYNOPSIS

In your main program:

 use Text::Indent;
 my $indent = Text::Indent->new;
 $indent->spaces(2);

In a module to produce indented output:

 use Text::Indent;
 my $indent = Text::Indent->instance;
 $indent->increase;
 print $indent->indent("this will be indented two spaces");
 $indent->increase(2);
 print $indent->indent("this will be indented six spaces");
 $indent->decrease(3);

=head1 DESCRIPTION

Text::Indent is designed for use in programs which need to produce output
with multiple levels of indent when the source of the output comes from
different modules that know nothing about each other.

For example take module A, whose output includes the indented output of
module B. Module B can also produce output directly, so it falls to module B
to know whether it should indent it's output or not depending on it's
calling context.

Text::Indent allows programs and modules to cooperate to choose an
appropriate indent level that is shared within the program context. In the
above example, module A would increase the indent level prior to calling the
output routines of module B. Module B would simply use the Text::Indent
instance confident that if it were being called directly no indent would be
applied but if module A was calling it then it's output would be indented
one level.

=for testing
use_ok('Text::Indent');
eval "use Test::NoWarnings";

=cut

package Text::Indent;

use strict;
use warnings;

our $VERSION = '0.02';

use Params::Validate    qw|:all|;

use Class::MethodMaker(
    new_with_init  => 'new',
    static_get_set => '_instance',
    get_set        => [ qw|
        spaces
        spacechar
    |],
    counter        => 'level',
    boolean        => 'add_newline',
);

=head1 CONSTRUCTOR

The constructor for Text::Indent should only be called once by the main
program using modules that produce indented text.  Modules which wish
to produce indented text should use the instance accessor described below.

To construct a new Text::Indent object, call the B<new> method, passing
one or more of the following parameters as a hash:

=over 4

=item * B<Spaces>

the number of spaces to used for each level of indentation.  Defaults to 2.

=item * B<SpaceChar>

the character to be used for indentation. Defaults to a space (ASCII 32)

=item * B<Level>

The initial indentation level to set.  Defaults to 0.

=item * B<AddNewLine>

Whether the B<indent> method should automatically add a newline to the input
arguments. Defaults to TRUE.

=item * B<Instance>

Whether the newly constructed Text::Indent object should become the new
singleton instance returned by the B<instance> accessor. Defaults to TRUE.

=back

=begin testing

eval { Text::Indent->new };
ok( ! $@, "can create an object");
eval {  Text::Indent->new( Foo => 'Bar' ) };
ok( $@, "constructor dies on invalid args");

=end testing

=cut

sub init
{
    
    my $self = shift;
    my $class = ref $self || $self;
    
    # validate args
    my %args = validate(@_,{
        Spaces     => { type    => SCALAR,
                        default => 2 },
        SpaceChar  => { type    => SCALAR,
                        default => ' ' },
        Level      => { type    => SCALAR,
                        default => 0 },
        AddNewLine => { type    => BOOLEAN,
                        default => 1 },
        Instance   => { type    => BOOLEAN,
                        default => 1 }
    });
    
    # populate object
    $self->spaces( $args{Spaces} );
    $self->spacechar( $args{SpaceChar} );
    $self->level( $args{Level} );
    $self->add_newline( $args{AddNewLine} );
    
    # set as the current instance unless told not to
    unless( exists $args{Instance} && ! $args{Instance} ) {
        $class->_instance( $self );
    }
    
    return $self;
    
}

=head1 INSTANCE ACCESSOR

The instance accessor is designed to be used by modules wishing to produce
indented output. If the instance already exists (as will be the case if the
main program using the module constructed a Text::Indent object) then both
the program and the module will use the same indentation scheme.

If the instance does not exist yet, the instance accessor dispatches it's
arguments to the constructor. As such, any of the parameters that the
constructor takes may also be passed to the instance accessor. Be mindful
that if the instance does exist, any parameters passed to the instance
accessor are ignored.

=cut

sub instance
{
    
    my $self = shift;
    my $class = ref $self || $self; 
    
    # return the class instance if we have one, otherwise
    # dispatch to the constructor
    return $class->_instance ? $class->_instance
                            : $class->new(@_);
    
}

=head1 METHODS

=head2 increase($how_many)

This method increases the level of indentation by $how_many levels.  If
not provided, $how_many defaults to 1.

=for testing
my $i = Text::Indent->new;
is( $i->level, 0, "level initialized to 0");
$i->increase;
is( $i->level, 1, "level increased to 1");
$i->increase(2);
is( $i->level, 3, "level increased to 3");

=cut

sub increase
{
    
    my $self = shift;
    my $how_many = shift || 1;
    
    $self->level_incr($how_many);
    
    return $self;
    
}

=head2 decrease

This method decreases the level of indentation by $how_many levels.  If
not provided, $how_many defaults to 1.

=for testing
my $i = Text::Indent->new( Level => 5 );
is( $i->level, 5, "level initialized to 5");
$i->decrease;
is( $i->level, 4, "level decreased to 4");
$i->decrease(2);
is( $i->level, 2, "level decreased to 2");

=cut

sub decrease
{
    
    my $self = shift;
    my $how_many = shift || 1;
    
    $self->level_incr( - $how_many );
    
    return $self;
    
}

=head2 reset

This method resets the level of indentation to 0.  It is functionally
equivalent to $ident->level(0).

=for testing
my $i = Text::Indent->new( Level => 5 );
is( $i->level, 5, "level initialized to 5");
$i->reset;
is( $i->level, 0, "level reset to 0");

=cut

sub reset
{
    
    my $self = shift;
    
    $self->level_reset;
    
    return $self;
    
}

=head2 indent(@what)

This is the primary workhorse method of Text::Indent. It takes a list of
arguments to be indented and returns the indented string.

The string returned is composed of the following list:

=over 4

=item * the 'space' character repeated x times, where x is the number of
spaces multiplied by the indent level.

=item * the stringification of arguments passed to the method (note that
this means that list arguments will have spaces inserted in between them).

=item * a newline if the 'add_newline' attribute of the Text::Indent object
is set.

=back

If the indent level drops is a negative value, no indent is applied.

=for testing
my $i = Text::Indent->new;
is( $i->indent("foo"), "foo\n", "no indentation");
$i->increase;
is( $i->indent("foo"), "  foo\n", "indent level 1");
$i->spaces(4);
is( $i->indent("foo"), "    foo\n", "change spaces to 4");
$i->spacechar("+");
is( $i->indent("foo"), "++++foo\n", "chance spacechar to +");
$i->add_newline(0);
is( $i->indent("foo"), "++++foo", "unset add_newline");
$i->reset;
is( $i->indent("foo"), "foo", "reset indent level");
$i->decrease;
is( $i->indent("foo"), "foo", "negative indent has no effect");

=cut

sub indent
{
    
    my $self = shift;
    my @args = @_;
    
    return ($self->spacechar x ($self->spaces * $self->level)) .
           "@args" . ($self->add_newline ? "\n" : '');
    
}

# keep require happy
1;


__END__


=head1 ACCESSORS

=for testing
my @accessors = qw|
    spaces
    spacechar
    level
    add_newline
|;
for( @accessors ) {
    can_ok('Text::Indent', $_);
}

=head2 spaces

Gets or sets the number of spaces used for each indent level.

=head2 spacechar

Gets or sets the character used for indentation.

=head2 level

Gets or sets the current indent level.

=head2 add_newline

Gets or sets the boolean attribute that determines if the B<indent> method
tacks a newline onto it's arguments.

=head1 EXAMPLES

In the main program producing indented output:

 use Text::Indent;
 use Bar;
 my $bar = Bar->new(...);
 my $i = Text::Indent->new( Level => 1 );
 print $i->indent("foo");
 $i->increase;
 print $bar->display;
 $i->decrease;
 print $i->indent("baz");
 $i->reset;
 print $i->indent("gzonk");

In Bar.pm:

 package Bar;
 use Text::Indent;
 sub display
 {
   my $i = Text::Indent->instance;
   return $i->indent("bar");
 }

The output from the preceeding example would be (> indicates the left edge
of output and is for illustrative purposes only):

 >  foo
 >    bar
 >  baz
 >gzonk

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003-10 James FitzGibbon.  All Rights Reserved.

This module is free software; you may use it under the same terms as Perl
itself.

=cut

#
# EOF
