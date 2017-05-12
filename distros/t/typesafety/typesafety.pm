package typesafety;

#
# simple static analisys, using the B backend.
#

#
#  But I see little reason to make $! readonly by default. All that       
#  does  is  prevent  clever  people from doing clever things that we haven't thought of yet. And it won't stop stupid people from doing 
#  stupid things.
#  - Larry Wall, Apocalypse 4
#

#
# this program aims to be well documented!
# if you don't understand something, and you've read http://perldesignpatterns.com/?PerlAssembly,
# the source and the comments, the writeups on the end of this file, and the
# perlhack, perlguts, and perlxs manual pages that come with perl, let me know, and i'll
# consider trying to fix the lapse. it is up to you to figure out the right order
# to read those documents in, and it'll probably take a few passes. i'd start with
# perlguts, personally.
#
# if you want to understand this code and you haven't read *all* of those documents, 
# then you're bound to be confused - this stuff is pretty intense.
#

# short-list of outstanding problems:

# o. $self->customer_template->($mail_data) (method returns closure) causes haavok
# o. sub foo { my $self = shift; $self->x } isn't being correctly scanned -- don't remember if it ever
#    assumed that $self was a __PACKAGE__ so I don't know if this is broken or unimplemented or I'm doing it wrong
# o. $ob->{foo} gave an error calling methodob->subscript; need to merge this much of the hashob and methodob 
#    functionality -- logic on and around 901 plus the typeobs
# ....
# o. support for hash style argument lists
# o. support for closures -- arguments and return types
# o. as far as our ->isa() is concerned, a Foo::Bar should isa Bar and vice versa -- this
#    is a crutch for the my Foo::Bar $baz problem.
# o. recognize method calls to methods created by Attribute::Property as typed variables
#    with inferred type. That is, $self->foo = $foo should be logically the same thing as the 
#    hash deref it stands in for, $self->{foo} = $foo. Perhaps this should be a general
#    rule of lvalue methods and subs - whatever types get assigned in come back out.

# bugs fixed this version:
# o. calling Foo::bar, such as with CGI::param(), is unchecked if the package specified isn't in the known universe
# o. skips checking subs/methods imported from other packages

# major outstanding problems - see also Bugs in the POD:

# o. hashes with individual types in each slot - okey, this is kinda bitchy. first instinct
#    is just to wrap the typeob::inferredob inferred type. if there are no overlapping
#    keys then it will never fail and that's bad. second instinct is to autovivicate
#    on the assigned-to side so that inconsistent assigns in the future can be cought.
#    have to autovivicate on both sides maybe. if we took a lesson from arrays, every
#    time the hash was assigned to something else, we'd want to go back and check
#    all of the constraints again with the new data - that's where it starts to get
#    bitchy. guess we could keep an array for emits and accepts and test them against
#    each other but compare hashes instead of primitive types.
#    but that doesn't fix the original problem - when are two hashes different? 
#    two very different hashes can coexist. i guess this is okey as strange as it sounds.
#    as soon as something looks expects a type in a slot and it isn't there we've cought
#    the inconsistency. that means hashes can be composed like objects almost -
#    it can have fields that come from all over the place. several very different
#    hashes can be rolled up in one.
# o. arrays and hashes should be able to contain other arrays and hashes - what was treated
#    as a scalar should be promoted to an arrayob or hashob when it is used as one.
#    this is a general question of references - a padsv is used to get the ref, then rv2av
#    or rv2hv turns that into the desired type. so we have a padsv that is really a 
#    hash or array. guess we just look for the rv2av and rv2hv ops before we look for
#    the padsv op and promote or create of the correct type as necessary.
# o. my Foo::Bar $baz doesn't work - a workaround is mentioned elsewhere. just repeating.
# o. "my Foo $bar" is used by fields.pm as well
# o. <kismet> your module works great if I can expect Foobar $bar to hold the same properties as Foobar $foo :)
#    but you'd need support to allow overrides on Foobar before $foo is setup.
#    something like my Foobar qw/blah baz foof/;  my Foobar $Foo;
#    or:  my FooBar $foo :mutable :persistent :fugly;
# o. aslice. test map and grep - they just might work right now.
# o. Malformed prototype for main::foo: BarBaz;Qux at -e line 1. - we've passed the point of no return.
#    we have to run so we can fix prototypes. we should delay loading code we don't need beyond the basics
#    needed to do ths. otherwise, we could do a compile() routine that runs at perl -MO=Typecheck or something.
# o. $_[0]->[0], $_[0]->{foo} - our data fields aren't typed and they aren't invidually typed. 
#    this would work very nicely with Object::Lexical, but even using O::L, you'd want to 
#    use hash or array fields for data accessable to super/sub classes. when data is assigned,
#    type is ignored and no error is generated, but data cannot be pulled out of our 
#    $self and assigned to a typed scalar or returned from a prototyped method.
#    However, if you never unshift, push, pop, or shift, but only use array indexes, eg $ar[3], and only with constants for indexes, then
#    each element of the array should be considered to have a seperate type so that you can make classes based on arrays
# o. rather than one huge sequence of if statements, solve_type() should dispatch based on
#    op name and/or other information. this is getting massive. a pattern is starting to
#    emerge - most ops just do solve_type(), solve_list_type(), enforce_type(), or enforce_list_type()
#    in some combination on some combination of the first(), last(), and first()->sibling()
#    with different error messages provided where enforce* methods are used.
# o. $expected could be better enforced
# o. typesafety::methodob should handle unshift, pop, push as well as shift and aelem.
# o. tools to generate type API cross references - who accepts what type, what returns what type,
#    and so forth. adding idioms to typesafety.pm to understand 'use base' and 'push @ISA'
#    would help with this.
# o. more tests - test for more bless idioms and do better coverage - checking
#    common types from lists and returns, for example.

# maybe outstanding issues - see also Future Direction in the POD:

# o. provide a typesafety::diagnostics() function that produces diagnostic output for a given
#    scalar. have to make notes from the bytecode tree to pull this off unless we learn how
#    to better navigate pads.
# o. after running, reclaim the memory we've used by undefing everything.
# o. check_args() does: goto OKEY if $rightob->type()->isa($left); - $left is just a string,
#    like FooBar. perhaps it would be helpful to keep a special hash of typeobs by package.
#    the typeob would be a default generic typeob representing the return type of the constructor,
#    not any specific method. in fact, not even that specific, but i can't think of any existing
#    typeob we have floating around more generic.
# o. everything depends on having a pad slot right now - this should be generalized to
#    handle locals. 
# o. private, public, protected, friend protection levels, as well as static. non-static
#    methods aren't callable in packages specified by const, only via padsvs and
#    such. eg, FooBar->bleah() must be prototyped static if prototyped. non-static methods
#    should get a $this that they can make method calls in and has type inferred by how it
#    was used (if $foo->bar() is called, and bar() calls $this->baz(), the type comes from 
#    what $foo was prototyped to hold).
# o. just for fun, we should use ourself (or a copy of ourself) on ourself. we should examplify the code style
#    we're proposing other people use.
# o. lvalues might just work right now - think about it and test. solve_type() hung off of an
#    sassign where substr() evaluates to 'string' would work, for example.
# o. if more than once instance of a given
#    type appears in a row as the last type in an argument list prototype, we can assume that the
#    array will take care of it. P6's globbing symmantics would be useful.
# o. use canned_type('unknown') in more places - atleast default where the context isn't void
# o. OPf_STACKED.
# o. what exactly is padix?
# o. mangle function names using source filters and do method overloading based on those mangled names?
# o. check_types() should be used more often. i think it could remove a lot of code.
# o. something like solve_list_type(), but rather than trying to find the value of everything
#    (as is appropriate for list assignments, argument construction to things like grep, etc),
#    just find the common type from the fall through value and any return values.
#    "a closure, method, subroutine, eval block, or similar was found."
#    this is tricky - we'd have to hack up solve_type() to distinguish between possibly
#    downward propogated types and things that really fall through and return.
#    perhaps a flag in typeob that indicates a calculated type is a returned/last in block.
#    a real understanding of perl's internal stacks and the ops that minipulate them is
#    what is really needed.
# o. pluggable usaging checking modules, sort of like Joel on Software's Hungarian
#    notion example, where deltas and absolute pixel couldn't be directly assigned to
#    each other (that would be a bug) but may be mixed in formulas in certain ways
#    (in this case, deltas can be added to absolute coordinates and maybe subtracted as 
#    well).

# major resolved issues:

# v/ litteral type names in strings - eg, arguments to bless. we might have to track data
#    with completely different heuristics and intentions to see if the first arg to a 
#    constructor gets converted from a possible object reference to a string and then
#    winds up being used as the second arg to bless. argh.
# v/ types.pm allows method prototypes like sub foo (int $bar, string $baz) - amazing! how? steal!
#    insert code into the op tree to create scalars and read arguments specified in the prototype ().
# v/ more method argument handling and bless idioms.
#    unshift on @_ should generate typeobs based on what unshift_prototype() has to say.
#    $_[0] should generate typeobs based on what aelem_prototype() has to say.
# v/ automatic tests!!
# v/ literal system - 'const' creates a typeob with a the literal stored.
#    sassign propogates this value to lexical scalars.
#    solve_lit() knows that a ref of something of a type is the name of that type,
#    it understands 'const', looks for literal information stored in lexicals,
#    understands 'aelemfast' when applied to @_ - $_[0] for all methods and the
#    all of @_ for prototyped methods. all of this is to support bless().
#    constructors should be created with literal set to their type name so the 0th arg to
#    new can be used as a literal to bless.
#    when prototyping constructors (method is new), literal is set to the name of the type -
#    shift_prototype() returns identity for the 0th argument. this way the 0th argument to
#    new() from shift_prototype is considered to be the literal name of that class.
# v/ OPf_STACKED on an op at the current root level means that the previous root level
#    op (and things under it) should be typechecked as an input for the first arg rather than 
#    something under it - i think. ahhh, children places values on the stack and run first,
#    so this is the normal method of getting arguments to an op. not sure if stacked is always
#    set when something takes from the stack, but some ops use a default when they don't
#    take from the stack, and this just lets the op remember whether it is doing the default
#    or using an argument.
# v/ 'return' returns to enclosing method/subroutine call, not the op above it - $expected
#    only tells the type the above op expects! bug! need another currently expected type for
#    the method call. bug!
# v/ arrays- they need to be able to refer to a history of types expected of
#    that type (things assigned *from* it) and a history of things assigned to it.
#    should an inconsistency arise between what is assigned to and what is assigned from,
#    report diagnostics on both. this means that we could assign any type of object and
#    all kinds of non-objects to an array with no problem, until the array is actually
#    used as the source for some type.
#    array pad slots, alem should typecheck to the type of the array
#    ML-style automatic argument type discerning?
#    explicit type-case analysis on a shift etc from an array might be checkable to make sure
#    that all possible array contents types are accounted for in the explicit type-case check.
#    ->type() on an untyped scalar or array that has things in its accept list should return
#    the common type of that list. XXX - this only considers things assigned to the array,
#    not things expected of it, right now. the latter logic could be useful if no information
#    about what is being assigned to it is visible at the time ->type() is called. 
#    ooo need support for shift, pop, unshift, push, grep, map, alem, and so forth
# v/ some array idioms are in place but are untested.
#    need a shift/aassign idiom for reading method arguments - badly.
#    incoming arguments to a method are checked for type, but we lose track of that type
#    going from one CV to another. minimally, two idioms must be recognized:
#    my $foo = shift and my($a, $b, $c) = @_
#    these should fix up the $scalars database, associating the new targs with elements
#    of the method prototype. shift would step through the prototype one thing at a time,
#    advancing to the next each time the idiom is seen. the array assignment would do
#    the whole thing at once. more generally, arrays could be considered to be prototyped
#    just like methods, in addition to just having inferred types. some arrays would
#    be big bags of a base type, others would be sequences of different types.
#    type check incoming arguments as they're used - $_[0], $_[1], $_[2], shift @_, pop @_
#    should all get this treatment. used with a prototype naming actual variables, this
#    gets cleaner.
# v/ need a special typeob to represent "no type at all", such as nextstate would give.
#    need special typeobs to represent int, float, and string.
# v/ there is some confusion between when to pass actual types down or expected types up.
#    from a comment:
#    we currently make no attempt to validate the result type - instead, the expected type is
#    propogated up. this is because solve_list_type() on a raw CV returns a lot of garbage from
#    ops it doesn't understand, whereas propogating it up gives better diagnostics and only
#    checks when and were appropriate.
#    oooh, and it gets worse. sometimes an assignment returns nothing (or its return value isn't used).
#    other times, it is. we have no way of knowing that i can think off. i guess $expected shouldn't
#    propogate so readily.
# v/ if, while, if/elsif/else, foreach, for... we aren't getting into the bodies of these
#    constructs. lineno.pm started to do this.
# v/ array, scalar, and void contexts could tell us whether or not $expected should be set.
#    in perl, pp_wantarray looks something like:
#       cxix = dopoptosub(cxstack_ix);
#       switch (cxstack[cxix].blk_gimme) 
#    is there something in a CV that specifies this? seems like the granularity would be much finer
# v/ argobs must die. all this if($argob->type()) stuff is bullshit. proposal: flag in typeob
#    to indicate whether it is an object or primitive type. clone() method so that diagnostics
#    can be added to types found other routes.
# v/ should call lookup_targ every time we find any sort of pad just so they get defined.
# v/ $scalars entries must be qualified by $curcv
# v/ we should observe *any* unsafe use of scalars we've defined - that means picking raw padsv's out of
#    the blue in the bytecode tree, and warning or dieing. likewise, we should descend through any
#    unknown ops or known ops used on non-type-checked things. should track expected return type, too.
# v/ we must descend into any code references we see defined. they should be pushed onto a 
#    queue, sort of like %knownuniverse.
# v/ functions should be prototyped too - package would obviously default to current package.
# v/ decyphering lists for the padsv on the end still doesn't work. my FooBar $foo :typed = 1; happily runs.
# v/ should we clear $scalars between calls to different methods? i think Perl reuses the pad numbers, so yes.
# v/ we should propogate expected type up as we recurse, if any, or else undef 
#    to make sure that nothing dies for lack of type data when we're just exploring the tree.
#    we're already narrowing down offending code to the statement, but propogating the
#    type information up would narrow it down to the exact place in the expression that
#    type safety was lost. reporting on the top and bottom would be most useful -
#    if a method argument is wrong and it comes from an expression, which arg has the
#    wrong type and at what point in the expression might both be useful. not sure what
#    i'm going to do with this. $expected in solve_type().
# v/ return statements themselves! how could i forget. this whole project was both more complex
#    and easier than expected. easier to do individual things but more things to do. in side of
#    a code block (the loop in check()), if there is a prototype for the code block we're
#    currently doing, make sure all return statements return something of that type.
# v/ implementation badly non-optimal - we scan recursively from each point, but we consider
#    each and every point! we could recurse like we do, but cache opcode=>type like types.pm,
#    or possible start to most deeply nested ops and work outwards, but we might miss prototypes etc.
#    move to tracking return values to and from each seq() number?
#    or, if we're fully recursive, we could walk the op tree ourselves, just going sibling to sibling
#    at the top level, recursing into the depths. yeah, i like that. okey, that's what we've done.
# v/ $a->meth() - $methods{$scalars->{targ of $a}->type()}->{'meth'} should exist, period, or we're trying to
#    call an unprototyped method.
# v/ when multiple things are declared on one line, they each still get their own nextstate.
#    this means we need only process them in the same order. each could link to the next.
#    was being silly about this. now the "declare" subs are just stubs and we extract original
#    data from the bytecode tree.
# v/ drop attributes, perhaps, and use proto() for scalars too. prototype proto():
#    declare FooBar => my $a; 
#    didn't drop attributes, but we added declare().
# v/ use ->sibling() rather than ->next() to skip over sub-expressions when parsing B - in SOME places
# v/ declare() needs B parser logic to back it up
# v/ beware looking for nextstate! makes compound instructions impossible!
# v/ inspect methods in all modules, not just root level main
# v/ CHECK { } is too soon - inserting code into the main tree at CHECK time might be the best solution.
#    scalar attributes and proto() are done runtime, so our check routine would have to be triggered
#    from the end?! just before the main loop? hrm. don't know how this is going to work. manual call
#    for now.

