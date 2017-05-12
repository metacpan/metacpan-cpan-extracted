use 5.008;
use strict;
use warnings;

package YAML::Active;
our $VERSION = '1.100810';
# ABSTRACT: Combine data and logic in YAML
use YAML::XS ();    # no imports, we'll define our own Load() and LoadFile()
use Exporter qw(import);
our %EXPORT_TAGS = (
    load   => [qw{Load Load_inactive Reload LoadFile}],
    dump   => [qw{Dump}],
    active => [qw{node_activate array_activate hash_activate}],
    assert => [qw{assert_arrayref assert_hashref}],
    null   => [qw{yaml_NULL NULL}],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
use constant NULL => 'YAML::Active::NULL';

sub should_process_node_in_phase {
    my ($node, $phase) = @_;

    if (defined $phase) {
        return 0
          unless exists $node->{_phase} && $phase eq $node->{_phase};
    } else {
        return 0 if exists $node->{_phase};
    }
    return 1;
}

sub array_activate ($$) {
    my ($node, $phase) = @_;

    #my @result;
    #my @node = @$node;
    #for my $index (0..$#node) {
    #    my $activated = node_activate($node[$index], $phase);
    #    next if ref($activated) eq NULL;
    #    push @result, $activated;
    #}
    #\@result;
    [   grep { ref ne NULL }
        map { node_activate($_, $phase) } @$node
    ];
}

sub hash_activate ($$) {
    my ($node, $phase) = @_;
    return unless should_process_node_in_phase($node, $phase);
    return {
        map {
            my $val = node_activate($node->{$_}, $phase);
            ref $val eq NULL ? () : ($_ => $val)
          } keys %$node
    };
}

sub node_activate ($$) {
    my ($node, $phase) = @_;
    return array_activate($node, $phase) if ref $node eq 'ARRAY';
    return hash_activate($node, $phase) if ref $node eq 'HASH';

    # FIXME:
    # don't just do
    #
    #   return array_activate($node, $phase)
    #
    # because of the following situation:
    #
    #   x: &REF
    #    foo: 1
    #   y: *REF
    #
    # $data->{y} comes out of YAML itself as a proper reference, but when we
    # just replace $data->{x}, the value of $data->{y} still points to the old
    # "{ foo => 1 }" hash ref and so gets replaced independently as well. This
    # means we end up not with a reference but with two reference, each
    # pointing to the same cloned hash.
    #     if (ref $node eq 'ARRAY') {
    #         my $result = array_activate($node, $phase);
    #         if (UNIVERSAL::isa($result, 'ARRAY')) {
    #             @$node = @$result;
    #             return $node;
    #         } else {
    #             return $result;
    #         }
    #     } elsif (ref $node eq 'HASH') {
    #         my $result = hash_activate($node, $phase);
    #         if (UNIVERSAL::isa($result, 'HASH')) {
    #             %$node = %$result;
    #             return $node;
    #         } else {
    #             return $result;
    #         }
    #     }
    if (my $class = ref $node) {
        if (!$class->can('yaml_activate')
            && index($class, 'YAML::Active') != -1) {
            eval "require $class";
            die $@ if $@;
        }
        if ($node->can('yaml_activate')) {
            return $node->yaml_activate($phase);
        } else {

            # it's a blessed reference, but it can't yaml_activate, so dig
            # deeper
            my $activated =
                UNIVERSAL::isa($node, 'ARRAY') ? array_activate($node, $phase)
              : UNIVERSAL::isa($node, 'HASH') ? hash_activate($node, $phase)
              :                                 $node;
            return bless $activated, ref $node;

            #             if (UNIVERSAL::isa($node, 'ARRAY')) {
            #                 my $result = array_activate($node, $phase);
            #                 if (UNIVERSAL::isa($result, 'ARRAY')) {
            #                     # the blessing stays the same
            #                     @$node = @$result;
            #                     return $node;
            #                 } else {
            #                     return bless $result, ref $node;
            #                 }
            #             } elsif (UNIVERSAL::isa($node, 'HASH')) {
            #                 my $result = hash_activate($node, $phase);
            #                 if (UNIVERSAL::isa($result, 'HASH')) {
            #                     # the blessing stays the same
            #                     %$node = %$result;
            #                     return $node;
            #                 } else {
            #                     return bless $result, ref $node;
            #                 }
            #             }
            #
            #             return $node;
        }
    }
    return $node;
}

# pass through
sub Load_inactive {
    my $node = shift;
    YAML::XS::Load($node);
}

sub Load {
    my ($node, $phase) = @_;
    node_activate(YAML::XS::Load($node), $phase)

      #my $x = node_activate(Load_inactive($node), $phase);
      #use Data::Dumper; print Dumper $x;
      #if (ref $x->{setup} eq 'HASH') {
      #    printf "foo [%s]\n", $x->{setup}{foo};
      #    printf "bar [%s]\n", $x->{setup}{bar};
      #}
      #$x;
}

sub Reload {
    my ($node, $phase) = @_;
    Load(Dump($node), $phase);
}

sub LoadFile {
    my ($node, $phase) = @_;
    node_activate(YAML::XS::LoadFile($node), $phase);
}

sub assert_arrayref {
    return if UNIVERSAL::isa($_[0], 'ARRAY');
    die sprintf "%s expects an array ref", (caller)[0];
}

sub assert_hashref {
    return if UNIVERSAL::isa($_[0], 'HASH');
    die sprintf "%s expects a hash ref", (caller)[0];
}
sub yaml_NULL { bless {}, NULL }

# end of activation-related code
# start of dump-related code
sub Dump {
    my ($node, %args) = @_;
    local $YAML::XS::ForceBlock =
      exists $args{ForceBlock} ? $args{ForceBlock} : 1;
    my $dump = YAML::XS::Dump(node_dump($node));
    our %prepare_dump;
    $_->can('finish_dump') && $_->finish_dump for keys %prepare_dump;
    $dump;
}

sub node_dump ($) {
    my $node = shift;
    return array_dump($node) if ref $node eq 'ARRAY';
    return hash_dump($node)  if ref $node eq 'HASH';
    if (my $class = ref $node) {
        if (!$node->can('yaml_dump')) {
            eval "require $class";
            die $@ if $@;
        }
        if ($node->can('prepare_dump')) {
            our %prepare_dump;
            $prepare_dump{ ref $node } ||= $node->prepare_dump;
        }
        return $node->can('yaml_dump') ? $node->yaml_dump : $node;
    }
    return $node;
}

sub array_dump ($) {
    my $node = shift;
    [   grep { ref ne NULL }
        map { node_dump($_) } @$node
    ];
}

sub hash_dump ($) {
    my $node = shift;
    return {
        map {
            my $val = node_dump($node->{$_});
            ref $val eq NULL ? () : ($_ => $val)
          } keys %$node
    };
}

package YAML::Active::Concat;
our $VERSION = '1.100810';
YAML::Active->import(':all');

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_arrayref($self);
    return join '' => @{ array_activate($self, $phase) };
}

