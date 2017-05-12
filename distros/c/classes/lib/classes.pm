package classes;

# $Id: classes.pm 147 2008-03-08 16:04:33Z rmuhle $

our $VERSION = '0.944';
use 5.006_001;
use Scalar::Util 'reftype', 'blessed';    # standard from 5.8.1

# keep false alarms quiet
use strict; no strict 'refs'; no warnings;

sub classes (@); *define = \&classes::classes;
sub load;

# fastest PERL_VERSION constant (from Schwern's CLASS module)
BEGIN{ *PERL_VERSION = eval "sub () { $] } " }

# do not change
$classes::ok_class_name
    = qr/^(?!(?:
            B$|                            # binary module
            _$
           )
        )
    (?i:(?:[a-z_]\w*\:\:)*[a-z_]\w*)$/xo;
$classes::ok_attr_name = qr/^(?i:[a-z_]\w*)$/xo;

# this one changable via tag
$classes::def_base_exception = 'X::classes::traceable';

######################################################################

sub import {
    my $package = shift;
    my (@class_declarations, $dynamic);
    my $caller = caller;

    # use classes DECLARATION;
    if ( !ref $_[0] ) {
        push @_, 1 if @_ == 1;
        push @class_declarations, {@_};
    }

    # use classes {DECLARATION}, {DECLARATION};
    else {
        @class_declarations = @_;
    }

    # implied name
    map { $_->{'caller'} = $caller } @class_declarations;

    classes::classes(@class_declarations);

    return $package;
}

######################################################################
# Called by import() itself to define classes at compile-time.
# Exported into anything that calls 'use classes'.
sub classes (@) {
    my @args = @_;
    my $tags;

    # classes { DECLARATION };
    if ( ref $args[0] eq 'HASH' ) {
        $tags = $args[0];
        map { classes $_ } @args if @args > 1; # recurse
    }

    # classes DECLARATION;
    elsif ( @args > 1 ) {
        $tags = {@args};
    }

    #-----------------------------------------------------------------

    my ($class,          $type,           $inherits,      $extends,
        $throws,         $exceptions,     $attrs,         $methods,
        $class_attrs,    $class_attrs_ro, $class_methods, $attrs_ro,
        $new_m,          $init_m,         $clone_m,       $caller,
        $mixes,          $mixes_def,      $class_mixes,   $dump_m,
        $base_exception, $unqualified,    $pkg_mixes,     $needs,
        $pkg_methods,    $needs,          $attrs_pr,      $justahash,
        $class_attrs_pr, $noaccessors,    $def_base_exception,
    );

    my $lookup = {
        caller               => \$caller,
        name                 => \$class,
        attrs                => \$attrs,
        attrs_ro             => \$attrs_ro,
        attrs_pr             => \$attrs_pr,
        class_attrs          => \$class_attrs,
        class_attrs_ro       => \$class_attrs_ro,
        class_attrs_pr       => \$class_attrs_pr,
        mixes                => \$mixes,
        class_mixes          => \$class_mixes,
        pkg_mixes            => \$pkg_mixes,
        mixes_def            => \$mixes_def,
        methods              => \$methods,
        class_methods        => \$class_methods,
        pkg_methods          => \$pkg_methods,
        throws               => \$throws,
        needs                => \$needs,
        extends              => \$extends,
        inherits             => \$inherits,
        type                 => \$type,
        exceptions           => \$exceptions,
        base_exception       => \$base_exception,
        new                  => \$new_m,
        init                 => \$init_m,
        clone                => \$clone_m,
        dump                 => \$dump_m,
        def_base_exception   => \$def_base_exception,
        unqualified          => \$unqualified,
        noaccessors          => \$noaccessors,
        justahash            => \$justahash,
    };

    while ( my ( $tag, $val ) = each %$tags ) {
        my $ref = $lookup->{$tag}
            or X::Usage->throw( "$tag ??" ); 
        $$ref = $val;
    }

    $class ||= $caller || caller;
    X::InvalidName->throw("name=>'$class'")
        if $class !~ $classes::ok_class_name; # main ok

    #-----------------------------------------------------------------
    # add CLASS and $CLASS constants (from Michael Schwern's CLASS)

    my $const_CLASS = $class . '::CLASS';
    if (!$$const_CLASS) {
        *$const_CLASS = \$class;
        if ( PERL_VERSION >= 5.008 ) {
            *$const_CLASS = sub () {$class};
        }
        else {
            *$const_CLASS = eval " sub () { q[$class] } ";
        }
    }

    #-----------------------------------------------------------------

    my $class_decl = $class . '::DECL';
    if (!*$class_decl{CODE}) {
        $$class_decl->{'name'} = $class;
        $$class_decl->{'type'} ||= 'static';
        if ( PERL_VERSION >= 5.008 ) {
            *$class_decl = sub () { $$class_decl };
        }
        else {
            *$class_decl = eval 'sub () { $' . $class_decl . '}';
        }
    }

    #-----------------------------------------------------------------

    # setup the special MIXIN method and var
    my $class_MIXIN = $class . '::MIXIN';
    if (!*$class_MIXIN{CODE}) {
        $$class_MIXIN = undef;
        if ( PERL_VERSION >= 5.008 ) {
            *$class_MIXIN = sub () { $$class_MIXIN };
        }
        else {
            *$class_MIXIN = eval 'sub () { $' . $class_MIXIN . '}';
        }
    }

    #-----------------------------------------------------------------

    $classes::def_base_exception = $def_base_exception
        if $def_base_exception;

    #-----------------------------------------------------------------

    # keep using a type that has already been declared
    if ($type) {
        X::Usage->throw( "type=>'$type' ??\n"
            . "    type => 'static'|'dynamic'|'mixable'\n" )
           if ! ( $type eq 'static' 
              ||  $type eq 'dynamic'
              ||  $type eq 'mixable' );
        $$class_decl->{'type'} = $type;
    }
    else {
        $type = $$class_decl->{'type'};
    }

    #-----------------------------------------------------------------
    # export a 'classes' function/statement into caller

    *{ $class . '::classes' } = \&classes::classes
        if $type eq 'dynamic';

    #-----------------------------------------------------------------

    my $class_super = $class . '::SUPER';
    if (!*$class_super{CODE}) {
        if ( PERL_VERSION >= 5.008 ) {
            *$class_super = sub () { ${ $class.'::ISA' }[0] };
        }
        else {
            *$class_super = eval 'sub () { $'.$class.'::ISA[0] }';
        }
    }

    #-----------------------------------------------------------------

    _define_mixins( $class, $mixes, $mixes_def, '')
        if defined $mixes;
    _define_mixins( $class, $class_mixes, $mixes_def, 'class_' )
        if defined $class_mixes;
    _define_mixins( $class, $pkg_mixes, $mixes_def, 'pkg_' )
        if defined $pkg_mixes;

    #-----------------------------------------------------------------
    # same as 'throws' for now

    # 'needs' IS DEPRECATED, use perl 'use' instead, too many
    # compilers/builders depend on 'use' to identify needed modules
    if ($needs) {
        my $is_ref = ref $needs;

        # needs => 'SomeOtherMod',
        if ( !$is_ref ) {
            $needs = [$needs];
            $is_ref = 'ARRAY';
        }

        X::Usage->throw( <<'EOM' ) if $is_ref ne 'ARRAY';

    DEPRECATED, use perl 'use' instead, too many compilers/builders
    depend on 'use' to identify which modules are needed
EOM

        for my $pkg (@$needs) {
            classes::load($pkg);
            push @{ $$class_decl->{'needs'} }, $pkg;
        }
    }    # needs


    #-----------------------------------------------------------------

    if ($throws) {
        my $is_ref = ref $throws;

        # throws => 'X::Usage',
        if ( !$is_ref ) {
            $throws = [$throws];
            $is_ref = 'ARRAY';
        }

        X::Usage->throw( <<'EOM' ) if $is_ref ne 'ARRAY';

    throws => 'X::Usage',
    throws => [ 'X::Usage', 'X::Mine::NotFound' ],
EOM

        for my $exc (@$throws) {
            classes::load($exc);
            push @{ $$class_decl->{'throws'} }, $exc;
        }
    }    # throws

    #-----------------------------------------------------------------
    
    if ($base_exception) {

        # base_exception => {name=>'X::MyBase',},
        if (ref $base_exception) {
            classes::classes($base_exception);
            $base_exception = $base_exception->{'name'};
        }

        # base_exception => 'X::class',
        # base_exception => 'Exception::Class',
        else {
            classes::load($base_exception);
        }

        $$class_decl->{'base_exception'} = $base_exception;
    }

    #-----------------------------------------------------------------

    if ($exceptions) {
        my $is_ref  = ref $exceptions;
        my $usage   = <<'EOM';

    exceptions => 'X::MyClass::Own1',
    exceptions => [
        'X::MyClass::Own1',
        'X::MyClass::Own2',
        { name=>'X::MyClass::EOF', attrs=>['file'], ... },
    ],
EOM

        # go with base exception class if one is declared
        my $base_x_class = $base_exception;
        
        # otherwise define X::MyClass default base
        if (!$base_x_class) {
            $base_x_class = "X::$class";

            # but create only if hasn't been created already
            if (!%{$base_x_class.'::'}) { 
                classes::classes(
                    name    => $base_x_class,
                    extends => $classes::def_base_exception,
                );
            }
        }

        if ($is_ref ne 'ARRAY') {
            $exceptions = [$exceptions];
            $is_ref = 'ARRAY';
        }

        for my $exc (@$exceptions) {
            my $exc_is_ref = ref $exc;

            # exceptions => ['X::Name']
            if (!$exc_is_ref) {
                X::NameUnavailable->throw([$exc]) if %{$exc.'::'};
                classes::classes(name=>$exc, extends=>$base_x_class);

            }

            # exceptions => [{name=>'X::Name',attrs=>['file']}]
            elsif ($exc_is_ref eq 'HASH') {
                my $name = $exc->{'name'};
                $exc->{'extends'} ||= $base_x_class;
                X::NameUnavailable->throw([$name])
                    if %{$name.'::'};
                classes::classes($exc);
            }
            
            # bad
            else { 
                X::Usage->throw($exceptions . $usage);
            }

            push @{ $$class_decl->{'exceptions'} }, $exc;
        }

    } # exceptions

    #-----------------------------------------------------------------

    # extends trumps inherits
    if ($extends) {
        X::Usage->throw(
            "extends=>'parent' OR inherits=>[qw( Parent1 Parent2 )]"
            )
            if $inherits || ref $extends;
            classes::load($extends);
            @{$class . '::ISA'} = ($extends);
            $$class_decl->{'extends'} = $extends;
            delete $$class_decl->{'inherits'};
    }

    #-----------------------------------------------------------------

    if ($inherits) {
        my $is_ref = ref $inherits;
        my $usage  = <<'EOM';

    extends  => 'SuperClass',
    inherits => 'SuperClass',
    inherits => [qw( Class1 Class2 )],
EOM

        if (!$is_ref) {
            $inherits = [$inherits];
            $is_ref = 'ARRAY';
        }

        X::Usage->throw($usage)
            if !$is_ref || $is_ref ne 'ARRAY';

        for my $parent (@$inherits) {
            next if $class->isa($parent);
            classes::load($parent);
            push @{ $class . '::ISA' }, $parent;
            push @{ $$class_decl->{'inherits'} }, $parent;
        }

    }    # inherits

    #-----------------------------------------------------------------

    if ($class_attrs_ro) {
        my $is_ref = ref $class_attrs_ro;
        my $usage  = <<'EOM';

    class_attrs_ro => [qw( attr1 attr2 )],
    class_attrs_ro => {
        attr0 => undef,
        attr1 => 1,
        attr2 => 'scalar',
        attr3 => \$scalar_ref,
        attr4 => [ 'array', 'ref' ],
        attr5 => { 'hash' => 'ref' },
        attr6 => sub { ... },
        attr7 => qr/^Get the idea(?:\?|\!)$/o,
        attr8 => 0,
        attr9 => '',
    },
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$class_attrs_ro) {
                X::InvalidName->throw(
                    "class_attrs_ro=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => undef, 'ro' );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $i_value ) = each %$class_attrs_ro ) {
                X::InvalidName->throw(
                    "class_attrs_ro=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => $i_value, 'ro' );
            }
        }
        else {
            X::Usage->throw($usage);
        }
    }    # class_attrs_ro

    #-----------------------------------------------------------------

    if ($class_attrs_pr) {
        my $is_ref = ref $class_attrs_pr;
        my $usage  = <<'EOM';

    class_attrs_pr => [qw( attr1 attr2 )],
    class_attrs_pr => {
        attr0 => undef,
        attr1 => 1,
        attr2 => 'scalar',
        attr3 => \$scalar_ref,
        attr4 => [ 'array', 'ref' ],
        attr5 => { 'hash' => 'ref' },
        attr6 => sub { ... },
        attr7 => qr/^Get the idea(?:\?|\!)$/o,
        attr8 => 0,
        attr9 => '',
    },
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$class_attrs_pr) {
                X::InvalidName->throw(
                    "class_attrs_pr=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => undef, 'pr' );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $i_value ) = each %$class_attrs_pr ) {
                X::InvalidName->throw(
                    "class_attrs_pr=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => $i_value, 'pr' );
            }
        }
        else {
            X::Usage->throw($usage);
        }
    }    # class_attrs_pr

    #-----------------------------------------------------------------

    if ($class_attrs) {
        my $is_ref = ref $class_attrs;
        my $usage  = <<'EOM';

    class_attrs => [qw( attr1 attr2 )],
    class_attrs => {
        attr0 => undef,
        attr1 => 1,
        attr2 => 'scalar',
        attr3 => \$scalar_ref,
        attr4 => [ 'array', 'ref' ],
        attr5 => { 'hash' => 'ref' },
        attr6 => sub { ... },
        attr7 => qr/^Get the idea(?:\?|\!)$/o,
        attr8 => 0,
        attr9 => '',
    },
EOM

        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$class_attrs) {
                X::InvalidName->throw(
                    "class_attrs=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => undef );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $i_value ) = each %$class_attrs ) {
                X::InvalidName->throw(
                    "class_attrs=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_class_attr( $class, $name => $i_value );
            }
        }
        else {
            X::Usage->throw($usage);
        }

    }    # class_attrs

    #-----------------------------------------------------------------

    if ($justahash) {
        $$class_decl->{'justahash'} = $justahash;
        $noaccessors = 1;
        $unqualified = 1;
        $new_m     ||= 'classes::new_fast';
    }
    else {
        $$class_decl->{'unqualified'} = $unqualified if $unqualified;
        $$class_decl->{'noaccessors'} = $noaccessors if $noaccessors;
    }

    #-----------------------------------------------------------------

    if ($attrs_ro) {
        my $is_ref = ref $attrs_ro;
        my $usage  = <<'EOM';

    attrs_ro => [qw( attr1 attr2 )],
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$attrs_ro) {
                X::InvalidName->throw(
                    "attrs_ro=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_attr( $class, $name, 'ro',
                        $unqualified, $noaccessors );
            }
        }
        else {
            X::Usage->throw($usage);
        }

    }    # attrs_ro

    #-----------------------------------------------------------------

    if ($attrs_pr) {
        my $is_ref = ref $attrs_pr;
        my $usage  = <<'EOM';

    attrs_pr => [qw( attr1 attr2 )],
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$attrs_pr) {
                X::InvalidName->throw(
                    "attrs_pr=>['$name']"
                ) if !$name || $name !~ $classes::ok_attr_name;
                _define_attr( $class, $name, 'pr',
                        $unqualified, $noaccessors );
            }
        }
        else {
            X::Usage->throw($usage);
        }

    }    # attrs_pr
    #-----------------------------------------------------------------

    if ($attrs) {
        my $is_ref = ref $attrs;
        my $usage  = <<'EOM';

    attrs => [qw( attr1 attr2 )],
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$attrs) {
                X::InvalidName->throw( "attrs=>['$name']" )
                    if !$name || $name !~ $classes::ok_attr_name;
                _define_attr( $class, $name, '',
                        $unqualified, $noaccessors );
            }
        }
        else {
            X::Usage->throw($usage);
        }

    }    # attrs

    #-----------------------------------------------------------------

    if ($class_methods) {
        my $is_ref = ref $class_methods;
        my $usage  = <<'EOM';

    class_methods => [ 'method1', 'method2' ],
    class_methods => {
        method1 => 'method1',
        method2 => 'local_method',
        method3 => 'Extern::library::method',
        method4 => 'ABSTRACT',
        method5 => <false> | 'EMPTY',
        method6 => sub { ... } | $code_ref | \&some::method,
    },
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$class_methods) {
                _define_method( $class, $name => $name, 'class_' );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $method ) = each %$class_methods ) {
                my $is_ref = ref $method;
                _define_method( $class, $name => $method, 'class_');
            }
        }
        else {
            X::Usage->throw($usage);
        }
    }    # class_methods

    #---------------------------------------------------------------

    if ($pkg_methods) {
        my $is_ref = ref $pkg_methods;
        my $usage  = <<'EOM';

    pkg_methods => [ 'method1', 'method2' ],
    pkg_methods => {
        method1 => 'method1',
        method2 => 'local_method',
        method3 => 'Extern::library::method',
        method4 => 'ABSTRACT',
        method5 => <false> | 'EMPTY',
        method6 => sub { ... } | $code_ref | \&some::method,
    },
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$pkg_methods) {
                _define_method( $class, $name => $name, 'pkg_' );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $method ) = each %$pkg_methods ) {
                my $is_ref = ref $method;
                _define_method( $class, $name => $method, 'pkg_');
            }
        }
        else {
            X::Usage->throw($usage);
        }

        # allows pkg_methods to be imported on request
        my $class_decl = $class . '::DECL';
        *{$class.'::import'} = sub {
            my $package = shift;
            my $caller = caller;

            # use MyPackage qw(my_pkg_method another_function);
            if ($_[0] and $_[0] ne ':all') {
                for my $method (@_) {
                    X::NotPkgMethod->throw([$method])
                        if !$$class_decl->{'pkg_methods'}->{$method};
                    *{$caller.'::'.$method} = \&{$class.'::'.$method};
                }
            }
            
            # use MyPackage ':all';
            else {
               for my $method (keys %{$$class_decl->{'pkg_methods'}}){
                    *{$caller.'::'.$method} = \&{$class.'::'.$method};
               }
            }
            return $package;
        };

    }    # pkg_methods

    #---------------------------------------------------------------

    if ($methods) {
        my $is_ref = ref $methods;
        my $usage  = <<'EOM';

    methods => [ 'method1', 'method2' ],
    methods => {
        method1 => 'method1',
        method2 => 'local_method',
        method3 => 'Extern::library::method',
        method4 => 'ABSTRACT',
        method5 => <false> || 'EMPTY',
        method6 => sub { ... } || $code_ref || \&some::method,
    },
EOM
        if ( $is_ref eq 'ARRAY' ) {
            for my $name (@$methods) {
                _define_method( $class, $name => $name, '' );
            }
        }
        elsif ( $is_ref eq 'HASH' ) {
            while ( my ( $name, $method ) = each %$methods ) {
                _define_method( $class, $name => $method, '' );
            }
        }
        else {
            X::Usage->throw($usage);
        }

    }    # methods

    #---------------------------------------------------------------
    # new, clone, initialize, and dump shortcuts

    _define_method( $class, 'initialize' => $init_m, '' ) if $init_m;
    _define_method( $class, 'clone' => $clone_m, '' ) if $clone_m;
    _define_method( $class, 'dump'  => $dump_m, '' )  if $dump_m;
    _define_method( $class, 'new' => $new_m, 'class_' ) if $new_m;

    return $class;
}