use 5.8.8;
use strict;
no strict 'refs';
use warnings;
our $VERSION = '0.05';

use B;
use B::Generate;

#
# constants
#

use B qw< ppname >;
use B qw< OPf_KIDS OPf_STACKED OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST >;
use B qw< OPpTARGET_MY >;
use B qw< SVf_IOK SVf_NOK SVf_POK SVf_IVisUV >;
sub SVs_PADMY () { 0x00000400 }     # use B qw< SVs_PADMY >;

#
# variables
#

my %knownuniverse; # all known namespaces - our inspection list
my %args;          # use-time arguments
my $debug = 0;     # debug mode flag
our $curcv;        # codevalue to get pad entries from
our $returnvalue;  # typeob expected of returns, if any

my $lastline; my $lastfile; my $lastpack;  # set from COP statements as we go 

#
# debugging
#

use Carp 'confess', 'cluck';
use B::Concise 'concise_cv';

sub debug { my @args = @_; my $line = (caller)[2]; print "debug: $line: ", @args, "\n" if $debug; }

sub nastily () { " in package $lastpack, file $lastfile, line $lastline"; }

# $SIG{__DIE__} =  $SIG{INT} = sub {
#    # when someone does kill -INT <our pid> from the command line, dump our stack and exit
#    print STDERR shift, map { (caller($_))[0] ? sprintf("%s at line %d\n", (caller($_))[1,2]) : ''; } 0..30;
#    print STDERR join "\n", @_;
#    exit 1;
# };

#
# allow user to specify what types ought to be
#

sub import {
  my $caller = caller;
  $args{$_}++ foreach @_;
  $debug = $args{debug};
  push @{$caller.'::ISA'}, 'typesafety'; 
  $knownuniverse{$caller}++; 
  *{$caller.'::proto'} = sub {
     my $method = shift;
     die qq{proto syntax: proto 'foo', returns => 'FooBar', takes => 'FooBar', undef, 'FooBar', 'BazQux', undef, undef, undef;\n}
       unless 'returns' eq shift; 
     my $type = shift;
     my $takes = [];
     if(@_) {
       die unless 'takes' eq shift; 
       $takes = [ @_ ];
     }
     (undef, my $filename, my $line) = caller(0); # XX nasty hardcode
     die "filename" unless $filename; die "line" unless $line;
     my $typeobject = typesafety::methodob->new(
          type=>$type, package=>$caller, filename=>$filename, line=>$line, 
          name=>$method, desc=>'prototyped method', takes=>$takes,
     );
     $typeobject->literal = $type if $method eq 'new'; # shift_prototype() for new() returns identity. bless looks for lit in this.
     define_method($caller, $method, $typeobject);
  };
  *{$caller.'::declare'} = sub :lvalue { 
    $_[1] 
  };
  return 1;
}

#
# data structures
#

{

  my $methods;       # $methods->{$package}->{$methodname} = typeob
  my $scalars;       # $scalars->{$curcv}->{$targ} = typeob

  sub lookup_method {
    my $package = shift;
    my $method = shift;
    return exists $methods->{$package} if ! defined $method;
    return $methods->{$package}->{$method} if defined $package and defined $method and exists $methods->{$package} and exists $methods->{$package}->{$method};
    return undef;
  }

  sub lookup_type {
    # like lookup_method, but concerned with the fundamental type. for now, we're using the return value of
    # new() in that package, and inferring it if we must.
    my $typename = shift;
    debug("lookup_type called for @{[ $typename || '(undef)' ]}");
    return lookup_method($typename, 'new') || typesafety::methodob->new(type=>$typename, desc=>'generic package type', literal=>$typename);
  }
  
  sub define_method {
    my $package = shift;
    my $method = shift;
    my $typeob = shift;
    $methods->{$package}->{$method} = $typeob;
    return $typeob;
  }
  
  sub lookup_targ {

    my $targ = shift;

    return $scalars->{$curcv}->{$targ} if exists $scalars->{$curcv} and exists $scalars->{$curcv}->{$targ};

    # assume first usage and infer type if possible
    # record that for future lookup

    my $name = (($curcv->PADLIST->ARRAY)[0]->ARRAY)[$targ];  # from B::Concise

    # from perlguts:
    #        One can deduce that an SV lives on a scratchpad by looking on its flags: lexicals
    #        have "SVs_PADMY" set, and targets have "SVs_PADTMP" set.
    # this doesn't seem to be accurate - doing my WrongType $wt2, this claims that $wt2 isn't PADMY

    # debug("lookup_targ: ", $name->sv(), " is not a PADMY") unless $name->FLAGS() & SVs_PADMY;
    # return undef unless $name->FLAGS() & SVs_PADMY;

    # $name is a PVMG - a magic pointer. perlguts illustrated at http://gisle.aas.no/perl/illguts/ has to say about PVMGs:
    # The SvPVMG is like SvPVNV above, but has two additional fields; MAGIC and STASH. MAGIC is a pointer to additional 
    # structures that contains callback functions and other data. ...  STASH (symbol table hash) is a pointer to a HV 
    # that represents some namespace/class. (That the HV represents some namespace means that the NAME field of the HV 
    # must be non-NULL. See description of HVs and stashes below). The STASH field is set when the value is blessed into 
    # a package (becomes an object). The OBJECT flag will be set when STASH is. (IMHO, this field should really have 
    # been named "CLASS". The GV and CV subclasses introduce their own unrelated fields called STASH which might be confusing.)

    # "main" is the default type should no other type be specified. we're only intersted in scalars that have types
    # specified, for now. eg: my FooBar $foo. later, though, we may attempt to track all of the different things expected of a scalar
    # in the default package and everything assigned to it. arrays, too.

    # from B::Concise.pm - $padname is our $name:
    #        if ($padname->FLAGS & SVf_FAKE) {
    #            my $fake = '';
    #            $fake .= 'a' if $padname->IVX & 1; # PAD_FAKELEX_ANON
    #            $fake .= 'm' if $padname->IVX & 2; # PAD_FAKELEX_MULTI
    #            $fake .= ':' . $padname->NVX if $curcv->CvFLAGS & CVf_ANON;
    #            $h{targarglife} = "$h{targarg}:FAKE:$fake";
    #        }
    #        elsif(defined $padname) { # sdw 2003
    #            my $intro = $padname->NVX - $cop_seq_base;
    #            my $finish = int($padname->IVX) - $cop_seq_base;
    #            $finish = "end" if $finish == 999999999 - $cop_seq_base;
    #            $h{targarglife} = "$h{targarg}:$intro,$finish";
    #        }
    # B::Concise prints out [t9] for 'temporary pad 9'. Something is temp when its class is 'SPECIAL'.
    # But where and why does its class set to SPECIAL? What is tested? Above is the non-special case.
    # Ahah!
    # From the perl source in the pad.c file:
    #   Iterating over the names AV iterates over all possible pad
    #   items. Pad slots that are SVs_PADTMP (targets/GVs/con-
    #   stants) end up having &PL_sv_undef "names" (see
    #   pad_alloc()).
    # And lots of other great notes.

    my $type;
    $type = $name->SvSTASH->NAME if $name->can('SvSTASH');

    if( ! $type or $type eq 'main' ) {
      return $scalars->{$curcv}->{$targ} = typesafety::scalarob->new(
        type=>'none', desc=>'non-type-checked scalar', pad=>$targ, 
        # name=>$name->sv(),
        name=>$name->PVX(),
        package=>$lastpack, filename=>$lastfile, line=>$lastline,
      );
    }

    # since we've never seen this lexical in this context before, we assume that it is new, and this is its first
    # usage. record the information for the current point in the perl program we're crawling.

    # highly experimental -- 'XX' gets transmorgified to '::' since '::' can't appear in my declarations
    # $type =~ s/XX/::/g; # no, this doesn't work -- Perl says 'no such class' when the package doesn't exist
    # can't just use the last part (eg, Bar in Foo::Bar) and guess the rest either for the same reason

    return $scalars->{$curcv}->{$targ} = typesafety::scalarob->new(
        type=>$type, desc=>'scalar variable named', pad=>$targ, name=>$name->PVX(), # name=>$name->sv(), # XXX highly experimental 000
        package=>$lastpack, filename=>$lastfile, line=>$lastline, 
    );

  }

  sub lookup_array_targ {
    # this is used on arrays - we can't hope to find type information for, but we want to
    # keep a record of it anyway. still must be lexical.
    # the lookup_targ() just spares us the bother of looking things up that are already defined.
    my $targ = shift;
    return $scalars->{$curcv}->{$targ} if exists $scalars->{$curcv} and exists $scalars->{$curcv}->{$targ};
    my $ret = $scalars->{$curcv}->{$targ} = typesafety::arrayob->new(
        pad=>$targ, name=>lexicalname($targ), desc=>'array variable named',
    );
    $debug and print "debug: ", __LINE__, ": lookup_array_targ: created this: ", $ret->diagnostics(), "\n";
    return $ret;
  }

  sub lookup_hash_targ {
    my $targ = shift;
    return $scalars->{$curcv}->{$targ} if exists $scalars->{$curcv} and exists $scalars->{$curcv}->{$targ};
    my $ret = $scalars->{$curcv}->{$targ} = typesafety::hashob->new(
        pad=>$targ, name=>lexicalname($targ), desc=>'hash variable named',
    );
    $debug and print "debug: ", __LINE__, ": lookup_hash_targ: created this: ", $ret->diagnostics(), "\n";
    return $ret;
  }
  
  sub summary {
    # give a nice report of what we did
    print "typesafety.pm status report:\n";
    print "----------------------------\n";
    foreach my $cv (values %$scalars) {
      foreach my $typeob (values %$cv) {
        print $cv->diagnostics(), "\n";
      }
    }
  }

  my $cannedtypes = {
    none      => typesafety::typeob->new(type => 'none',     desc => "construct doesn't return any value at all"), 
    unknown   => typesafety::typeob->new(type => 'unknown',  desc => "construct returns a value -- probably -- but what, we aren't sure"),
    constant  => typesafety::typeob->new(type => 'constant', desc => 'constant value'), 
    int       => typesafety::typeob->new(type => 'int',      desc => 'integer value'),  
    float     => typesafety::typeob->new(type => 'float',    desc => 'floating point value'), 
    string    => typesafety::typeob->new(type => 'string',   desc => 'string value'), 
    # inferred  => typesafety::inferredob->new(                desc => 'type inferred from usage'),
  };

  *canned_type = sub {
     confess unless exists $cannedtypes->{$_[0]};
     return $cannedtypes->{$_[0]};
  };

}

#
# verify that types are what the user specified
#

sub check {

  # this is the heart of this module.
  # we grok the bytecode, looking for signiture pattern, and extract information
  # from them. when a pattern is found, we update internal information, or
  # else test internal information to see if something is "safe".

  $knownuniverse{$_}++ for @_; # users can pass in names of namespaces to add to the check list

  foreach my $package (keys %knownuniverse) {
    foreach my $method (grep { defined &{$package.'::'.$_} } keys %{$package.'::'}) {

      # we're looking for things in the code like this: 
      # sub foo (FooBar; BazQux, FooBar, undef) {  }
      # this is based on Arthur Bergman's code in types.pm. i bastardized it - typesafety.pm is no where near as elegant.

      my $cv = B::svref_2object(*{$package.'::'.$method}{CODE});

      if($cv->FLAGS & SVf_POK) {

          # ab: we have, we have, we have arguments

          my $sig = $cv->PV;
          my @prot;
          my $returns;

          $sig =~ m/(?:\w+;)|(?:,)/ or do {
              *{$package.'::proto'}{CODE}->($method, 'returns', undef, 'takes', undef);
              return;
          };

          ($returns, $sig) = $sig =~ m/^\s*(\w+);(.*)/;
          $returns = undef if $returns eq 'undef';

          foreach my $type (split /\s*,\s*/, $sig)  {
              no warnings 'uninitialized';
              debug("method signature: $package $method returns $returns - next arg: $type");
              $type = undef if $type eq 'undef';  
              push @prot, $type;
          }

          # proto syntax: proto 'foo', returns => 'FooBar', takes => 'FooBar', undef, 'FooBar', 'BazQux', undef, undef, undef;

          # debug("prototype: method: ``@{[ $method||'undef' ]}'' returns: ``@{[ $returns||'' ]}'' takes: ``@{[ @prot ? join ', ', map $_||'(undef)', @prot : '(nothing)' ]}''"); # argh!! and still uninitialized errors!?
          no warnings 'uninitialized';
          debug("prototype: method: ``$method'' returns: ``$returns'' takes: ``@prot''");

          *{$package.'::proto'}{CODE}->($method, 'returns', $returns, 'takes', @prot);

          $cv->PV(";@");
      }

    }
  }

  # check the main area first - it may set things up that are in the scope of methods defined later
  # this is where we actually start to crawl the bytecode, yay!

  $returnvalue = undef;

  $curcv = B::main_cv();
  B::main_root->name ne 'null' and solve_list_type(B::main_root()->first(), undef); # denull doesn't help...? when does this happen?

  # each package that has used us, check them as well

  # generate prototypes for each method that has a method signature as a first pass
  # before doing actual type-checking

  foreach my $package (keys %knownuniverse) {
    foreach my $method (grep { defined &{$package.'::'.$_} } keys %{$package.'::'}) {

      next if $method eq 'proto';
      next if $method eq 'declare';

      # STDERR->print("debug: ************ stashname: ", B::svref_2object(*{$package.'::'.$method}{CODE})->STASH()->NAME(), "\n");
      next if B::svref_2object(*{$package.'::'.$method}{CODE})->STASH()->NAME() ne $package; # skip code imported from elsewhere


      debug("checking $package\::$method");

      # return statements out of methods are expected to return a certain type, as are fall-through values.

      # debug("knownuiverse: method: $method");

      my $cv = *{$package.'::'.$method}{CODE};
      $curcv = B::svref_2object($cv);
      B::svref_2object($cv)->ROOT() or die;

      # $debug and concise_cv(0, $cv); # dump the opcode tree of this code value
      # B::Concise::walk_topdown($curcv->ROOT(), sub { $_[0]->concise($_[1]) }, 0);

      my $expected = lookup_method($package, $method);

      debug("method is prototyped as: ", $expected ? $expected->diagnostics() : 'not prototyped');

      # shifts done on @_ return objects typed consistent with the prototype
      # value that "return" statements should return - $expected changes as we go down the op tree, but $returnvalue covers the whole method
      $returnvalue = $expected;
      $returnvalue ||= lookup_type($package) if $method eq 'new';
      $returnvalue->reset_prototype() if $returnvalue; 

      # enforce_list_type(B::svref_2object($cv)->ROOT()->first(), $expected, 'method return type is prototyped');
      solve_list_type(B::svref_2object($cv)->ROOT()->first(), $expected);

    }
  }

  summary() if(exists $args{summary}); 

}

