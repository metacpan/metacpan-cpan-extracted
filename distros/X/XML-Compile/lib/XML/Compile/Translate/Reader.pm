# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Translate::Reader;
use vars '$VERSION';
$VERSION = '1.63';

use base 'XML::Compile::Translate';

use strict;
use warnings;
no warnings 'once', 'recursion';

use Log::Report       'xml-compile';

use List::Util         qw/first/;
use Scalar::Util       qw/weaken blessed/;

use XML::Compile::Util qw/pack_type odd_elements type_of_node SCHEMA2001i/;
use XML::Compile::Iterator ();


# Each action implementation returns a code reference, which will be
# used to do the run-time work.  The mechanism of `closures' is used to
# keep the important information.  Be sure that you understand closures
# before you attempt to change anything.

# The returned reader subroutines will always be called
#      my @pairs = $reader->($tree);

# Some error messages are labeled with 'misfit' which is used to indicate
# that the structure of found data is not conforming the needs. For optional
# blocks, these errors are caught and un-done.

sub actsAs($)             {$_[1] eq 'READER'}
sub makeTagUnqualified(@) {$_[3]} # ($self, $path, $node, $local, $ns)
sub makeTagQualified(@)   {$_[3]} # same params

sub typemapToHooks($$)
{   my ($self, $hooks, $typemap) = @_;
    while(my($type, $action) = each %$typemap)
    {   defined $action or next;
        my $hook;
        if(!ref $action)
        {   my $class = $action;
            no strict 'refs';
            keys %{$class.'::'}
                or error __x"class {pkg} for typemap {type} is not loaded"
                     , pkg => $class, type => $type;

            $class->can('fromXML')
                or error __x"class {pkg} does not implement fromXML(), required for typemap {type}"
                     , pkg => $class, type => $type;

            trace "created reader hook for type $type to class $class";
            $hook = sub { $class->fromXML($_[1], $type) };
        }
        elsif(ref $action eq 'CODE')
        {   $hook = sub { $action->(READER => $_[1], $type) };
            trace "created reader hook for type $type to CODE";
        }
        else
        {   my $object = $action;
            $object->can('fromXML')
                or error __x"object of class {pkg} does not implement fromXML(), required for typemap {type}"
                     , pkg => ref($object), type => $type;

            trace "created reader hook for type $type to object";
            $hook = sub {$object->fromXML($_[1], $type)};
        }

        push @$hooks, +{action => 'READER', type => $type, after => $hook};
    }
    $hooks;
}

sub makeElementWrapper
{   my ($self, $path, $processor) = @_;
    # no copy of $_[0], because it may be a large string
    sub { my $tree;
          if(blessed $_[0] && $_[0]->isa('XML::LibXML::Iterator'))
          {   $tree = $_[0];
          }
          else
          {   my $xml = XML::Compile->dataToXML($_[0])
                  or return ();
              $xml    = $xml->documentElement
                  if $xml->isa('XML::LibXML::Document');
              $tree   = XML::Compile::Iterator->new($xml, 'top',
                  sub { $_[0]->isa('XML::LibXML::Element') } );
          }

          my $data = ($processor->($tree))[-1];
          unless(defined $data)
          {    my $node = $tree->node;
               error __x"data not recognized, found a `{type}' at {where}"
                  , type => type_of_node $node, where => $node->nodePath;
          }
          $data;
        };
}

sub makeAttributeWrapper
{   my ($self, $path, $processor) = @_;

    sub { my $attr = shift;
          ref $attr && $attr->isa('XML::LibXML::Attr')
              or error __x"expects an attribute node, but got `{something}' at {path}"
                   , something => (ref $attr || $attr), path => $path;

          my $node = XML::LibXML::Element->new('dummy');
          $node->addChild($attr);

          $processor->($node);
        };
}

sub makeWrapperNs        # no namespaces in the HASH
{   my ($self, $path, $processor, $index, $filter) = @_;
    $processor;
}

#
## Element
#

sub makeSequence($@)
{   my ($self, $path, @pairs) = @_;
    if(@pairs==2)
    {   my ($take, $action) = @pairs;
        my $code
         = (ref $action eq 'BLOCK' || ref $action eq 'ANY')
         ? sub { $action->($_[0]) }
         : sub { $action->($_[0] && $_[0]->currentType eq $take ? $_[0]:undef)};
        return bless $code, 'BLOCK';
    }

    bless
    sub { my $tree = shift;
          my @res;
          my @do = @pairs;

          while(@do)
          {   my ($take, $do) = (shift @do, shift @do);
              push @res, ref $do eq 'BLOCK'
                      || ref $do eq 'ANY'
                      || (defined $tree && $tree->currentType eq $take)
                       ? $do->($tree) : $do->(undef);
          }

          @res;
        }, 'BLOCK';
}