####################################################################

sub load {
    my $pkg = shift;

    X::InvalidName->throw( [$pkg] )
        if $pkg !~ $classes::ok_class_name;

    # from 'base', don't bother loading if have VERSION,
    my $vglob = ${$pkg.'::'}{VERSION};
    return $pkg if $vglob && *$vglob{SCALAR};

    # unlike 'base' that does a 'require', we 'use' instead to
    local $SIG{__DIE__} = 'IGNORE';
    eval "use $pkg";

    # unlike 'base' that does a 'require', we 'use' instead to
    # propogate exception as is unless "can't locate", which is
    # expected when the base pkg is defined in same file, etc.
    # had to remove the '^' initial match because of braindead
    # idiot programs like Indigo's perl2exe that stick a bunch
    # of irrelevant text before the actual expected error string
    die if $@ && $@ !~ /Can't locate .*? at \(eval /o;

    # problem if the pkg doesn't have any var or sub symbols in it
    # milage may vary when loading pkgs that use DynaLoader (ugh)
    X::Empty->throw([$pkg]) if !%{$pkg.'::'};

    # for 'use base' compatibility, if the loaded pkg didn't have
    # a VERSION of its own give it one so we don't load it again
    ${$pkg.'::VERSION'} = "-1, set by classes.pm"
        if !defined ${$pkg.'::VERSION'};

    return $pkg;
}


####################################################################

sub _define_mixins {
    my ($class, $mixes, $mixes_def, $type) = @_;
    my $is_ref      = ref $mixes;
    my $class_DECL  = $class.'::DECL';
    my $class_MIXIN = $class.'::MIXIN';

    my $usage  = <<'EOM';

    [class_|pkg_]mixes => 'Module',
    [class_|pkg_]mixes => { Module => ... },
    [class_|pkg_]mixes => [
        'Module1',
        { Module2 => ['method1'] },
        { Module3 => 'ALL'|'PUB'|'SAFE' },
        { Module4 => qr/.../ },
        { Module5 => ... , scope=>'CLASS' },
     ],

    mixes_def => 'ALL'|'PUB'|'SAFE',
EOM
    # mixes => 'Module1',
    # mixes => { Module1 => ... },
    if ( !$is_ref || $is_ref eq 'HASH' ) {
        $mixes  = [$mixes];
        $is_ref = 'ARRAY';
    }

    X::Usage->throw($usage) if $is_ref ne 'ARRAY';

    MIXIN:
    for my $module ( reverse @$mixes ) {         # first wins

        my $is_ref = ref $module;
        my $filter = $mixes_def || 'SAFE';

        # mixes => [ 'Module1' ], 
        if ( !$is_ref ) {
            $module = { $module => $filter };
            $is_ref = 'HASH';
        }

        X::Usage->throw($usage) if $is_ref ne 'HASH';

        # mixes => [ { Module1 => ... } ], 
        ($module, $filter) = each %$module; # only one left

        X::InvalidName->throw( "mixes=>'$module' ??" )
            if !$module || $module !~ $classes::ok_class_name;

        # only SAFE, PUB, and ALL acceptable non-refs
        my $filter_is_ref = ref $filter;
        if ( !$filter_is_ref ) {
            {
                $filter = qr/^(?!(?:_|\d|[A-Z0-9_]+$))/o,
                    last if $filter eq 'SAFE';
                $filter = qr/^
                    (?!_|BEGIN|CHECK|END|INIT|CLONE
                        |CLASS|SUPER|DECL|MIXIN)
                    [a-z_]\w*$/xoi,
                    last if $filter eq 'PUB';
                $filter = qr/^
                    (?!BEGIN|CHECK|END|INIT|CLONE
                      |CLASS|SUPER|DECL|MIXIN)
                    [a-z_]\w*$/xoi,
                    last if $filter eq 'ALL';
                X::Usage->throw($filter." ??\n".$usage);
            }
            $filter_is_ref = 'Regexp';
        }
        
        classes::load($module);
        my $mod_sym  = $module.'::';

        # unfortunately the following causes an empty DECL
        # to autovivify if not one there already, perl's problem
        my $mod_DECL = ${"$module\::DECL"};

        my $mod_type = ${"$module\::DECL"}->{'type'};

        # if declared AND type is set by author to 'mixin'
        # go ahead and only use the declaration.

        if ( $mod_type and $mod_type eq 'mixable' ) {
            my $methods        = $mod_DECL->{'methods'};
            my $class_methods  = $mod_DECL->{'class_methods'};
            my $pkg_methods    = $mod_DECL->{'pkg_methods'};
            my $attrs          = $mod_DECL->{'attrs'};
            my $attrs_ro       = $mod_DECL->{'attrs_ro'};
            my $attrs_pr       = $mod_DECL->{'attrs_pr'};
            my $class_attrs    = $mod_DECL->{'class_attrs'};
            my $class_attrs_ro = $mod_DECL->{'class_attrs_ro'};
            my $class_attrs_pr = $mod_DECL->{'class_attrs_pr'};

            while ( my ($name, $ivalue) = each %$class_methods ) {
                _clear_method_name($class, $name);
                _mixin( $module => $class, $name ); 
                $$class_DECL->{'class_methods'}->{$name} = $ivalue;
            }

            while ( my ($name, $ivalue) = each %$methods ) {
                _clear_method_name($class, $name);
                _mixin( $module => $class, $name ); 
                $$class_DECL->{'methods'}->{$name} = $ivalue;
            }

            while ( my ($name, $ivalue) = each %$pkg_methods ) {
                _clear_method_name($class, $name);
                _mixin( $module => $class, $name ); 
                $$class_DECL->{'pkg_methods'}->{$name} = $ivalue;
            }

            for my $name ( @$attrs ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin( $module => $class, "set_$name" ); 
                _mixin( $module => $class, "get_$name" ); 
                _mixin_key( $module => $class, $name ); 
                push @{$$class_DECL->{'attrs'}}, $name;
            }

            for my $name ( @$attrs_ro ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin( $module => $class, "get_$name" ); 
                _mixin_key( $module => $class, $name ); 
                push @{$$class_DECL->{'attrs_ro'}}, $name;
            }

            for my $name ( @$attrs_pr ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin_key( $module => $class, $name ); 
                push @{$$class_DECL->{'attrs_pr'}}, $name;
            }

            while ( my ($name, $ivalue) = each %$class_attrs ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin( $module => $class, "set_$name" ); 
                _mixin( $module => $class, "get_$name" ); 
                _mixin_key( $module => $class, $name, 'class' ); 
                $$class_DECL->{'class_attrs'}->{$name} = $ivalue;
            }

            while ( my ($name, $ivalue) = each %$class_attrs_ro ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin( $module => $class, "get_$name" ); 
                _mixin_key( $module => $class, $name, 'class' ); 
                $$class_DECL->{'class_attrs_ro'}->{$name} = $ivalue;
            }

            while ( my ($name, $ivalue) = each %$class_attrs_pr ) {
                _clear_method_name($class, "set_$name");
                _clear_method_name($class, "get_$name");
                _mixin_key( $module => $class, $name, 'class' ); 
                $$class_DECL->{'class_attrs_pr'}->{$name} = $ivalue;
            }

            next MIXIN;
        }

        # not declared as a mixable ...

        # we only look at the methods in the symbol table here
        # and don't care how they got there. these may very well have
        # classes declarations but probably not. more likely these
        # are old fashioned function libraries

        # mixes => [ { Module1 => ['method'] } ], 
        if ( $filter_is_ref eq 'ARRAY' ) {
            for my $name ( @$filter ){

                X::InvalidName->throw(
                    "mixes=>{$module=>['$name']} ??"
                    ) if !$name || $name !~ /^[a-z_]\w*$/o;

                my $glob = $$mod_sym{$name};
                my $code;

                # careful: only CODE slot, not others
                next if !$glob || !( $code = *$glob{CODE} );

                # import
                *{ $class . '::' . $name } = $code;
                _clear_method_name($class, $name);

                $$class_MIXIN->{$name} = $module.'::'.$name;
                $$class_DECL->{$type.'methods'}->{$name}
                    = $module.'::'.$name;
            }
        }

        # mixes => [ { Module1 => qr/.../o } ], 
        elsif ( $filter_is_ref eq 'Regexp'
             or $filter_is_ref eq 'Regex' ) { # older
            while ( my ($name) = each %$mod_sym ) {

                my $glob = $$mod_sym{$name};
                my $code;

                # careful: only CODE slot, not others
                next if $name !~ $filter || !$glob 
                        || !( $code = *$glob{CODE} );

                # import
                *{ $class . '::' . $name } = $code;
                _clear_method_name($class,$name);
                $$class_MIXIN->{$name} = $module;

                $$class_DECL->{$type.'methods' }->{$name}
                    = $module.'::'.$name;
            }
        }

        # ref to something else
        else {
            X::Usage->throw($filter_is_ref . $usage);
        }                                 # filter_is_ref
    }                                     # module
}