package YAML::Active::Eval;
our $VERSION = '1.100810';
YAML::Active->import(':all');

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_hashref($self);
    my $code_ref = eval node_activate($self->{code}, $phase);
    return $code_ref->();
}

package YAML::Active::Include;
our $VERSION = '1.100810';
YAML::Active->import(':all');

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_hashref($self);
    return LoadFile(node_activate($self->{filename}, $phase));
}
sub YAML::Active::PID::yaml_activate { $$ }

package YAML::Active::Shuffle;
our $VERSION = '1.100810';
YAML::Active->import(':all');

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_arrayref($self);
    return [ sort { 1 - int rand 3 } @{ array_activate($self, $phase) } ];
}

# example of a side-effect-only plugin
package YAML::Active::Print;
our $VERSION = '1.100810';
YAML::Active->import(':all');

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_arrayref($self);
    my $result = array_activate($self, $phase);
    print @$result;
    return yaml_NULL();
}

package YAML::Active::ValueMutator;
our $VERSION = '1.100810';
YAML::Active->import(':all');
sub mutate_value { $_[1] }

sub yaml_activate {
    my ($self, $phase) = @_;
    if (UNIVERSAL::isa($self, 'ARRAY')) {
        return [ map { ref($_) ? $_ : $self->mutate_value($_) }
              @{ array_activate($self, $phase) } ];
    } elsif (UNIVERSAL::isa($self, 'HASH')) {
        my $h = hash_activate($self, $phase);
        $_ = $self->mutate_value($_) for grep { !ref } values %$h;
        return $h;
    }
    return $self;    # shouldn't get here
}