#
# deduce type given an opcode
#

sub solve_type {

  # what type does an expression return? 

  # this is called for each opcode at the root level of the program, where it recurses
  # to the depths of that node.
  # when an assignment is found, this is called for each of the right and left sides.
  # when a prototyped method call is found, this is called for each argument to that method call.
  # called and recursively by ourself, and indirectly recursively by ourselves by way of
  # solve_list_type() and check_args(), which we call.

  # $expected, the second arg, changes our role from merely solving which type something
  # returns to enforcing that things return that type. we're able to more intelligently
  # do this than something looking at our return data.

  # failure dies. 
  # success returns typesafety::argob object representing the result and the where 
  # bytetree scanning left off.
  # success is easily won when no particular type is expected.

  my $self = shift;
  my $expected = shift;

  my $want = $self->flags() & OPf_WANT;

  $debug && $expected and print "debug: ", __LINE__, ": expected true going into solve_type(): ", $expected->diagnostics(), "\n";

  debug('solve_type: op: ', $self->name());

  #
  # XXXX 
  #

  if($want == OPf_WANT_VOID) {
    # highly experimental XXX
    # if we impose void context, then we and none of our children can or will return anything. 
    # if we're trying to solve a list, then this op just doesn't contribute to this list - not undef, nothing. 
    $expected = undef;
  }

  #
  # simple and recursive
  #

  # null - ops that were optimized away

  if($self->name() eq 'null' and
     $self->can('targ') and
     $self->flags & OPf_KIDS and
     $self->first() 
  ) {
    debug("null type: ppname: ", $self->can('targ') ? ppname($self->targ()) : 'unknown');
    debug("null op has kids, first is: ", $self->first()->name());
    # return solve_type($self->first(), $expected); # XXX - if first child is an ex-list, this is completely worthless
    return solve_list_type($self->first(), $expected);
  }

  # c           <|> cond_expr(other->d) lK/1 ->h
  # b              <2> modulo[t3] sK/2 ->c
  # 9                 <1> int[t2] sK/1 ->a
  # 8                    <1> rand[t1] sK/1 ->9
  # 7                       <$> const(IV 5) s ->8
  # a                 <$> const(IV 2) s ->b
  # d              <$> const(PV "hi") s ->e
  # h              <$> const(PV "there") s ->e

  if($self->name() eq 'cond_expr') {
    # an if() or ? : - the condition doesn't return anthing but should be examined for buried use of types.
    # the two blocks must both return the expected type, if any. yes - there are always two blocks -
    # if there were only one, this would be reduced to an 'and' instruction.
    # XXX - in the case of if(0), only the second block should be checked, and if(1), only the first.
    solve_type($self->first(), undef);
    enforce_type($self->first()->sibling(), $expected);
    enforce_type($self->first()->sibling()->sibling(), $expected);
  }

  # for(my $i = 1..20) { print $i, "\n"; }

  # j     <2> leaveloop vK/2 ->k
  # a        <{> enteriter(next->g last->j redo->b) lK ->h
  #             ..... condition goes here
  # -        <1> null vK/1 ->j
  #             ..... body goes here

  if($self->name() eq 'leaveloop') {
    # we don't expect that a for() loop returns anything, but we should check inside of it and the conditional.
    # which is the first thing at the beginning of the body. how bizarre.
    # sdw -- 2005 -- unknown subroutine check_list_type()
    # check_list_type($self->first(), undef); 
    # check_list_type($self->first()->sibling(), undef); 
    solve_list_type($self->first(), undef); 
    solve_list_type($self->first()->sibling(), undef); 
  }

  if($self->name() eq 'and') {
    enforce_type($self->first(), undef);
    enforce_type($self->first()->sibling(), $expected);
  }

  if($self->name() eq 'or') {
    enforce_type($self->first(), $expected);
    enforce_type($self->first()->sibling(), $expected);
  }

  # nextstate

  # 2     <;> nextstate(main 494 test.pl:32) v ->3

  if($self->name() eq 'nextstate') {

    # record where we are in the program - we use this information to relate bytecode
    # information with information recorded from attributes at compile time.

    $lastpack = $self->stash()->NAME();
    # $lastpack = 'XXX';
    $lastfile = $self->file();
    $lastline = $self->line();

    $debug and print "debug: ", join ' ', '-' x 20, $lastline, $lastfile, $lastpack, '-' x 20, "\n";

    return canned_type('none');

  }

  if($self->name() eq 'pushmark') {
    return canned_type('none');
  }

  # const

  if($self->name() eq 'const') {
    # very simple case
    debug('const');
    debug("going to look at sv");
    # my $sv = $self->sv;
    my $value; 
    $value = eval { $self->sv->sv }; $@ and $value = '(unknown constant value)';

    # this mess got written trying to solve the "I am sorry but we couldn't find this root!" B::Generate error
    # but it looks like the $foo->{bleah}->foo construct just plays haavok with B::Genreate's presentation of the const op
    #if($sv->isa("B::IV")) { $value = $sv->int_value; debug("B::IV"); }
    #elsif($sv->isa("B::NV")) { $value = $sv->NVX; debug("B::NV"); }
    #elsif($sv->isa("B::RV")) { $value = $sv->RV; debug("B::RV"); }  # XXX this is meaningless
    #elsif($sv->isa("B::PV")) { $value = $sv->PV; debug("B::PV"); }
    #elsif($sv->isa("B::GV")) { $value = $sv->SV->sv; debug("B::GV"); }  # XXX this one needs to recurse rather do ->sv()
    #elsif($sv->isa("B::PV")) { $value = $sv->PV; debug("B::PV"); }
    #elsif($sv->isa("B::PVIV")) { $value = $sv->PV; debug("B::PVIV"); } # B::PVIV is a subclass of B::PV
    #else { $value = $self->sv; debug("B:: whatever... default..."); } # not sure when this case runs
    ## B::IO, B::AV, B::HV, others not delt with at all -- don't think it's possible to use them with const

    # $self->sv->sv is fine with things like <<const(PV "foo") s>> but hates things like <<const(PVIV "credit_card_number") s/BARE>>
    # trying PV instead of PVX or SV

    my $type = canned_type('constant')->clone(sprintf q{'%s', }, $value);
    $type->literal = $value;
    return $type;

    # this that don't work in all cases:
    # my $type = canned_type('constant')->clone(sprintf q{'%s', }, $self->sv()->sv()); 
    # my $type = canned_type('constant')->clone(sprintf q{'%s', }, $self->sv()->PVX()); # XXX highly experimental 000 # oops, didn't fly: Can't locate object method "PVX" via package "B::IV"
    # $type->literal = $self->sv()->sv(); # $type->literal = $self->sv()->PVX(); -- same as above
  }

  # lexicals

  if($self->name() eq 'padsv') {
    # simple case
    # $debug and print "debug: ", __LINE__, ": padsv\n";
    return lookup_targ($self->targ()); 
  }

  if($self->name() eq 'padav') {
    # array on the pad
    # it will never happen that we find type info for an array - perl doesn't allow this. we must infer types.
    # for(lookup_array_targ($self->targ())) {
    #   debug("padav: official type: ", $_ ? $_->type() : 'no type info');
    #   debug("padav: type of typeob object found: ", $_ ? ref($_) : 'none found');
    # }
    return lookup_array_targ($self->targ());
  }

  if($self->name() eq 'padhv') {
    # hash on the pad
    # we don't find type information already associated with a hash when the hash is first found either.
    return lookup_hash_targ($self->targ());
  }

  # stacked - XXX - todo

  if($self->flags() & OPf_STACKED) {
    # XXX
    debug("oh, by the way, found an BINOP that is STACKED: ", $self->name());
  }

  #
  # return
  #

  # return 1, 2, 3, 4;

  # 8     <@> return K ->9
  # 3        <0> pushmark s ->4
  # 4        <$> const(IV 1) s ->5
  # 5        <$> const(IV 2) s ->6
  # 6        <$> const(IV 3) s ->7
  # 7        <$> const(IV 4) s ->8

  if($self->name() eq 'return') {
    # the pushmark seems to always be there - even on an empty return. yes, the return op has the needs mark bit in ops.h/opcodes.pl.
    # individual items in the list vary, of course.
    # return is special because each and every return's type must jive with the methods prototyped type. 
    # my $return = solve_list_type($self->first()->sibling(), $returnvalue);
    debug("return: expecting ", $returnvalue->diagnostics()) if $returnvalue;
    return enforce_list_type($self->first()->sibling(), $returnvalue, 'improper return value');
  }

  #
  # shift, push, pop, unshift, alem, etc
  # 

  # track which types are assigned, shifted, pushed, spliced into/onto arrays

  # <1j>shift---<1i>rv2av[t2]---<1h>gv(*_)

  if($self->name() eq 'shift') {{
    # special case - reading arguments off of @_ using shift
    last unless $self->flags & OPf_KIDS;
    last unless $self->first;
    last unless $self->first->name eq 'rv2av'; 
    last unless $self->first->flags & OPf_KIDS;
    last unless $self->first->first;
    last unless $self->first->first->name eq 'gv';
    last unless $self->first->first->gv->NAME eq '_'; # as in @_
    debug("shift-rv2av-gv construct - found the signature, but there is no returnvalue specified") unless $returnvalue; # XXX - perhaps we should just lookup_type() here ourselves and fudge it?
    last unless $returnvalue;
    my $ret = $returnvalue->unshift_prototype();
    debug("shift-rv2av-gv construct - called unshift prototype, got: ", $ret->diagnostics());
    # return $returnvalue->unshift_prototype();
    return $ret;
  }}

  # d        <2> aelem sK/2 ->e
  # b           <0> padav[@a:1,2] sR ->c
  # c           <$> const(IV 1) s ->d

  # b        <1> shift sK/1 ->c
  # a           <0> padav[@a:1,3] lRM ->b

  if($self->name() eq 'shift' or $self->name() eq 'pop' or $self->name() eq 'aelem') {

    # dumb case - the array is our single child.   
    # this should be redundant with the generic UNOP/BINOP/LISTOP handling at the end - is it? almost - we propogate $expected,
    # but the generic case should too! XXX

    debug("aelem/pop/shift: we've decided the array type is: ", solve_type($self->first())->diagnostics());

    return enforce_type($self->first(), $expected, 'wrong array type');

  }

  if($self->name() eq 'aelemfast') {{
    # index is in ->private(), the array itself in ->sv(). how so very CISC. 
    # aelemfast will never reference a pad - aelem will happily accept a padav, though. this is only useful
    # for accessing method arguments.
    # few! this works - gv() does all of the padix() magic for us
    # debug("aelemfast: gv stash name: ", $self->gv()->STASH()->NAME()   );  # main
    # $returnvalue is the typeob for the current method, constructed from the method prototype. it contains
    # the list of types we accept as arguments.
    last unless $returnvalue;
    last unless $self->gv()->NAME() eq '_'; # as in @_
    last unless $returnvalue;
    return $returnvalue->aelem_prototype($self->private());
  }}

  # h     <@> push[t7] vK/2 ->i
  # e        <0> pushmark s ->f
  # f        <0> padav[@a:1,3] lRM ->g   <-- array type, here only
  # g        <0> padsv[$b:2,3] l ->h     <-- list type, here on down

  if($self->name() eq 'unshift' or $self->name() eq 'push') {

    # solve the type of the list after the first real arg; ->accept() that type into the array; return the type of the array

    my $arraytype = solve_type($self->first()->sibling()); 
    my $listtype = solve_list_type($self->first()->sibling()->sibling());
    $arraytype->accept($listtype);
    return $arraytype;

  }

  # h        <2> helem sK/2 ->i
  # f           <1> rv2hv[t2] sKR/1 ->g
  # e              <0> padsv[$hash:1,2] sM/64 ->f
  # g           <$> const(PVIV "1") s ->h

  if($self->name() eq 'helem') {
    my $type = solve_type($self->first()); # gets us a typeob, probably a hashob
    ($type->can('stuff') and $type->stuff() eq 'hashob') or return canned_type('unknown'); # XXX highly experimental -- $ob->{foo} was screwing up
    my $subscript = solve_lit($self->last()); # gets us constant index hopefully
    debug('helem: diagnostics: ', $type->diagnostics());
    debug('helem: constant subscript: ', $subscript) if $subscript;
    if($subscript) {
      $type->subscript($subscript) ||= 
        typesafety::inferredob->new(type=>undef, package=>$lastpack, filename=>$lastfile, line=>$lastline, desc=>"$subscript hash key", name=>$subscript);
      return $type->subscript($subscript);
    } else {
      return enforce_type($self->first(), $expected, 'wrong type in hash'); 
    }
  }
 
  #
  # pattern match ops
  #

  if(ref($self) eq 'B::PMOP' and $self->pmreplroot() && ${$self->pmreplroot()}) {
    # s///e
    # a code block is attached to the pattern match operation. code adapted from types.pm.
    # substring
    # XXX untested, probably wrong
    # XXX multiple concurrent pads required - have to index $scalars by $curcv as well as $targ
    local $curcv = $self->pmreplroot(); 
    return solve_list_type($self->pmreplroot(), $expected);
  }

  #
  # closures 
  #

  # sub { print "hi\n"; }->();

  # 8  <@> leave[&:-586,-588] vKP/REFC ->(end)
  # 1     <0> enter ->2
  # 2     <;> nextstate(main 2 -e:1) v ->3
  # 7     <1> entersub[t2] vKS/TARG,1 ->8
  # -        <1> ex-list K ->7
  # 3           <0> pushmark s ->4
  # -           <1> ex-rv2cv K/1 ->-
  # 6              <1> refgen sK/1 ->7
  # -                 <1> ex-list lKRM ->6
  # 4                    <0> pushmark sRM ->5
  # 5                    <$> anoncode[CV ] lRM ->6

  # anoncode's t_arg is an index into the padlist for the current cv. at that index is a CV.

  if($self->name() eq 'anoncode') {
    # XXX untested
    # XXX Perl6::Contexts does this right -- we do it wrong
    my @padlist = $curcv->PADLIST->ARRAY->ARRAY; # voodoo based on logic in B::Utils
    local $curcv = $padlist[$self->targ()];
    solve_type($curcv->ROOT, $expected);
  }

  #
  # real code and constructs
  #

  #
  # blessing and other constructor idioms
  # 

  # bless {}, "FooBar";

  # 7     <@> bless vK/2 ->8
  # -        <0> ex-pushmark s ->3
  # 5        <1> srefgen sK/1 ->6
  # -           <1> ex-list lKRM ->5
  # 4              <@> anonhash sKRM ->5
  # 3                 <0> pushmark s ->4
  # 6        <$> const(PV "FooBar") s ->7

  if($self->name() eq 'bless') {
    # first arg doesn't matter, though we could scream if it seems like something is being reblessed. 
    # reblessing would really muck up the works.
    # there is always a pushmark or ex-pushmark: ignore it. then the reference. then an optional type.
    my $op = $self->first(); 
    my $ref = denull($op->sibling());
    my $typeop = denull($op->sibling()->sibling());
    my $type;
    debug("bless: 2nd and 3rd args: ", $ref->name(), ' ', $typeop->name());
    if(! $$typeop) {
      # single argument bless defaults to blessing into current package
      $type = $lastpack;
    } else {
      $type = solve_lit($typeop); # - aelem and aelemfast and shift on @_
      $type or die "typesafety.pm isn't currently able to infer the type of the about to be created" . nastily;
      $type or return canned_type('unknown')->clone('bless but not one of the supported idioms - I suck');
    }
    # XXX else, is this scalar a special one that contains ref $_[0]?
    return typesafety::typeob->new(type=>$type, package=>$lastpack, filename=>$lastfile, line=>$lastline, desc=>'type as returned by constructor');
  }

  #
  # method and function calls
  #

  # bar->new();

  # 9        <1> entersub[t2] sKS/TARG ->a          <--- this is the node passed to us in this case
  # 3           <0> pushmark s ->4
  # 4           <$> const(PV "bar") sM/BARE ->5
  # 5           <$> const(IV 1) sM ->6
  # 6           <$> const(IV 2) sM ->7
  # 7           <$> const(IV 3) sM ->8
  # 8           <$> method_named(PVIV "new") s ->9

  if($self->name() eq 'entersub') {

     # is it a constructor call on a constant type? 
     # these are self-typing. abstract factories shouldn't use constructors for their dirty work.

     # print "debug: entersub (constructor?), line $lastline\n" if $debug;

     my $op = $self->first();

     # XXX this is probably needed in a thousand places in this program, not to mention recursive application
     $op = denull($op);

     my $type;
     my $success = 0;
     my $argop;

     foreach my $test (
       sub { $op->name() eq 'pushmark' },
       # sub { return unless $op->name() eq 'const'; $type = $op->sv()->sv(); return 1; }, # XXX highly experimental 000
       sub { return unless $op->name() eq 'const'; $type = $op->sv()->PVX(); return 1; },
       sub {
         while($op->name() ne 'method_named' and $op->name() ne 'null') {
           # seek past method call arguments but remember the opcode of the first argument.
           $argop ||= $op;
           $op = $op->sibling();
         }
         return unless $op and $op->name() ne 'null'; 
         return unless $op->sv()->PVX() eq 'new'; 
         $success = 1; 
         $debug and print "debug: success\n";
       },
     ) {
       debug("bar->new(): considering: ", $op->name());
       last unless $test->(); 
       $op = $op->sibling() or last;
     }

     if($success) {
       debug("success! found constructor for type $type");
       debug("but what we really want is a ", $expected->diagnostics()) if $expected;
       return check_args($argop, $type, 'new');
       # return lookup_method($type, 'new'); # just not the same thing for some reason - huh
     }

  }

  # package FooBar; foo('BazQux');

  #   `-<6>entersub[t1]---ex-list-+-<3>pushmark
  #                               |-<4>const(PV "BazQux")
  #                               `-ex-rv2cv---<5>gv(*FooBar::foo)

  # case, when the method is known and perl references the gv directly

  # XXX stumbles on this case, where a closure is invoked:
  # i     <2> sassign vKS/2 ->j
  # g        <1> entersub[t6] sKS/TARG,1 ->h
  # -           <1> ex-list sK ->g
  # d              <0> pushmark s ->e
  # e              <0> padsv[$mail_data:4,6] lM ->f
  # -              <1> ex-rv2cv sK/1 ->-
  # f                 <0> padsv[$mail_template:3,6] s ->g
  # h        <0> padsv[$msg:5,6] sRM*/LVINTRO ->i

  if($self->name() eq 'entersub') {

     my $op = denull($self->first());

     my $type;
     my $method;
     my $success = 0;
     my $argop;

     foreach my $test (
       sub { $op->name() eq 'pushmark' },
       sub {
         while($$op) {
           # seek past method call arguments but remember the opcode of the first argument.
           if($op->name() eq 'null' and ! ${$op->sibling()} and pppname($op) eq 'pp_rv2cv') {
             # no next op, and this current op s an optimized away rv2cv
             # XXX is ->gv()->sv() the way to get at the value in <5>gv(*FooBar::foo)? seems to work
             # XXX can we safely assume $lastpack if we can't find :: in the name?
             # debug - confess
             $op->first()->name eq 'padsv' and return undef; # XXX this is the closure-invoking case we're not currently dealing with
             ($type, $method) = $op->first()->gv()->sv() =~ m{^\*(.*)::([^:]+)$} or confess;  
             $debug and print "debug: ", __LINE__, ": we think we have a function call - package $type function $method\n";
             return if $method eq 'proto'; # XXX
             $success = 1;
             return 1;
           }
           $argop ||= $op;
           $op = $op->sibling();
         }
         return;
       },
     ) {
       $debug and print "debug: ", __LINE__, ": foo() - normal function call: considering: ", $op->name(), "\n";
       last unless $test->(); 
       $op = $op->sibling() or last;
     }

     return check_args($argop, $type, $method) if $success and exists $knownuniverse{$type};

  }

  # $a->bar();

  # this one is tricky. we have to get $a's type to get bar's package to see if that matches $b's type.

  # k        <1> entersub[t4] sKS/TARG ->l       <--- this node is the one given to us
  # c           <0> pushmark s ->d
  # d           <0> padsv[$a:3,5] sM ->e         .... may not be a padsv - should use solve_type()! XXX
  # e           <$> const(IV 5) sM ->f           <--- from here until we hit the method_named op,
  # f           <$> const(IV 4) sM ->g                we these are processed by check_args() for type safety. 
  # g           <$> const(IV 3) sM ->h                the first argument gets held by $argop.
  # h           <$> const(IV 2) sM ->i
  # i           <$> const(IV 1) sM ->j
  # j           <$> method_named(PVIV "bar") s ->k

  if($self->name() eq 'entersub') {

     # print "debug: entersub (method call on typed object)\n" if $debug;

     my $op = $self->first();
     my $method;   # bar, in "$a->bar()"
     my $targ;     # $a, in "$a->bar()", gets us this from its typeob
     my $success = 0;
     my $argop;    # pointer to opcode representing first argument

     foreach my $test (
       sub { $op->name() eq 'pushmark' },
       sub { return unless $op->name() eq 'padsv'; $targ = $op->targ(); return 1; }, 
           # XXX - instead of just a targ holding the object ref, this could be an expression! XXX recurse
       sub { 
         while($op and $op->name() ne 'method_named') {
           $argop ||= $op;
           $op = $op->sibling();
         }
         return unless $op and $op->name() eq 'method_named'; 
         # whoops, busted. new in 5.9.0 apparently method names contain additional binary info after \0000.
         # $method = $op->sv()->sv();                               # bar, in "$b = $a->bar()"
         $method = $op->sv()->PVX();                               # bar, in "$b = $a->bar()"
         $success = 1;
       },
     ) {
       print "debug: ", __LINE__, ": considering: ", $op->name(), "\n" if $debug;
       last unless $test->(); 
       $op = $op->sibling() or last;
     }

     if($success) {

       if(! lookup_targ($targ)) {
          confess 'missing type information for ' . lexicalname($targ) . 
                  " in expression that should return " . $expected->diagnostics() . nastily if $expected;
       } else {
         debug(lookup_targ($targ)->diagnostics());
         my $type = lookup_targ($targ)->type() or die nastily;          # $a, from "$b = $a->bar()"
         if($type ne 'none') {
             lookup_method($type, $method) or die "unknown method '$method' in class '$type' " . nastily;
             # lookup_method($type) or die 'unknown package: ' . $type . ' ' . nastily;
             return check_args($argop, $type, $method);
         # I think this will just kinda happen by default if nothing else in solve_type() recognizes the construct
         # } else {
         #     canned_type('unknown');
         }
       }

     }

  }

  # sassign
  # aassign
  # binops that target pads

  if($self->name() eq 'sassign' or
     $self->name() eq 'aassign' or
     (ref($self) eq 'B::BINOP' and $self->private() & OPpTARGET_MY)
  ) {{

    $debug and print 'debug: ', __LINE__, ": considering ", $self->name(), " at line $lastline\n";

    # the left hand side is what is being assigned to. if it isn't type-checked,
    # then type checking isn't in effect on this statement.
    # this refers to the side of the assign operator being applied to us.

    # in case of aassign (array assign, one list is assigned to another):
    # instead of calling solve_list_type() as might make sense, we instead just call
    # solve_type(), as either of the lists may have been optimized away, and solve_type()
    # handles this general case, kicking over to solve_list_type() as needed.

    # XXX - is the OPpTARGET_MY flag valid for all BINOPs?

    debug("sassign/aassign/binop-target-my: expected is true: ", $expected->diagnostics()) if $expected;

    my $left = solve_type($self->last(), $expected) or confess $self->last()->name(); 

    $debug and print 'debug: left diagnostics: ', $left->diagnostics(), 
                     ' opname: ', $self->last()->name(), ' ',
                     " at line $lastline.\n";

    my $right = solve_type($self->first(), $expected) or confess $self->first()->name();

    $debug and print 'debug: right diagnostics: ', $right->diagnostics(), 
                     ' opname: ', $self->first()->name(), ' ',
                     " at line $lastline.\n";

    $right->emit($expected) if $expected;
    $right->emit($left) if $left->type() ne 'none' and $left->type() ne 'unknown';

    $left->accept($right);

    $left->literal = $right->literal if defined $right->literal;  # for things like $a = 'FooBar'; $b = $a; bless [], $b;

    debug('sassign/aasign: left after possible literal transfer: ', $left->diagnostics());

    # is something expected? make sure we get it!

    $right->isa($expected, 'value needed from assignment') if $expected;

    # special case - we don't know what the heck is on the left, but we know that the
    # value on the right will pass through in this one case.

    if($left->type() eq 'none' or $left->type() eq 'unknown') {
      # assignments tend to happen in void context, but might as well try and see if something should be returned
      return $right; 
    }

    # is the thing on the right a subtype of the variable meant to hold it?
    # our little type objects have their own isa() method.
    # XXX trying to get little packages wired up so that this works on primitive types as well as complex
    # XXX this isa test is redundant with accept() and emit() on arrays and possibly in the future, scalars

    $right->isa($left, 'unsafe assignment');
    return $left;

  }}

  #
  # listops
  # 

  if($self->name() eq 'lineseq' or
     $self->name() eq 'list' or
    (ref($self) eq 'B::LISTOP' and $self->first()->name() eq 'pushmark')       # stolen from types.pm
  ) {

    # the lineseq stuff is redundant, but it serves to illustrate a common example.
    # general case - we have a list type, which is the GCD of all types in the list
    # a whole class of problems, really. an sassign is being done to the lvalue result of a list.
    # that lvalue result could be a type-checked variable used in a substr() or other lvalue
    # built in, or it could be a declaration being assigned to right off, perhaps from a 
    # constructor. 
    # solve_types() should be able to go into a list and figure out which type checked scalar (if any)
    # is the fall through value - XXX. in order to do this, we'd have to track what arguments go into and
    # come out of each op, and then when the block ends, remember which op was the last. 
    # XXX okey, i'm pretty fuzzy on all of this here
    # return, above, we don't check the result type, but we propogate the expected type. 
    # here, we propogate the expected type and we check the common result type. 

    my $return = solve_list_type($self->first(), $expected);
    $debug && $expected and print "debug: ", __LINE__, ": expecting ", $expected->diagnostics(), "\n";
    return $return unless $expected;
    # $return->isa($expected); # XXX this is a no-op
    # check_types($return, $expected, 0); # XXX should be 1 - fatal if mismatch
    return $return;

  }

  #
  # nothing we recognize. we're going to return "unknown", but first we should make sure
  # that expressions nested under this point get inspected for type safety. so, we 
  # recurse, expecting nothing.
  # 

  if($self->flags() & OPf_KIDS) {

    $debug and print "debug: ", __LINE__, ": generic handling for UNOP/BINOP/LISTOPs: handling op: ", $self->name(), "\n";

    # this should work for unops, binops, *and* listops

    return enforce_list_type($self->first(), $expected);

  }

  $debug and print "debug: ", __LINE__, ": unknown op: ", $self->name(), " context: $want\n";

  return canned_type('unknown')->clone(sprintf 'unrecognized scalar construct (op: %s)', $self->name()) if($want == OPf_WANT_SCALAR);
  return canned_type('unknown')->clone(sprintf 'unrecognized list construct (op: %s)', $self->name())   if($want == OPf_WANT_LIST);
  return canned_type('none')->clone(sprintf 'unrecognized void construct (op: %s)', $self->name())      if($want == OPf_WANT_VOID);

  $debug and print "debug: ", __LINE__, ": unknown context number $want - that sucks\n";
  return canned_type('none')->clone(sprintf 'unrecognized construct in unrecognized context (op: %s)', $self->name());

}