sub _mixin {
    my ($from_pkg, $to_pkg, $name, $dest_name) = @_;
    $dest_name ||= $name;
    *{ $to_pkg . '::' . $dest_name } = \&{ $from_pkg . '::' . $name };
    my $really_from = ${ $from_pkg.'::MIXIN' }->{$name};
    ${ $to_pkg.'::MIXIN' }->{$dest_name} = $really_from || $from_pkg;
}

sub _mixin_key {
    my ($from_pkg, $to_pkg, $name, $is_class) = @_;
    my $var_name = ($is_class && 'CLASS_') . 'ATTR_' . $name;
    *{$to_pkg.'::'.$var_name} = \${$from_pkg.'::'.$var_name};
    my $really_from = ${$from_pkg.'::MIXIN'}->{"\$$var_name"};
    ${ $to_pkg.'::MIXIN' }->{"\$$var_name"}
        = $really_from || $from_pkg;
}

sub _clear_method_name {
    my $decl = ${ $_[0].'::DECL' };
    my ($cm, $m, $pkm);
    $pkm = $decl->{'pkg_methods'}    and delete $pkm->{$_[1]};
    $cm  = $decl->{'class_methods'}  and delete $cm->{$_[1]};
    $m   = $decl->{'methods'}        and delete $m->{$_[1]};
    delete ${ $_[0].'::MIXIN' }->{$_[1]};
    return;
}

####################################################################

sub _define_class_attr {
    my ( $class, $name => $i_value, $scope ) = @_;
    my $qual_name  = $class.'::'.$name;
    my $scope_x = sub {X::AttrScope->throw([$name])};
    my $has_getter = $class->can("get_$name");
    my $has_setter = $class->can("set_$name");

    # set the initial value
    $$qual_name = $i_value;

    # create a string containing the name of the class attribute
    # for use privately within the class
    *{"$class\::CLASS_ATTR_$name"} = \$qual_name;

    # define 'getter' for all but private 
    *{"$class\::get_$name"} = sub { $$qual_name }
        if $scope ne 'pr';

    # define 'setter' for read-write
    if ($scope ne 'pr' and $scope ne 'ro') {
        *{"$class\::set_$name"} 
            = sub { $$qual_name = $_[1]; return };
    }

    # private shouldn't have getter or setter, if so, cause exception
    *{"$class\::get_$name"} = $scope_x
        if $scope eq 'pr' && $has_getter;
    *{"$class\::set_$name"} = $scope_x
        if $scope eq 'pr' && $has_setter;

    # read-only shouldn't have setter if so, cause exception
    *{"$class\::set_$name"} = $scope_x
        if $scope eq 'ro' && $has_setter;

    # update declaration
    my $decl = ${ $class.'::DECL' };
    $decl->{'class_attrs'
        . ($scope ? "_$scope" : '')}->{$name} = $i_value;

    return $class;
}

####################################################################

sub _define_attr {
    my ( $class, $name, $scope, $unqual, $noaccess ) = @_;
    my $qual_name   = $class.'::'.$name;
    my $attr_name   = $unqual ? $name : $qual_name;

    # create a string containing the name of the attribute
    # for use privately within the class as a object hash key
    *{"$class\::ATTR_$name"} = \$attr_name;

    # noaccess means don't create accessors, plain old perl objects
    if (!$noaccess) {
        my $scope_x = sub {X::AttrScope->throw([$name])};
        my $has_getter = $class->can("get_$name");
        my $has_setter = $class->can("set_$name");

        # define 'getter' for all but private 
        *{"$class\::get_$name"} = sub { $_[0]->{$attr_name} }
            if $scope ne 'pr';

        # define 'setter' for read-write
        if ($scope ne 'pr' and $scope ne 'ro') {
            *{"$class\::set_$name"} 
                = sub { $_[0]->{$attr_name} = $_[1]; return };
        }

        # private shouldn't have getter or setter
        # if so override with one that throws an exception at run time
        *{"$class\::get_$name"} = $scope_x
            if $scope eq 'pr' && $has_getter;
        *{"$class\::set_$name"} = $scope_x
            if $scope eq 'pr' && $has_setter;

        # read-only shouldn't have setter if so, cause exception
        *{"$class\::set_$name"} = $scope_x
            if $scope eq 'ro' && $has_setter;
    }

    # update declaration
    my $decl = ${ $class.'::DECL' };
    my $tag = 'attrs' . ($scope ? "_$scope" : '');
    push @{$decl->{$tag}}, $name
        if !grep {$_ eq $name} @{$decl->{$tag}};

    return $class;
}

####################################################################

sub _define_method {
    my ( $class, $name, $method, $type ) = @_; # trust 
    my $is_ref = ref $method;
    my ($code, $m_pkg, $m_name);

    $method = 'EMPTY' if !$method;

    # classes::abstract, classes::empty, Module::method, method
    if (!$is_ref ) {

        # inline anon to get better X::Unimplemented message
        if ( $method eq 'ABSTRACT' ) {
            $code = sub {
                X::Unimplemented->throw( "$class->$name()" );
            };
        }

        elsif ( $method eq 'EMPTY' ) {
            $code = sub { };
        }

        # Module::Mine::method_name or method_name 
        else {
            ($m_pkg, $m_name) = $method 
                =~ /^
                    (?: 
                        (   
                            (?: 
                                [a-z_]\w*\:\:    # opt: Module::
                            )*
                            [a-z_]\w*            # opt: Mine
                        )
                        ::                       # opt: ::
                    )?
                    (   
                        [a-z_]\w*                # req: method_name
                    )
                $/iogx;

            X::InvalidName->throw( [$method] ) if !$m_name;

            # no package name, method_name only - qualify
            if (!$m_pkg) {
                $method = $class . '::' . $m_name;
                $m_pkg ||= $class;
            }

            # treat as any other mixin
            else {
                _clear_method_name($class, $name);
                _mixin( $m_pkg => $class, $m_name => $name );
                my $decl = ${ $class.'::DECL' };
                $decl->{$type.'methods'}->{$name} = $method;
                return $class;
            }

            load $m_pkg if !%{$m_pkg.'::'};

            # unfortunately since we allow compile-time
            # class definition it is too early to test for defined
            # method, we have to trust that one will be defined
            # or caught by perl run-time, the following springs
            # a symbolic code ref into life no matter what,
            # rather annoying, but best we can do for now

            $code = \&$method;
        }

    }

    # sub { ... }  or  \&method
    else {
        X::Usage->throw( "$name $is_ref ??" )
            if $is_ref ne 'CODE';
        $code = $method;
        $method = 'CODE';
    }

    *{ $class . '::' . $name }  = $code;

    # update declaration - same named removed since all are methods
    _clear_method_name($class, $name);
    my $decl = ${ $class.'::DECL' };
    $decl->{$type.'methods'}->{$name} = $method;

    return $class;
}

######################################################################

sub new_args {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->classes::init_args(@_);
}

sub new_only { 
    return bless {}, $_[0];
}

sub new_init {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->initialize(@_);
}

sub new_fast {
    my $class = shift;
    return bless($_[0], $class) if ref $_[0];
    return bless({@_}, $class)  if @_;
    return bless({}, $class);
}

######################################################################

sub init_args {
    my $self  = shift;
    my $attrs = $_[0];
    $attrs = {@_} if ref $attrs ne 'HASH';

    while ( my ( $attr, $value ) = each %$attrs ) {
        my $setter = $self->can("set_$attr")
            or X::UnknownAttr->throw([$attr]);
        $self->$setter($value);
    }

    return $self;
}

######################################################################
# Modeled after Clone::PP and Clone, Matthew Simon Cavalletto,
# David Muir Sharnoff, Ray Finch, chocolateboy. See pod for
# differences.
#
# Could use some work to get object 'clone' methods observed--
# especially with the prevalence of unclonable perl classes
# out there, but alas, this makes cloning self refs difficult
# because their cached copies no longer match.

sub clone {
    X::Usage->throw('$obj->clone') if @_ != 1;
    my ($this) = @_;

    # 'undef' is a valid leaf clone value
    return $this if !defined $this;

    my $is_ref     = reftype $this;
    my $blessed_as = blessed $this;
    my $clone      = undef;

    # cache of back references to prevent recursion, mark top,
    # localized global makes the clone_cache visible down through
    # the recursive subroutine calls

    local %classes::_clone_cache = ( __top => 1, __self => $this )
        unless ( exists $classes::_clone_cache{'__self'} );

    if ( $classes::_clone_cache{__top} ) {

        # put stuff for first run, if needed, here

        delete $classes::_clone_cache{__top};
    }

    # block recursion, seen already
    return $classes::_clone_cache{$this}
        if exists $classes::_clone_cache{$this};

    # scalar = leaf
    return $this if !$is_ref;

    # clone each key or value that is a ref recursively
    if ( $is_ref eq 'HASH' ) {
        $classes::_clone_cache{$this} = $clone = {};
        %$clone = map { !ref $_ ? $_ : classes::clone($_) } %$this;
    }

    # clone each element in array  that is a ref recursively
    elsif ( $is_ref eq 'ARRAY' ) {
        $classes::_clone_cache{$this} = $clone = [];
        @$clone = map { !ref $_ ? $_ : classes::clone($_) } @$this;
    }

    # clone refs to refs and simple refs to scalars
    elsif ( $is_ref =~ /^(REF|SCALAR)$/o && !$blessed_as ) {
        $classes::_clone_cache{$this} = $clone = \( my $var = q[] );
        $$clone = classes::clone($$this);
    }

    # plain copies of anything else (globs, regx, etc.)
    else {
        $classes::_clone_cache{$this} = $clone = $this;
    }

    bless $clone, $blessed_as if $blessed_as;
    return $clone;
}