sub makeChoice($@)
{   my ($self, $path, %do) = @_;
    my @specials;
    foreach my $el (keys %do)
    {   push @specials, delete $do{$el}
            if ref $do{$el} eq 'BLOCK' || ref $do{$el} eq 'ANY';
    }

    if(keys %do==1 && !@specials)
    {   my ($option, $action) = %do;
        return bless
        sub { my $tree = shift;
              my $type = defined $tree ? $tree->currentType : '';
              return $action->($tree)
                  if $type eq $option;

              try { $action->(undef) };  # minOccurs=0
              $@ or return ();

              $type
                  or error __x"element `{tag}' expected for choice at {path}"
                       , tag => $option, path => $path, _class => 'misfit';

              error __x"single choice option `{option}' at `{type}' at {path}"
                , option => $option, type => $type, path => $path
                , _class => 'misfit';
         }, 'BLOCK';
    }

    @specials or return bless
    sub { my $tree = shift;
          my $type = defined $tree ? $tree->currentType : undef;
          my $elem = defined $type ? $do{$type} : undef;
          return $elem->($tree) if $elem;

          # very silly situation: some people use a minOccurs within
          # a choice, instead on choice itself.  That always succeeds.
          foreach my $some (values %do)
          {   try { $some->(undef) };
              $@ or return ();
          }

          $type
              or error __x"no element left to pick choice at {path}"
                   , path => $path, _class => 'misfit';

          trace "choose element from @{[sort keys %do]}";
          error __x"no applicable choice for `{tag}' at {path}"
            , tag => $type, path => $path, _class => 'misfit';
    }, 'BLOCK';

    return bless
    sub { my $tree = shift;
          my $type = defined $tree ? $tree->currentType : undef;
          my $elem = defined $type ? $do{$type} : undef;
          return $elem->($tree) if $elem;

          my @special_errors;
          foreach (@specials)
          {   my @d = try { $_->($tree) };
              return @d if !$@ && @d;
              push @special_errors, $@->wasFatal->message if $@;
          }

          foreach my $some (values %do, @specials)
          {   try { $some->(undef) };
              $@ or return ();
          }

          $type
              or error __x"choice needs more elements at {path}"
                   , path => $path, _class => 'misfit';


          my @elems = sort keys %do;
          trace "choose element from @elems or fix special at $path" if @elems;
          trace "failed specials in choice: $_" for @special_errors;

          error __x"no applicable choice for `{tag}' at {path}"
            , tag => $type, path => $path, _class => 'misfit';
    }, 'BLOCK';
}

sub makeAll($@)
{   my ($self, $path, %pairs) = @_;
    my %specials;
    foreach my $el (keys %pairs)
    {   $specials{$el} = delete $pairs{$el}
            if ref $pairs{$el} eq 'BLOCK' || ref $pairs{$el} eq 'ANY';
    }

    if(!%specials && keys %pairs==1)
    {   my ($take, $do) = %pairs;
        return bless
        sub { my $tree = shift;
              $do->($tree && $tree->currentType eq $take ? $tree : undef);
            }, 'BLOCK';
    }

    keys %specials or return bless
    sub { my $tree = shift;
          my %do   = %pairs;
          my @res;
          while(1)
          {   my $type = $tree && $tree->currentType or last;
              my $do   = delete $do{$type}  or last; # already seen?
              push @res, $do->($tree);
          }

          # saw all of all?
          push @res, $_->(undef)
              for values %do;

          @res;
        }, 'BLOCK';

    # an 'all' block with nested structures or any is quite nasty.  Don't
    # forget that 'all' can have maxOccurs > 1 !
    bless
    sub { my $tree = shift;
          my %do   = %pairs;
          my %spseen;
          my @res;
       PARTICLE:
          while(1)
          {   my $type = $tree->currentType or last;
              if(my $do = delete $do{$type})
              {   push @res, $do->($tree);
                  next PARTICLE;
              }

              foreach (keys %specials)
              {   next if $spseen{$_};
                  my @d = try { $specials{$_}->($tree) };
                  next if $@;

                  $spseen{$_}++;
                  push @res, @d;
                  next PARTICLE;
              }

              last;
          }
          @res or return ();

          # saw all of all?
          push @res, $_->(undef)
              for values %do;

          push @res, $_->(undef)
              for map {$spseen{$_} ? () : $specials{$_}} keys %specials;

          @res;
        }, 'BLOCK';
}