package YAML::Active::uc;
our $VERSION = '1.100810';
our @ISA = 'YAML::Active::ValueMutator';
sub mutate_value { uc $_[1] }

package YAML::Active::lc;
our $VERSION = '1.100810';
our @ISA = 'YAML::Active::ValueMutator';
sub mutate_value { lc $_[1] }
1;


__END__
=pod

=head1 NAME

YAML::Active - Combine data and logic in YAML

=head1 VERSION

version 1.100810

=for stopwords LoadFile RPN

=for test_synopsis 1;
__END__

=head1 SYNOPSIS

  use YAML::Active;
  my $data = Load(<<'EOYAML');
  pid: /YAML::Active::PID
    doit:
  foo: bar
  include_test: /YAML::Active::Include
      filename: t/testperson.yaml
  ticket_no: /YAML::Active::Concat
    - '20010101.1234'
    - /YAML::Active::PID
      doit:
    - /YAML::Active::Eval
      code: sub { sprintf "%04d", ++(our $cnt) }
  setup:
    1: /Registry::YAML::Active::WritePerson
       person:
         personname: Foobar
         handle: AB123456-NICAT
    2: /Registry::YAML::Active::WritePerson
       person: /YAML::Active::Include
         filename: t/testperson.yaml
  EOYAML

=head1 DESCRIPTION

YAML is an intuitive way to describe nested data structures. This
module extends YAML's capabilities so that it ceases to be a static
data structure and become something more active, with data and logic
combined. This makes the logic reusable since it is bound to the data
structure. Without C<YAML::Active>, you have to load the YAML data,
then process it in some way. The logic describing which parts of the
data have to be processed and how was separated from the data. Using
C<YAML::Active>, the description of how to process the data can be
encapsulated in the data structure itself.

The way this works is to assign a transfer type to the YAML nodes you
want to process. The transfer type refers to a Perl package which is
expected to have a C<yaml_active()> method which contains the
logic; you can think of the array or hash structure below that node as
the subroutine's arguments.

C<YAML::Active> provides its own C<Load()> and C<LoadFile()>
subroutines which work like the subroutines of the same name in
C<YAML>, except that they also traverse the whole data structure,
recognizing packages named as transfer types that have a
C<yaml_active()> method and calling that method on the given node.

An example:

  some_string: /YAML::Active::Concat
    - foo
    - bar
    - baz

defines a hash key whose value is an active YAML element. When you call
C<YAML::Active>'s C<Load()> on that data, at some point the hash value
is being encountered. The C<YAML::Active::Concat> plugin (as a
convenience also defined in the same file as C<YAML::Active>) has a
C<yaml_active()> method which expects to be called on an array
reference (that is, the thing blessed into C<YAML::Active::Concat> is
expected to be an array reference). The method in turn activates all of
the array's elements and joins the results. So after loading the data
structure, the result is equivalent to

  some_string: foobarbaz

Because C<YAML::Active::Concat> also activates all of its arguments,
you can nest activation logic:

  some_string /YAML::Active::Concat
    - foo
    - /YAML::Active::PID
      doit:
    - /YAML::Active::Eval
      code: sub { sprintf "%04d", ++(our $cnt) }

