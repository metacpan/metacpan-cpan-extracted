# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Translate::Template;
use vars '$VERSION';
$VERSION = '1.63';

use base 'XML::Compile::Translate';

use strict;
use warnings;
no warnings 'once', 'recursion';

use Log::Report    'xml-compile';

use XML::Compile::Util
    qw/odd_elements even_elements SCHEMA2001i pack_type unpack_type/;
use List::Util     qw/max first/;

use vars '$VERSION';         # OODoc adds $VERSION to the script
$VERSION ||= 'undef';


sub makeTagQualified
{   my ($self, $path, $node, $local, $ns) = @_;
    my $prefix = $self->_registerNSprefix('', $ns, 1);

    # it is certainly not correct to do a keyRewrite here, but it works :(
      $self->{_output} eq 'PERL' ? $self->keyRewrite($ns, $local)
    : length $prefix             ? "$prefix:$local"
    :                              $local;
}

sub makeTagUnqualified
{   my ($self, $path, $node, $local, $ns) = @_;
#   $name =~ s/.*\://;
    return $self->keyRewrite($ns, $local)
        if $self->{_output} eq 'PERL';

    my $prefix = $self->_registerNSprefix('', $ns, 1);
    length $prefix ? "$prefix:$local" : $local;
}

# Detect recursion.  Based on type is best, but some schema's do not
# have named types, so tags are indexed as well.
my (%recurse_type, %reuse_type, %recurse_tag, %reuse_tag);

sub compile($@)
{   my ($self, $type, %args) = @_;
    $self->{_output} = $args{output};
    $self->{_style}  = $args{output_style} || 1;
    (%recurse_type, %reuse_type, %recurse_tag, %reuse_tag) = ();
    $self->SUPER::compile($type, %args);
}

sub actsAs($)
{   my ($self, $as) = @_;
       ($as eq 'READER' && $self->{_output} eq 'PERL')
    || ($as eq 'WRITER' && $self->{_output} eq 'XML')
}

sub makeWrapperNs($$$$$)
{   my ($self, $path, $processor, $index, $filter) = @_;

    my @entries;
    $filter = sub {1} if ref $filter ne 'CODE';

    foreach my $entry (sort {$a->{prefix} cmp $b->{prefix}} values %$index)
    {   $entry->{used} or next;
        my ($prefix, $uri) = @{$entry}{'prefix', 'uri'};
        $filter->($uri, $prefix) or next;
        push @entries, [ $uri, $prefix ];
        $entry->{used} = 0;
    }

    sub { my $data = $processor->(@_) or return ();
          if($self->{include_namespaces})
          {   $data->{"xmlns:$_->[1]"} = $_->[0] for @entries;
          }
          $data;
        };
}

sub typemapToHooks($$)
{   my ($self, $hooks, $typemap) = @_;

    while(my($type, $action) = each %$typemap)
    {   defined $action or next;

        my ($struct, $example)
          = $action =~ s/^[\\]?\&/\$/
          ? ( "call on converter function with object"
            , "$action->('WRITER', \$object, '$type', \$doc)")
          : $action =~ m/^\$/
          ? ( "call on converter with object"
            , "$action->toXML(\$object, '$type', \$doc)")
          : ( [ "calls toXML() on $action objects", "  with $type and doc" ]
            , "bless({}, '$action')" );

        my $details  =
          { struct  => $struct
          , example => $example
          };

        push @$hooks, { type => $type, replace => sub { $details} };
    }

    $hooks;
}

sub makeElementWrapper
{   my ($self, $path, $processor) = @_;
    sub { $processor->() };
}
*makeAttributeWrapper = \&makeElementWrapper;