sub makeBlockHandler
{   my ($self, $path, $label, $min, $max, $process, $kind, $multi) = @_;

    # flatten the HASH: when a block appears only once, there will
    # not be an additional nesting in the output tree.
    if($max ne 'unbounded' && $max==1)
    {
        return ($label => $process) if $min==1;

        my $code =
        sub { my $tree    = shift or return ();
              my $starter = $tree->currentChild or return ();
              my @pairs   = try { $process->($tree) };
              if($@->wasFatal(class => 'misfit'))
              {   my $ending = $tree->currentChild;
                  $@->reportAll if !$ending || $ending!=$starter;
                  return ();
              }
              elsif($@) {$@->reportAll}
              @pairs;
            };
        return ($label => bless($code, 'BLOCK'));
    }

    if($max ne 'unbounded' && $min>=$max)
    {   my $code =
        sub { my $tree = shift;
              my @res;
              while(@res < $min)
              {   my @pairs = $process->($tree);
                  push @res, {@pairs};
              }
              ($multi => \@res);
            };
         return ($label => bless($code, 'BLOCK'));
    }

    if($min==0)
    {   my $code =
        sub { my $tree = shift or return ();
              my @res;
              while($max eq 'unbounded' || @res < $max)
              {   my $starter = $tree->currentChild or last;
                  my @pairs   = try { $process->($tree) };
                  if($@->wasFatal(class => 'misfit'))
                  {   # misfit error is ok, if nothing consumed
                      trace "misfit $label ($min..$max) ".$@->wasFatal->message;
                      my $ending = $tree->currentChild;
                      $@->reportAll if !$ending || $ending!=$starter;
                      last;
                  }
                  elsif($@) {$@->reportAll}

                  @pairs or last;
                  push @res, {@pairs};
              }

              @res ? ($multi => \@res) : ();
            };
         return ($label => bless($code, 'BLOCK'));
    }

    my $code =
    sub { my $tree = shift or error __xn
             "block with `{name}' is required at least once at {path}"
           , "block with `{name}' is required at least {_count} times at {path}"
           , $min, name => $label, path => $path;

          my @res;
          while(@res < $min)
          {   my @pairs = $process->($tree);
              push @res, {@pairs};
          }
          while($max eq 'unbounded' || @res < $max)
          {   my $starter = $tree->currentChild or last;
              my @pairs   = try { $process->($tree) };
              if($@->wasFatal(class => 'misfit'))
              {   # misfit error is ok, if nothing consumed
                  trace "misfit $label ($min..) ".$@->wasFatal->message;
                  my $ending = $tree->currentChild;
                  $@->reportAll if !$ending || $ending!=$starter;
                  last;
              }
              elsif($@) {$@->reportAll};

              @pairs or last;
              push @res, {@pairs};
          }
          ($multi => \@res);
        };

    ($label => bless($code, 'BLOCK'));
}

sub makeElementHandler
{   my ($self, $path, $label, $min, $max, $required, $optional) = @_;
    $max eq "0" and return sub {};  # max can be "unbounded", hence strcmp

    if($max ne 'unbounded' && $max==1)
    {   return $min==1
        ? sub { my $tree  = shift;
                my @pairs = $required->(defined $tree ? $tree->descend :undef);
                $tree->nextChild if defined $tree;
                ($label => $pairs[1]);
              }
        : sub { my $tree  = shift or return ();
                $tree->currentChild or return ();
                my @pairs = $optional->($tree->descend);
                $tree->nextChild;
                @pairs or return ();
                ($label => $pairs[1]);
              };
    }
        
    if($max ne 'unbounded' && $min>=$max)
    {   return
        sub { my $tree = shift;
              my @res;
              while(@res < $min)
              {   my @pairs = $required->(defined $tree ? $tree->descend:undef);
                  push @res, $pairs[1];
                  $tree->nextChild if defined $tree;
              }
              @res ? ($label => \@res) : ();
            };
    }

    if(!defined $required)
    {   return
        sub { my $tree = shift or return ();
              my @res;
              while($max eq 'unbounded' || @res < $max)
              {   $tree->currentChild or last;
                  my @pairs = $optional->($tree->descend);
                  @pairs or last;
                  push @res, $pairs[1];
                  $tree->nextChild;
              }
              @res ? ($label => \@res) : ();
            };
    }

    sub { my $tree = shift;
          my @res;
          while(@res < $min)
          {   my @pairs = $required->(defined $tree ? $tree->descend : undef);
              push @res, $pairs[1];
              $tree->nextChild if defined $tree;
          }
          while(defined $tree && ($max eq 'unbounded' || @res < $max))
          {   $tree->currentChild or last;
              my @pairs = $optional->($tree->descend);
              @pairs or last;
              push @res, $pairs[1];
              $tree->nextChild;
          }
          ($label => \@res);
        };
}