######################################################################

sub sprintf {
    my ($self, $format, @attrs) = @_;
    my @values = map {
        my $getter = $self->can("get_$_");
        defined $getter ? $self->$getter : undef;
    } @attrs;
    CORE::sprintf $format, @values;
}

sub printf {
    my ($self, $format, @attrs) = @_;
    my @values = map {
        my $getter = $self->can("get_$_");
        defined $getter ? $self->$getter : undef;
    } @attrs;
    CORE::printf $format, @values;
}

######################################################################

sub set {
    my ( $self, $name, $value ) = @_;
    my $accessor = $self->can("set_$name")
        || X::MethodNotFound->throw("set_$name");
    return $self->$accessor($value);
}

sub get {
    my ( $self, $name ) = @_;
    my $accessor = $self->can("get_$name")
        || X::MethodNotFound->throw("get_$name");
    return $self->$accessor;
}

####################################################################

sub dump {
    my ( $this, $out ) = @_;
    my $is_ref     = ref $out;
    my $blessed_as = blessed $this;
    my $class      = $blessed_as || $this || caller;
    my $decl       = ${ $class . '::DECL' };
    my $mixins     = ${ $class . '::MIXIN' };

    my $usage = <<'EOM';

    MyClass|$object->classes::dump;
    ... ->classes::dump( $handle );
    ... ->classes::dump( \$buffer );
    classes::dump(['just','anything']);
EOM

    X::Usage->throw($usage)
        if $out && !$is_ref; # handle or scalar ref

    $out ||= *STDERR;

    require Data::Dumper;

    local $Data::Dumper::Varname;
    local $Data::Dumper::Indent = 1;
    my $buf;

    # header line
    my $len = length $class;
    my $pad = int( ( 70 - $len ) / 2 );
    my $rest = 70 - ( $pad*2 + $len );
    $pad -= 2;
    $buf .= '#' x $pad . "  $class  " 
          . '#' x ( $pad + $rest ) . "\n\n";

    if ( $decl ) {
        $Data::Dumper::Varname = 'DECL';
        $buf .= Data::Dumper::Dumper($decl) . "\n";

        if ( $mixins ) {
            $Data::Dumper::Varname = 'MIXIN';
            $buf .= Data::Dumper::Dumper($mixins) . "\n";
        }

        my $d_class_attrs    = $decl->{'class_attrs'};
        my $d_class_attrs_ro = $decl->{'class_attrs_ro'};

        # pull out internal class attrs (if any) by accessor
        if ( $d_class_attrs || $d_class_attrs_ro ) {
            my %class_attr;
            $Data::Dumper::Varname = 'CLASS_STATE';
            if ( $d_class_attrs ) {
                while ( my ( $tag, $val ) = each %$d_class_attrs ) {
                    my $getter = "get_$tag";
                    my $accessor = $class->can($getter);
                    $class_attr{$tag} =
                       $accessor
                            ? $class->$accessor
                            : 'ERROR_NO_ACCESSOR';
                }
            }
            if ( $d_class_attrs_ro ) {
                while ( my ($tag, $val) = each %$d_class_attrs_ro ) {
                    my $getter = "get_$tag";
                    my $accessor = $class->can($getter);
                    $class_attr{$tag} =
                       $accessor
                            ? $class->$accessor
                            : 'ERROR_NO_ACCESSOR';
                }
            }
            $buf .= Data::Dumper::Dumper( \%class_attr ) . "\n";
        }

        # object only
        if ($blessed_as) {
            $Data::Dumper::Varname = 'OBJECT_STATE';
            $buf .= Data::Dumper::Dumper($this) . "\n";
        }

    }

    else {
        $Data::Dumper::Varname = 'THIS';
        $buf .= Data::Dumper::Dumper( $this );

        if ($blessed_as) {
            $Data::Dumper::Varname = 'PACKAGE_SYMBOLS';
            $buf .= Data::Dumper::Dumper( \%{$blessed_as.'::'} );
        }
        
    }

    # string buffer
    if ( $is_ref and $is_ref eq 'SCALAR' ) {
        $$out = $buf;
    }

    # io handle
    else {
        print $out $buf;
    }

    return $this;
}

######################################################################

sub id { Scalar::Util::refaddr($_[0]) }

######################################################################
# Throwable mixin - the guts of perl exceptions

package classes::Throwable;
use strict 'subs'; no warnings;
use Scalar::Util;

use classes
    type => 'mixable',
    class_methods => {
        throw   => 'throw',
        caught  => 'caught',
        catch   => 'caught',     # synonym
    },
    methods => {
        capture  => 'capture',
        rethrow  => 'rethrow',
        send     => 'rethrow',
    },
; # END DECLARATION

sub capture { $_[0] };
sub throw   { my $x = shift->new(@_); $x->capture; die $x }
sub rethrow { die $_[0] if $_[0] }

sub caught {
    my $class    = shift;
    my $last_err = $@;

    return $last_err
        if Scalar::Util::blessed $last_err && $last_err->isa($class);

    return undef;
}

######################################################################
# Bare minimum exception class

package X::classes;
use strict 'subs'; no warnings;
use Scalar::Util;

use classes
    mixes   => 'classes::Throwable',
    new     => 'classes::new_init',
    init    => 'classes::init_args',
    clone   => 'classes::clone',
    dump    => 'classes::dump',
    methods => ['as_string'],
;

sub as_string {
    my $c = Scalar::Util::blessed shift;
    return "exception $c\n"
}

use overload bool => sub {1}, '""' => 'as_string', fallback => 1;
 
######################################################################
# base exception class

package X::classes::traceable;
use strict 'subs'; no warnings;
use Scalar::Util;

use classes
    extends   => 'X::classes',
    new       => 'classes::new_init',
    init      => 'initialize',
    clone     => 'classes::clone',
    dump      => 'classes::dump',
    class_attrs => {
        'Verbose'       => 3,
        'Order'         => ['item','message'],
        'Format'        => '',
        'Caller_Format' => q[    at %4$s %1$s '%2$s' %3$s],
        'Whole_Stack'   => undef,
    },
    attrs => [qw(
            item message full_message attr_list
        )],
    attrs_ro => [qw(
            pid uid euid gid egid time
            call_stack call_package call_method call_file call_line
        )],
    methods => [ 'as_string' ],
;

sub get_full_message { get_message(@_) }
sub set_full_message { set_message(@_) }

sub capture {
    my ($self, $offset) = @_;

    my @call_stack;
    $offset = @_ >= 2 ? $offset : 0;

    # remove this method (at least)
    my $whole_stack = $self->get_Whole_Stack;
    my $frame = $whole_stack ? 1 : 1 + $offset;

    # fixes problems with some versions of perl time
    $self->{$ATTR_time} = CORE::time();

    # process ownership
    $self->{$ATTR_pid}  = $$;
    $self->{$ATTR_uid}  = $<;
    $self->{$ATTR_euid} = $>;
    $self->{$ATTR_gid}  = $(;
    $self->{$ATTR_egid} = $);

CALL_TRACE:
    while (1) {
        my @call_frame = caller($frame);
        last CALL_TRACE if !@call_frame;
        push @call_stack, \@call_frame;
        ++$frame;
    }

    # if at least one frame, give context of the caller's caller
    shift @call_stack if @call_stack > 1 && !$whole_stack;

    my $call_stack_ref = \@call_stack;
    $self->{$ATTR_call_stack}   = $call_stack_ref;
    $self->{$ATTR_call_package} = $call_stack[0][0];
    $self->{$ATTR_call_file}    = $call_stack[0][1];
    $self->{$ATTR_call_line}    = $call_stack[0][2];
    $self->{$ATTR_call_method}  = $call_stack[0][3];

    return $self;
}

sub initialize {
    my $self = shift;
    my $is_ref = ref $_[0];

    $self->{$ATTR_message}      = '';
    $self->{$ATTR_full_message} = '';

    # X::classes::traceable->new('some message')
    if ( !$is_ref && @_ == 1 ) {
        $self->{$ATTR_message} = $_[0];
        return $self;
    }

    # X::classes::traceable->new( ['item'] )
    elsif ( $is_ref eq 'ARRAY' ) {
        $self->set_attr_list($_[0]);
        return $self;
    }
    # normal
    # X::classes::traceable->new( message=>'blah', item=>2 )
    # X::classes::traceable->new( -message=>'blah', -item=>2 )
    # X::classes::traceable->new( { message=>'blah', item=>2 } )
    # X::classes::traceable->new( { -message=>'blah', -item=>2 } )
    return $self->classes::init_args(@_);
}

sub set_attr_list {
    my $self = shift;
    X::Usage->throw("\$exc->set_attr_list(ARRAYREF)\n")
        if ref $_[0] ne 'ARRAY';
    my $attr_list = $self->{$ATTR_attr_list} = $_[0];

    # Rest is dispatch side-effect ...

    my $order = $self->get_Order; # commonly overriden
    my @order = @$order;

    # cannot dispatch if no 'Order' of attr_list
    return $attr_list unless @order >= 1;

    for my $attr_value (@$attr_list) {
        my $attr_name = shift @order;

        # order = 'name', undef,     'rank'
        # list  = 'Bob',  'ignored', 'private', 'ignored2'
        next if !$attr_name;

        # dispatch to accessor
        $self->classes::set( $attr_name => $attr_value );
    }

    return $attr_list;
}

sub as_string {
    my $self    = shift;
    my $verbose = $self->get_Verbose;

    return '' if not $verbose;

    my $exception_name = Scalar::Util::blessed $self;
    my $full_message   = $self->get_full_message;

    my $attrs          = $self->get_attr_list;
    my @attrs          = @$attrs if $attrs;
    my $format         = $self->get_Format;

    return $exception_name . "\n" if $verbose == 1; 

    # exception
    my $string = $exception_name;

    # exception + message or attr_list
    if ( $verbose >= 2 ) {
        $string .= ' ';
        $string .= $full_message
            || (
            ($format)
            ? sprintf( $format, @attrs )
            : "@attrs"
            );
        $string .= "\n";
    }

    # exception + message or attr_list + trace (3=file, 4=path)
    if ( $verbose >= 3 ) {
        my $caller_format = $self->get_Caller_Format;
        my $call_stack    = $self->get_call_stack;
        for my $caller (@$call_stack) {
            if ( $verbose == 3) {
                use File::Basename 'basename';
                $$caller[1] = basename $$caller[1];
            }
            $string .= sprintf $caller_format . "\n", @$caller;
        }
    }

    return $string;
}

use overload bool => sub {1}, '""' => 'as_string', fallback => 1;

################################################################
## exceptions used by 'classes' itself
################################################################

package main;
classes::classes
    { name=>'X::NameUnavailable', extends=>'X::classes::traceable' },
    { name=>'X::InvalidName', extends=>'X::classes::traceable' },
    { name=>'X::NotPkgMethod', extends=>'X::classes::traceable' },
    { name=>'X::Unimplemented', extends=>'X::classes::traceable' },
    { name=>'X::Usage', extends=>'X::classes::traceable' },
    { name=>'X::Undefined', extends=>'X::classes::traceable' },
    { name=>'X::Empty', extends=>'X::classes::traceable' },
    { name=>'X::MethodNotFound', extends=>'X::classes::traceable' },
    { name=>'X::AttrScope', extends=>'X::classes::traceable' },
    { name=>'X::UnknownAttr', extends=>'X::classes::traceable' },
;

1;
__END__

=pod

=head1 NAME

classes - conventional Perl 5 classes

=head1 VERSION

This document covers version 0.944