sub _block($@)
{   my ($self, $block, $path, @pairs) = @_;
    bless
    sub { my @elems  = map { $_->()    } odd_elements @pairs;
          my @tags   = map { $_->{tag} } @elems;

          local $" = ', ';
          my $struct = @tags ? "$block of @tags"
            : "empty $block from ".join(" ", even_elements @pairs);

          my @lines;
          while(length $struct > 65)
          {   $struct =~ s/(.{1,60}|\S+)(?:\s+|$)//;
              push @lines, $1;
          }
          push @lines, $struct
              if length $struct;
          $lines[$_] =~ s/^/  / for 1..$#lines;

           { tag    => $block
           , elems  => \@elems
           , struct => \@lines
           };
        }, 'BLOCK';
}

sub makeSequence { my $self = shift; $self->_block(sequence => @_) }
sub makeChoice   { my $self = shift; $self->_block(choice   => @_) }
sub makeAll      { my $self = shift; $self->_block(all      => @_) }

sub makeBlockHandler
{   my ($self, $path, $label, $min, $max, $proc, $kind, $multi) = @_;

    my $code =
    sub { my $data = $proc->();
          my $occur
           = $max eq 'unbounded' && $min==0 ? 'occurs any number of times'
           : $max ne 'unbounded' && $max==1 && $min==0 ? 'is optional' 
           : $max ne 'unbounded' && $max==1 && $min==1 ? ''  # the usual case
           :       "occurs $min <= # <= $max times";

          $data->{occur} ||= $occur if $occur;
          if($max ne 'unbounded' && $max==1)
          {   bless $data, 'BLOCK';
          }
          else
          {   $data->{tag}      = $multi;
              $data->{is_array} = 1;
              bless $data, 'REP-BLOCK';
          }
          $data;
        };
    ($label => $code);
}

sub makeElementHandler
{   my ($self, $path, $label, $min, $max, $req, $opt) = @_;
    sub { my $data = $opt->() or return;
          my $occur
           = $max eq 'unbounded' && $min==0 ? 'occurs any number of times'
           : $max ne 'unbounded' && $max==1 && $min==0 ? 'is optional' 
           : $max ne 'unbounded' && $max==1 && $min==1 ? ''  # the usual case
           :                                  "occurs $min <= # <= $max times";
          $data->{occur}  ||= $occur if $occur;
          $data->{is_array} = $max eq 'unbounded' || $max > 1;
          $data;
        };
}

sub makeRequired
{   my ($self, $path, $label, $do) = @_;
    $do;
}

sub makeElementHref
{   my ($self, $path, $ns, $childname, $do) = @_;
    $do;
}

sub makeElement
{   my ($self, $path, $ns, $childname, $do) = @_;
    sub { my $h = $do->(@_);
          $h->{_NAME} = $childname;
          $h;
    };
}

sub makeElementDefault
{   my ($self, $path, $ns, $childname, $do, $default) = @_;
    sub { my $h = $do->(@_);
          $h->{occur}   = "defaults to '$default'";
          $h->{example} = $default;
          $h;
        };
}

sub makeElementFixed
{   my ($self, $path, $ns, $childname, $do, $fixed) = @_;
    sub { my $h = $do->(@_);
          $h->{occur}   = "fixed to '$fixed'";
          $h->{example} = $fixed;
          $h;
        };
}

sub makeElementAbstract
{   my ($self, $path, $ns, $childname, $do) = @_;
#   sub { () };
    sub {
       my $h = $do->(@_);
       $h->{_NAME} = $childname;
       $h->{occur} = "ABSTRACT";
       $h;
    };
}