This active YAML uses two more plugins, C<YAML::Active::PID> and
C<YAML::Active::Eval>. C<YAML::Active::PID> replaces its node with the
current process's id. Note that even though this plugin doesn't need
any arguments, we have to provide something - anything, in fact,
whether it be an array reference or a hash reference, because YAML can
bless only references. C<YAML::Active::Eval> expects a hash reference
with a C<code> key whose value is the source code for an anonymous sub
which the plugin calls and whose return value it uses to replace the
activated node.

An activation plugin (that is, a package referred to by a node's
transfer type) can have any name, but if that name contains the string
C<YAML::Active>, it is being C<required()> if it doesn't already
provide a C<yaml_active()> method. This is merely a convenience so you
don't have to C<use()> or C<require()> the packages beforehand and
things work a bit more transparently. If you merely want to bless a
node (that is, provide a transfer type) into a package that's not an
activation plugin, be sure that the package name doesn't contain the
string C<YAML::Active>.

=head1 FUNCTIONS

=head2 Load

Like C<YAML>'s C<Load()>, but activates the data structure after
loading it and returns the activated data structure.

=head2 Load_inactive

Like C<YAML>'s C<Load()>, it doesn't activate the data structure.

=head2 Dump

Like C<YAML>'s C<Dump()>.

=head2 Reload

Dumps, then loads the data structure and returns the result.

=head2 LoadFile

Like C<YAML>'s C<LoadFile()>, but activates the data structure after
loading it and returns the activated data structure.

=head2 node_activate

Expects a reference and recursively activates it, returning the
resulting reference.

If it encounters an array, it calls C<array_activate()> on the node and
returns the result.

If it encounters a hash, it calls C<hash_activate()> on the node and
returns the result.