#
# check method call arguments against prototype
#

sub check_args {

  # someone somewhere found something that looks like a method call.
  # we check the arguments to that method call against the methods prototype.
  # we also make sure that that method has a prototype, is a constructor, or else the
  # method appears in the package via can(), since we don't want to compute inheritance manually.
  # XXX if we can track down the package where it is defined, we might find a prototype there.
  # we die if the prototype doesn't match the actual types of the chain of ops.
  # in case of a match, we return the typeob representing the prototype of this function.

  my $op = shift;
  my $type = shift;
  my $method = shift;

  # no $op means no arguments were found. this might be what the prototype is looking for! is this safe? XXX

  # $debug && ! $op and print "debug: ", __LINE__, " check_args called without an OP! type: $type method: $method\n";
  # $debug && $op and print "debug: ", __LINE__, ": check_args called: op: ", $op->name(), ' ', $op->seq(), 
  #                         " type: $type method: $method\n";

  my $argob;

  # default case - method is prototyped in the package specified by type
  $argob = lookup_method($type, $method) if lookup_method($type, $method);

  # if method is 'new' and no type exists, default to the type of the reference - XXX refactor to use lookup_type()
  if($method eq 'new' and ! $argob) {
    $argob = typesafety::methodob->new(type=>$type, package=>$type, name=>'new', desc=>'constructor', literal=>$type);
  }

  # kludge, but inheritance doesn't work otherwise!
  if(! $argob and $type->can($method)) {
    $argob = typesafety::methodob->new(type=>$type, package=>$type, name=>$method, desc=>'inherited/unprototyped method');
  }

  $argob or die "unknown method. methods called on type safe objects " .
                 "must be prototyped with proto(). package: " . $type . ' method: ' . $method . ' ' . nastily;

  # at this point, we know the return type of the method call. now, we check the argument signiture, if there is one.
  # if we cooked up our own because new() wasn't prototyped, then there won't be one. that's okey.

  my $takes = $argob->takes();

  unless($takes and @$takes) {
    # this method's arguments aren't prototyped
    # success, so far. this is this being assigned to something else, that might conflict if we also don't have
    # any type information.
    # $debug and print "debug: ", __LINE__, ": no 'takes' information found for the type '$type'\n";
    return $argob; 
  }

  # method call arguments get checked for types too! woot!
  # given a list of parameter types and a pointer to an op in a bytecode stream, return undef
  # for success or an error message if there is a type mismatch between the two.

  if(!$argob and scalar(@$takes)) {
    die "arguments were expected, but none were provided, calling $method in $type, " . nastily;
  }

  my $index = 0;
  my $leftop = $op; my $left;
  my $rightob;

  # XXX we hardcode in method_named - really, we just want to discard the last op in the stream.
  # XXX otherwise, this will prevent checking function prototypes.

  while($leftop and $leftop->name() ne 'method_named') {

    if(! exists $takes->[$index]) {
      die "more parameters passed than specified in prototype. calling $method in $type, " . nastily;
    }

    # $debug and print "debug: ", __LINE__, ": checking prototype: considering: ", $leftop->name(), "\n";

    $left = $takes->[$index];
    goto OKEY if ! $left;

    $rightob = solve_type($leftop); 

    if($left and ! $rightob) {
      confess "argument number " . ($index + 1) . " must be type $left according to prototype. " . 
           'instead, it is a(n) ' . $rightob->diagnostics() . nastily;
    }

    # rightob->isa(left)

    goto OKEY if $rightob->type() eq $left;
    goto OKEY if $rightob->type()->isa($left); # $left is a plain string here, so we have to do ->type()
    die "argument number " . ($index + 1) . " type mismatch: must be type '$left', instead we got a(n) " .
        $rightob->type() . ' ' . nastily; 

    OKEY:
    $leftop = $leftop->sibling() or last;
    $index++;

  }

  if($index < @$takes) {
    die "insufficient number of paramenters - only got " . ($index + 1) . ", expecting " . ((scalar @$takes) + 1) . ' .' .
        nastily;
  }

  return $argob; # success

}