sub makeComplexElement
{   my ($self, $path, $tag, $elems, $attrs, $any_attr, $type, $is_nillable)=@_;
    my @elem_parts = odd_elements @$elems;
    my @attr_parts = (odd_elements(@$attrs), @$any_attr);

    sub { my (@attrs, @elems);
          my $is_pseudo_type = $type !~ m/^{/;  # like "unnamed complex"

          if((!$is_pseudo_type && $recurse_type{$type}) || $recurse_tag{$tag})
          {   return
              +{ kind   => 'complex'
               , struct => 'probably a recursive complex'
               , tag    => $tag
               , _TYPE  => $type
               };
          }

          if((!$is_pseudo_type && $reuse_type{$type}) || $reuse_tag{$tag})
          {   return
              +{ kind   => 'complex'
               , struct => 'complex structure shown above'
               , tag    => $tag
               , _TYPE  => $type
               };
          }

          $recurse_type{$type}++; $recurse_tag{$tag}++;
          $reuse_type{$type}++;   $reuse_tag{$tag}++;
          push @elems, $_->() for @elem_parts;
          push @attrs, $_->() for @attr_parts;

          $recurse_type{$type}--; $recurse_tag{$tag}--;

          +{ kind   => 'complex'
           , struct => ($is_nillable ? "is nillable, as: $tag => NIL" : undef)
           , tag    => $tag
           , attrs  => \@attrs
           , elems  => \@elems
           , _TYPE  => $type
           };
        };
}

sub makeTaggedElement
{   my ($self, $path, $tag, $st, $attrs, $attrs_any, $type, $is_nillable) = @_;
    my @parts = (odd_elements(@$attrs), @$attrs_any);

    sub { my @attrs  = map $_->(), @parts;
          my %simple = $st->();

          my @struct = 'string content of the container';
          push @struct, $simple{struct} if $simple{struct};
          push @struct, 'is nillable, hence value or NIL' if $is_nillable;

          my %content =
            ( tag     => '_'
            , struct  => \@struct
            , example => ($simple{example} || 'Hello, World!')
            );
          $content{_TYPE}   = $simple{_TYPE}   if $simple{_TYPE};

          +{ kind    => 'tagged'
           , struct  => "$tag is simple value with attributes"
           , tag     => $tag
           , attrs   => \@attrs
           , elems   => [ \%content ]
           , _TYPE   => $type
           };
        };
}

sub makeMixedElement
{   my ($self, $path, $tag, $elems, $attrs, $attrs_any, $type, $is_nillable)=@_;
    my @parts = (odd_elements(@$attrs), @$attrs_any);

    my @struct = 'mixed content cannot be processed automatically';
    push @struct, 'is nillable' if $is_nillable;

    my %mixed =
     ( tag     => '_'
     , struct  => \@struct
     , example => "XML::LibXML::Element->new('$tag')"
     );

    unless(@parts)   # show simpler alternative
    {   $mixed{tag}   = $tag;
        $mixed{type} = $type;
        return sub { \%mixed };
    }

    sub { my @attrs = map $_->(), @parts;
          +{ kind    => 'mixed'
           , struct  => "$tag has a mixed content"
           , tag     => $tag
           , elems   => [ \%mixed ]
           , attrs   => \@attrs
           , _TYPE   => $type
           };
        };
}

sub makeSimpleElement
{   my ($self, $path, $tag, $st, undef, undef, $type, $is_nillable) = @_;
    sub { my @struct;
          push @struct, 'is nillable, hence value or NIL' if $is_nillable;
          +{ kind    => 'simple'
           , struct  => \@struct
           , tag     => $tag
           , $st->()
           };
        };
}

sub makeBuiltin
{   my ($self, $path, $node, $type, $def, $check_values) = @_;
    sub { (_TYPE=> $type, example => $def->{example}) };
}

sub makeList
{   my ($self, $path, $st) = @_;
    sub { my %d = $st->();
          $d{struct} = 'a list of values, where each';
          my $example = $d{example};
          if($self->{_output} eq 'PERL')
          {   $example    = qq("$example") if $example =~ m/[^0-9.]/;
              $d{example} = "[ $example , ... ]";
          }
          else
          {   $d{example} = "$example $example ...";
          }
          %d };
}

sub makeFacetsList
{   my ($self, $path, $st, $info) = @_;
    $self->makeFacets($path, $st, $info);
}

sub _ff($@)
{  my ($self,$type) = (shift, shift);
    my @lines = $type.':';
    while(@_)
    {   my $facet = shift;
        $facet =~ s/\t/\t/g;
        $facet = qq{"$facet"} if $facet =~ m/\s/;
        push @lines, '  ' if length($lines[-1]) + length($facet) > 55;
        $lines[-1] .= ' '.$facet;
    }
    @lines;
}

sub makeFacets
{   my ($self, $path, $st, $info) = @_;
    my @comment;
    foreach my $k (sort keys %$info)
    {   my $v = $info->{$k};
        push @comment
        , $k eq 'enumeration'  ? $self->_ff('Enum', sort @$v)
        : $k eq 'pattern'      ? $self->_ff('Pattern', @$v)
        : $k eq 'length'       ? "fixed length of $v"
        : $k eq 'maxLength'    ? "length <= $v"
        : $k eq 'minLength'    ? "length >= $v"
        : $k eq 'totalDigits'  ? "total digits is $v"
        : $k eq 'maxScale'     ? "scale <= $v"
        : $k eq 'minScale'     ? "scale >= $v"
        : $k eq 'maxInclusive' ? "value <= $v"
        : $k eq 'maxExclusive' ? "value < $v"
        : $k eq 'minInclusive' ? "value >= $v"
        : $k eq 'minExclusive' ? "value >  $v"
        : $k eq 'fractionDigits' ? "faction digits is $v"
        : $k eq 'whiteSpace'   ? "white-space $v"
        : "restriction? $k = $v";
    }

    my %facet = (facets => \@comment, $st->());

    if(my $enum = $info->{enumeration})
    {   $facet{example} = $enum->[0];
    }

    sub { %facet };
}

sub makeUnion
{   my ($self, $path, @types) = @_;
    sub { my @choices = map { +{$_->()} } @types;
          +( kind    => 'union'
           , struct  => "one of the following (union)"
           , choice  => \@choices
           , example => $choices[0]->{example}
           );
        };
}

sub makeAttributeRequired
{   my ($self, $path, $ns, $tag, $label, $do) = @_;

    sub { +{ kind   => 'attr'
           , tag    => $label
           , occur  => "attribute $tag is required"
           , $do->()
           };
        };
}

sub makeAttributeProhibited
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    ();
}