sub makeRequired
{   my ($self, $path, $label, $do) = @_;

    my $req =
    sub { my $tree  = shift;  # can be undef
          my @pairs = $do->($tree);
          @pairs
              or error __x"data for element or block starting with `{tag}' missing at {path}"
               , tag => $label, path => $path, _class => 'misfit';
          @pairs;
        };
    ref $do eq 'BLOCK' ? bless($req, 'BLOCK') : $req;
}

sub makeElementHref
{   my ($self, $path, $ns, $childname, $do) = @_;

    sub { my $tree  = shift;

          return ($childname => $tree->node)
              if defined $tree
              && $tree->nodeType eq $childname
              && $tree->node->hasAttribute('href');

          $do->($tree);
        };
}

sub makeElement
{   my ($self, $path, $ns, $childname, $do) = @_;
    sub { my $tree  = shift;
          my $value = defined $tree && $tree->nodeType eq $childname
             ? $do->($tree) : $do->(undef);
          defined $value ? ($childname => $value) : ();
        };
}

sub makeElementDefault
{   my ($self, $path, $ns, $childname, $do, $default) = @_;

    my $mode = $self->{default_values};
    $mode eq 'IGNORE'
       and return sub
        { my $tree = shift or return ();
          return () if $tree->nodeType ne $childname
                    || $tree->node->textContent eq '';
          $do->($tree);
        };

    my $def = $do->($default);

    $mode eq 'EXTEND'
       and return sub
        { my $tree = shift;
          return ($childname => $def)
              if !defined $tree 
              || $tree->nodeType ne $childname
              || $tree->node->textContent eq '';

          $do->($tree);
        };

     $mode eq 'MINIMAL'
        and return sub
        { my $tree = shift or return ();
          return () if $tree->nodeType ne $childname
                    || $tree->node->textContent eq '';
          my $v = $do->($tree);
          undef $v if defined $v && $v eq $def;
          ($childname => $v);
        };

    error __x"illegal default_values mode `{mode}'", mode => $mode;
}

sub makeElementFixed
{   my ($self, $path, $ns, $childname, $do, $fixed) = @_;
    my ($tag, $fix) = $do->($fixed);

    sub { my $tree = shift;
          my ($label, $value)
            = $tree && $tree->nodeType eq $childname ? $do->($tree) : ();

          defined $value
              or return ($tag => $fix);

          $value eq $fix
              or error __x"element `{name}' must have fixed value `{fixed}', got `{value}' at {path}"
                     , name => $childname, fixed => $fix, value => $value
                     , path => $path;

          ($label => $value);
        };
}

sub makeElementAbstract
{   my ($self, $path, $ns, $childname, $do, $tag) = @_;
    sub { my $tree = shift or return ();
          $tree->nodeType eq $childname or return ();

          error __x"abstract element `{name}' used at {path}"
            , name => $childname, path => $path;
        };
}

#
# complexType and complexType/ComplexContent
#

# Be warned that the location reported in 'path' may not be the actual
# location, caused by the cashing of compiled schema components.  The
# path you see is the first path where that element was encountered.
sub _not_processed($$)
{   my ($child, $path) = @_;
    error __x"element `{name}' not processed for {path} at {where}"
      , name => type_of_node($child), path => $path
      , _class => 'misfit', where => $child->nodePath;
}

sub makeComplexElement
{   my ($self, $path, $tag, $elems, $attrs, $attrs_any,undef,$is_nillable) = @_;
#my @e = @$elems; my @a = @$attrs;

    my @elems = odd_elements @$elems;
    my @attrs = (odd_elements(@$attrs), @$attrs_any);

    $is_nillable and return
    sub { my $tree    = shift or return ();
          my $node    = $tree->node;
          my %complex =
            ( ($tree->nodeNil ? (_ => 'NIL') : (map $_->($tree), @elems))
            , (map $_->($node), @attrs)
            );

          _not_processed $tree->currentChild, $path
              if $tree->currentChild;

          ($tag => \%complex);
        };

    @elems > 1 || @attrs and return
    sub { my $tree    = shift or return ();
          my $node    = $tree->node;
          my %complex = ((map $_->($tree), @elems), (map $_->($node), @attrs));

          _not_processed $tree->currentChild, $path
              if $tree->currentChild;

          ($tag => \%complex);
        };

    @elems || return
    sub { my $tree = shift or return ();
          _not_processed $tree->currentChild, $path
              if $tree->currentChild;

          ($tag => {});
        };

    my $el = shift @elems;
    sub { my $tree    = shift or return ();
          my %complex = $el->($tree);

          _not_processed $tree->currentChild, $path
              if $tree->currentChild;

          ($tag => \%complex);
        };
}