=head1 SYNOPSIS

    package MyClass;
    use strict 'subs'; no warnings;
    use classes
        new             => 'classes::new_init',
        class_attrs     => [ 'Attr' ],
        class_attrs_ro  => { 'Read_Only_Attr'=>'yes' },
        class_attrs_pr  => { 'Priv_No_Accessors'=>'ok' },
        attrs           => [ 'attr', '_not_really_private' ],
        attrs_ro        => [ 'read_only_attr' ],
        attrs_pr        => [ 'attr_no_accessors' ],
        class_methods   => { 'Empty_Method'=>0 },
        methods         => { abstract_method => 'ABSTRACT' },
        throws          => 'X::Usage',
        exceptions      => 'X::MyOwn',
    ; 

Mixins:

    package MyMixinMod;
    use classes
        type=>'mixable',
        ...
    ;

    package UsesMixins;
    use classes
        mixes => ['MyMixinMod','AnyPackage'],
        methods => {
                foo => 'SomePackage::a_foo_method',
            },
        ...
    ;

Inheritance:

    use classes name=>'MySuper', attrs=>['color'];

    package ExtendsMySuper;
    use classes
        extends => 'MySuper',
        ...
    ;

    package MultipleInheritance:
    use classes
        inherits => [ 'MySuper', 'AnotherPackage' ],
        ...
    ;

Package Methods (traditional export):

    package FunctionLib;
    use classes
        pkg_methods => [ 'foo', 'bar' ],
        ...
    ;

    use FunctionLib ':all';
    use FunctionLib qw( foo bar );

Dynamic Classes:

    package DynamicOne;
    use classes
        type => 'dynamic',
        class_methods => ['add_attr'],
        ...
    ;

    sub add_attr {
        my ($class, $attr_name) = @_;
        classes attrs => [$attr_name];
        return $class;
    }

B<DECLARATION TAGS>

    name => 'MyClass',

    type => 'static',
    type => 'dynamic',
    type => 'mixable',

    extends  => 'SuperClass',
    inherits => 'SuperClass',
    inherits => ['Class1', 'Class2'],

    mixes => 'Module',
    mixes => { Module => ... },
    mixes => [
        'Module1',
        { Module2 => [ 'method1', ... ] },
        { Module3 => 'ALL' | 'PUB' | 'SAFE' },
        { Module4 => qr/.../ },
     ],
    class_mixes => ...
    pkg_mixes => ...

    mixes_def => 'SAFE' | 'ALL' | 'PUB',

    attrs => [ 'attr1', 'attr2' ],
    attrs_ro => ...
    attrs_pr => ...

    class_attrs => [ 'class_attr1', 'class_attr2' ],
    class_attrs => {
        class_attr1 => undef,
        class_attr2 => 100,
        class_attr3 => 'string',
        class_attr4 => <ref>,
    },
    class_attrs_ro => ...
    class_attrs_pr => ...
     
    unqualified => 1,
    unqualified => 0,

    noaccessors => 1,
    noaccessors => 0,

    justahash => 1,  # unqualified + noaccessors
    justahash => 0,  # unqualified + noaccessors

    methods => [ 'method1', 'method2' ],
    methods => {
        method1 => 'method1',
        method2 => 'local_method',
        method3 => 'Extern::library::method',
        method4 => 'ABSTRACT',
        method5 => <false> | 'EMPTY',
        method6 => sub { ... } | \&some::method,
    },
    class_methods => ...
    pkg_methods => ...

    new   => 'new',
    new   => 'classes::new_args',
    new   => 'classes::new_only',
    new   => 'classes::new_init',
    new   => 'classes::new_fast',
    new   => 'MyModule::new_method',

    init  => 'initialize',
    init  => 'classes::init_args',
    init  => 'MyModule::initialize',

    clone => 'clone',
    clone => 'classes::clone',
    clone => 'MyModule::clone',

    dump  => 'classes::dump',

    throws => 'X::Usage',
    throws => [ 'X::Usage' ],

    exceptions => 'X::Doh',
    exceptions => [
        'X::Ouch',
        'X::NoWay',
        { name => 'X::FileOnFire', attrs=>['file'] },
    ],
    exceptions => { name => 'X::FileOnFire', attrs=>['file'] },

    base_exception => 'X::OtherClass',
    base_exception => 'X::classes',
    base_exception => {
        name    => 'X::BaseException',
        extends => 'X::Whatever',
    },

    def_base_exception => 'X::classes',

B<COMMON METHODS>

    my $object = MyClass->new;
    my $object = MyClass->new(  attr1=>1  );
    my $object = MyClass->new({ attr1=>1 });

    $object->initialize;
    $object->initialize(  attr1=>1  );
    $object->initialize({ attr1=>1 });

    my $deep_clone = $object->clone;

    $object->dump;
    MyClass->dump;

B<ACCESSOR METHODS>

    my $value = MyClass->get_My_Class_Attr;
    my $value = $object->get_my_attr;

    MyClass->set_My_Class_Attr(7);
    $object->set_my_attr(7);

B<AUTOMATIC>

    $self->{$ATTR_foo}
    $$CLASS_ATTR_foo

    MyClass->DECL;
    $object->DECL;
    $MyClass::DECL;

    MyClass->MIXIN;
    $object->MIXIN;
    $MyClass::MIXIN;

    MyClass->CLASS;
    $object->CLASS;
    $MyClass::CLASS;

    MyClass->SUPER;  # $ISA[0]
    $object->SUPER;  # $ISA[0]
    $MyClass::SUPER;

    $classes::PERL_VERSION

B<UTILITY METHODS>

    MyClass->classes::dump;
    $object->classes::dump;
    $any_scalar->classes::dump;
        ... ->classes::dump( $handle );
        ... ->classes::dump( \$buffer );

    classes::dump;
    classes::dump(MyClass);
    classes::dump($object);
    classes::dump(['any', 'scalar', 'really']);

    classes::load MyClass;
    classes::load MyModule;
    classes::load MyPackage;

    MyClass->classes::set( My_Class_Attr=>1 );
    $object->classes::set( my_attr=>1 );

    my $value = MyClass->classes::get( 'My_Class_Attr' );
    my $value = $object->classes::get( 'my_attr1' );

    my $string = MyClass->classes::sprintf( '%s', 'My_Class_Attr');
    my $string = $object->classes::sprintf( '%s', 'my_attr1');

    MyClass->classes::printf( '%s', 'My_Class_Attr');
    $object->classes::printf( '%s', 'my_attr1');

    my $id = $object->classes::id; 

B<EXCEPTIONS>

    X::classes
        X::classes::traceable
            X::AttrScope
            X::Empty
            X::InvalidName
            X::NameUnavailable
            X::NotPkgMethod
            X::MethodNotFound
            X::Unimplemented
            X::Usage
            X::Undefined

See
L<X::classes>,
L<X::classes::traceable>,
L<classes::Throwable>

=head1 DESCRIPTION

A simple, stable, fast, and flexible way to use conventional Perl 5
classes in scripts, rapid prototypes, and full-scale applications.

This reference document covers syntax only. See the following
for more:

=over 4

=item L<classesoop>

Introductory primer of concepts, ideas and terms from object oriented
programming without any particular implementation specifics in mind.

=item L<classestut>

List of included tutorials aimed at taking a beginning Perl
programmer from the basics to advanced techniques of object oriented
programming with C<classes>.

=item L<classescb>

Cookbook collection of specific tasks and examples with lots of
useable code.

=item L<classesfaq> 

Questions and answers about support, design decisions, justification,
motivation, and other hype.

=back

=head1 DECLARATION TAGS

Declaration tags are passed to C<use classes> at compile time or to
the C<classes> function at run time. All tags are optional depending
on the context. Some have default values. Tags with undefined
or otherwise negative values are usually ignored. A declaration
representing the class is always available in a special C<DECL>
meta attribute best displayed with C<classes::dump>.

Tag descriptions are ordered as you may expect to find them in
a declaration.

=over

=item name

Name of the class to define. If omitted will use the implied name
of the calling package--including C<main>, (which is just another
class). Name must be valid Perl package name.

See:
L<perlmod>,
L<perlobj>

=item type

Specifies the type of C<classes> usage:

=over 4

=item I<static>

Default. Indicates a class that is not going to change during its
run time life:

=over 4

=item *

Does not import the C<classes> function

=item *

Defines and initializes declaration C<DECL>

=item *

Defines the C<CLASS> constant

=item *

Defines the C<SUPER> method

=back

=item I<mixable>

Same as C<static> but indicates the class/module/package can be
used as a mixin. Like C<static> a C<mixable> can be a stand-alone
class or not (unlike some other languages that support mixins). The
attributes and methods declared in a C<mixable> are "mixed into"
other classes that use the C<mixes> tag. The result is something
between inheritance and having defined everything originally in
the receiving classes.

Calls to the mixed in methods respond mostly as if they were
inherited, they "see" functions and variables defined within the
package in which C<mixable> was declared. The only exception to
this is the special C<$ATTR_foo> and C<$CLASS_ATTR_foo> keys which
behave as expected pointing to the mixin from which they came. To
help keep these straight they are included in the special C<MIXIN>
table along with every method that has been mixed in.

B<WARNING:> Every object or class B<I<method.>>, but not necessarily
I<function>, used by any declared object or class method in
a C<mixable> must also be declared in order for the declared
method to work. Consider C<$self-E<gt>_next_one> called from a
declared C<mixable> method. See I<Can't locate object method>
under C<TROUBLESHOOTING> for more.

Strictly speaking a mixin is not inherited. The special C<@ISA>
array is not updated and the normally inherited C<UNIVERSAL-E<gt>isa>
method returns false if checked for the name of the mixin. Such an
equivalent is not practical when dealing with mixins. Use C<MIXIN>
to assist with introspection if needed. It contains every method
not from that immediate class and the package it came from.

See: C<mixes>, C<$MIXIN>, C<$DECL>,

=item I<dynamic>

Indicates a class that can be created or redefined in some way at
run time. C<dynamic> classes behave exactly as C<static> classes
except they also import the C<classes> function into the class
itself allowing it to be used at run time to add to or redefine
some part of the class.

=back

=item extends

Declares single class to extend that will be searched out of C<@INC>
and loaded exactly like the C<base> pragma. Cannot be included in
the same declaration with C<inherits>.

Choose C<mixes> over C<extends> where possible.

Throws:
C<X::InvalidName>,
C<X::Usage>

See:
L<base>,
L<perlvar/"@INC">,
C<SUPER>

=item inherits

Same as C<extends> but for one or more classes (multiple
inheritance).

C<SUPER> will refer to the first inherited class. This tag cannot
be included in the same class declaration as C<extends>.

Choose C<mixes> over C<inherits> where possible.

See:
C<SUPER>

=item mixes

"Mixes in" methods and attributes from another class or
package. Modules are loaded if needed. The meta attributes C<$DECL>
and C<$MIXIN> are updated.

Behavior differs depending on what is being mixed in.

If C<use classes type=E<gt>'mixable'> (see C<type>) was used to
declare the mixin then all of the following from the declaration
are mixed in: 

    methods
    class_methods
    pkg_methods
    attrs
    attrs_ro
    class_attrs
    class_attrs_ro

For public attributes the special associated attribute key name
strings are also mixed in (ex: C<$ATTR_foo>, C<$CLASS_ATTR_foo>,
see C<attrs>).

Everything else is seen as a simple package, a collection of methods
or functions which might be a class declared with C<use classes>
(not type C<mixable>), a traditional Perl class, a function library or
any other package with subroutines. These can be selectively mixed
in by name, regular expression, or one of the following aliases:

=over 4

=item I<SAFE>

Default and safest. Matches any method name that is not all caps
nor preceded with an underscore.

=item I<ALL>

Matches any valid method name, including all caps and initial
underscore B<I<except>> for the special:

    BEGIN CHECK INIT END
    CLONE
    CLASS SUPER DECL MIXIN

B<WARNING>: Other special all caps perl subroutines B<I<will>> be
imported when using C<ALL>. This includes C<DESTROY> and C<AUTOLOAD>
if defined.

=item I<PUB>

Matches any valid method name--including all caps--that does
B<I<not>> begin with underscore B<I<except>> for the same special
names listed for C<ALL> above.

=back

You can change the default alias by adding the C<mixes_def> tag.

When in doubt check the symbol table with
C<classes::dump(\%MyClass::)>.

Throws:
C<X::InvalidName>,
C<X::Usage>

See:
C<class_mixes>,
C<pkg_mixes>,
C<mixes_def>,
C<methods>,
C<class_methods>,
C<pkg_methods>,
C<attrs>,
C<attrs_ro>,
C<class_attrs>,
C<class_attrs_ro>,
C<MIXIN>,
C<$MIXIN>,
C<classes::load>,
L<perlre>,
L<perlref>,
L<perlmod>,
L<perlobj>,
L<AutoLoader>