#
# solve types of lists
#

sub solve_list_type {

    # a 'list' op was found - any number of things could be littered onto the stack.
    # this calculates the largest common type of those objects, if any. yes, this means
    # arrays can't contain mixed information - they're an array of one base kind of object
    # or integers or floats or something. 
    # the first sibling under list is passed in.
    # this is called from solve_type(), and itself calls solve_type().
    # stolen from types.pm by Auther Bergman, then hacked into worthlessness
    # this can be used any place where solve_type() may be used - a list of one op is just fine.

    my $op = shift;
    my $expected = shift;

    my @types;
    my $type;

    while($$op) {
        # $debug and print "debug: ", __LINE__, ": trying to solve type for op ", $op->name(), ' ', $op->seq(), "\n";
        # confess "solve_type for " . $op->name() . " did it - ref type " . ref $types[-1] unless ref($types[-1]) and $types[-1]->isa('typesafety::typeob'); # debug # heh - our new ->isa() broke this
        # this is a bit different now - we only consider the return if the op actually puts something onto the stack - no more voids!

        $type = solve_type($op, $expected);
        confess "offending op was " . $op->name() . ' returned to us: ' . $type unless ref($type) and UNIVERSAL::isa($type, 'typesafety::typeob');
        push @types, $type if $type->type() and $type->type() ne 'none';
        $op = $op->sibling();

    }

    $debug and print "debug: ", __LINE__, ": okey, this is what solve_list_type() has to work with: ", join ', ', map({ $_->type() } @types), "\n";

    my $encapsulates = common_type_from_list(@types);

    $debug and print "debug: ", __LINE__, ": aren't we clever? greatest common type: ", $encapsulates->diagnostics(), "\n";

    return $encapsulates;

}

sub common_type_from_list {

    # which object, if any, encapsulates all of the others?
    # if there are several, they must all be the same class, right?
    # if there are none, there is no common type to this list!

    my @types = @_;

    OUTTER: 
    foreach my $outter (@types) {

      foreach my $inner (@types) {
        no warnings 'uninitialized';
        next if $inner->type() eq 'none';
        next OUTTER if $outter->type() eq 'none';
        next OUTTER unless $outter->isa($inner);
      }

      return $outter;
      # push @encapsulates, $outter;

    }

    # build up a super-none from all of the types - no common type can be found.
    return canned_type('none')->clone('no common type in list:' . join ', ', map { $_->diagnostics() } @types);

}


sub uncommon_type_from_list {

    # which object, if any, is not encapsulated by any other? opposite of common_type_from_list()

    my @types = @_;

    OUTTER: 
    foreach my $outter (@types) {
      next if $outter->type() eq 'none';

      foreach my $inner (@types) {
        next if $inner->type() eq 'none';
        next OUTTER if $inner->isa($outter);
      }

      return $outter;

    }

    return $types[0]; # all the same thing, doesn't matter
}

sub solve_lit {

  # an op returns a litteral string that is used as a type name - currently only used by 'bless' in solve_type()

  my $self = denull(shift());

  if($self->name() eq 'const') {
    # return $self->sv()->sv(); # XXX highly experimental 0000
    return $self->sv()->PVX();
  }

  if($self->name() eq 'ref') {{
    last unless $self->first()->name() eq 'padsv';
    my $typeob = lookup_targ($self->first()->targ());
    last unless $typeob;
    return $typeob->type();
  }}

  # print $_[0];

  # 6  <@> leave[t1] vKP/REFC ->(end)
  # 1     <0> enter ->2
  # 2     <;> nextstate(main 1 -e:1) v ->3
  # 5     <@> print vK ->6
  # 3        <0> pushmark s ->4
  # -        <1> ex-aelem sK/2 ->5
  # -           <1> ex-rv2av sKR/1 ->-
  # 4              <$> aelemfast(*_) s ->5
  # -           <0> ex-const s ->-

  if($self->name() eq 'aelemfast') {{

    # index is in ->private(), the array itself in ->sv(). how so very CISC. 
    # debug("aelemfast: gv stash name: ", $self->gv()->STASH()->NAME()   );  # main
    # $lastpack is almost correct - in some cases a subclass that inherits the constructor will be the actual type
    # returned at runtime, but considering the base type is safe from an analysis standpoint.

    last unless $self->gv()->NAME() eq '_'; # better known as the default argument list, @_

    # we're ignoring typeob->aelem_prototype() for now and naively assuming the 0th argument to be the package type
    # return $lastpack if $self->private() == 0; # works, but ignores the effects of prior shift()s

    last unless $returnvalue;
    return $returnvalue->aelem_prototype($self->private());

  }}

  if($self->name() eq 'padsv') {{
    my $type = lookup_targ($self->targ());
    debug('solve_lit: padsv: ', $type ? $type->diagnostics() : 'no type information for this scalar');
    last unless $type;
    return $type->literal;
  }}

}

#
# utility methods
#

# these just factor out some of the cruftier syntax

sub enforce_type {
  # common repeated code sequence - 
  # solve a type; if a type is expected, make sure it is that type
  my $op = shift;
  my $expected = shift;
  my $reason = shift;
  my $type = solve_type($op, $expected);
  $type->isa($expected, $reason || 'type mismatch - ') if $expected;
  return $type;
}

sub enforce_list_type {
  # common repeated code sequence - 
  # solve a type; if a type is expected, make sure it is that type
  my $op = shift;
  my $expected = shift;
  my $reason = shift;
  my $type = solve_list_type($op, $expected);
  $type->isa($expected, $reason || 'type mismatch - ') if $expected;
  return $type;
}

sub lexicalname {
  # given a pad number (stored in all perl operators as $op->targ()), return its name.
  # works well - we get "$foo" etc back
  # PVX() returns the string stored in a scalar as null terminated, ignoring the length info, 
  # which is the correct thing to do with pad entries (length info is barrowed for something else).
  # otherwise, PVX() is like PV().
  my $targ = shift;
  my $padname = (($curcv->PADLIST->ARRAY)[0]->ARRAY)[$targ];  # from B::Concise
  return 'SPECIAL' if B::class($padname) eq 'SPECIAL';
  return $padname->PVX(); 
}

sub lexicalref {
  # given a pad number, return a B object representing it as a scalar.
  # pads are stored as a parallel array of names/metainformation and actual scalar references to the data.
  my $targ = shift;
  (($curcv->PADLIST->ARRAY)[1]->ARRAY)[$targ]->sv(); 
}

sub pppname {
   # like ppname, but we take the op itself. saves typing. returns something like "pp_list".
   my $self = shift;
   return $self->can('targ') ? ppname($self->targ()) : 'null';
}

sub denull {

  my $op = shift;

  if(
     $op->name() eq 'null' and 
     $op->can('targ') and 
     # ppname($op->targ()) eq 'pp_list' and
     $op->flags() & OPf_KIDS and
     $op->can('first')
   ) {
     debug('denull descending past null op ', ppname($op->targ()), ' to: ', $op->first()->name());
     $op = $op->first();
     return denull($op);
   }

   return $op;

}

sub source_status { return ($lastpack, $lastfile, $lastline) }


#
# typeob
#

# represents a type itself, including where it was defined, how it was defined, and how it is actually used.
# type data associated with a typed scalar - includes verbose information about where the type was defined
# for good diagnostics in case of error

package typesafety::typeob;

# accessors

sub type     :lvalue { $_[0]->[0] }          # point of our existance
sub package  :lvalue { $_[0]->[1] }          # diagnostic output in case of type match failure
sub filename :lvalue { $_[0]->[2] }          # diagnostics
sub line     :lvalue { $_[0]->[3] }          # diagnostics
sub pad      :lvalue { $_[0]->[4] }          # scalars only 
sub name     :lvalue { $_[0]->[5] }          # scalars only 
sub desc     :lvalue { $_[0]->[6] }          # scalar or method return? diagnostics? creating info?
sub takes    :lvalue { $_[0]->[7] }          # in the case of methods, what types (in order) do we take for args?

sub accepts  { [] }                          # 8 - typesafety::arrayob does something with this
sub emits    { [] }                          # 9 - noop in this base class
sub accept   { }                             # noop in this base class
sub emit     { }                             # noop in this bsae class

sub literal  :lvalue { $_[0]->[10] }         # literal value stored in scalar, if known. new's prototype is reused as prototype first arg to new.
sub created  :lvalue { $_[0]->[11] }         # internal debugging - which program line called the constructor


sub argnum     { typesafety::confess }       # 12 - next arg to be read, methodobs
sub subobjects { typesafety::confess }       # 12 - hashes contain other invidually typed objects

sub reset_prototype  { typesafety::confess } # typesafety::methodob 
sub shift_prototype  { typesafety::confess } # typesafety::methodob 
sub aelem_prototype  { typesafety::confess } # typesafety::methodob 

sub new { 
  my $self = bless ['none', typesafety::source_status(), (undef) x 4, [], [], undef], shift(); 
  while(@_) { 
    my $f = shift; $self->$f = shift; 
  } 
  # ignore the output string, just make sure that the fields required for diagnostics are defined
  $self->created = (caller)[2]; 
  $self->diagnostics(); 
  typesafety::debug("typesafety::typeob: new: created ", $self->diagnostics());
  return $self; 
}

sub clone { 
  my $self = shift; 
  my @new = @$self; 
  # augment description - this is the primary (only?) change made to clones
  $new[6] ||= ''; $new[6] .= ' ' . $_[0] if @_;  
  typesafety::debug("new desc is $new[6]");
  # typesafety::cluck("new desc");
  bless \@new, ref $self;
}

sub diagnostics { 
  my $self = shift;
  my @diag;
  push @diag, $self->desc if $self->desc;
  push @diag, $self->name if $self->name; # typesafety::confess unless $self->name;
  push @diag, 'type ' . $self->type if $self->type; # typesafety::confess unless $self->type;
  push @diag, 'containing the literal value "' . $self->literal . '"' if defined $self->literal;
Carp::confess "strange crap in 'takes'" if $self->takes and ref($self->takes) ne 'ARRAY';
  push @diag, 'taking as arguments the types "' . join(', ', map $_||'(undef)', @{ $self->takes }) . '"' if $self->takes and ref($self->takes) eq 'ARRAY';
  push @diag, 'created inside typesafety by request from line ' . $self->created if $debug;
  push @diag, sprintf 'defined in package %s, file %s, line %s', $self->package, $self->filename, $self->line if $self->package or $self->filename;
  return join ', ', @diag;
}

sub isa {
  # wrapper for the normal UNIVERSAL::isa() test - should two typeobs not match, we die with diagnostics
  my $self = shift; 
  my $arewe = shift or typesafety::confess(); 
  ref $arewe or typesafety::confess(); 
  my $fatal = shift; 
  return 1 if ! $self->type();  # despite having a type object, they're untyped... this happens with methods prototyped to (undef; ...)
  return 1 if ! $arewe->type();  # despite having a type object, we're untyped... this happens with methods prototyped to (undef; ...)
  return 1 if $self->type() eq $arewe->type() or $self->type()->isa($arewe->type()); 
  return undef unless $fatal;
  die join ' ', $fatal, ($fatal?': ':''),  "type mismatch: expected: ", $arewe->diagnostics(), 
                "; got: ", $self->diagnostics(), typesafety::nastily(); 
}

package typesafety::scalarob; 

use base 'typesafety::typeob'; 

sub typesafety::scalarob::stuff { 'scalar' }

#
# typesafety::methodob
#

package typesafety::methodob; 

use base 'typesafety::typeob'; 

sub typesafety::methodob::stuff { 'method' }

sub argnum    :lvalue { $_[0]->[12] }   # next argument position to be read 

sub unshift_prototype {
  my $self = shift;
  my $takes = $self->takes; 
  my $argnum = $self->argnum++;
  return $self if $argnum == 0;   # OO perl adds $self as first argument - $_[0] is our own type
  # return lookup_type($self->type()) if $argnum == 0;   # OO perl adds $self as first argument
  return typesafety::lookup_type($takes->[$argnum - 1]) if exists $takes->[$argnum - 1];
  return typesafety::canned_type('unknown')->clone('shifted off an argument of unknown type in argument position ' . $argnum);
}