#
# complexType/simpleContent
#

sub makeTaggedElement
{   my ($self, $path, $tag, $st, $attrs, $attrs_any,undef,$is_nillable) = @_;
    my @attrs = (odd_elements(@$attrs), @$attrs_any);

    sub { my $tree   = shift // return ();
          my $simple = $is_nillable && ref $tree && $tree->nodeNil ? 'NIL' : $st->($tree);
          ref $tree or return ($tag => {_ => $simple});
          my $node   = $tree->node;
          my @pairs  = map $_->($node), @attrs;
          defined $simple || @pairs ?  ($tag => {_ => $simple, @pairs}) : ();
        };
}

#
# complexType mixed or complexContent mixed
#

sub makeMixedElement
{   my ($self, $path, $tag, $elems, $attrs, $attrs_any,undef,$is_nillable) = @_;
    my @attrs = (odd_elements(@$attrs), @$attrs_any);
    my $mixed = $self->{mixed_elements}
         or panic "how to handle mixed?";
$is_nillable and panic "nillable mixed not yet supported";

      ref $mixed eq 'CODE'
    ? sub { my $tree = shift or return;
            my $node = $tree->node or return;
            my @v = $mixed->($path, $node);
            @v ? ($tag => $v[0]) : ();
          }

    : $mixed eq 'XML_NODE'
    ? sub {$_[0] ? ($tag => $_[0]->node) : () }

    : $mixed eq 'ATTRIBUTES'
    ? sub { my $tree   = shift or return;
            my $node   = $tree->node;
            my @pairs  = map $_->($node), @attrs;
            ($tag => { _ => $node, @pairs
                     , _MIXED_ELEMENT_MODE => 'ATTRIBUTES'});
          } 
    : $mixed eq 'TEXTUAL'
    ? sub { my $tree   = shift or return;
            my $node   = $tree->node;
            my @pairs  = map $_->($node), @attrs;
            ($tag => { _ => $node->textContent, @pairs
                     , _MIXED_ELEMENT_MODE => 'TEXTUAL'});
          } 
    : $mixed eq 'XML_STRING'
    ? sub { my $tree   = shift or return;
            my $node   = $tree->node or return;
            ($tag => $node->toString);
          }
    : $mixed eq 'STRUCTURAL'

      # this cannot be reached, because handled somewhere else
    ? panic "mixed structural handled as normal element"

    : error __x"unknown mixed_elements value `{value}'", value => $mixed;
}

#
# simpleType
#

sub makeSimpleElement
{   my ( $self, $path, $tag, $st, undef, undef, $comptype, $is_nillable) = @_;

      $is_nillable
    ? sub { my $tree  = shift // return $st->(undef);
            my $value = (ref $tree && $tree->nodeNil) ? 'NIL' : $st->($tree);
            defined $value ? ($tag => $value) : ();
          }
    : sub { my $value = $st->(@_);
            defined $value ? ($tag => $value) : ();
          };

}

sub default_anytype_handler($$)
{   my ($path, $node) = @_;
    ref $node or return $node;
      (first{ UNIVERSAL::isa($_, 'XML::LibXML::Element') } $node->childNodes)
    ? $node : $node->textContent;
}

sub makeBuiltin
{   my ($self, $path, $node, $type, $def, $check_values) = @_;

    if($type =~ m/}anyType$/)
    {
        if(my $a = $self->{any_type})
        {   return sub {
               my $node
                 = ref $_[0] && UNIVERSAL::isa($_[0], 'XML::Compile::Iterator')
                 ? $_[0]->node : $_[0];
               $a->( $path, $node, \&default_anytype_handler)};
        }
        else
        {   return sub
              { ref $_[0] or return $_[0];
                my $node = UNIVERSAL::isa($_[0], 'XML::Compile::Iterator')
                  ? $_[0]->node : $_[0];
                (first{ UNIVERSAL::isa($_, 'XML::LibXML::Element') }
                     $node->childNodes) ? $node : $node->textContent;
              };
        }
    }

    my $check = $check_values ? $def->{check} : undef;
    my $parse = $def->{parse};
    my $err   = $path eq $type
      ? N__"illegal value `{value}' for type {type}"
      : N__"illegal value `{value}' for type {type} at {path}";

    $check
    ? ( defined $parse
      ? sub { my $value = ref $_[0] ? $_[0]->textContent : $_[0];
              defined $value or return undef;
              return $parse->($value, $_[1]||$_[0])
                  if $check->($value);
              error __x$err, value => $value, type => $type, path => $path;
            }
      : sub { my $value = ref $_[0] ? $_[0]->textContent : $_[0];
              defined $value or return undef;
              return $value if $check->($value);
              error __x$err, value => $value, type => $type, path => $path;
            }
      )

    : ( defined $parse
      ? sub { my $value = ref $_[0] ? $_[0]->textContent : $_[0];
              defined $value or return undef;
              $parse->($value, $_[1]||$_[0]);
            }
      : sub { ref $_[0] ? shift->textContent : $_[0] }
      );
}