=item class_mixes

Exactly the same as C<mixes> but as if C<class_methods> were
used instead of C<methods>.

=item pkg_mixes

Exactly the same as C<mixes> but as if C<pkg_methods> were
used instead of C<methods>.

=item mixes_def

Sets the default C<mixes> filter for all mixins in that same
declaration. Set to C<SAFE> by default.

=item attrs

Declares object attributes. Attribute names must begin with
C<[a-zA-Z_]> followed by zero or more C<[a-zA-Z0-9_]> characters.

Each attribute receives both a public pair of accessor methods
which begin with C<set_> and C<get_>, unless specifically requested
otherwise with C<noaccessors> or C<justahash>. A key variable of
the form C<$ATTR_foo> is also added to the class for use within the
class. Use this when referring to your object attribute key since
it observes things like C<unqualified>. [It is a fraction of 1%
slower according to benchmarks. There are other more advanced
reasons explained in L<classescb>].

    $self->{$ATTR_foo} = 'blah';

B<TIP:> Vim users can add this macro line to your F<.vimrc> file or
equivalent to create your attributes quickly by typing the attribute
name, escaping, then typing backslash (\a):

    map \a bi$self->{$ATTR_<ESC>ea}

All attribute values must be scalars. References to arrays,
hashes and blessed objects are scalars.

B<WARNING:> In your overriden C<get_> accessor use C<classes::clone>
or otherwise return a clone of attribute values that are references
if you are concerned your class users might directly manipulate
your attribute by using the returned reference. Better yet, don't
make that attribute public, even as read-only, and use other methods
that operate on the attribute values instead.

The C<get_> accessor always return the current value of
the attribute, which is C<undef> until some value is set. Initialize
object attribute values from the C<new> or C<initialize> methods:

    package MyClass;
    use classes
        new   => 'new',
        attrs => ['color'],
    ;

    sub new {
        my $class = shift;
        my $self = {
            $ATTR_color => 'chartreuse',
        };
        bless $self, $class;
        return $self->classes::init_args(@_);
    }

    package main;
    my $object = MyClass->new;
    print $object->get_color;             # chartreuse
    $object->set_color('blue');
    print $object->get_color;             # blue

Or, if you intend to "recycle" and reinitialize existing objects
rather than throwing them away and creating new ones:

    package MyClass;
    use classes
        new   => 'classes::new_init',
        attrs => ['color'],
    ;

    sub initialize {
        my $self = shift;
        $self->{$ATTR_color} = 'chartreuse';
        return $self->classes::init_args(@_);
    }

    package main;
    my $object = MyClass->new;
    print $object->get_color;             # chartreuse
    $object->set_color('blue');
    print $object->get_color;             # blue

B<NOTE:> The C<classes> pragma follows the Perl best practice of
adding the accessor prefixes (C<set_> and C<get_>) to increase
clarity, improve performance, catch bugs at compile time, and reduce
the risk of attribute methods stomping on other methods. Attibute
names can even be all capitals or other reserved names because the
accessor method prefix prevents name collision.

B<WARNING:> The C<set_> accessor (mutator) must B<I<always>> return
void (C<return> with no arguments). I<The return value of a C<set_>
method should never be checked or used for anything.> Throw and
catch exceptions to handle bad values, etc.

    sub set_color { $_[0]->{$ATTR_color} = 'my:'. $_[1]; return }


Throws:
C<X::Usage>,
C<X::InvalidName>,
C<X::classes::AttrAlreadyPublic>

See:
C<attrs_ro>,
C<class_attrs>,
C<class_attrs_ro>,
C<unqualified>,
C<initialize>,
L<perlsub>,
L<perldoc/"return">

=item attrs_ro

Same as C<attrs> but only C<get_> public accessor defined.

However, if an inherited read-write attribute with the same name
is detected a read-only C<set_> public accessor is defined that
does nothing more than throw a C<X::classes::ReadOnly> exception.

B<WARNING:> Beware of leaving behind custom overriden public
C<set_> accessors when changing a read-write attribute (C<attrs>)
to read-only (C<attrs_ro>).

=item attrs_pr

Same as C<attrs> but no public accessors are defined at all. The
C<$ATTR_foo> string is still created within the declaring
class. These private/protected attributes are not inherited with
C<extends>, C<inherits>, or C<use base> since they have no accessor
methods to inherit. 

However, the object attribute hash key C<$ATTR_foo> B<I<is>> mixed
in if the attribute is in a explicitely C<mixable> module allowing
C<$self-E<gt>{$ATTR_foo}> from within the mixing class. This makes
refactoring mixins from class code very easy since methods can
literally be cut and paste without modification.

=item unqualified

Sets internal use of unqualified attribute key names, which
is usually a bad idea unless you really know what you are doing
since classes could inadvertently stomp over each other's internal
keys. Set to 1 to cause the internal object hash ref to not have
each key prefixed with C<E<lt>CLASSE<gt>::>.

B<NOTE:> Use the C<$ATTR_foo> and C<$CLASS_ATTR_foo> key variables
containing the corresponding names in order to avoid changing
class code during refactoring. Methods can be cut and paste often
without modification by following this convention. See C<attrs>
and C<class_attrs> for more about this.

=item noaccessors

Disables creation of C<set_> and C<get_> accessor methods for
object attributes expecting them to be set directly. Usually used in
conjuction with C<unqualified>. If so, consider setting C<justahash>
instead.

=item justahash

Same as C<unqualified>, C<noaccessors>, and
C<new=>'classes::new_fast'> combined. Great for POPOs (plain old
perl objects) that are first hashes that happen to have methods
and class attributes associated with them. Objects from a class
with this declaration fully expect to have their "internal" hash
ref accessed directly.

=item class_attrs

Same as C<attrs> but for attributes with class scope. In addition
class attributes can be declared with initial values. 

Class attributes declared and defined with the C<classes> pragma
behave like most OO programmers expect; changing a class attribute
value anywhere changes it for all objects from that class as well
as all objects from any class that inherits or mixes it in. Classes
wishing to take over the class attribute must redeclare it (thereby
overriding its accessors).

B<WARNING>: This behavior is unlike L<Class::Data::Inheritable>
which obtusely allows any class to take over a "class attribute"
by simply setting its value.

Class attributes are implemented as package variables. A key variable
containing the qualified name of the attribute is available in the
C<$CLASS_ATTR_foo> form. Use it within the class to refer to class
attribute package variables (with strict 'vars' off of course):

    no strict 'refs';
    sub set_Color { $$CLASS_ATTR_color = $_[1]; return }

B<TIP:> Vim users can add the following macro line to their F<.vimrc>
to quickly create this by typing the name of the class attribute,
then escape, then backslash capital A (\A):

    map \A bi$$CLASS_ATTR_<ESC>ea

The following are identical within the class. Pick the one you
prefer, but keep in mind that if your class package name changes,
you might have a lot of find and replace to do on your class:

    $MyClass::color
    ${__PACKAGE__.'::color'}
    ${CLASS.'::color'}
    ${"$CLASS\::color"}
    ${$CLASS_ATTR_color}
    $$CLASS_ATTR_color

C<WARNING>: Don't attempt to initialize a class attribute value
during during C<new> or C<initialize> since it blows away any
changes to the class attribute over the previous life of the class
affecting all its derived classes. Provide an initial value in the
hash ref form of the C<class_attrs> declaration:

    class_attr => {
        foo => 'initial value',
    },

=item class_attrs_ro

Same as C<class_attrs> but no C<set_> accessor like C<attrs_ro>.

=item class_attrs_pr

Same as C<class_attrs> but private (no accessors) like C<attrs_pr>.

=item methods

Declares member methods (more strictly, "operations") and the
I<actual> methods to which they refer. Usually the two will be the
same, which seems redundant and is the default for the C<ARRAY>
ref form, but the actual method may refer to any method in any
class, module, or package. Like C<mixes> the module containing
the external method will be loaded if it has not been.

The following special anonymous methods are also available:

=over 4

=item I<ABSTRACT>

Assigns a nearly empty anonymous method that will throw an
C<X::Unimplemented> exception if called before being
overriden. This is useful for defining an abstract class or interface
which expects to have methods mixed in or inherited to realize the
abstract ones.

=item I<EMPTY>

=item I<E<lt>falseE<gt>>

Assigns an empty anonymous method C<sub {}>. Useful for nullifying a
method without breaking the interface.

=back

Method values can also be C<CODE> refs with the disadvantage of
only appearing as C<CODE> in the declaration C<DECL> instead of
the local or qualified method name.

Use C<methods>, C<class_methods>, or C<pkg_methods> instead of
C<mixes> if you only need to pull in a few specific methods.

Per L<perlstyle> guidelines, name your public methods with an initial
lowercase letter. Join multiword methods with underscores. Begin
your private methods with an underscore, if you declare them at all.

Throws:
C<X::Usage>,
C<X::InvalidName>,

See:
C<class_methods>,
C<pkg_methods>,
C<mixes>,
C<extends>,
C<inherits>,
L<perlstyle>

=item class_methods

Same as C<methods> but with class scope. However, since perl
currently makes no distinction there is no difference between this
tag and C<methods> other than the C<class_methods> section of the
declaration C<DECL>.

Avoid I<bimodal> methods that can be called from both a class or
object. You cannot declare a I<class> and I<object> method with
the same name, (although should you wish you could declare a method
with the same name as an attribute because of the attribute accessor
prefixes C<set/get>).

See: C<methods>, C<pkg_methods>

=item pkg_methods

Package methods are just functions. Using this tag is optimized
shorthand for what you might do using the C<Exporter> module's
C<EXPORT_OK> hash. Package methods are automatically available for
import on request:

    package MyPackage;
    use classes pkg_methods=>['ini2hash', 'hash2ini'];

    package main;
    use MyPackage 'ini2hash';
    my $hash = ini2hash($ini);

Or, use the special C<':all'> tag:

    use MyPackage ':all';
    my $hash = ini2hash($ini);
    my $ini  = hash2ini($hash);

Under the hood the C<import> routine added to your package is a
slimmed down equivalent to what would be added by the C<Exporter>
module. Obviously you can override the automatic C<import> with your
own if you want to do something fancier with your C<pkg_methods>
when they are requested.

Unlike C<class_methods> and C<methods>, C<pkg_methods> do not
expect a first argument to be a class or object reference.

See: C<methods>, C<class_methods>, C<pkg_mixes>

=item throws

Declares exceptions that are thrown by the class but defined
elsewhere. Loads the module containing the exception class if needed
and found.

Use C<throws> or C<exceptions> to quickly add common exceptions
to your shell scripts and prototypes. Even if you are not using
OO the base L<X::classes> and L<X::classes::traceable>
classes, which both mix in L<classes::Throwable>, can be useful.

See:
C<exceptions>,
L<EXCEPTIONS>,
C<classes::load>

=item exceptions

Declares exception classes be automatically defined. Exception
classes are listed by name or declaration. By default each is a
subclass of a automatically defined exception class matching the
class name of the form C<X::MyClass>.

    package MyClass;
    use classes
        exceptions => ['X::MyException','X::MyOther'],
    ;

The above is exactly equivalent to the following long hand:

    classes
        { name=>X::MyClass,     extends=>'X::classes::traceable' },
        { name=>X::MyException, extends=>'X::MyClass' },
        { name=>X::MyOther,     extends=>'X::MyClass' },
    ;

This preserves a convenient exception inheritance tree useful for
catching exceptions in user code.

If the hash ref form is used and C<extends> is omitted it is
implied to be whatever the base exception class is, by default the
C<X::MyClass> exception.

Use C<base_exception> and C<def_base_exception> to change the default
base exception class from the C<X::MyClass> one dynamically created
matching the class name.

Inheritance is strongly preferred over mixins for exceptions in
order to trap them at different scope levels.

B<TIP:> To save further hassle declaring exception classes, use the
C<X::classes::traceable> C<message> and C<item> generic attributes
instead of declaring your own additional exception attributes
where practical.

Declaring an exception class that already appears to exist causes a
C<X::NameUnavailable> exception to be thrown. To avoid this, change
the declaration from C<exceptions> to C<throws>; or, use a different
name in the hash ref declaration of the exception and specify it as
extending the one that already exists; or, use a different name and
just don't worry about extending the other. C<X::Usage> is a good
example of this. It is predeclared and used by C<classes> itself and
therefore available to every class that uses the C<classes> pragma.

