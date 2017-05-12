# Copyrights 2008-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::Cache;
use vars '$VERSION';
$VERSION = '1.05';

use base 'XML::Compile::Schema';

use Log::Report 'xml-compile-cache', syntax => 'SHORT';

use XML::Compile::Util   qw/pack_type unpack_type/;
use List::Util           qw/first/;
use Scalar::Util         qw/weaken/;
use XML::LibXML::Simple  qw/XMLin/;


sub init($)
{   my ($self, $args) = @_;
    $self->addPrefixes($args->{prefixes});

    $self->SUPER::init($args);

    $self->{XCC_opts}   = delete $args->{opts_rw}      || [];
    $self->{XCC_ropts}  = delete $args->{opts_readers} || [];
    $self->{XCC_wopts}  = delete $args->{opts_writers} || [];
    $self->{XCC_undecl} = delete $args->{allow_undeclared} || 0;

    $self->{XCC_dropts} = {};  # declared opts
    $self->{XCC_dwopts} = {};
    $self->{XCC_uropts} = {};  # undeclared opts
    $self->{XCC_uwopts} = {};

    $self->{XCC_readers} = {}; # compiled code refs;
    $self->{XCC_writers} = {};

    $self->typemap($args->{typemap});
    $self->xsiType($args->{xsi_type});
    $self->anyElement($args->{any_element} || 'ATTEMPT');

    $self;
}

#----------------------


sub typemap(@)
{   my $self = shift;
    my $t    = $self->{XCC_typemap} ||= {};
    my @d    = @_ > 1 ? @_ : !defined $_[0] ? ()
             : ref $_[0] eq 'HASH' ? %{$_[0]} : @{$_[0]};
    while(@d) { my $k = $self->findName(shift @d); $t->{$k} = shift @d }
    $t;
}


sub addXsiType(@)
{   my $self = shift;
    my $x    = $self->{XCC_xsi_type} ||= {};
    my @d    = @_ > 1 ? @_ : !defined $_[0] ? ()
             : ref $_[0] eq 'HASH' ? %{$_[0]} : @{$_[0]};

    while(@d)
    {   my $k = $self->findName(shift @d);
        my $a = shift @d;
        $a = $self->namespaces->autoexpand_xsi_type($k) || []
            if $a eq 'AUTO';

        push @{$x->{$k}}
          , ref $a eq 'ARRAY' ? (map $self->findName($_), @$a)
          :                     $self->findName($a);
    }

    $x;
}
*xsiType = \&addXsiType;


sub allowUndeclared(;$)
{   my $self = shift;
    @_ ? ($self->{XCC_undecl} = shift) : $self->{XCC_undecl};
}


sub anyElement($)
{   my ($self, $anyelem) = @_;

    # the "$self" in XCC_ropts would create a ref-cycle, causing a
    # memory leak.
    my $s = $self; weaken $s;

    my $code
      = $anyelem eq 'ATTEMPT' ? sub {$s->_convertAnyTyped(@_)}
      : $anyelem eq 'SLOPPY'  ? sub {$s->_convertAnySloppy(@_)}
      :                         $anyelem;
     
    $self->addCompileOptions(READERS => any_element => $code);
    $code;
}

#----------------------


sub addPrefixes(@)
{   my $self  = shift;
    my $p     = $self->{XCC_namespaces} ||= {};
    my $first = shift;
    @_ or defined $first
        or return $p;

    my @pairs
      = @_                    ? ($first, @_)
      : ref $first eq 'ARRAY' ? @$first
      : ref $first eq 'HASH'  ? %$first
      : error __x"prefixes() expects list of PAIRS, an ARRAY or a HASH";

    my $a    = $self->{XCC_prefixes} ||= {};
    while(@pairs)
    {   my ($prefix, $ns) = (shift @pairs, shift @pairs);
        $p->{$ns} ||= { uri => $ns, prefix => $prefix, used => 0 };

        if(my $def = $a->{$prefix})
        {   if($def->{uri} ne $ns)
            {   error __x"prefix `{prefix}' already refers to {uri}, cannot use it for {ns}"
                  , prefix => $prefix, uri => $def->{uri}, ns => $ns;
            }
        }
        else
        {   $a->{$prefix} = $p->{$ns};
            trace "register prefix $prefix for '$ns'";
        }
    }
    $p;
}