sub makeAttribute
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    sub { +{ kind    => 'attr'
           , tag     => $tag
           , occur   => "becomes an attribute"
           , $do->()
           };
        };
}

sub makeAttributeDefault
{   my ($self, $path, $ns, $tag, $label, $do) = @_;
    sub {
          +{ kind  => 'attr'
           , tag   => $tag
           , occur => "attribute $tag has default"
           , $do->()
           };
        };
}

sub makeAttributeFixed
{   my ($self, $path, $ns, $tag, $label, $do, $fixed) = @_;
    my $value = $fixed->value;

    sub { +{ kind   => 'attr'
           , tag    => $tag
           , occur  => "attribute $tag is fixed"
           , example => $value
           };
        };
}

sub makeSubstgroup
{   my ($self, $path, $type, @todo) = @_;

    sub {
        my (@example_tags, $example_nest, %tags);
        my @do    = @todo;
        my $group = $do[1][0];

        while(@do)
        {   my ($type,  $info) = (shift @do, shift @do);
            my ($label, $call) = @$info;
            my $processed = $call->();
            my $show = '';
            if($processed->{kind} eq 'substitution group')
            {   # substr extended by subst, which already is formatted.
                # need to extract only the indicated type info.
                my $s = $processed->{struct} || [];
                /^  $label (.*)/ and $show = $1 for @$s;
            }
            elsif(my $type = $processed->{_TYPE})
            {   $show = $self->prefixed($type);
            }

            if($processed->{occur} && $processed->{occur} eq 'ABSTRACT')
            {   $show .= ' (abstract)';
            }
            else
            {   # some complication to always produce the same tag for
                # regression tests... Instance uses a HASH...
                push @example_tags, $label;
                $example_nest ||= $processed->{kind} eq 'simple'
                    ? ($processed->{example} || '...') : '{...}';
            }
        
            $tags{$label} = $show;
        }

        my $longest = max map length, keys %tags;
        my @lines = map sprintf("  %-${longest}s %s", $_, $tags{$_}),
            sort keys %tags;

        my $example_tag = (sort @example_tags)[0];
        my $example = $example_tag ? "{ $example_tag => $example_nest }"
          : "undef  # only abstract types known";

        my $name    = $self->prefixed($type);

       +{ kind    => 'substitution group'
        , tag     => $group
        , struct  => [ "substitutionGroup $name", @lines ]
        , example => $example
        };
    };
}