sub makeList
{   my ($self, $path, $st) = @_;
    sub { my $tree = shift // return undef;
          my $node
             = UNIVERSAL::isa($tree, 'XML::LibXML::Node') ? $tree
             : ref $tree ? $tree->node : undef;
          my $v = ref $tree ? $tree->textContent : $tree;
          [ grep defined, map $st->($_, $node), split " ", $v ];
        };
}

sub makeFacetsList
{   my ($self, $path, $st, $info, $early, $late) = @_;
    my @e = grep defined, @$early;
    my @l = grep defined, @$late;

    # enumeration and pattern are probably rare
    @e or return sub {
        my $values = $st->(@_) // return;
        $_->($values) for @l;
        $values;
    };

    sub { defined $_[0] or return undef;
        my $list = ref $_[0] ? $_[0]->textContent : $_[0];
        $_->($list) for @e;
        my $values = $st->($_[0]) // return;
        $_->($values) for @l;
        $values;
    };
}

sub makeFacets
{   my ($self, $path, $st, $info, $early, $late) = @_;
	@$early || @$late or return $st;

    unless(@$early)
	{   return sub {
            my $v = $st->(shift);
			defined $v or return undef;
            $v = $_->($v) for @$late;
            $v;
        };
    }

    sub {
        my $v = shift;
        if(@$early)
		{   return if !defined $v;
            $v = $_->($v) for @$early;
        }
        $v = $st->($v) // return undef;
        $v = $_->($v) for @$late;
        $v;
    };
}

sub makeUnion
{   my ($self, $path, @types) = @_;
    sub { my $tree = shift // return undef;
          for(@types) { my $v = try { $_->($tree) }; $@ or return $v }
          my $text = ref $tree ? $tree->textContent : $tree;

          substr $text, 20, -5, '...' if length($text) > 50;
          error __x"no match for `{text}' in union at {path}"
             , text => $text, path => $path;
        };
}

# Attributes

sub makeAttributeRequired
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    sub { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
          defined $node
             or error __x"attribute `{name}' is required at {path}"
                    , name => $tag, path => $path;

          defined $node or return ();
          my $value = $do->($node);
          defined $value ? ($label => $value) : ();
        };
}

sub makeAttributeProhibited
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    sub { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
          defined $node or return ();
          error __x"attribute `{name}' is prohibited at {path}"
              , name => $tag, path => $path;
          ();
        };
}

sub makeAttribute
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    sub { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
          defined $node or return ();
          my $val = $do->($node);
          defined $val ? ($label => $val) : ();
        };
}

sub makeAttributeDefault
{   my ($self, $path, $ns, $tag, $label, $do, $default) = @_;

    my $mode = $self->{default_values};
    $mode eq 'IGNORE'
        and return sub
          { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
            defined $node ? ($label => $do->($node)) : () };

    my $def = $do->($default);

    $mode eq 'EXTEND'
        and return sub
          { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
            ($label => ($node ? $do->($node) : $def))
          };

    $mode eq 'MINIMAL'
        and return sub
          { my $node = $_[0]->getAttributeNodeNS($ns, $tag);
            my $v = $node ? $do->($node) : $def;
            !defined $v || $v eq $def ? () : ($label => $v);
          };

    error __x"illegal default_values mode `{mode}'", mode => $mode;
}

sub makeAttributeFixed
{   my ($self, $path, $ns, $tag, $label, $do, $fixed) = @_;
    my $def  = $do->($fixed);

    sub { my $node  = $_[0]->getAttributeNodeNS($ns, $tag)
              or return ($label => $def);

          my $value = $do->($node);
          defined $value && $value eq $def
              or error __x"value of attribute `{tag}' is fixed to `{fixed}', not `{value}' at {path}"
                  , tag => $tag, fixed => $def, value => $value, path => $path;

          ($label => $def);
        };
}

# SubstitutionGroups