sub prefixes(@)
{   my $self = shift;
    return $self->addPrefixes(@_) if @_;
    $self->{XCC_namespaces} || {};
}


sub prefix($) { $_[0]->{XCC_prefixes}{$_[1]} }

# [0.995] should this be public?
sub byPrefixTable() { shift->{XCC_prefixes} }


sub prefixFor($)
{   my $def = $_[0]->{XCC_namespaces}{$_[1]} or return ();
    $def->{used}++;
    $def->{prefix};
}


sub addNicePrefix($$)
{   my ($self, $base, $ns) = @_;
    if(my $def = $self->prefix($base))
    {   return $base if $def->{uri} eq $ns;
    }
    else
    {   $self->addPrefixes($base => $ns);
        return $base;
    }

    $base .= '01' if $base !~ m/[0-9]$/;
    while(my $def = $self->prefix($base))
    {   return $base if $def->{uri} eq $ns;
        $base++;
    }
    $self->addPrefixes($base => $ns);
    $base;
}


sub learnPrefixes($)
{   my ($self, $node) = @_;
    my $namespaces = $self->prefixes;

  PREFIX:
    foreach my $ns ($node->getNamespaces)  # learn preferred ns
    {   my ($prefix, $uri) = ($ns->getLocalName, $ns->getData);
        next if !defined $prefix || $namespaces->{$uri};

        if(my $def = $self->prefix($prefix))
        {   next PREFIX if $def->{uri} eq $uri;
        }
        else
        {   $self->addPrefixes($prefix => $uri);
            next PREFIX;
        }

        $prefix =~ s/0?$/0/;
        while(my $def = $self->prefix($prefix))
        {   next PREFIX if $def->{uri} eq $uri;
            $prefix++;
        }
        $self->addPrefixes($prefix => $uri);
    }
}

sub addSchemas($@)
{   my ($self, $xml) = (shift, shift);
    $self->learnPrefixes($xml);
    $self->SUPER::addSchemas($xml, @_);
}


sub prefixed($;$)
{   my $self = shift;
    my ($ns, $local) = @_==2 ? @_ : unpack_type(shift);
    $ns or return $local;
    my $prefix = $self->prefixFor($ns);
    defined $prefix
        or error __x"no prefix known for namespace `{ns}', use addPrefixes()"
            , ns => $ns;

    length $prefix ? "$prefix:$local" : $local;
}

#----------------------


sub compileAll(;$$)
{   my ($self, $need, $usens) = @_;
    my ($need_r, $need_w) = $self->_need($need || 'RW');

    if($need_r)
    {   foreach my $type (keys %{$self->{XCC_dropts}})
        {   if(defined $usens)
            {   my ($myns, $local) = unpack_type $type;
                next if $usens eq $myns;
            }
            $self->reader($type);
        }
    }

    if($need_w)
    {   foreach my $type (keys %{$self->{XCC_dwopts}})
        {   if(defined $usens)
            {   my ($myns, $local) = unpack_type $type;
                next if $usens eq $myns;
            }
            $self->writer($type);
        }
    }
}


sub _same_params($$)
{   my ($f, $s) = @_;
    @$f==@$s or return 0;
    for(my $i=0; $i<@$f; $i++)
    {   return 0 if !defined $f->[$i] ? defined $s->[$i]
                  : !defined $s->[$i] ? 1 : $f->[$i] ne $s->[$i];
    }
    1;
}