sub makeXsiTypeSwitch($$$$)
{   my ($self, $where, $elem, $default_type, $types) = @_;
    my @types   = map "  ".$self->prefixed($_), sort keys %$types;
    my $deftype = $self->prefixed($default_type);

    sub { +{ kind    => 'xsi:type switch'
           , tag     => $elem
           , struct  => [ 'xsi:type alternatives:', @types ]
           , example => "{ XSI_TYPE => '$deftype', %data }"
           }
        };
}

sub makeAnyAttribute
{   my ($self, $path, $handler, $yes, $no, $process) = @_;
    $yes ||= []; $no ||= [];
    $yes = [ map {$self->prefixed("{$_}") || $_} @$yes];
    $no  = [ map {$self->prefixed("{$_}") || $_} @$no];
    my $occurs = @$yes ? "in @$yes" : @$no ? "not in @$no" : 'in any namespace';
    bless sub { +{kind => 'attr' , struct  => "any attribute $occurs"
                 , tag => 'ANYATTR', example => 'AnySimple'} }, 'ANY';
}

sub makeAnyElement
{   my ($self, $path, $handler, $yes, $no, $process, $min, $max) = @_;
    $yes ||= []; $no ||= [];
    $yes = [ map {$self->prefixed("{$_}") || $_} @$yes];
    $no  = [ map {$self->prefixed("{$_}") || $_} @$no];
    my $where = @$yes ? "in @$yes" : @$no ? "not in @$no" : 'in any namespace';

    my $data  = +{ kind => 'element', struct  => "any element $where"
                 , tag => "ANY", example => 'Anything' };
    my $occur
      = $max eq 'unbounded' && $min==0 ? 'occurs any number of times'
      : $max ne 'unbounded' && $max==1 && $min==0 ? 'is optional' 
      : $max ne 'unbounded' && $max==1 && $min==1 ? ''  # the usual case
      :                                  "occurs $min <= # <= $max times";
    $data->{occur}  ||= $occur if $occur;
    $data->{is_array} = $max eq 'unbounded' || $max > 1;

    bless sub { +$data }, 'ANY';
}

sub makeHook($$$$$$$)
{   my ($self, $path, $r, $tag, $before, $replace, $after, $fulltype) = @_;

    return $r unless $before || $replace || $after;

    error __x"template only supports one production (replace) hook"
        if $replace && @$replace > 1;

    return sub {()} if $replace && grep {$_ eq 'SKIP'} @$replace;

    my @replace = $replace ? map {$self->_decodeReplace($path,$_)} @$replace:();
    my @before  = $before  ? map {$self->_decodeBefore($path,$_) } @$before :();
    my @after   = $after   ? map {$self->_decodeAfter($path,$_)  } @$after  :();

    sub
    {   my $doc = XML::LibXML::Document->new;
        for(@before) { $_->($doc, $path, undef) or return }

       my $xml = @replace ? $replace[0]->($doc, $path, $r) : $r->();
       defined $xml or return ();

       for(@after) { $xml = $_->($doc, $path, $xml) or return }
       $xml;
     }
}