sub makeSubstgroup
{   my ($self, $path, $base, %do) = @_;
    keys %do or return bless sub { () }, 'BLOCK';

    bless
    sub { my $tree  = shift;
          my $type  = ($tree ? $tree->currentType : undef)
              or error __x"no data for substitution group {type} at {path}"
                    , type => $base, path => $path, class => 'misfit';

          my $do    = $do{$type} or return ();
          my @subst = $do->[1]($tree->descend);
          @subst or return ();

          $tree->nextChild;
          ($do->[0] => $subst[1]);   # key-rewrite
        }, 'BLOCK';
}

# anyAttribute

sub makeAnyAttribute
{   my ($self, $path, $handler, $yes, $no, $process) = @_;
    return () unless defined $handler;

    my %yes = map +($_ => 1), @{$yes || []};
    my %no  = map +($_ => 1), @{$no  || []};

    # Takes all, before filtering
    my $all =
    sub { my @result;
          foreach my $attr ($_[0]->attributes)
          {   $attr->isa('XML::LibXML::Attr') or next;
              my $ns = $attr->namespaceURI || $_[0]->namespaceURI || '';
              next if keys %yes && !$yes{$ns};
              next if keys %no  &&   $no{$ns};

              push @result, pack_type($ns, $attr->localName) => $attr;
          }
          @result;
        };

    weaken $self;

    # Create filter if requested
    my $run = $handler eq 'TAKE_ALL' ? $all
    : ref $handler ne 'CODE'
    ? error(__x"any_attribute handler `{got}' not understood", got => $handler)
    : sub { my @attrs = $all->(@_);
            my @result;
            while(@attrs)
            {   my ($type, $data) = (shift @attrs, shift @attrs);
                my ($label, $out) = $handler->($type, $data, $path, $self);
                push @result, $label, $out if defined $label;
            }
            @result;
          };

     bless $run, 'ANY';
}

# anyElement

sub makeAnyElement
{   my ($self, $path, $handler, $yes, $no, $process, $min, $max) = @_;
    $handler ||= 'SKIP_ALL';

    my %yes = map +($_ => 1), @{$yes || []};
    my %no  = map +($_ => 1), @{$no  || []};

    # Takes all, before filtering
    my $any = ($max eq 'unbounded' || $max > 1)
    ? sub
      {   my $tree  = shift or return ();
          my $count = 0;
          my %result;
          while(   (my $child = $tree->currentChild)
                && ($max eq 'unbounded' || $count < $max))
          {   my $ns = $child->namespaceURI || '';
              $yes{$ns} or last if keys %yes;
              $no{$ns} and last if keys %no;

              my $k = pack_type $ns, $child->localName;
              push @{$result{$k}}, $child;
              $count++;
              $tree->nextChild;
          }

          $count >= $min
              or error __x"too few any elements, requires {min} and got {found}"
                    , min => $min, found => $count;

          %result;
      }
    : sub
      {   my $tree  = shift               or return ();
          my $child = $tree->currentChild or return ();
          my $ns    = $child->namespaceURI || '';

          (!keys %yes || $yes{$ns}) && !(keys %no && $no{$ns})
              or return ();

          $tree->nextChild;
          (type_of_node($child), $child);
      };
 
    bless $any, 'ANY';

# I would like to weaken here, but "ANY" needs the whole compiler structure
# intact: someone has to catch it.
#   weaken $self;

    # Create filter if requested
    my $run
     = $handler eq 'TAKE_ALL' ? $any
     : $handler eq 'SKIP_ALL' ? sub { $any->(@_); () }
     : ref $handler ne 'CODE'
     ? error(__x"any_element handler `{got}' not understood", got => $handler)
     : sub { my @elems = $any->(@_);
             my @result;
             while(@elems)
             {   my ($type, $data) = (shift @elems, shift @elems);
                 my ($label, $out) = $handler->($type, $data, $path, $self);
                 push @result, $label, $out if defined $label;
             }
             @result;
           };

     bless $run, 'ANY';
}

# xsi:type handling

sub makeXsiTypeSwitch($$$$)
{   my ($self, $where, $elem, $default_type, $types) = @_;

    sub {
        my $tree = shift or return;
        my $node = $tree->node or return;
        my $type = $node->getAttributeNS(SCHEMA2001i, 'type');
        my ($alt, $code);
        if($type)
        {   my ($pre, $local) = $type =~ /(.*?)\:(.*)/ ? ($1, $2) : ('',$type);
            $alt  = pack_type $node->lookupNamespaceURI($pre), $local;
            $code = $types->{$alt}
                or error __x"specified xsi:type list for `{default}' does not contain `{got}'"
                     , default => $default_type, got => $type;
        }
        else
        {   ($alt, $code) = ($default_type, $types->{$default_type});
        }

        my ($t, $d) = $code->($tree);
        defined $t or return ();

        $d = { _ => $d } if ref $d ne 'HASH';
        $d->{XSI_TYPE} ||= $alt;
        ($t, $d);
    };
}