sub reader($@)
{   my ($self, $name) = (shift, shift);
    my %args    = @_;
    my $type    = $self->findName($name);
    my $readers = $self->{XCC_readers};

    if(exists $self->{XCC_dropts}{$type})
    {   trace __x"ignoring options to pre-declared reader {name}"
          , name => $name if @_;

        return $readers->{$type}
            if $readers->{$type};
    }
    elsif($self->allowUndeclared)
    {   if(my $ur = $self->{XCC_uropts}{$type})
        {   # do not use cached version when options differ
            _same_params $ur, \@_
                or return $args{is_type}
                  ? $self->compileType(READER => $type, @_)
                  : $self->compile(READER => $type, @_);
        }
        else
        {   $self->{XCC_uropts}{$type} = \@_;
        }
    }
    elsif(exists $self->{XCC_dwopts}{$type})
         { error __x"type {name} is only declared as writer", name => $name }
    else { error __x"type {name} is not declared", name => $name }

    $readers->{$type} ||= $args{is_type}
       ? $self->compileType(READER => $type, @_)
       : $self->compile(READER => $type, @_);
}


sub writer($%)
{   my ($self, $name) = (shift, shift);
    my %args    = @_;
    my $type    = $self->findName($name);
    my $writers = $self->{XCC_writers};

    if(exists $self->{XCC_dwopts}{$type})
    {   trace __x"ignoring options to pre-declared writer {name}"
          , name => $name if @_;

        return $writers->{$type}
            if $writers->{$type};
    }
    elsif($self->{XCC_undecl})
    {   if(my $ur = $self->{XCC_uwopts}{$type})
        {   # do not use cached version when options differ
            _same_params $ur, \@_
                or return $args{is_type}
                  ? $self->compileType(WRITER => $type, @_)
                  : $self->compile(WRITER => $type, @_);
        }
        else
        {   $self->{XCC_uwopts}{$type} = \@_;
        }
    }
    elsif(exists $self->{XCC_dropts}{$type})
    {   error __x"type {name} is only declared as reader", name => $name;
    }
    else
    {   error __x"type {name} is not declared", name => $name;
    }

    $writers->{$type} ||= $args{is_type}
       ? $self->compileType(WRITER => $type, @_)
       : $self->compile(WRITER => $type, @_);

}

sub template($$@)
{   my ($self, $action, $name) = (shift, shift, shift);
    $action =~ m/^[A-Z]*$/
        or error __x"missing or illegal action parameter to template()";

    my $type  = $self->findName($name);
    my @opts = $self->mergeCompileOptions($action, $type, \@_);
    $self->SUPER::template($action, $type, @opts);
}


sub addCompileOptions(@)
{   my $self = shift;
    my $need = @_%2 ? shift : 'RW';

    my $set
      = $need eq 'RW'      ? $self->{XCC_opts}
      : $need eq 'READERS' ? $self->{XCC_ropts}
      : $need eq 'WRITERS' ? $self->{XCC_wopts}
      : error __x"addCompileOptions() requires option set name, not {got}"
          , got => $need;

    if(ref $set eq 'HASH')
         { while(@_) { my $k = shift; $set->{$k} = shift } }
    else { push @$set, @_ }
    $set;
}

# Create a list with options for X::C::Schema::compile(), from a list of ARRAYs
# and HASHES with options.  The later options overrule the older, but in some
# cases, the new values are added.  This method knows how some of the options
# of ::compile() behave.  [last update X::C v0.98]