B<WARNING>: Always use the conventional C<X::> namespace in your
exception class names. This practice makes exceptions easy to spot
in code while reducing name conflicts with other legitimate classes
and base exceptions. If you are really concerned with exception
class namespace clashes that are out of your control then add the
full class name after the C<X::> to qualify it further, long for
sure, but safe from conflict. The following C<vim> syntax hilighting
macro makes spotting exceptions even easier in the code. Add it to
your F<~/.vim/syntax/perl.vim>:

    syn match  perlOperator "X\:\:[a-zA-Z:_0-9]*"

See:
C<throws>,
L<X::classes>,
L<X::classes::traceable>,
L<classes::Throwable>,
L<EXCEPTIONS>,
L<DECLARATION TAGS>

=item base_exception

Sets the base exception class to use for all C<exceptions>
declared. By default becomes a dynamically create exception class
matching the name of the class in the form C<X::MyClass>. Applys only
to the specified or implied class associated with the declaration.

=item def_base_exception

Same as C<base_exception> but applies to any and all declarations that
use the C<classes> pragma from that time forward. Remember that
this applies at compile time when using C<use classes>.

B<TIP:> If you never need or want traceablity in your exceptions
set this to C<X::classes> in some master class to create the lightest
exceptions possible. Then when debugging, you can change in the
master class back to C<X::classes::traceable> or something like it.

=item new

Declares the method to use for the standard C<new>
constructor. Shortcut for C<class_methods>. The following are
equivalent:

    new => 'new',
    class_methods => [qw( new )],
    class_methods => { new => 'new'},
    
    new => 'classes::new_only',
    class_methods => { new => 'classes::new_only' }

B<NOTE:> Athough using the name C<new> for the constructor is
not required it is recommended and a well-established
best practice.

See also:
C<new>,
C<clone>,
C<initialize>,
C<new_args>,
C<new_init>,
C<new_only>,
C<new_fast>,
C<class_methods>

=item init

Declares the method to use for the standard C<initialize>
method. Shortcut for C<methods>. The following are
equivalent:

    init => 'initialize',
    methods => [qw( initialize )],
    methods => { initialize => 'initialize'},
    
    init => 'classes::init_args',
    methods => { initialize => 'classes::init_args' }

B<NOTE:> Athough an C<initialize> method is not required it is
recommended for classes with objects that would prefer to be
(re)initialized than thrown away and replaced with a new one.

See also:
C<initialize>,
C<new>,
C<new_init>,
C<init_args>,
C<methods>

=item clone

Declares the method to use for the common C<clone> method. Shortcut
for C<methods>. The following are equivalent:

    clone => 'clone',
    methods => [qw( clone )],
    methods => { clone => 'clone'},

    clone => 'classes::clone',
    methods => { clone => 'classes::clone' }

See also:
C<clone>,
C<new>,
C<methods>

=item dump

Declares the method to use for the C<dump> method commonly defined
during development to help with debugging. The following are
equivalent:

    dump => 'classes::dump',
    methods => { dump => 'classes::dump' }

See also:
C<classes::dump>,
C<methods>

=back

=head1 METHODS

The following methods are either defined into the classes and mixins
that are created using C<classes> or are available with the
fully qualifed C<classes::> prefix and can be mixed into your code:

=over

=item classes

=item classes::classes

=item classes::define

=item define

    use classes type=>'dynamic';
    classes ... ;

    use classes ();
    classes::classes ... ;
    classes::define ... ;

Main C<classes> command function. The dynamic (run time) variant of
C<use classes>. The C<classes> function is imported into classes with
the C<type =E<gt> 'dynamic'> to allow manipulation of classes at
run time. The C<classes::define> function is an identical (symbol)
alias to C<classes::classes> that is never exported and always
available in its fully qualified form.

Throws: every exception listed under L<EXCEPTIONS>

See:
C<type>

=item new

The standard constructor method. Defined by most all classes
but often missing from C<mixables>. When called from a class
returns a new instance (object) of the class. C<classes::new_args>
and C<classes::new_only> are good defaults where no constructor
customization is needed. C<classes::new_init> hands all arguments
to an expected C<initialize> method. C<classes::new_fast> expects
a single hash ref as argument and uses it for the internal object
storage.

Use C<clone> instead of C<new> to create copies of objects.

Often you will need a custom C<new> method to initialize object
attributes. See C<attrs> for a small example of this.

Consider overriding C<initialize> before C<new> if your class'
objects may need to be reinitialized rather than thrown away and
replaced with new ones.

See:
C<new>,
C<new_args>,
C<new_only>,
C<new_init>,
C<new_fast>,
C<initialize>,
C<class_methods>,
L<perlobj>,
L<perlref>

=item classes::new_args

=item new_args

Constructor implementation. Fulfills C<new>. Creates object
and then hands off with any arguments to C<classes::init_args>:

    sub new_args {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        return $self->classes::init_args(@_);
    }

See:
C<init_args>,
C<new>,
C<new_init>,
C<new_only>,
C<new_fast>,
C<class_methods>

=item classes::new_only

=item new_only

Constructor implementation. Fulfills C<new>. Ignores any arguments
(since it does not call the initializer):

    sub new_only { return bless {}, $_[0] }

See:
C<new>,
C<new_args>,
C<new_init>,
C<new_fast>,
C<class_methods>

=item classes::new_init

=item new_init

Constructor implementation. Fulfills C<new>. Creates object
and then hands off with any arguments to C<initialize>:

    sub new_init {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        return $self->initialize(@_);
    }

See:
C<new>,
C<new_args>,
C<new_only>,
C<new_fast>,
C<class_methods>

=item classes::new_fast

=item new_fast

Fastest constructor implementation. Fulfills C<new>. Expects a
compatible hash ref as the first and only argument. Blesses that
ref into class.

    sub new_fast { return bless $_[1]||{}, $_[0] }

Useful when you have a hash that you absolutely trust and need the
speed. Particularly useful when 'inflating' thousands of record
objects from parsed lines and the like and have every intention of
directly manipulating the internal hash ref rather than burdening
it with accessors but still want to associate that record with a
class. In short, a good way to tack a class onto your structure
with the least amount of OO bloat.

B<NOTE:> The only way faster to associate a hash with a class is to
bypass any accessor altogether and call C<bless> on the hash. Using
C<bless> alone completely trusts that the class will never use the
constructor in any other way, which is a pretty big leap in most
OO code.

See:
C<new>,
C<new_only>,
C<new_init>,
C<class_methods>

=item initialize

The initializer. Commonly defined by classes instead of a
custom C<new> constructor so that objects from the class can
be reinitialized rather than thrown away and recreated. Usually
called by C<new> constructor to setup the initial object state
including aggregations from other classes. C<classes::new_init>
expects an C<initialize>.

The C<initialize> method always takes an initial self-reference
to the object being initialized as the first argument, the rest of
the arguments are dependent on the class itself, but usually a hash
and/or hash ref of attribute keys and values are accepted. Usually
C<new> and C<initialize> should accept the same argument signature
and C<initialize> must always return the same self reference passed
to it to preserve the identify of the object.

See C<attrs> and C<dump> for examples.

See:
C<init_args>,
C<new>,
C<new_init>,
C<new_only>,
C<methods>

=item classes::init_args

=item init_args

Initializer implementation. Takes a hash or C<HASH> ref as
arguments--usually passed from the C<new> constructor--and uses
the argument keys as attribute names setting each attribute value
by calling the corresponding accessor:

    # $object->set_attr1(1) implied
    $object->initialize(  attr=>1  );
    $object->initialize({ attr=>1 });

Combined with a C<new> constructor:

    my $object = MyClass->new(  attr1=>1  );
    my $object = MyClass->new({ attr1=>1 });

Here is the actual code for quick reference:

    sub init_args {
        my $self  = shift;
        my $attrs = $_[0];
        $attrs = {@_} if ref $attrs ne 'HASH';

        while ( my ( $attr, $value ) = each %$attrs ) {
            my $setter = $self->can("set_$attr")
                or X::UnknownAttr->throw([$attr]);
            $self->$setter($value);
        }

        return $self;
    }

B<NOTE:> Dispatching to attribute accessor methods not only supports
encapsulation but also is the only reliable method of generically
setting attributes during construction and initialization, despite
the extra subroutine call. This is because Perl 5 does not do I<any>
attribute inheritance, only method inheritance.

See:
C<attrs>,
C<class_attrs>

Throws C<X::UnknownAttr> if can't find a setter for the attr/key
passed.

=item classes::clone

=item clone

When called from an object returns a new object with the current
state of the original, a deep clone. No clone method is defined by
default, but it is recommended.

Use C<clone> instead of a bimodal C<new>:

    my $object = MyClass->new;    # good
    my $clone  = $object->clone;  # good
    my $clone  = $object->new;    # not so good

The C<classes::clone> method can be mixed into your classes:

    clone => 'classes::clone',

The C<classes::clone> method is modeled after the L<Clone_PP>
and L<Clone> modules to create the best clone reasonably possible
with Perl 5. It returns deeply cloned copies of the original
objects, but makes shallow copies of attributes that are globs,
regx objects and anything other than the basic C<HASH>, C<ARRAY>,
C<SCALAR>, and C<REF>, which themselves are cleanly and recursively
cloned. Attributes that are objects are cloned by their primitive
blessed ref type--not their own C<clone> methods--and are then
blessed into the same class.

C<classes::clone> can also serve as a standalone function for
cloning structures besides objects:

    my $array = [ 'some', {thing=>'a'}, \$little, qr/komplex/ ];
    my $cloned_array = classes::clone $array;

If you need to reference the actual C<classes::clone> code consider
C<perldoc -m classes>.

Throws: C<X::Usage>

See:
L<Clone_PP>,
L<Clone>,

=item classes::id

=item id

Returns the numeric, unique memory address of the object (or any
ref) that is passed. Shortcut to C<Scalar::Util::refaddr>:

    sub id { Scalar::Util::refaddr($_[0]) }

Useful when comparing clones in testing and what not:

    my $event = Event->new;
    my $clone = $event->clone;
    if ($event->classes::id == $clone->classes::id) {
        print 'come on, that is not a _real_ clone';
    }

Can be combined with the C<CORE::time> and/or the current process ID
to make a pretty unique object identifier for persistence and
the like:

    package MyClass;
    use classes
        new      => 'new',
        attrs_ro => ['id'],
    ;

    sub new {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        $self->initialize;
        $self->{$ATTR_id} = CORE::time . "-$$-" . $self->classes::id;
        return $self;
    }

See:
L<Scalar::Util/"refaddr">

=item classes::set

=item set

A mutator dispatch method. Companion to C<classes::get>. When called
from an object or class sets and returns a new value for a named
attribute by calling (dispatching) the object's setter/writer/mutator
method. The minimal speed loss for the dispatch pays for the
flexibility of allowing attributes to be set without knowing their
names before the code is executed.

    $crayon->classes::set( 'color' => 'purple' );

Can be mixed into your class to give them public dispatchers:

    methods => { set => 'classes::set' },

Here is the actual code for quick reference:

    sub set {
        my ( $self, $name, $value ) = @_;
        my $accessor = $self->can("set_$name")
            || X::MethodNotFound->throw("set_$name");
        return $self->$accessor($value);
    }

Throws: C<X::MethodNotFound> if the attribute was defined
read-only or not defined at all.

=item classes::get

=item get

The accessor dispatch method. Companion to C<classes::set>. Returns
the current value of the named attribute but does not set a new
value.

Here is the actual code for quick reference:

    sub get {
        my ( $self, $name ) = @_;
        my $accessor = $self->can("get_$name")
            || X::MethodNotFound->throw("get_$name");
        return $self->$accessor;
    }

Throws: C<X::MethodNotFound> if the attribute was not
defined.

=item classes::sprintf

=item sprintf

Mixable object or class method that takes a standard C<sprintf>
C<FORMAT> and a list of C<ATTRNAMES> and simply looks up the
attribute values by their C<get_foo> equivalents and returns a
formatted string with the values.

=item classes::printf

=item printf

Same as C<sprintf> but prints the string instead of just returning
it.

=item classes::dump

=item dump

Using L<Data::Dumper> dumps a visual representation of a class,
object, or any scalar to a handle (C<STDERR> by default) or string
buffer.

B<NOTE:> Be sure to use parens or indirect notation when dumping
objects since context is important--especially when dumping the
self-referencing return value or most methods:

    $ini->read->classes::dump;   # right
    classes::dump $ini->read;    # not what you would expect

Can also be mixed into your classes to give them their own C<dump>
methods:

    dump => 'classes::dump',

Dumps the implied caller if no argument passed:

   package MyClass;
   classes::dump;