sub _decodeBefore($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';
    error __x"labeled before hook `{name}' undefined", name => $call;
}

sub _decodeReplace($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';

    if($call eq 'COLLAPSE')
    {   return sub 
         {  my ($tag, $path, $do) = @_;
            my $h = $do->();
            $h->{elems} = [ { struct => [ 'content collapsed' ]
                            , kind   => 'collapsed' } ];
            delete $h->{attrs};
            $h;
         };
    }

    # SKIP already handled
    error __x"labeled replace hook `{name}' undefined", name => $call;
}

sub _decodeAfter($$)
{   my ($self, $path, $call) = @_;
    return $call if ref $call eq 'CODE';
    error __x"labeled after hook `{name}' undefined", name => $call;
}


###
### toPerl
###

sub toPerl($%)
{   my ($self, $ast, %args) = @_;
    $ast or return undef;

    my @lines;
    if($ast->{kind})
    {   my $name = $ast->{_NAME} || $ast->{tag};
        my $pref = $self->prefixed($name);
        push @lines, defined $pref
          ? ("# Describing $ast->{kind} $pref", "#     $name")
          :  "# Describing $ast->{kind} $name";
    }

    push @lines
      , "#"
      , "# Produced by ".__PACKAGE__." version $VERSION"
      , "#          on ".localtime()
      , "#"
      , "# BE WARNED: in most cases, the example below cannot be used without"
      , "# interpretation.  The comments will guide you."
      , "#"
        unless $args{skip_header};

    # add info about name-spaces
    foreach my $nsdecl (grep /^xmlns\:/, sort keys %$ast)
    {   push @lines, sprintf "# %-15s %s", $nsdecl, $ast->{$nsdecl} || '(none)';
    }
    push @lines, '' if @lines;
    
    # produce data tree
    push @lines, $self->_perlAny($ast, \%args);

    # remove leading  'type =>'
    for(my $linenr = 0; $linenr < @lines; $linenr++)
    {   next if $lines[$linenr] =~ m/^\s*\#/;
        next unless $lines[$linenr] =~ s/.*? \=\>\s*//;
        $lines[$linenr] =~ m/\S/ or splice @lines, $linenr, 1;
        last;
    }

    my $lines = join "\n", @lines;
    $lines =~ s/\,?\s*$/\n/;
    $lines;
}