sub aelem_prototype {
  my $self = shift;
  my $argnum = shift() + $self->argnum;
  my $takes = $self->takes; 
  return $self if $argnum == 0;   # OO perl adds $self as first argument
  return typesafety::lookup_type($takes->[$argnum - 1]) if exists $takes->[$argnum - 1];
  return typesafety::canned_type('unknown')->clone('shifted off an argument of unknown type in argument position ' . $argnum);
}

sub reset_prototype { $_[0]->argnum = 0; }

sub helem_prototype {
  # XXX - this could decide what hash was passed and return the type for the constant index
}

#
# typesafety::inferedob
#

package typesafety::inferredob;  

use base 'typesafety::typeob'; 

sub stuff  { 'inferred' }

sub type :lvalue { 
  my $self = shift; 
  if((! $self->[0] or $self->[0] eq 'none') and @{$self->emits()}) {
     typesafety::debug("typesafety::inferredob::type computing array type from emits");
     $self->[0] = typesafety::common_type_from_list(@{$self->emits()})->type();
  }
  if((! $self->[0] or $self->[0] eq 'none') and @{$self->accepts()}) {
     typesafety::debug("typesafety::infferedob::type computing array type from accepts");
     $self->[0] = typesafety::uncommon_type_from_list(@{$self->accepts()})->type();
  }
  if(! $self->[0] or $self->[0] eq 'none') {
    typesafety::debug("typesafety::inferredob::type should be computing array type from emits but we have no emits or accepts yet");
  }
  $self->[0] ||= 'none'; 
  $self->[0]; 
}

sub accepts          { $_[0]->[8] }  # arrayref of types of objects we've been asked to store
sub emits            { $_[0]->[9] }  # arrayref of types of objects we've been asked to provide

sub accept   { my $self = shift; typesafety::debug("accept: ", $_[0]->diagnostics()); push @{$self->accepts()}, shift(); $self->compat(); $self; } # things on the lhs accept
sub emit     { my $self = shift; typesafety::debug("emit: ", $_[0]->diagnostics()); push @{$self->emits()}, shift(); $self->compat(); $self; }   # things on the rhs emit

sub compat { 
  my $self = shift; 
  my @left = @{$self->accepts()} or return;
  my @right = @{$self->emits()} or return;
  typesafety::debug('compat: getting ready to permute');
  foreach my $right (@right) { 
    foreach my $left (@left) { 
      # this is backwards from normal, but so is our role - normally, we test if data can be downgraded to fit its container. here, we want to
      # test to make sure that we haven't downgraded beyond what is acceptable.
      typesafety::debug("compat: permuting: left: ", $left->diagnostics(), " = right: ", $right->diagnostics(), "\n");
      $left->isa($right, 'array used inconsistently'); 
    } 
  } 
  typesafety::debug('compat: end permute');
}

#
# typesafety::arrayob
#

package typesafety::arrayob;

use base 'typesafety::inferredob';

sub stuff { 'array' }

#
# typesafety::hashob
#

package typesafety::hashob;

use base 'typesafety::inferredob';

sub type :lvalue {
  my $self = shift;
  $self->[0] = 'hash' if $self->[0] eq 'none';
  $self->[0] ||= 'hash';
  $self->[0];
}

sub subobjects        { $_[0]->[12] ||= {}; $_[0]->[12] }

sub subscript :lvalue { $_[0]->subobjects()->{$_[1]} }

#    $right->emit($expected) if $expected;
#    $right->emit($left)
#    $left->accept($right);

sub accept { jive($_[0], $_[1], sub { $_[0]->accept($_[1]) }) }
sub emit   { jive($_[0], $_[1], sub { $_[0]->emit($_[1])   }) }

sub jive {
  my $self = shift;
  my $them = shift;
  my $callback = shift;
  return unless UNIVERSAL::isa($them, 'typesafety::hashob');
  my %keys;
  my $ob = sub {
    typesafety::inferredob->new(
        type=>'none', desc=>'hash entry of inferred type', pad=>undef, name=>$_[0],
        package=>$lastpack, filename=>$lastfile, line=>$lastline,
    );
  };
  foreach my $key (%{$self->subobjects()}) { $keys{$key}++ }
  foreach my $key (%{$them->subobjects()}) { $keys{$key}++ }
  foreach my $key (keys %keys) {
    $self->subobjects()->{$key} ||= $ob->($key);
    $them->subobjects()->{$key} ||= $ob->($key);
    $callback->($self->subobjects()->{$key}, $them->subobjects()->{$key});
  }
}

#
# other diddling around in other packages
#

# none, constant, int, float, string

@none::ISA = ();
push @int::ISA, 'none';
push @float::ISA, 'int';

sub B::NULL::name { 'null' }

1;

=pod

=head1 NAME

typesafety.pm - compile-time object type usage static analysis 

=head1 ABSTRACT

Perform heuristics on your program before it is run, with a goal
of insuring that object oriented types are used consistently -- the correct class
(or a subclass of it) is returned in the right places, provided in method call
argument lists in the right places, only assigned to the right variables, and
so on. 
This is a standard feature of non-dynamic languages such as Java, C++, and C#. 
Lack of this feature is one of the main reasons Perl is said not to be a "real" object oriented language.

=head1 SYNOPSIS

  package main;
  use typesafety; # 'summary', 'debug';

  my FooBar $foo;            # establish type-checked variables
  my FooBar $bar;            # FooBar is the base class of references $bar will hold
  my BazQux $baz;

  $foo = new FooBar;         # this is okay, because $foo holds FooBars
  $bar = $foo;               # this is okay, because $bar also holds FooBars
  # $foo = 10;               # this would throw an error - 10 is not a FooBar
  # $baz = $foo;             # not allowed - FooBar isn't a BazQux
  $foo = $baz;               # is allowed -  BazQux is a FooBar because of inheritance
  $bar = $foo->foo($baz, 1); # this is okay, as FooBar::foo() returns FooBars also

  typesafety::check();   # perform type check static analysis

  #

  package FooBar;
  use typesafety;

  # unneeded - new() defaults to prototype to return same type as package
  # proto 'new', returns => 'FooBar'; 

  sub new {
      bless [], $_[0]; 
      # or: bless whatever, __PACKAGE__;
      # or: bless whatever, 'FooBar';
      # or: my $type = shift; bless whatever, $type;
      # or: my $type = shift; $type = ref $type if ref $type; bless whatever, $type;
  }

  sub foo (FooBar; BazQux, undef) { my $me = shift; return $me->new(); } 

  # or: proto 'foo', returns => 'FooBar'; sub foo { my $me = shift; return $me->new(); } 

  #

  package BazQux;
  use typesafety;
  @ISA = 'FooBar';

=head1 DESCRIPTION

This module is similar to "strict.pm" or "taint.pm" in that it checks your
program for classes of possible errors.
It identifies possible data flow routes and performs heuristics on the data flow
to rule out the possibility of the 

=head2 Important

This software is BETA! 
Critical things seem to work, but it needs more testing
(for bugs and usability) from the public before I can call it "1.0". 
The API is subject to change (and has already changed with each version so far).
This is the first version where I'm happy with the basic functionality and
consider it usable, so I'm calling it beta.
While it correctly makes sense of a lot of code related to types in OO, there's still a lot
of code out there in the wild that it mistakes for an object related construct and causes
death and internal bleeding when it foolishly tries to swollow it.

IMPORTANT:
This module depends on L<B::Generate>, but the version up on CPAN doesn't
build cleanly against current versions of Perl.
I have a modified version of B::Generate up in my area that works, at least for me.
As I write this, Perl 5.8.8 is current.

IMPORTANT:
Like adapting a Perl 4 program to compile cleanly on Perl 5 with strict and
warnings in effect, adapting a Perl 5 program to cleanly pass type checking
is a major undertaking.  
And like adapting a Perl 4 program for strict, it takes some self-education
and adjustment on the part of the programmer.
Also like adapting a program for strict, it's an extremely rewarding habit
to get into for a program that might grow to tens of thousands of lines.
I suggest making it a corporate project (with large sums of money budged
towards consulting fees for me) or else for the adventurous and broad-minded.

IMPORTANT-ish:
There's a good tutorial on strong typing (type safety, type checking)
in my _Perl 6 Now: The Core Ideas Illustrated with Perl 5_ along with
loads of other great stuff (you should buy it just for the two chapters
on coroutines).
See L<http://perl6now.com> for excerpts, more plugging, and links to buy.

=head2 Strong Typing

Failure to keep track what kind of data is in a given variable or returned 
from a given method is an epic source of confusion and frustration during
debugging. 

Given a C<< ->get_pet() >> method, you might try to bathe the output. If it always
a dog during testing, everything is fine, but sooner or later, you're
going to get a cat, and that can be rather bloody.

Welcome to Type Safety. Type Safety means knowing what kind of data you
have (atleast in general - it may be a subclass of the type you know
you have). Because you always know what kind of data it is, you see in
advance when you try to use something too generic (like a pet) where you
want something more specific (like a dog, or atleast a pet that implements
the "washable" interface).

Think of Type Safety as a new kind of variable scoping -
instead of scoping where the variables can be seen from, you're scoping
what kind of data they might contain.

"Before hand" means when the program is parsed, not while it is running.
This prevents bugs from "hiding". I'm sure you're familiar with
evil bugs, lurking in the dark, il-used corners of the program, like
so many a grue.
Like Perl's C<use strict> and C<use warnings> and C<use diagnostics>,
potential problems are brought to your attention before they are
proven to be a problem by tripping on them while the program happens
on that nasty part of code.  You might get too much information, but you'll
never have to test every aspect of the program to try to uncover
these sorts of warnings. Now you understand the difference between
"run time diagnostics" and "compile time warnings".

Asserts in the code, checking return values manually, are an example of
run-time type checking:

  # we die unexpectedly, but atleast bad values don't creep around!
  # too bad our program is so ugly, full of checks and possible bad
  # cases to check for...

  my $foo = PetStore->get_pet();
  $foo->isa('Dog') or die; 

Run-time type checking misses errors unless a certain path of execution
is taken, leaving little time bombs to go off, showing up later. More
importantly, it clutters up the code with endless "debugging" checks,
known as "asserts", from the C language macro of the same name.

Type Safety is a cornerstone of Object Oriented programming. It works
with Polymorphism and Inheritance (including Interface Inheritance).

Use C<typesafety.pm> while developing. Comment out the C<typesafety::check()> statement when
placing the code into production. This emulates what is done with compiled
languages - types are checked only after the last time changes are made
to the code. The type checking is costly in terms of CPU, and as long as the
code stays the same, the results won't change. If everything was type
safe the last time you tested, and you haven't changed anything, then it
still is.

A few specific things are inspected in the program when 
C<typesafety::check()> is called:

  $a = $b;

Variable assignment.
Rules are only applied to variables that are "type safe" - a type safe
variable was declared using one of the two constructs shown in the
L<SYNOPSIS>. If it isn't type safe, none of these rules apply.
Otherwise, 
C<$b> must be the same type as C<$a>, or a subclass of C<$a>'s type.
In other words, the types must "match".

  $a->meth();

Method call. If C<$a> is type safe, then the method C<meth()> must
exist in whichever package C<$a> was prototyped to hold a 
reference to. Note that type safety can't keep you from trying
to use a null reference (uninitialized variable), only from trying
to call methods that haven't been proven to be part of the
module they're prototyped to hold a reference to. If the method
hasn't been prototyped in that module, then a C<< ->can() >>
test is done at compile time. Inheritance is handled this way.

  $a = new Foo;

Package constructors are always assumed to return an object of the same type
as their package. In this case, C<< $a->isa('Foo') >> is expected to be
true after this assignment. This may be overridden with a prototype for your
abstract factory constructors (which really belong in another method anyway,
but I'm feeling generous). The return type of C<< Foo->new() >> must match
the type of C<$a>, as a seperate matter. To match, it must match exactly or 
else be a subclass of C<$a> expects. This is just like the simple case
of "variable assignment", above.
If C<new()> has arguments prototyped for it, the
arguments types must also match. This is just like "Method call", above.

  $a = $foo->new();

Same as above. If C<$foo> is type checked and C<$a> is not, then arguments
to the C<new()> method are still checked against any prototype.
If C<$a> is type checked, then the return value of C<new()> must match.
If no prototype exists for C<new()> in whatever package C<$foo> belongs
to, then, as above, the return value is assumed to be the same as the
package C<$foo> belongs to. In other words, in normal circumstances,
you don't have to prototype methods.

  $b = $a->bar();

As above: the return type of C<bar()> must be the same as, or a subclass
of, C<$b>'s, if C<$b> is type safe. If C<$a> is type safe and there is
a prototype on C<bar()>, then argument types are inforced.

  $b = $a->bar($a->baz(), $z->qux());

The above rules apply recursively: if a method call is made to compute
an argument, and the arguments of the C<bar()> method are prototyped,
then the return values of method calls made to compute the arguments
must match the prototype. Any of the arguments in the prototype may be 
C<undef>, in which case no particular type is enforced. Only 
object types are enforced - if you want to pass an array reference,
then bless that array reference into a package and make it an object.

  bless something, $_[0];
  bless something, __PACKAGE__;
  bless something, 'FooBar';

This is considered to return an object of the type of the hard-coded value
or of the present package. This value may "fall through" and be the default
return value of the function.

  return $whatever;

Return values in methods must match the return type prototyped for that
method.

  push @a, $type;
  unshift @a, $type;
  $type = pop @a;
  $type = shift @a;
  $type = $a[5];

When typed variables and typed expressions are used in conjunction with arrays, the
array takes on the types of all of the input values. Arrays only take on 
types when assigned from another array, a value is C<push>ed onto it, or a
value is C<unshift>ed onto it.
Whenever the array is used to generate a value with an index, via C<pop>,
or via C<unshift>, the expected type is compared to each of the types the
array holds values from. Should a value be assigned to the array that
is incompatiable with the types expected of the array, the program dies
with a diagnostic message.
This feature is extremely experimental. In theory, this type of automatic type
inference could be applied to method arguments, scalars, and so forth, such that
types can be specified by the programmer when desired, but never need to be, and
the program is still fully type checked. O'Caml reported does this, but with a 
concept of records like datastructures, where different elements of an array
are typed seperately if the array isn't used as a queue. We only support
one type for the whole array, as if it were a queue of sorts.

  sub foo (FooBar; BazQux, undef) { my $me = shift; return $me->new(); } 

Method prototypes are provided in the C<()> after method name. You might
recognize the C<()> from L<perlsub>. You might also remember L<perlsub>
explaining that these prototypes aren't prototypes in the normal meaning
of the word. Well, with C<typesafety.pm>, they are. The format is
C<(ReturnType; FirstArgType, SecondArgType, ThirdArgType)>. Any of them
may be C<undef>, in which case nothing is done in the way of enforcement
for that argument. The C<ReturnType> is what the method returns - it
is seperated from the arguments with a simicolon (C<;>). The argument
types are then listed, seperated by commas (C<,>). Any calls made to
that method (well, I<almost> any) will be checked against this 
prototype. 

  sub foo (FooBar; BazQux) {
    my $b = $_[0];
    my $a = shift;
    # ...
  }

Arguments read from prototyped methods using a simple C<shift> or C<$_[n]> 
take the correct type from the prototype. C<shift @_> should work, too - 
it is the same thing. In this example, C<$a> and C<$b> would be of type
C<BazQux>. Of course, you can, and probably should, explicitly specify
the type: C<my BazQux $a = shift;>.

  typesafety::check(); 

This must be done after setting things up to perform actual type checking, or
it can be commented out for production. The module will still need to be used
to provide the C<proto()>, and add the C<attribute.pm> interface handlers.

Giving the 'summary' argument to the C<use typesafety> line generates a report
of defined types when C<typesafety::check()> is run:

  typesafety.pm status report:
  ----------------------------
  variable $baz, type BazQux, defined in package main, file test.7.pl, line 36
  variable $bar, type FooBar, defined in package main, file test.7.pl, line 34
  variable $foo, type FooBar, defined in package main, file test.7.pl, line 33

I don't know what this is good for except warm fuzzy feelings.

You can also specify a 'debug' flag, but I don't expect it will be very helpful
to you.

=head1 DIAGNOSTICS

  unsafe assignment:  in package main, file test.7.pl, line 42 - variable $baz, 
  type BazQux, defined in package main, file test.7.pl, line 36 cannot hold method 
  foo, type FooBar, defined in package FooBar, file test.7.pl, line 6 at 
  typesafety.pm line 303.

There are actually a lot of different diagnostic messages, but they are all
somewhat similar. Either something was being assigned to something it shouldn't
have been, or else something is being passed in place of something it shouldn't
be. The location of the relavent definitions as well the actual error are
included, along with the line in C<typesafety.pm>, which is only useful to me.

=head1 EXPORT

C<proto()> is always exported. This is considered a bug.

=head1 BUGS

My favorite section!

Yes, every module I write mentions Damian Conway =)