Dumping a class displays three things: the current declaration
C<DECL>, the current state of any C<class_attrs> and the list of
any methods that have been mixed in. Dumping an object also
displays its internal hash ref:

    package MixMeSimple;
    sub mixed_in {'yes'};

    package MixMeDeclared;
    use classes
        type           => 'mixable',
        attrs          => [qw( a_mixmedecl )],
        attrs_pr       => [ 'private_attr' ],
        class_attrs    => [qw( ca_mixmedecl )],
        class_attrs_pr => { PrivateAttr=>'yep' },
        methods        => [qw( m_mixmedecl )],
        class_methods  => [qw( cm_mixmedecl )],
    ;

    package main;
    use classes
        name  => 'MySuper',
        attrs => ['color'],
        new   => 'classes::new_args',
    ;

    use classes
        name            => 'MyClass',
        extends         => 'MySuper',
        new             => 'classes::new_init',
        init            => 'classes::init_args',
        throws          => 'X::Usage',
        exceptions      => 'X::MyOwn',
        mixes           => [qw( MixMeSimple MixMeDeclared )],
        class_attrs     => { Attr=>1 },
        class_attrs_ro  => { Read_Only_Attr=>'yes' },
        attrs           => [ 'attr' ],
        attrs_ro        => [ 'read_only_attr' ],
        class_methods   => { Empty_Method=>0 },
        methods         => { abstract_method=>'ABSTRACT' },
    ;

    my $object = MyClass->new(attr=>'ok');
    $object->set_color('green');
    $object->classes::dump;

Produces:

    ###########################  MyClass  ############################

    $DECL1 = {
      'attrs' => [
        'a_mixmedecl',
        'attr'
      ],
      'exceptions' => [
        'X::MyOwn'
      ],
      'class_attrs' => {
        'ca_mixmedecl' => undef,
        'Attr' => 1
      },
      'name' => 'MyClass',
      'class_attrs_ro' => {
        'Read_Only_Attr' => 'yes'
      },
      'class_methods' => {
        'Empty_Method' => 'EMPTY',
        'new' => 'classes::new_init',
        'cm_mixmedecl' => 'MixMeDeclared::cm_mixmedecl'
      },
      'inherits' => [
        'MySuper'
      ],
      'attrs_ro' => [
        'read_only_attr'
      ],
      'methods' => {
        'mixed_in' => 'MixMeSimple::mixed_in',
        'abstract_method' => 'ABSTRACT',
        'initialize' => 'classes::init_args',
        'm_mixmedecl' => 'MixMeDeclared::m_mixmedecl'
      },
      'attrs_pr' => [
        'private_attr'
      ],
      'type' => 'static',
      'class_attrs_pr' => {
        'PrivateAttr' => 'yep'
      },
      'throws' => [
        'X::Usage'
      ]
    };

    $MIXIN1 = {
      '$ATTR_a_mixmedecl' => 'MixMeDeclared',
      '$CLASS_ATTR_PrivateAttr' => 'MixMeDeclared',
      '$ATTR_private_attr' => 'MixMeDeclared',
      'initialize' => 'classes',
      'get_ca_mixmedecl' => 'MixMeDeclared',
      'cm_mixmedecl' => 'MixMeDeclared',
      'set_a_mixmedecl' => 'MixMeDeclared',
      'mixed_in' => 'MixMeSimple',
      'get_a_mixmedecl' => 'MixMeDeclared',
      'set_ca_mixmedecl' => 'MixMeDeclared',
      'new' => 'classes',
      '$CLASS_ATTR_ca_mixmedecl' => 'MixMeDeclared',
      'm_mixmedecl' => 'MixMeDeclared'
    };

    $CLASS_STATE1 = {
      'Read_Only_Attr' => 'yes',
      'ca_mixmedecl' => undef,
      'Attr' => 1
    };

    $OBJECT_STATE1 = bless( {
      'MySuper::color' => 'green',
      'MyClass::attr' => 'ok'
    }, 'MyClass' );


Throws: C<X::Usage>

=item classes::load

=item load

Loads a module with C<use MyModule> using C<use base> compatibility,
but without the C<@ISA> updates> and C<fields> stuff. Used internally
by the C<classes> pragma itself to load packages and modules.

Throw a C<X::Empty> exception (somewhat like I<Base class
package Foo is empty> error C<use base> throws) when no symbols
whatsoever are found for the loaded module.

=item CLASS

=item $CLASS

Returns a constant (inlined subroutine) containing the class
name. Exactly the same as C<__PACKAGE__> and literally stolen from
L<CLASS> module (Michael G. Schwern). Defined into anything that
uses C<classes>.

=item DECL

=item $DECL

Returns a hash reference of the class declaration kept current as the
class is altered at run time with C<classes> or C<classes::define>.

B<WARNING>: Do not directly alter the C<DECL> hash. Take a copy if
needed instead:

    my %own_decl = %$MyClass::DECL;
    my %own_decl = %$DECL;

See: example output of C<DECL> from C<classes::dump> method

=item SUPER

Returns the name of the super (parent) class in which it is defined
(C<$E<lt>blessed_asE<gt>::ISA[0]>). This fills the gap left by the
C<SUPER::> construct that only refers to the super class of the
current I<package>. Without a C<SUPER> that refers to the actual
superclass C<mixes> that deal with inheritance would be
much more difficult to code:

    package Parent;
    sub foo {'foo'};

    package MixMod;
    sub bar1 { shift->SUPER->foo };
    sub bar2 { shift->SUPER::foo };  # BAD

    package MyClass;
    use classes extends=>'Parent', mixes=>'MixMod';
    print MyClass->SUPER->foo . "\n";  # foo
    print MyClass->SUPER::foo . "\n";  # foo
    print MyClass->bar1 . "\n";        # foo
    print MyClass->bar2 . "\n";        # ERROR

See: L<perlobj/SUPER>

=item MIXIN

=item $MIXIN

Defined when the C<mixes> tag is used. Contains a dynamically
updated hash of mixed in method and attribute names and the package
and name from which they came. This is the only way to identify if
a method or attribute was mixed in rather than simply declared:

    package MyMixin;
    sub bar {'bar'};

    package MyClass;
    use classes
        mixes=>'MyMixin',
        methods=>['foo'],
    ;

    package main;
    print "bar is mixin\n" if MyClass->MIXIN->{bar};
    print "foo is mixin\n" if MyClass->MIXIN->{foo};

The C<MIXIN> hash is displayed in the C<classes::dump> output.

B<WARNING>: Testing for C<defined $MIXIN> is not sufficient since
the ref will usually be defined even if the C<HASH> it refers to
contains nothing. Use C<defined %$MIXIN> instead.

See:
C<mixes>,
C<classes::dump>

=item classes::PERL_VERSION

=item PERL_VERSION

Constant referring to the current perl version (C<$]>).

See: L<perlvar/"$]">

=back

=head1 EXCEPTIONS

The C<classes> pragma defines and uses the following exception
classes that any code with C<use classes> can immediately use:

=over

=item X::classes

Minimal base exception class. Base class of all other exception
classes. See L<X::classes>.

=item X::classes::traceable 

Subclass of C<X::classes>. Adds light traceability to similar to
C<Exception::Class>. Base class of all other exception classes. See
L<X::classes::traceable>.

=item X::AttrScope

Thrown when somehow unexpectedly an attribute accessor is called
where the attribute was initially declared with greater scope and
then redeclared with a more limited scope, C<ro> or C<pr>:

    package WideOpen;
    use strict 'subs'; no warnings;
    use classes
        type  => 'mixable',
        new   => 'classes::new_args',
        attrs => ['foo'],
    ;

    package MorePrivate;
    use strict 'subs'; no warnings;
    use classes
        mixes    => 'WideOpen',
        attrs_ro => ['foo'],
    ;

    sub do_something_involving_foo {
        my $self = shift;
        $self->{$ATTR_foo} = 'something new';
        return $self;
    }


    package main;
    my $o = MorePrivate->new; 
    $o->do_something_involving_foo;
    print $o->get_foo;          # ok
    $o->set_foo('something');   # throws X::AttrScope

Even though the redeclaration causes the correct update to
C<DECL> the inherited accessor method is overriden as a safety
precaution. This is not a problem if the attribute with the same
name was never declared with greater scope in the first place
since the public accessor (the setter in this case) won't exist,
causing a different Perl compile-time error. See C<attrs> for more.

=item X::Empty

Something was empty that shouldn't be, a package being loaded,
a variable, etc.

=item X::InvalidName

Class or attribute name is invalid.

=item X::NotPkgMethod

Attempt to import a package method detected where the method is
not defined or defined as a class or object method instead.

=item X::MethodNotFound

Accessor method not found when C<set> or C<get> dispatch methods
are called.

=item X::Unimplemented

A call to an unimplemented C<ABSTRACT> method is detected.

=item X::Usage

Any invalid syntax usage.

=item X::Undefined

Attribute value undefined.

=item X::UnknownAttr

Attribute not known to the class in question.

=back

See: 
L<X::classes>,
L<X::classes::traceable>,
L<classes::Throwable>

=head1 TROUBLESHOOTING

See L<classesfaq>

=head1 EXAMPLES

See
C<classes::dump>,
L<classescb>,
L<classestut>

=head1 SUPPORT

=over 4

=item * SourceForge 'perl5class' Project Site

L<http://sourceforge.net/projects/perl5class>

Please submit any bugs or feature requests to this site.

=item * perl5class-usage mailing list

L<http://lists.sourceforge.net/lists/listinfo/perl5class-usage>

=item * Search CPAN

L<http://search.cpan.org/dist/classes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/classes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/classes>

=back

=head1 DEPENDENCIES

Dependencies have been all but left out to improve portability.

Perl 5.6.1 is required.

L<Scalar::Utils> and I<CORE::time> are required and supported since
5.6 and standard from 5.8.

L<Data::Dumper> is required for C<classes::dump> to work and has
been part of Perl standard since pre 5.6.1.

=head1 SEE ALSO

L<classestut>,
L<classescb>,
L<classesfaq>,
L<X::classes>,
L<X::classes::traceable>,
L<classes::Throwable>,
L<classes::test>

The object oriented Perl related pages:

=over 4

L<perlobj>,
L<perlboot>,
L<perltoot>,
L<perltooc>,
L<perlbot>,
L<perlstyle>

=back

The object oriented modules that most influenced the creation of
the C<classes> pragma:

=over 4

L<base>,
L<fields>,
L<CLASS>,
L<Class::Struct>,
L<Exception::Class>,
L<Clone>,
L<Clone::PP>,
L<Class::MethodMaker>,
L<Class::MakeMethods>,
L<Class::Base>,
L<Class::Contract>,
L<Class::Accessor>,
L<Class::Meta>,
L<Class::Std>,
L<Class::Data::Inheritable>,
L<Class::Maker>

=back

All the rest of the C<Class::> (and related) namespace on CPAN
including, but by no means limited to, the following:

=over 4

L<Attribute::Deprecated>,
L<Attribute::Unimplemented>,
L<Class::Container>,
L<Class::Field>,
L<Class::Generate>,
L<Class::HPL00::Class>,
L<Class::Inspector>,
L<Class::MOP>,
L<Clone::Clonable>,
L<Class::Class>

=back

=head1 AUTHOR

Robert S Muhlestein (rmuhle at cpan dot org)

=head1 ACKNOWLEDGEMENTS

The C<classes> pragma was built from many other great modules and
ideas with a lot of feedback and testing. Here are a few specific
individuals who directly or indirectly contributed to its creation:

Matthew Simon Cavalletto,
Damian Conway,
Derek Cordon,
Ray Finch,
A. (Pete) Fontenot,
C. Garrett Goebel,
Erik Johnson,
Jim Miner,
ken1,
Dave Rolsky,
Matt Sargent,
David Muir Sharnoff,
Dean Roehrich,
Michael G Schwern,
Casey West,
David Wheeler

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2006 Robert S. Muhlestein (rob at muhlestein.net) All
rights reserved. This module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself. [See
L<perlartistic>.]

=head1 BUGS AND CHANGES

The Perl 'strict' pragma was not seeing some cases of $$foo, specifically
when used as an argument to defined. When they fixed that bug in the
'strict' pragma they caused some of the classes pragma unit tests to fail,
but only because of strict's normal overzealousness rejection of good perl
in an advanced context, which is required to create other simplifications
in Perl OO programming using classes.

If you use accessor methods use strict should not give you problems, and
when it does remember you can turn it off for sections of code or the whole
thing with 'no strict', if you are careful and use it properly no one will
burn you at the stake, at least not on my team.