my %seen;
sub _perlAny($$);
sub _perlAny($$)
{   my ($self, $ast, $args) = @_;

    my ($pref, @lines);
    if($ast->{_TYPE} && $args->{show_type})
    {   if($pref = $self->prefixed($ast->{_TYPE}))
        {   push @lines  # not perfect, but a good attempt
              , $pref =~ m/^[aiou]/i && $pref !~ m/^(uni|eu)/i
              ? "# is an $pref" : "# is a $pref";
        }
    }

    if($ast->{struct} && $args->{show_struct})
    {   my $struct = $ast->{struct};
        my @struct = ref $struct ? @$struct : $struct;
        s/^/# /gm for @struct;
        push @lines, @struct;
    }

    push @lines, "# $ast->{occur}"
        if $ast->{occur} && $args->{show_occur};

    if($ast->{facets} && $args->{show_facets})
    {   my $facets = $ast->{facets};
        my @facets = ref $facets ? @$facets : $facets;
        s/^/# /gm for @facets;
        push @lines, @facets;
    }

    my @childs;
    push @childs, @{$ast->{attrs}}  if $ast->{attrs};
    push @childs, @{$ast->{elems}}  if $ast->{elems};
    push @childs,   $ast->{body}    if $ast->{body};

    my @subs;
    foreach my $child (@childs)
    {   my @sub = $self->_perlAny($child, $args);
        @sub or next;

        # last line is code and gets comma
        $sub[-1] =~ s/\,?\s*$/,/
            if $sub[-1] !~ m/\#\s/;

        if(ref $ast ne 'BLOCK')
        {   s/^(.)/$args->{indent}$1/ for @sub;
        }

        # seperator blank, sometimes
        unshift @sub, ''
            if $sub[0] =~ m/^\s*[#{]/   # } 
            || (@subs && $subs[-1] =~ m/[}\]]\,\s*$/);

        push @subs, @sub;
    }

    if(ref $ast eq 'REP-BLOCK')
    {  # repeated block
       @subs or @subs = '';
       $subs[0] =~ s/^  /{ / or $subs[0] =~ s/^\s*$/{/;
       if($subs[-1] =~ m/\#\s/) { push @subs, "}," }
       else { $subs[-1] =~ s/$/ },/ }
    }

    # XML does not permit difficult tags, but we still check.
    my $tag = $ast->{tag} || '';
    if(defined $tag && $tag !~ m/^[\w_][\w\d_]*$/)
    {   $tag =~ s/\\/\\\\/g;
        $tag =~ s/'/\\'/g;
        $tag = qq{'$tag'};
    }

    my $kind = $ast->{kind} || '';
    if(ref $ast eq 'REP-BLOCK')
    {   s/^(.)/  $1/ for @subs;
        $subs[0] =~ s/^ ?/[/;
        push @lines, "$tag => ", @subs , ']';
    }
    elsif(ref $ast eq 'BLOCK')
    {   push @lines, @subs;
    }
    elsif(@subs)
    {   length $subs[0] or shift @subs;
        if($ast->{is_array})
        {   s/^(.)/  $1/ for @subs;
            $subs[0]  =~ s/^[ ]{0,3}/[ {/;
            if($subs[-1] =~ m/\#\s/ || $self->{_style}==2)
                 { push @subs, "}, ], " }
            else { $subs[-1] .= ' }, ], ' }
            push @lines, "$tag =>", @subs;
        }
        else
        {   $subs[0]  =~ s/^  /{ /;
            if($self->{_style}==2)
            {   push @subs, "}, ";
                $subs[-1] .= "# $pref" if $pref;
            }
            elsif($subs[-1] =~ m/\#\s/) { push @subs, "}, " }
            else { $subs[-1] .= ' },' }
            push @lines, "$tag =>", @subs;
        }
    }
    elsif($kind eq 'complex' || $kind eq 'mixed')  # empty complex-type
    {   # if there is an "occurs", then there can always be more than one
        push @lines, $tag.' => '.($ast->{occur} ? '[{},]' : '{}');
    }
    elsif($kind eq 'collapsed') {;}
    elsif($kind eq 'union')    # union type
    {   foreach my $union ( @{$ast->{choice}} )
        {  # remove examples
           my @l = grep { m/^#/ } $self->_perlAny($union, $args);
           s/^\#/#  -/ for $l[0];
           s/^\#/#   / for @l[1..$#l];
           push @lines, @l;
        }
    }
    elsif(!exists $ast->{example})
    {   push @lines, "$tag => 'TEMPLATE-ERROR $ast->{kind}'";
    }

    my $example = $ast->{example};
    if(defined $example)
    {   $example = qq{"$example"}      # in quotes unless
          if $example !~ m/^[+-]?\d+(?:\.\d+)?$/  # numeric or
          && $example !~ m/^\$/                   # variable or
          && $example !~ m/^bless\b/              # constructor or
          && $example !~ m/^\$?[\w:]*\-\>/        # method call example
          && $example !~ m/^\{.*\}$/              # anon HASH example
          && $example !~ m/^\[.*\]$/;             # anon ARRAY example

        push @lines, "$tag => "
          . ($ast->{is_array} ? "[ $example, ]" : $example);
    }
    @lines;
}

###
### toXML
###

sub toXML($$%)
{   my ($self, $doc, $ast, %args) = @_;
    my $xml = $self->_xmlAny($doc, $ast, "\n$args{indent}", \%args);

    UNIVERSAL::isa($xml, 'XML::LibXML::Element')
        or return $xml;

    # add comment
    my $pkg = __PACKAGE__;
    my $now = localtime();

    my $header = $doc->createComment( <<_HEADER . '    ' );

 BE WARNED: in most cases, the example below cannot be used without
  interpretation. The comments will guide you.
  Produced by $pkg version $VERSION
          on $now
_HEADER

    unless($args{skip_header})
    {   $xml->insertBefore($header, $xml->firstChild);
        $xml->insertBefore($doc->createTextNode("\n  "), $header);
    }

    # I use xsi:type myself, too late for the usual "used" counter
    $ast->{'xmlns:xsi'} ||= SCHEMA2001i
        if $args{show_type};

    # add info about name-spaces
    foreach (sort keys %$ast)
    {   if( m/^xmlns\:(.*)/ )
        {   $xml->setNamespace($ast->{$_}, $1, 0);
        }
    }

    $xml;
}

sub _xmlAny($$$$);
sub _xmlAny($$$$)
{   my ($self, $doc, $ast, $indent, $args) = @_;
    my @res;
    my $xsi = $self->_registerNSprefix('xsi', SCHEMA2001i, 1)
        if $args->{show_type};

    my @comment;
    if($ast->{struct} && $args->{show_struct})
    {   my $struct = $ast->{struct};
        push @comment, ref $struct ? @$struct : $struct;
    }

    push @comment, $ast->{occur}
        if $ast->{occur}  && $args->{show_occur};

    if($ast->{facets}  && $args->{show_facets})
    {   my $facets = $ast->{facets};
        push @comment, ref $facets eq 'ARRAY' ? @$facets : $facets;
    }

    if(defined $ast->{kind} && $ast->{kind} eq 'union')
    {   push @comment, map "  $_->{type}", @{$ast->{choice}};
    }

    my @attrs = @{$ast->{attrs} || []};
    foreach my $attr (@attrs)
    {   push @res, $doc->createAttribute($attr->{tag}, $attr->{example});
        my ($ns, $local) = unpack_type $attr->{_TYPE};
        my $prefix = $self->_registerNSprefix('', $ns, 1);
        push @comment, "attr $attr->{tag} has type $prefix:$local"
            if $args->{show_type};
    }

    my $nest_indent = $indent.$args->{indent};
    if(@comment)
    {   my $comment = ' '.join("$nest_indent   ", @comment) .' ';
        push @res
          , $doc->createTextNode($indent)
          , $doc->createComment($comment);
    }

    my @elems = @{$ast->{elems} || []};
    foreach my $elem (@elems)
    {   if(ref $elem eq 'BLOCK' || ref $elem eq 'REP-BLOCK')
        {   push @res, $self->_xmlAny($doc, $elem, $indent, $args);
        }
        elsif($elem->{tag} eq '_')
        {   push @res, $doc->createTextNode($indent.$elem->{example});
        }
        else
        {   my $node = $self->_xmlAny($doc, $elem, $nest_indent, $args);
            push @res, $doc->createTextNode($indent)
                if $node->isa('XML::LibXML::Element');
            push @res, $node;
        }
    }

    (my $outdent = $indent) =~ s/$args->{indent}$//;  # sorry

    if(my $example = $ast->{example})
    {  push @res, $doc->createTextNode
          (@comment ? "$indent$example$outdent" : $example)
    }

    if($ast->{_TYPE} && $args->{show_type})
    {   my $pref = $self->prefixed($ast->{_TYPE});
        push @res, $doc->createAttribute("$xsi:type" => $pref);
    }

    return @res
        if wantarray;

    my $node = $doc->createElement($ast->{tag});
    $node->addChild($_)         for @res;
    $node->appendText($outdent) if @elems;
    $node;
}

sub makeBlocked($$$)
{   my ($self, $where, $class, $type) = @_;
    panic "namespace blocking not yet supported for Templates";
}


1;