Testing 13 is commented out because it was failing ( C<< $foo{bar} = $foo{baz} >> where each slot held a different object type).

Constructs like C<< $foo->bar->() >> were kicking its butt (functions that return closures) and probably still are. 
Not sure about closure handling.  
This is on my todo. 
Not having it is an embarasement.

C<my Foo $bar> is used by L<fields> as well.

Blesses are only recognized as returning a given type when not used with a variable,
or when used with C<< $_[0] >>.
E.g., all of these are recognized: C<< bless {}, 'FooBar' >>, 
C<< bless {}, $_[0] >>, and
C<< bless {}, __PACKAGE__ >>. (C<< __PACKAGE__ >> is a litteral as far as perl is concerned). 
Doing C<< bless {}, $type >> and other constructs will throw a diagnostic about
an unrecognized construct - C<typesafety.pm> loses track of the significance of
C<$_[0]> when it is assigned to another variable. 
To get this going, I'd have to track data as it is unshifted
from arguments into other things, and I'd have to recognize the result of C<ref>
or the first argument to new as a special thing that produces a predictable type
when feed to C<new> as the second argument. Meaty.
Update: a few more constructs are supported: C<< my $type = shift; bless whatever, $type; >>
the most significant. Still, you won't have much trouble stumping this thing.

C<undef> isn't accepted in place of an object. Most OO langauges permit this - 
however, it is a well known duality that leads to checking each return value.
This is a nasty case of explicit type case analysis syndrome. Rather than
each return value be checked for nullness (or undefness, in the case of Perl)
and the error handling logic be repeated each place where a return value
is expected, use the introduce null object pattern: return values should
always be the indicated type - however, a special subclass of that type
can throw an error when any of its methods are accessed. Should a method
call be performed to a method that promises it will always return a given
type, and this return value isn't really needed, and failure is acceptable,
the return can be compared to the special null object of that class.
The normal situation, where a success return is expected, is handled
correctly without having to introduce any ugly return checking code or
diagnostics. The error reporting code is refactored into the special
null object, rather than be littered around the program, in other words.

We're intimately tied to the bytecode tree,
the structure of which could easily change in future versions of Perl. This
works on my 5.9.0 pre-alpha. It might not work at all on what you have.

Only operations on lexical C<my> variables are supported. Attempting to
assign a global to a typed variable will be ignored - type errors
won't be reported. Global variables themselves cannot yet be type checked.
All doable, just ran out of steam.

Only operations on methods using the C<< $ob->method(args) >> syntax is 
supported - function calls are not prototyped nor recognized. Stick
to method calls for now. New - function prototypes might work, but 
I haven't tested this, nor written a test case.

Types should be considered to match if the last part matches - C<< Foo::Bar->isa('Bar') >> would be true.
This might take some doing. Workaround to C<::> not being allowed in attribute-prototypes.
Presently, programs with nested classes, like C<Foo::Bar>, cannot have these types assigned
to variables. No longer true - the C<declare()> syntax is a work-around to this.

Many valid, safe expressions will stump this thing. It doesn't yet understand all
operations - only a small chunk of them. C<map { }>, when the last thing in the
block is type safe, C<grep { }>, slice operations on arrays, and dozens of other
things could be treated as safe. When C<typesafety.pm> encounters something it doesn't
understand, it barfs.

We use L<B::Generate> just for the C<< ->sv() >> method. Nothing else. I promise! We're not modifying
the byte code tree, just reporting on it. I B<do> have some ideas for using L<B::Generate>,
but don't go off thinking that this module does radical run time self modifying code stuff.
XXX this should go anyway; B has equivilents but it needs a wrapper to switch on the object type to get the right one for the
situation.

The root (code not in functions) of C<main::> is checked, but not the roots of other modules.
I don't know how to get a handle on them. Sorry. Methods and functions in C<main::> and other
namespaces that C<use typesafety;> get checked, of course. Update: L<B::Utils> will give me
a handle on those, I think, but I'm too lazy to add support.

Having to call a "check" function is kind of a kludge. I think this could be done in a
C<CHECK { }> block, but right now, the C<typesafety::check()> call may be commented out,
and the code should start up very quickly, only having to compile the few thousand
lines of code in C<typesafety.pm>, and not having to actually recurse through the 
bytecode.
Modules we use have a chance to run at the root level, which lets the C<proto()> functions
all run, if we are used after they are, but the main package has no such benefit. Running
at CHECK time doesn't let anything run. 

The B tree matching, navigation, and type solving logic should be presented as a 
reusable API, and a module specific to this task should use that module. After I 
learn what the pattern is and fascilities are really needed, I'll consider this. 

Tests aren't run automatically - I really need to fix this. I keep running them
by hand. It is one big file where each commented-out line gets uncommented
one by one. This makes normal testing procedures awkward. I'll have to rig something up.

Some things just plain might not work as described. Let me know.

=head1 FUTURE DIRECTION

  sub foo (FooBar $a, BazQux $b) { 
  }

This should use L<B::Generate> to insert instructions into the op tree to C<shift @_> 
into C<$a> and <$b>. When C<foo()> runs, C<$a> and C<$b> would contain the argument
values. Also, support for named parameters - each key in the parameter list could be
associated with a type. This is much more perlish than mere argument order (bleah).
That might look something like:

  sub foo (returns => FooBar, name => NameObject, color => ColorObject, file => IO::Handle) {
  }

This would first require support for hashes, period. Then support for types on individual hash
keys when hash keys are literal constants. 

Support for hashes is also sorely needed for type safe access to instance variables:

  sub foo (FooBar; undef) {
    my $self = shift; 
    return $self->{0}; # XXX dies, even if we always store only FooBars in $self->{0}!
  }

Scalars without explicitly defined types and method parameters to unprototyped methods
should be given the same treatment as arrays - the type usage history should be
tracked, and if an inconsistency is found, it should be reported.

C<map {}>, C<grep {}>, and probably numerous other operations should be supported on
arrays. Probably numerous other operations should be supported on scalars. If you stub
your toe on something and just can't stand it, let me know. I'll look into making it work.