sub mergeCompileOptions($$$)
{   my ($self, $action, $type, $opts) = @_;

    my @action_opts
      = ($action eq 'READER' || $action eq 'PERL')
      ? ($self->{XCC_ropts}, $self->{XCC_dropts}{$type})
      : ($self->{XCC_wopts}, $self->{XCC_dwopts}{$type});

    my %p    = %{$self->{XCC_namespaces}};
    my %t    = %{$self->{XCC_typemap}};
    my %x    = %{$self->{XCC_xsi_type}};
    my %opts = (prefixes => \%p, hooks => [], typemap => \%t, xsi_type => \%x);

    # flatten list of parameters
    my @take = map {!defined $_ ? () : ref $_ eq 'ARRAY' ? @$_ : %$_ }
        $self->{XCC_opts}, @action_opts, $opts;

    while(@take)
    {   my ($opt, $val) = (shift @take, shift @take);
        defined $val or next;

        if($opt eq 'prefixes')
        {   my $t = $self->_namespaceTable($val, 1, 0);  # expand
            @p{keys %$t} = values %$t;   # overwrite old def if exists
        }
        elsif($opt eq 'hooks' || $opt eq 'hook')
        {   my $hooks = $self->_cleanup_hooks($val);
            unshift @{$opts{hooks}}, ref $hooks eq 'ARRAY' ? @$hooks : $hooks
                if $hooks;
        }
        elsif($opt eq 'typemap')
        {   $val ||= {};
            if(ref $val eq 'ARRAY')
            {   while(@$val)
                {   my $k = $self->findName(shift @$val); 
                    $t{$k} = shift @$val;
                }
            }
            else
            {   while(my($k, $v) = each %$val)
                {   $t{$self->findName($k)} = $v;
                }
            }
        }
        elsif($opt eq 'key_rewrite')
        {   unshift @{$opts{key_rewrite}}, ref $val eq 'ARRAY' ? @$val : $val;
        }
        elsif($opt eq 'xsi_type')
        {   while(my ($t, $a) = each %$val)
            {   my @a = ref $a eq 'ARRAY' ? map($self->findName($_), @$a)
                  : $self->findName($a);
                push @{$x{$self->findName($t)}},  @a;
            }
        }
        elsif($opt eq 'ignore_unused_tags')
        {   $opts{$opt} = defined $opts{$opt} ? qr/$opts{$opt}|$val/ : $val;
        }
        else
        {   $opts{$opt} = $val;
        }
    }

    %opts;
}

# rewrite hooks
sub _cleanup_hooks($)
{   my ($self, $hooks) = @_;
    $hooks or return;

    # translate prefixed type names into full names
    foreach my $hook (ref $hooks eq 'ARRAY' ? @$hooks : $hooks)
    {   if(my $types = $hook->{type})
        {   $hook->{type} =
              [ map {ref $_ eq 'Regexp' ? $_ : $self->findName($_)}
                       ref $types eq 'ARRAY' ? @$types : $types ];
        }
        elsif(my $ext = $hook->{extends})
        {   $hook->{extends} = $self->findName($ext);
        }
    }
    $hooks;
}

my %need = (READER => [1,0], WRITER => [0,1], RW => [1,1]);
$need{READERS} = $need{READER};
$need{WRITERS} = $need{WRITER};

sub _need($)
{   my $need = $need{$_[1]}
       or error __x"use READER, WRITER or RW, not {dir}", dir => $_[1];
    @$need;
}

# support prefixes on types
sub addHook(@)
{   my $self = shift;
    my $hook = @_ > 1 ? {@_} : shift;
    $self->_cleanup_hooks($hook);
    $self->SUPER::addHook($hook);
}

sub compile($$@)
{   my ($self, $action, $elem) = splice @_, 0, 3;
    defined $elem
        or error __x"compile() requires action and type parameters";

    $self->SUPER::compile
      ( $action => $self->findName($elem)
      , $self->mergeCompileOptions($action, $elem, \@_)
      );
}

sub compileType($$@)
{   my ($self, $action, $type) = splice @_, 0, 3;
    defined $type
        or error __x"compileType() requires action and type parameters";

    $self->SUPER::compileType
      ( $action => $self->findName($type)
      , $self->mergeCompileOptions($action, $type, \@_)
      );
}

#----------------------