# any kind of hook

sub makeHook($$$$$$$)
{   my ($self, $path, $r, $tag, $before, $replace, $after, $fulltype) = @_;
    return $r unless $before || $replace || $after;

    return sub { ($_[0]->node->localName => 'SKIPPED') }
        if $replace && grep $_ eq 'SKIP', @$replace;

    my @replace = $replace ? map $self->_decodeReplace($path,$_),@$replace : ();
    my @before  = $before  ? map $self->_decodeBefore($path,$_), @$before  : ();
    my @after   = $after   ? map $self->_decodeAfter($path,$_),  @$after   : ();

    weaken $self;

    sub
     { my $tree = shift or return ();
       my $xml  = $tree->node;
       foreach (@before)
       {   $xml = $_->($xml, $path, $fulltype);
           defined $xml or return ();
       }

       my $process = sub { $r->($tree->descend($xml)) };
       my @h = @replace
         ? map $_->($xml, $self, $path, $tag, $process, $fulltype), @replace
         : $process->();

       @h or return ();
       my $h = @h==1 ? $h[0] : $h[1];  # detect simpleType
       foreach my $after (@after)
       {   $h = $after->($xml, $h, $path, $fulltype);
           defined $h or return ();
       }
       ($tag => $h);
     };
}

sub _decodeBefore($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';

      $call eq 'PRINT_PATH' ? sub {print "$_[1]\n"; $_[0] }
    : error __x"labeled before hook `{call}' undefined for READER", call=>$call;
}

sub _decodeReplace($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';

      $call eq 'XML_NODE'  ? sub { ($_[3] => $_[0]) }    # don't parse XML
    : error __x"labeled replace hook `{call}' undefined for READER",call=>$call;
}

my %after = 
  ( PRINT_PATH   => sub {print "$_[2]\n"; $_[1] }
  , INCLUDE_PATH => sub { my $h = $_[1];
        $h = { _ => $h } if ref $h ne 'HASH';
        $h->{_PATH} = $_[0];
        $h;
    }
  , XML_NODE     => sub { my $h = $_[1];
        $h = { _ => $h } if ref $h ne 'HASH';
        $h->{_XML_NODE} = $_[0];
        $h;
    }
  , ELEMENT_ORDER => sub { my ($xml, $h) = @_;
        $h = { _ => $h } if ref $h ne 'HASH';
        my @order = map type_of_node($_)
          , grep $_->isa('XML::LibXML::Element'), $xml->childNodes;
        $h->{_ELEMENT_ORDER} = \@order;
        $h;
    }
  , ATTRIBUTE_ORDER => sub { my ($xml, $h) = @_;
        $h = { _ => $h } if ref $h ne 'HASH';
        my @order = map $_->nodeName, $xml->attributes;
        $h->{_ATTRIBUTE_ORDER} = \@order;
        $h;
    }
  , NODE_TYPE => sub { my ($xml, $h) = @_;
        $h = { _ => $h } if ref $h ne 'HASH';
        $h->{_NODE_TYPE} = type_of_node $xml;
        $h;
    }
  );

sub _decodeAfter($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';

    # The 'after' can be called on a single.  In that case, turn it into
    # a HASH for additional information.
    my $dec = $after{$call}
        or error __x"labeled after hook `{call}' undefined for READER"
            , call=> $call;

    $dec;
}

sub makeBlocked($$$)
{   my ($self, $where, $class, $type) = @_;
    my $err_type = $self->prefixed($type) || $type;

    # errors are produced in class=misfit to allow other choices to succeed.
      $class eq 'anyType'
    ? { st => sub { error __x"use of `{type}' blocked at {where}"
              , type => $err_type, where => $where, _class => 'misfit';
          }}
    : $class eq 'simpleType'
    ? { st => sub { error __x"use of {class} `{type}' blocked at {where}"
              , class => $class, type => $err_type, where => $where
              , _class => 'misfit';
          }}
    : $class eq 'complexType'
    ? { elems => [] }
    : $class eq 'ref'
    ? { st => sub { error __x"use of referenced `{type}' blocked at {where}"
              , type => $err_type, where => $where, _class => 'misfit';
          }}
    : panic "blocking of $class for $type not implemented";
}

#-----------------------------------


1;