C<private>, C<public>, C<protected>, C<friendly> protection levels, as well as C<static>. Non-C<static>
methods aren't callable in packages specified by constant names, only via padsvs and
such (C<$a->meth()>, not C<Foo->meth()>. Eg, C<FooBar->bleah()>, C<bleah()> must be prototyped static if 
prototyped.
Non-static methods should get a C<$this> that they can make method calls in.

See also the comments at the top of the C<typesafety.pm> file.

Even though I have plenty of ideas of things I'd like to do with this module, 
I'm really pleased with this module as it is now. However, you're likely to try
to use it for things that I haven't thought of and be sorely dissappointed.
Should you find it lacking, or find a way in which it could really shine for
your application, let me know. I'm not likely to do any more work on this beyond
bug fixes unless I get the clear impression that doing so would make someone
happy. If no one else cares, then neither do I.

=head1 HISTORY

This is the fifth snapshot.
The first was ugly, ugly, ugly and contained horrific bugs and the implementation
was lacking. The second continued to lack numerous critical features but the code
was radically cleaned up. In the third version, I learned about the context bits
in opcodes, and used that to deturmine whether an opcode pushed nothing onto the
stack, or whether it pushed something that I didn't know what was, for opcodes
that I didn't have explicit heuristics coded for. This was a huge leap forward.
This fourth version added support for more bless() idioms and fixed return() to
check the return value against the method prototype rather than the type 
expected by the return's parent opcode, and added support for shift() and
indexing argument array and got generic types for arrays working. Version
four also introduced the concept of literal values beyond just object types,
needed to make the bless() idioms work.
The interface is in flux and has changed between each version. 
The fourth one was pretty good but has essentially no users, so I kind of 
ignored the whole mess for a while.
The fifth version makes the thing more tolerant of closures but it still doesn't do the
right thing.
Some constant expressions were stumping it (duh).
There were some fixes that really didn't seem right to me... it didn't seem to be able to cope with untyped function calls at all, but I was certain that it just ignored all untyped stuff. 
Another thing that was confusing it was functions that were exported into the checked namespace from other modules --
it should have been ignoring those, and now it is.
Some more places uses PVX rather than sv to get strings without meta-information tacked on after nulls.
I forget what they were (it happened a few months ago) but there were some other fixes for 5.8.8.
I didn't get to clean up (and spell check) the docuemntation or add new features in this
release, but a new release was over due.

=head1 OTHER MODULES

L<Class::Contract> by Damian Conway. Let me know if you notice any others.
Class::Contract only examines type safety on arguments to and from method
calls. It doesn't delve into the inner workings of a method to make sure
that types are handled correctly in there. This module covers the same
turf, but with less syntax and less bells and whistles. This module
is more natural to use, in my opinion.

To the best of my knowledge, no other module attempts to do what this
modules, er, attempts to do.

L<Object::PerlDesignPatterns> by myself. Documentation.
Deals with many concepts surrounding
Object Oriented theory, good design, and hotrodding Perl. The current
working version is always at L<http://perldesignpatterns.com>. 

=head1 SEE ALSO

See "Pragmatic Modules" in L<perlmodlib>.

L<types>, by Arthur Bergman - C style type checking on strings, integers,
and floats. 

L<http://perldesignpatterns.com/?TypeSafety> - look for updated documentation
on this module here - this included documentation is sparse - only usage
information, bugs, and such are included. The TypeSafety page on 
L<http://perldesignpatterns.com>, on the other hand, is an introduction and
tutorial to the ideas.

L<http://www.c2.com/cgi/wiki?NoseJobRefactoring> - an extreme case of the
utility of strong types.

L<Class::Contract>, by Damian Conway

L<Attribute::Types>, by Damian Conway

L<Sub::Parameters>, by Richard Clamp

L<Object::PerlDesignPatterns>, by myself. 

The realtest.pl file that comes with this distribution demonstrates exhaustively
everything that is allowed and everything that is not. 

The source code. At the top of the .pm file is a list of outstanding issues,
things that I want to do in the future, and things that have been knocked down.
At the bottom of the .pm file is a whole bunch of comments, documentation, and
such.

L<http://perldesignpatterns.com/?PerlAssembly> - C<typesafety.pm> works by
examining the bytecode tree of the compiled program. This bytecode is known
as "B", for whatever reason. I'm learning it as I write this, and as I
write this, I'm documenting it (talk about multitasking!)
The PerlAssembly page has links to other resources I've found around the
net, too.

L<http://perl.plover.com/yak/typing/> - Mark Jason Dominus did an 
excellent presentation and posted the slides and notes. His description on 
of Ocaml's type system was the inspiration for our handling of arrays.

=head1 AUTHOR

Scott Walters - scott@slowass.net

=head1 COPYRIGHT

Distribute under the same terms as Perl itself.
Copyright 2003 Scott Walters. Some rights reserved.

=cut

__END__

Oh. SVs know what stash they're in. Very very handy!

    if($op->name eq 'padsv') {
        my $target = (($cv->PADLIST->ARRAY)[0]->ARRAY)[$op->targ];
        if(UNIVERSAL::isa($target,'B::SV') && $target->FLAGS & SVpad_TYPED) {
            $typed{$cv->ROOT->seq}->{$op->targ}->{type} = $target->SvSTASH->NAME;
            $typed{$cv->ROOT->seq}->{$op->targ}->{name} = $target->PV;
        } elsif(UNIVERSAL::isa($target,'B::SV') &&
                exists($typed{$cv->ROOT->seq}->{$target->PV})) {
            $typed{$cv->ROOT->seq}->{$op->targ} = $typed{$cv->ROOT->seq}->{$target->PV};
        }
    }

------

Perl stores an amazing amount of data in the bytecode tree. This makes
static analysis both a joy and a fertile field of study. 

Source filters can do some things that the B modules can't. L<Acme::Bleach>
operates on something radically different than Perl. L<Sub::Lexical>
extends the syntax beyond what Perl is capable of.
See L<Filter::Simple> for information on source filters.

See perldoc B and L<B::Generate> for more information on Perl's bytecode
interpreter, B.

---------

    my $cv = $op->find_cv();

            $typed{$cv->ROOT->seq}->{$op->targ}->{type} = $target->SvSTASH->NAME;
            $typed{$cv->ROOT->seq}->{$op->targ}->{name} = $target->PV;

--------

package FooBar; package main; my FooBar @foos;

Can't declare class for non-scalar @foos in "my" at -e line 1, near "my FooBar @foos"
Execution of -e aborted due to compilation errors.

# we don't like typechecked arrays. blurgh.

-------------

Context - void vs scalar:

# print my $a=10, "\n";

9  <@> leave[$a:1,2] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <@> print vK ->9
3        <0> pushmark s ->4
6        <2> sassign sKS/2 ->7
4           <$> const(IV 10) s ->5
5           <0> padsv[$a:1,2] sRM*/LVINTRO ->6
7        <$> const(PV "\n") s ->8

# my $a=10;

6  <@> leave[$a:1,2] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
5     <2> sassign vKS/2 ->6
3        <$> const(IV 10) s ->4
4        <0> padsv[$a:1,2] sRM*/LVINTRO ->5

Look at the padsvs - when the my appears in a print, it is in
scalar context. When it appears off of root, it is in void context.

#           v      OPf_WANT_VOID    Want nothing (void context)
#           s      OPf_WANT_SCALAR  Want single value (scalar context)
#           l      OPf_WANT_LIST    Want list of any length (list context)

# currently the real problem is $expected propogating where it shouldn't - we need two levels of $expected -
# one for "this expression MUST evaluate to" and another for "anything returned out of this code block must be".
# the first implies the latter. either all of that, or else we need to be able to tell when an expression doesn't
# return anything and ignore its (lack of) output. which it looks like we might be able to acheive!
# possible solutions: 
# x. info from opcodes.pl about whether each arg is a list, scalar, array, etc. somewhat useful, maybe.
# x. hand crafted list of which ops sometimes return things and those that never do. if we get to the
#    bottom and haven't found anything yet, then we can return the "none" typeob.
# x. context!

-----------------------

       Scratchpads and recursion

       In fact it is not 100% true that a compiled unit contains
       a pointer to the scratchpad AV. In fact it contains a
       pointer to an AV of (initially) one element, and this ele-
       ment is the scratchpad AV. Why do we need an extra level
       of indirection?

       The answer is recursion, and maybe threads. Both these can
       create several execution pointers going into the same sub-
       routine. For the subroutine-child not write over the tem-
       poraries for the subroutine-parent (lifespan of which cov-
       ers the call to the child), the parent and the child
       should have different scratchpads. (And the lexicals
       should be separate anyway!)

       So each subroutine is born with an array of scratchpads
       (of length 1).  On each entry to the subroutine it is
       checked that the current depth of the recursion is not
       more than the length of this array, and if it is, new
       scratchpad is created and pushed into the array.
       The targets on this scratchpad are "undef"s, but they are
       already marked with correct flags.

        my $target = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
        my $name =   (($cv->PADLIST->ARRAY)[0]->ARRAY)[$targ];  # from B::Concise


---------

Context propogation:

       When a context for a part of compile tree is known, it is
       propagated down through the tree.  At this time the con-
       text can have 5 values (instead of 2 for runtime context):
       void, boolean, scalar, list, and lvalue.  In contrast with
       the pass 1 this pass is processed from top to bottom: a
       node's context determines the context for its children.

-----------

    sub compat   { my $self = shift; my @in = @{$self->accepts()}; my @out = @{$self->emits()};
                   foreach my $out (@out) { foreach my $in (@in) { $in->isa($out, 'array used inconsistently'); } } }

Everything accepted into an array must by usable every place a value is expected from that array.
Lets say we have A, B, C, and D, such that D isa C, C isa B, and B isa A. So, the inheritance tree would
look like:

  A <- B <- C <- D

  arr->accept(C)    
  arr->accept(D)     
  arr->emit(B)   # no problem - C and D both pass the isa(B) test
  arr->accept(A) # problem - A does not pass the isa(B) test

As long is nothing is emitted, the array will accept anything. If one thing is emitted
from the array (pushed or shifted off), then everything added to that array at any point
must be an instance of that expected type. If multiple different types are expected at
different points, then everything added to the array must pass the isa test for each 
thing expected from it.

On a related note:

sub type in typesafety::typeob might want to consider doing something sort of like this:

  $self->[0] = common_type_from_list(@{$self->accepts()}) if ! $self->[0] and $self->accepts(); 

but get the least common type instead of most common, should the emits() test fail. This would cover cases
where where a value or two has been assigned to an array, and we want to know what to expect from it. Right
now, we're infering the type purely from has been assigned to it.

------

# sub foo (int $la, string $bar) {
# }

    if($cv->FLAGS & SVf_POK && !$function_params{$cv->START->seq}) {
        #we have, we have, we have arguments
        my @type;
        my @name;
        my $i = 1;
        foreach (split ",", $cv->PV)  {
            my ($type, $sigil, $name) = split /\b/, $_;
        #    print "$type - $sigil - $name \n";
            push @type, $type;
            if($sigil && $name)  {
                push @name, $sigil.$name;
                $typed{$cv->ROOT->seq}->{"$sigil$name"}->{type} = $type;
                $typed{$cv->ROOT->seq}->{"$sigil$name"}->{name} = $sigil.$name;
            } else {
                push @name, "Argument $i";
            }
            $i++;
        }

        $function_params{$cv->START->seq}->{name} = \@name;
        $function_params{$cv->START->seq}->{type} = \@type;


        #print $cv->PV . "\n";
        $cv->PV(";@");

    }

---------

Two constructs that *must* be supported in methods in order for this whole thing to be useful:

my $foo = shift; # done! 

my($a, $b, $c) = @_ 

b  <@> leave[$a:1,2] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
a     <2> aassign[t5] vKS ->b
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av[t4] lK/1 ->6           <-- below here will be different in a method - *_ instead of *ARGV
4              <$> gv(*_) s ->5
-        <1> ex-list lKPRM*/128 ->a
6           <0> pushmark sRM*/128 ->7
7           <0> padsv[$a:1,2] lRM*/LVINTRO ->8
8           <0> padsv[$b:1,2] lRM*/LVINTRO ->9
9           <0> padsv[$c:1,2] lRM*/LVINTRO ->a

----------

major overview of this program:

several routines exist to handle the creation, storage, and lookup of typeobs.
lookup_targ() creates and stores typeobs for unknown lexical scalars upon demand
and always returns a valid typeob. lookup_method() returns typeobs created from
the prototyping of methods. yes, we use typeobs for everything - there are a 
number of subclasses, but each follows from the same basic idea.

import() is called when we are use'd. it exports a proto() method and keeps a list of
package names that should be inspected for typesafety (any package that uses us).

check() is what the user calls to trigger typechecking. it does three things, in order:
pass over all namespaces in order examining each method for prototypes and recording the
prototyped information; perform type analysis on the mainroot (code not in methods in
the main package); perform type analysis on all methods in order. type analysis is
done by calling solve_list_type() or enforce_list_type(). lookup_type() autovivicates
a typeob if needed to represent any given type, but it uses the typeob representing
the new() method for a given type if one is available. define_method() is called by
proto() to register a typeob for a given method in a given package. canned_type()
returns a preconfigured generic typeob that should be cloned and configured. 
the most two significant of these are "unknown" and "none" - unknown is the result
of an operation that we know to produce a value but we don't understand. "none"
litterally represents no value - this special typeob is disreguarded in many places,
for example when extracting a common type from a list of types. it is used when
a typeob is expected but the expression being examined doesn't produce anything.

solve_type() is the main routine. given an opcode and an optional expected type in
the form of a typeob, it may die if it finds an op that returns something else,
but will otherwise just return a typeob representing the type that the expression
evaluates to. it calls itself and other solve|enforce*_type methods recursively -
all opcodes under the opcode passed to it are checked. all of the heuristics about
how different opcodes work are in here and solve_lit().

solve_list_type() is like solve_type() in purpose, but uses solve_type() to get 
the real work done. solve_list_type() is called for an op that has siblings,
and the common type between that op and its siblings is desired. this happens
for example in an argument list. it is always safe to call this in place of 
solve_type().

enforce_type() and enforce_list_type() are wrappers for the two above functions.
they make sure that the type returned by solve_type() and solve_list_type() match
an expected type and throw a given diagnostic message if not.

common_type_from_list() is a utility function that takes a list of typeobs and
returns the one typeob from the list that encompases everything (everything else isa).
this is used on arrays and ops that take lists, such as return. the value of the
list of values is considered to be "greatest common" type. 

there are other utility methods, but they are pretty straight forward.

then there are typeobs - typeobs come in a few flavors - arrayobs, scalarobs, methodobs,
and plain tyepobs (the base class). each subclass adds logic for dealing with problems
specific to the use of typeobs. arrayobs track how they are used - both values sent
and in and taken out - and ensures usage is consistent. methodobs take information
from the prototype for a method and provide values for indices and shifts on the
argument list.

good luck!
-scott

-------------

OPpOUR_INTRO, OPpLVAL_INTRO when $op->name =~ /^(gv|rv2)[ash]v$/

------------

sub populate_curcvlex {
    my $self = shift;
    for (my $cv = $self->{'curcv'}; class($cv) eq "CV"; $cv = $cv->OUTSIDE) {
        my @padlist = $cv->PADLIST->ARRAY;
        my @ns = $padlist[0]->ARRAY;

        for (my $i=0; $i<@ns; ++$i) {
            next if class($ns[$i]) eq "SPECIAL";
            next if $ns[$i]->FLAGS & SVpad_OUR;  # Skip "our" vars
            if (class($ns[$i]) eq "PV") {
                # Probably that pesky lexical @_
                next;
            }
            my $name = $ns[$i]->PVX;
            my $seq_st = $ns[$i]->NVX;
            my $seq_en = int($ns[$i]->IVX);

            push @{$self->{'curcvlex'}{$name}}, [$seq_st, $seq_en];
        }
    }
}

----------


sub find_scope_st { ((find_scope(@_))[0]); }
sub find_scope_en { ((find_scope(@_))[1]); }

# Recurses down the tree, looking for pad variable introductions and COPs
sub find_scope {
    my ($self, $op, $scope_st, $scope_en) = @_;
    carp("Undefined op in find_scope") if !defined $op;
    return ($scope_st, $scope_en) unless $op->flags & OPf_KIDS;

    for (my $o=$op->first; $$o; $o=$o->sibling) {
        if ($o->name =~ /^pad.v$/ && $o->private & OPpLVAL_INTRO) {
            my $s = int($self->padname_sv($o->targ)->NVX);
            my $e = $self->padname_sv($o->targ)->IVX;
            $scope_st = $s if !defined($scope_st) || $s < $scope_st;
            $scope_en = $e if !defined($scope_en) || $e > $scope_en;
        }
        elsif (is_state($o)) {
            my $c = $o->cop_seq;
            $scope_st = $c if !defined($scope_st) || $c < $scope_st;
            $scope_en = $c if !defined($scope_en) || $c > $scope_en;
        }
        elsif ($o->flags & OPf_KIDS) {
            ($scope_st, $scope_en) =
                $self->find_scope($o, $scope_st, $scope_en)
        }
    }

    return ($scope_st, $scope_en);
}

----------

sub pp_unstack { return "" } # see also leaveloop

sub pp_stub {
    my $self = shift;
    my($op, $cx, $name) = @_;
    if ($cx) {
        return "()";
    }
    else {
        return "();";
    }
}   

----------

sub pp_exists {
    my $self = shift;
    my($op, $cx) = @_;
    my $arg;
    if ($op->private & OPpEXISTS_SUB) {
        # Checking for the existence of a subroutine
        return $self->maybe_parens_func("exists",
                                $self->pp_rv2cv($op->first, 16), $cx, 16);
    }
    if ($op->flags & OPf_SPECIAL) {
        # Array element, not hash element
        return $self->maybe_parens_func("exists",
                                $self->pp_aelem($op->first, 16), $cx, 16);
    }
    return $self->maybe_parens_func("exists", $self->pp_helem($op->first, 16),
                                    $cx, 16);
}

sub pp_delete {
    my $self = shift;
    my($op, $cx) = @_;
    my $arg;
    if ($op->private & OPpSLICE) {
        if ($op->flags & OPf_SPECIAL) {
            # Deleting from an array, not a hash
            return $self->maybe_parens_func("delete",
                                        $self->pp_aslice($op->first, 16),
                                        $cx, 16);
        }
        return $self->maybe_parens_func("delete",
                                        $self->pp_hslice($op->first, 16),
                                        $cx, 16);
    } else {
        if ($op->flags & OPf_SPECIAL) {
            # Deleting from an array, not a hash
            return $self->maybe_parens_func("delete",
                                        $self->pp_aelem($op->first, 16),
                                        $cx, 16);
        }
        return $self->maybe_parens_func("delete",
                                        $self->pp_helem($op->first, 16),
                                        $cx, 16);
    }
}

----------

        } elsif (!null($kid->sibling) and
                 $kid->sibling->name eq "anoncode") {
            return "sub " .
                $self->deparse_sub($self->padval($kid->sibling->targ));



----------

http://groups.google.com/groups?threadm=200208052352.g75NqGj05578%40crypt.compulink.co.uk
http://groups.google.com/groups?threadm=3D511373.8050706%40hexaflux.com


-----------

Of course, untyped arrays and hashes will be just as acceptable as they are currently. But a language can only run so fast when you force it to defer all type checking and method lookup till run time.

The intent is to make use of type information where it's useful, and not require it where it's not. Besides performance and safety, one other place where type information is useful is in writing interfaces to other languages.

-apo2

------

In Perl 5, a lot of contextual processing was done at run-time, and even then, a given function could only discover whether it was in void, scalar or list context. In Perl 6, we will extend the notion of context to be more amenable to both compile-time and run-time analysis. In particular, a function or method can know (theoretically even at compile time) when it is being called in:

    Void context
    Scalar context
        Boolean context
        Integer context
        Numeric context
        String context
        Object context
    List context
        Flattening list context (true list context).
        Non-flattening list context (list of scalars/objects)
        Lazy list context (list of closures)
        Hash list context (list of pairs)

-apo2

--------------------------

lightbright# perl -MO=Concise
my %hash1;
my %hash2;

$hash1{foo} = new FooBar;
$hash2{foo} = new WrongType;
$hash1{foo} = $hash2{foo};
w  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -:1) v ->3
3     <0> padhv[%hash1:1,3] vM/LVINTRO ->4
4     <;> nextstate(main 2 -:2) v ->5
5     <0> padhv[%hash2:2,3] vM/LVINTRO ->6
6     <;> nextstate(main 3 -:4) v ->7
e     <2> sassign vKS/2 ->f
a        <1> entersub[t3] sKS/TARG ->b
7           <0> pushmark s ->8
8           <$> const(PV "FooBar") sM/BARE ->9
9           <$> method_named(PVIV "new") s ->a
d        <2> helem sKRM*/2 ->e
b           <0> padhv[%hash1:1,3] sR ->c
c           <$> const(PVIV "foo") s/BARE ->d
f     <;> nextstate(main 3 -:5) v ->g
n     <2> sassign vKS/2 ->o
j        <1> entersub[t4] sKS/TARG ->k
g           <0> pushmark s ->h
h           <$> const(PV "WrongType") sM/BARE ->i
i           <$> method_named(PVIV "new") s ->j
m        <2> helem sKRM*/2 ->n
k           <0> padhv[%hash2:2,3] sR ->l
l           <$> const(PVIV "foo") s/BARE ->m
o     <;> nextstate(main 3 -:6) v ->p
v     <2> sassign vKS/2 ->w
r        <2> helem sK/2 ->s
p           <0> padhv[%hash2:2,3] sR ->q
q           <$> const(PVIV "foo") s/BARE ->r
u        <2> helem sKRM*/2 ->v
s           <0> padhv[%hash1:1,3] sR ->t
t           <$> const(PVIV "foo") s/BARE ->u

-------------

%hash1 = %hash2;

11    <2> aassign[t5] vKS ->12
-        <1> ex-list lK ->z
x           <0> pushmark s ->y
y           <0> padhv[%hash2:837,838] l ->z
-        <1> ex-list lK ->11
z           <0> pushmark s ->10
10          <0> padhv[%hash1:836,838] lRM* ->11





----------------------------