sub declare($$@)
{   my ($self, $need, $names, @opts) = @_;
    my $opts = @opts==1 ? shift @opts : \@opts;
    $opts = [ %$opts ] if ref $opts eq 'HASH';

    my ($need_r, $need_w) = $self->_need($need);

    foreach my $name (ref $names eq 'ARRAY' ? @$names : $names)
    {   my $type = $self->findName($name);
        trace "declare $type $need";

        if($need_r)
        {   defined $self->{XCC_dropts}{$type}
               and warning __x"reader {name} declared again", name => $name;
            $self->{XCC_dropts}{$type} = $opts;
        }

        if($need_w)
        {   defined $self->{XCC_dwopts}{$type}
               and warning __x"writer {name} declared again", name => $name;
            $self->{XCC_dwopts}{$type} = $opts;
        }
    }

    $self;
}


sub findName($)
{   my ($self, $name) = @_;
    defined $name
        or panic "findName called without name";

    return $name
        if substr($name, 0, 1) eq '{';

    my ($prefix,$local) = $name =~ m/^([\w-]*)\:(\S*)$/ ? ($1,$2) : ('',$name);
    my $def = $self->{XCC_prefixes}{$prefix};
    unless($def)
    {   return $name if $prefix eq '';   # namespace-less
        trace __x"known prefixes: {prefixes}"
          , prefixes => [ sort keys %{$self->{XCC_prefixes}} ];
        error __x"unknown name prefix `{prefix}' for `{name}'"
           , prefix => $prefix, name => $name;
    }

    length $local ? pack_type($def->{uri}, $local) : $def->{uri};
}


sub printIndex(@)
{   my $self = shift;
    my $fh   = @_ % 2 ? shift : select;
    my %args = @_;
    my $decl = exists $args{show_declared} ? delete $args{show_declared} : 1;

    return $self->SUPER::printIndex($fh, %args)
        unless $decl;

    my $output = '';
    open my($out), '>', \$output;

    $self->SUPER::printIndex($out, %args);

    close $out;
    my @output = split /(?<=\n)/, $output;
    my $ns     = '';
    foreach (@output)
    {   $ns = $1 if m/^namespace\:\s+(\S+)/;
        my $local = m/^\s+(\S+)\s*$/ ? $1 : next;
        my $type  = pack_type $ns, $local;

        substr($_, 1, 1)
          = $self->{XCC_readers}{$type} ? 'R'
          : $self->{XCC_dropts}{$type}  ? 'r' : ' ';

        substr($_, 2, 1)
          = $self->{XCC_writers}{$type} ? 'W'
          : $self->{XCC_dwopts}{$type}  ? 'w' : ' ';
    }
    $fh->print(@output);
}

#---------------
# Convert ANY elements and attributes

sub _convertAnyTyped(@)
{   my ($self, $type, $nodes, $path, $read) = @_;

    my $key     = $read->keyRewrite($type);
    my $reader  = try { $self->reader($type) };
    if($@)
    {   trace "cannot auto-convert 'any': ".$@->wasFatal->message;
        return ($key => $nodes);
    }
    trace "auto-convert known type for 'any': $type";

    my @nodes   = ref $nodes eq 'ARRAY' ? @$nodes : $nodes;
    my @convert = map $reader->($_), @nodes;
    ($key => (@convert==1 ? $convert[0] : \@convert) );
}

sub _convertAnySloppy(@)
{   my ($self, $type, $nodes, $path, $read) = @_;

    my $key     = $read->keyRewrite($type);
    my $reader  = try { $self->reader($type) };
    if($@)
    {   # unknown type or untyped...
        my @convert = map XMLin($_), @$nodes;
        return ($key => @convert==1 ? $convert[0] : \@convert);
    }
    else
    {   trace "auto-convert known 'any' $type";
        my @nodes   = ref $nodes eq 'ARRAY' ? @$nodes : $nodes;
        my @convert = map $reader->($_), @nodes;

        ($key => @convert==1 ? $convert[0] : \@convert);
    }
}

1;