If it encounters a node that can be activated (i.e., that is blessed
into a package that has a C<yaml_activate()> method, it activates the
node and returns the result. If the package name contains the string
C<YAML::Active> and it doesn't have a C<yaml_activate()> method,
C<node_activate()> tries to C<require()> the package (as a
convenience). That is, if you want to write a plugin, you can either
include the string C<YAML::Active> somewhere in its package name, or
use any other name but then you'd have to C<use()> or C<require()> it
before activating some YAML.

Otherwise it just returns the node as it could be an unblessed scalar
or a reference blessed into a package that's got nothing to do with
activation.

=head2 array_activate

Takes an array reference and activates every array element in turn,
then returns a new array references containing the results. Null
elements (that is, elements blessed into C<YAML::Active::NULL>) are
ignored.

=head2 hash_activate

Takes a hash reference and activates every value, then returns a new
hash references containing the results (the hash keys are left alone).
Keys with null values (that is, values blessed into
C<YAML::Active::NULL>) are ignored.

=head2 assert_arrayref

Checks that its argument is an array reference. If not, C<die()>s
reporting the caller.

=head2 assert_hashref

Checks that its argument is a hash reference. If not, C<die()>s
reporting the caller.

=head2 yaml_NULL

Returns an empty hash reference blessed into the C<YAML::Active::NULL>
package. This function is used by side-effect-only plugins that don't
want to have a trace of their existence left in the activated data
structure. For an example see the C<YAML::Active::Print>.

=head2 NULL

This is a constant with the value C<YAML::Active::NULL>.

=head2 node_dump

Dumps a data structure node. It is used by C<Dump()>. It calls C<array_dump()>
and C<hash_dump()> as necessary. For scalar nodes, if the node is a blessed
reference and the package it is blessed into has a C<prepare_dump()> function,
that function is called. Then, if the package has a C<yaml_dump()> function,
that function is called as well. After the recursive dump is finished, each
package that had a C<prepare_dump()> function is checked for a
C<finish_dump()> function, which is called if it exists.

=head2 array_dump

Dumps an array reference node. It is called by C<node_dump()> and calls
C<node_dump()> itself on the array elements.

=head2 hash_dump

Dumps a hash reference node. It is called by C<node_dump()> and calls
C<node_dump()> itself on the hash values.

=head2 should_process_node_in_phase

Takes as arguments a node and optionally a phase. If the phase argument is
given, return true for those nodes that have this phase requirements. If the
phase argument is not given, return true for those nodes that don't have a
phase requirements.

=head1 EXPORT

Nothing is exported by default, but you can request each of the subroutines
individually or grouped by tags. The tags and their symbols are, in YAML
notation:

  load:
    - Load
    - LoadFile
  active:
    - node_activate
    - array_activate
    - hash_activate
  assert:
    - assert_arrayref
    - assert_hashref
  null:
    - yaml_NULL
    - NULL

There is also the C<all> tag, which contains all of the above symbols.

=head1 DEFAULT PLUGINS

=over 4

=item C<YAML::Active::Concat>

Expects an array reference and joins the activated array elements,
returning the joined string.

For an example, see the L<DESCRIPTION> above.

=item C<YAML::Active::Eval>

Expects a hash reference with a C<code> key. C<eval>s the activated
hash value returns the result from executing the coderef (passing no
arguments).

Example:

  - /YAML::Active::Eval
    code: sub { sprintf "%04d", ++(our $cnt) }

Result:

  - 1

At least, that's the answer the first time around.

=item C<YAML::Active::Include>

Expects a hash reference with a C<filename> key. Calls
C<YAML::Active>'s C<LoadFile()> on the activated filename. That is,
the filename can itself use an activation plugin, and the file contents
are activated as well.

Example:

  description: /YAML::Active::Include
    filename: description.yaml

Result:

  description: >
    The content of the included file goes here.

=item C<YAML::Active::PID>

Returns the current process id.

Example:

  the_pid: /YAML::Active::PID
    whatever:

Result (for example):

  the_pid: 12345

Note that, although this plugin doesn't require any arguments, we have
to give it either an array reference or a hash reference, because
C<YAML> can't bless something that's not a reference. The contents of
the reference don't matter.

=item C<YAML::Active::Shuffle>

Expects an array reference and returns another array reference with the
activated original elements in random order.

Example:

  data: /YAML::Active::Shuffle
        - 1
        - 2
        - 3
        - 4
        - 5

Result (for example):

  data:
    - 3
    - 5
    - 1
    - 2
    - 4

=item C<YAML::Active::Print>

Expects an array reference and joins the activated array elements,
printing the result and returning a null (i.e., a
C<YAML::Active::NULL>) node. That is, the node won't appear in the
resulting activated data structure.

Example:

  data:
    - foo
    - /YAML::Active::Print
       - '# Hello, world!'
       - 'Goodbye, world!'
    - baz

Result:

  data:
    - foo
    - baz

and the string C<# Hello, world!Goodbye, world!> is printed.

=item C<YAML::Active::uc>

Replaces node values (scalars, array elements and hash values) with
their lowercased value. Does not descend into deeper array references
or hash references, but passes them through unaltered.

Example:

  data: /YAML::Active::uc
    - Hello
    - world and
    - one: GOoD
      two: byE
    - wOrLd!

Result:

  data:
    - HELLO
    - WORLD AND
    - one: GOoD
      two: byE
    - WORLD!

=item C<YAML::Active::lc>

Like C<YAML::Active::uc>, but lowercases the values.

=back

=head1 WRITING YOUR OWN PLUGIN

Suppose you want to write an activation plugin that takes a reference
to an array of numbers and adds them.

By including the string C<YAML::Active> in the package name we can let
C<YAML::Active> load the package when necessary. All we need to do is
to provide a C<yaml_activate()> method that does the work.

  package My::YAML::Active::Add;

  use YAML::Active qw/array_activate assert_arrayref/;

  sub yaml_activate {
      my $self = shift;
      assert_arrayref($self);
      my $result;
      $result += $_ for @{ array_activate($self) };
      return $result;
  }

Now you can do:

  result: /My::YAML::Active::Add
    - 1
    - 2
    - 3
    - 7
    - 15

And the result would be:

  result: 28

This could be the beginning of a YAML-based stack machine or at least
an RPN calculator...

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=YAML-Active>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/YAML-Active/>.

The development version lives at
L<http://github.com/hanekomu/YAML-Active/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

