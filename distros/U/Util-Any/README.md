# NAME

Util::Any - to export any utilities and to create your own utility module

# SYNOPSIS

    use Util::Any -list;
    # you can import any functions of List::Util and List::MoreUtils
    
    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to choose functions

    use Util::Any -list => ['uniq'];
    # you can import uniq function only, not import other functions
    
    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import All kind of utility functions

    use Util::Any -all;
    
    my $o = bless {};
    my %hash = (a => 1, b => 2);
    
    # from Scalar::Util
    blessed $o;
    
    # from Hash::Util
    lock_keys %hash;

If you want to import functions with prefix(ex. list\_, scalar\_, hash\_)

     use Util::Any -all, {prefix => 1};
     use Util::Any -list, {prefix => 1};
     use Util::Any -list => ['uniq', 'min'], {prefix => 1};
     
     print list_uniq qw/1, 0, 1, 2, 3, 3/;
    

If you want to import functions with your own prefix.

    use Util::Any -list => {-prefix => "l_"};
    print l_uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import functions as different name.

    use Util::Any -list => {uniq => {-as => 'listuniq'}};
    print listuniq qw/1, 0, 1, 2, 3, 3/;

When you use both renaming and your own prefix ?

    use Util::Any -list => {uniq => {-as => 'listuniq'}, -prefix => "l_"};
    print listuniq qw/1, 0, 1, 2, 3, 3/;
    print l_min qw/1, 0, 1, 2, 3, 3/;
    # the following is NG
    print l_uniq qw/1, 0, 1, 2, 3, 3/;

# DESCRIPTION

For the people like the man who cannot remember `uniq` function is in whether List::Util or List::MoreUtils.
And for the newbie who don't know where useful utilities is.

Perl has many modules and they have many utility functions.
For example, List::Util, List::MoreUtils, Scalar::Util, Hash::Util,
String::Util, String::CamelCase, Data::Dumper etc.

We, Perl users, have to memorize modules name and their functions name.
Using this module, you don't need to memorize modules name,
only memorize kinds of modules and functions name.

And this module allows you to create your own utility module, easily.
You can create your own module and use this in the same way as Util::Any like the following.

    use YourUtil -list;

see `CREATE YOUR OWN Util::Any`, in detail.

# HOW TO USE

## use Util::Any (KIND)

    use Util::Any -list, -hash;

Give list of kinds of modules. All functions in modules are exported.

## use Util::Any KIND => \[FUNCTIONS\], ...;

NOTE THAT kind '-all', 'all' or ':all' cannot take this option.

    use Util::Any -list => ['uniq'], -hash => ['lock_keys'];

Give hash whose key is kind and value is function names as array ref.
Selected functions are exported.

you can write it as hash ref.

    use Util::Any {-list => ['uniq'], -hash => ['lock_keys']};

## use Util::Any ..., {OPTION => VALUE};

Util::Any can take last argument as option, which should be hash ref.

- prefix => 1

    add kind prefix to function name.

        use Util::Any -list, {prefix => 1};
        
        list_uniq(1,2,3,4,5); # it is List::More::Utils's uniq function

- module\_prefix => 1

    see ["PREFIX FOR EACH MODULE"](#prefix-for-each-module).
    Uti::Any itself doesn't have such a definition.

- smart\_rename => 1

    see ["SMART RENAME FOR EACH KIND"](#smart-rename-for-each-kind).

- plugin => 'lazy' / 'eager' / 0 (default is 'lazy')

    If utility module based on Util::Any has plugin,
    Its plugins are loaded when related kind is specified(if kind name matches module name).
    If you want to load all plugin on using module, give 'eager' to this option.
    If you don't want to use plugin, set 0.

        use Util::Yours -kind, .... {plugin => 'eager'}; # all plugins are loaded
        use Util::Yours -kind, .... {plugin => 0};       # disable plugin feature.
        use Util::Yours -kind;                           # is equal {plugin => 'lazy'}

    Relation of kind name and plugin name is the following.

    for example, If you have the following modules.

        Util::Yours::Plugin::Date
        Util::Yours::Plugin::DateTime
        Util::Yours::Plugin::Net
        Util::Yours::Plugin::Net::Amazon
        Util::Yours::Plugin::Net::Twitter

    the following code:

        use Util::Yours -date; # Plugin::Date is loaded
        use Util::Yours -datetime; # Plugin::DateTime is loaded
        use Util::Yours -net; # Plugin::Net is loaded
        use Util::Yours -net_amazon; # Plugin::Net::Amazon is loaded
        use Util::Yours -net_all; # Plugin::Net and Plugin::Net::* is loaded

    `_all` is special keyword. see ["NOTE ABOUT all KEYWORD"](#note-about-all-keyword).

- debug => 1/2

    Util::Any doesn't say anything when loading module fails.
    If you pass debug value, warn or die.

        use Util::Any -list, {debug => 1}; # warn
        use Util::Any -list, {debug => 2}; # die

# EXPORT

Kinds of functions and list of exported functions are below.
Note that these modules and version are on my environment(Perl 5.8.4).
So, it must be different on your environment.

## -data

NOTE THAT: its old name is 'scalar' (you can use the name, yet).

from Scalar::Util (1.19)

    blessed
    dualvar
    isvstring
    isweak
    looks_like_number
    openhandle
    readonly
    refaddr
    reftype
    set_prototype
    tainted
    weaken

## -hash

from Hash::Util (0.05)

    hash_seed
    lock_hash
    lock_keys
    lock_value
    unlock_hash
    unlock_keys
    unlock_value

## -list

from List::Util (1.19)

    first
    max
    maxstr
    min
    minstr
    reduce
    shuffle
    sum

from List::MoreUtils (0.21)

    after
    after_incl
    all
    any
    apply
    before
    before_incl
    each_array
    each_arrayref
    false
    first_index
    first_value
    firstidx
    firstval
    indexes
    insert_after
    insert_after_string
    last_index
    last_value
    lastidx
    lastval
    mesh
    minmax
    natatime
    none
    notall
    pairwise
    part
    true
    uniq
    zip

from List::Pairwise (0.29)

    mapp
    grepp
    firstp
    lastp
    map_pairwise
    grep_pairwise
    first_pairwise
    last_pairwise
    pair

## -string

from String::Util (0.11)

    crunch
    define
    equndef
    fullchomp
    hascontent
    htmlesc
    neundef
    nospace
    randcrypt
    randword
    trim
    unquote

from String::CamelCase (0.01)

    camelize
    decamelize
    wordsplit

## -debug

from Data::Dumper (2.121)

    Dumper

# EXPORTING LIKE Sub::Exporter

Like Sub::Exporter, Util::Any can export function name as you like.

    use Util::Yours -list => {-prefix => 'list__', miin => {-as => "lmin"}};

functions in -list, are exported with prefix "list\_\_" except 'min' and 'min' is exported as `lmin`.

# PRIORITY OF THE WAYS TO CHANGE FUNCTION NAME

There are some ways to change function name.
Their priority is the following.

- 1 rename

        -list => {uniq => {-as => 'luniq'}}

- 2 kind\_prefix

        -list => {-prefix => list}

- 3 module\_prefix

    Only if module's prefix is defined

        ..., {module_prefix => 1}

- 4 prefix

        ..., {prefix => 1}

- 5 smart\_rename

        ..., {smart_rename => 1}

I don't recommend to use 3, 4, 5 in same time, because it may confuse you.

- 3 + 4

    if module's prefix is defined in class(not defined in Util::Any), use 3, or use 4.

- 3 + 5

    3 or 5. reason is as same as the above.

- 3 + 4 + 5

    5 is ignored.

- 4 + 5

    5 is ignored.

# NOTE ABOUT all KEYWORD

**all** is special keyword, so it has some restriction.

## use module with 'all' cannot take its arguments

    use Util::Any -all; # or 'all', ':all'

This cannot take sequential arguments for "all". For example;

    NG: use Util::Any -all => ['shuffle'];

When sequential arguments is kind's, it's ok.

    use Util::Any -all, -list => ['unique'];

## -plugin\_module\_all cannot take its arguments

    use Util::Yours -plugin_name_all;

This cannot take sequential arguments for it. For example:

    NG: use Util::Yours -plugin_name_all => ['some_function'];

# CREATE YOUR OWN Util::Any

Just inherit Util::Any and define $Utils hash ref as the following.

    package Util::Yours;
    
    use Clone qw/clone/;
    use Util::Any -Base; # as same as use base qw/Util::Any/;
    # If you don't want to inherit Util::Any setting, no need to clone.
    our $Utils = clone $Util::Any::Utils;
    push @{$Utils->{-list}}, qw/Your::Favorite::List::Utils/;
    
    1;

In your code;

    use Util::Yours -list;

## $Utils STRUCTURE

### overview

    $Utils => {
       # simply put module names
       -kind1 => [qw/Module1 Module2 ..../],
       -# Module name and its prefix
       -kind2 => [ [Module1 => 'module_prefix'], ... ],
       # limit functions to be exported
       -kind3 => [ [Module1, 'module_prefix', [qw/func1 func2/] ], ... ],
       # as same as above except not specify modul prefix
       -kind4 => [ [Module1, '', [qw/func1 func2/] ], ... ],
    };

### Key must be lower character.

    NG $Utils = { LIST => [qw/List::Util/]};
    OK $Utils = { list => [qw/List::Util/]};
    OK $Utils = { -list => [qw/List::Util/]};
    OK $Utils = { ':list' => [qw/List::Util/]};

### `all` cannot be used for key.

    NG $Utils = { all    => [qw/List::Util/]};
    NG $Utils = { -all   => [qw/List::Util/]};
    NG $Utils = { ':all' => [qw/List::Util/]};

### Value is array ref which contained scalar or array ref.

Scalar is module name. Array ref is module name and its prefix.

    $Utils = { list => ['List::Utils'] };
    $Utils = { list => [['List::Utils', 'prefix_']] };

see ["PREFIX FOR EACH MODULE"](#prefix-for-each-module)

## PREFIX FOR EACH MODULE

If you want to import many modules and they have same function name.
You can specify prefix for each module like the following.

    use base qw/Util::Any/;
    
    our $Utils = {
         list => [['List::Util' => 'lu_'], ['List::MoreUtils' => 'lmu_']]
    };

In your code;

    use Util::Yours qw/list/, {module_prefix => 1};

## SMART RENAME FOR EACH KIND

smart\_rename option rename function name by a little smart way.
For example,

    our $Utils = {
      utf8 => [['utf8', '',
                {
                 is_utf8   => 'is_utf8',
                 upgrade   => 'utf8_upgrade',
                 downgrade => 'downgrade',
                }
               ]],
    };

In this definition, use `prefix =` 1> is not good idea. If you use it:

    is_utf8      => utf8_is_utf8
    utf8_upgrade => utf8_utf8_upgrade
    downgrade    => utf8_downgrade

That's too bad. If you use `smart_rename =` 1> instead:

    is_utf8      => is_utf8
    utf8_upgrade => utf8_upgrade
    downgrade    => utf8_downgrade

rename rule is represented in \_create\_smart\_rename in Util::Any.

## CHANGE smart\_rename BEHAVIOUR

To define \_create\_smart\_rename, you can change smart\_rename behaviour.
\_create\_smart\_rename get 2 argument, package name and kind of utility,
and should return code reference which get function name and return new name.
As an example, see Util::Any's \_create\_smart\_rename.

## OTHER WAY TO EXPORT FUNCTIONS

### SELECT FUNCTIONS

Util::Any automatically export functions from modules' @EXPORT and @EXPORT\_OK.
In some cases, it is not good idea like Data::Dumper's Dumper and `DumperX`.
These 2 functions are same feature.

So you can limit functions to be exported.

    our $Utils = {
         -debug => [
                   ['Data::Dumper', '',
                   ['Dumper']], # only Dumper method is exported.
                  ],
    };

or

    our $Utils = {
         -debug => [
                   ['Data::Dumper', '',
                    { -select => ['Dumper'] }, # only Dumper method is exported.
                   ]
                  ],
    };

### SELECT FUNCTIONS EXCEPT

Inverse of -select option. Cannot use this option with -select.

    our $Utils = {
         -debug => [
                   ['Data::Dumper', '',
                    { -except => ['DumperX'] }, # export functions except DumperX
                   ]
                  ],
    };

### RENAME FUNCTIONS

To rename function name, write original function name as hash key and renamed name as hash value.
this definition is prior to -select/-except.

In the following example, 'min' is not in -select list, but can be exported.

    our $Utils = {
         -list  => [[
                     'List::Util', '',
                     {
                      'first' => 'list_first', # first as list_first
                      'sum'   => 'lsum',       # sum   as lsum
                      'min'   => 'lmin',       # min   as lmin
                      -select => ['first', 'sum', 'shuffle'],
                     }
                  ]]
     };

### USE Sub::Exporter's GENERATOR WAY

It's somewhat complicate, I just show you code.

Your utility class:

    package SubExporterGenerator;
    
    use strict;
    use Util::Any -Base;
    
    our $Utils =
      {
       -test => [[
                 'List::Util', '',
                 { min => \&build_min_reformatter,}
                ]]
      };
    
    sub build_min_reformatter {
      my ($pkg, $class, $name, @option) = @_;
      no strict 'refs';
      my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
      sub {
        my @args = @_;
        $code->(@args, $option[0]->{under} || ());
      }
    }

Your script using your utility class:

    package main;
    
    use strict;
    use lib qw(lib t/lib);
    use SubExporterGenerator -test => [
          min => {-as => "min_under_20", under => 20},
          min => {-as => "min_under_5" , under => 5},
        ];
    
    print min_under_20(100,25,30); # 20
    print min_under_20(100,10,30); # 10
    print min_under_20(100,25,30); # 5
    print min_under_20(100,1,30);  # 1

If you don't specify `-as`, exported function as `min`.
But, of course, the following doesn't work.

    use SubExporterGenerator -test => [
          min => {under => 20},
          min => {under => 5},
        ];

Util::Any try to export duplicate function `min`, one of both should fail.

#### GIVE DEFAULT ARGUMENTS TO CODE GENERATOR

You may want to give default arguments to all code generators in same kind.
For example, if you create shortcut to use Number::Format,
you may want to give common arguments with creating instance.

    -number => [
       [ 'Number::Format' => {
           'round' => sub {
               my($pkg, $class, $func, $args, $default_args) = @_;
               my $n = 'Number::Format'->new(%$default_args);
               sub { $n->round(@_); }
           },
           'number_format' => sub {
               my($pkg, $class, $func, $args, $default_args) = @_;
               my $n = 'Number::Format'->new(%$default_args, %$args);
               sub { $n->format_number(@_); }
           }
         }
       ];

And write as the following:

    use Util::Yours -number => [-args => {thousands_sep => "_", int_curr_symbol => '\'} ];
    
    print number_format(100000); # 100_000
    print number_price(100000);  # \100_000

thousands\_sep and int\_curr\_symbol are given to all of -number kind of function.

## DO SOMETHING WITHOUT EXPORTING ANYTHING

    -strict => [
       [ 'strict' => {
           '.' => sub {
              strict->import();
              warnings->import();
           },
         }
       ];

This definition works like as pragma.

    use Util::Yours -strict;

function name '.' is special. This name is not exported and only execute the code in the definition.

## ADD DEFAULT ARGUMENT FOR EXPORTING

Define the following method.

    package You::Utils -Base;
    # ....
    sub _default_kinds { '-list', '-string' }

This means '-list' and '-string' arguments are given as default exporting arguments.
So, these are same.

    use Your::Utils;

is equal to

    use Your::Utils -list, -string;

If you want to disable default kinds.

    use Your::Utils -list => [], -string;

## ADD PLUGGABLE FEATURE FOR YOUR MODULE

Just add a flag -Pluggbale.

    package Util::Yours;
    use Util::Any -Base, -Pluggable;

And write plugin as the following:

    package Util::Yours::Plugin::Net;
    
    sub utils {
      # This structure is as same as $Utils.
      return {
          # kind name and plugin name should be same.
          -net => [
                    [
                     'Net::Amazon', '',
                     {
                      amazon => sub {
                        my ($pkg, $class, $func, $args) = @_;
                        my $amazon = Net::Amazon->new(token => $args->{token});
                        sub { $amazon }
                      },
                     }
                    ]
                  ]
         };
    }
    
    1;

And you can use it as the following.

    use Util::Yours -net => [amazon => {token => "your_token"}];
    
    my $amazon = amazon; # get Net::Amazon object;

Util::Any can merge definition in plugins. If same kind is in several plugins, it works.
But same kind and same function name is defined, one of them doesn't work.

## WORKING WITH EXPORTER-LIKE MODULES

NOTE THAT: I don't recommend this usage, because using this may confuse user;
some of import options are for Util::Any and others are for exporter-like module
(especially, using with Sub::Exporter is confusing).

CPAN has some modules to export functions.
Util::Any can work with some of such modules, [Exporter](https://metacpan.org/pod/Exporter), [Exporter::Simple](https://metacpan.org/pod/Exporter::Simple) and [Sub::Exporter](https://metacpan.org/pod/Sub::Exporter).
(note that: [Perl6::Export::Attrs](https://metacpan.org/pod/Perl6::Export::Attrs) is not supported after version 0.25 and the above)
If you want to use other modules, please inform me or implement import method by yourself.

If you want to use module mentioned above, you have to change the way to inherit these modules.

### DIFFERENCE between 'all' and '-all' or ':all'

If your utility module which inherited Util::Any has utility functions and export them by Exporter-like module,
behaviour of 'all' and '-all' or ':all' is a bit different.

    'all' ... export all utilities defined in your package's $Utils variables.
    '-all' or ':all' ... export all utilities including functions in your util module itself.

### ALTERNATIVE INHERITING

Normally, you use;

    package YourUtils;
    
    use Util::Any -Base; # or "use base qw/Util::Any/;"

But, if you want to use [Exporter](https://metacpan.org/pod/Exporter), [Exporter::Simple](https://metacpan.org/pod/Exporter::Simple) or [Perl6::Export::Attrs](https://metacpan.org/pod/Perl6::Export::Attrs).
write as the following, instead.

    # if you want to use Exporter
    use Util::Any -Exporter;
    # if you want to use Exporter::Simple
    use Util::Any -ExporterSimple;
    # if you want to use Sub::Exporter
    use Util::Any -SubExporter;

That's all.
Note that **don't use base the above modules in your utility module**.

There is one notice to use Sub::Exporter.

    Sub::Exporter::setup_exporter
          ({
              as => 'do_import', # name is important
              exports => [...],
              groups  => { ... },
          });

You must pass "as" option to setup\_exporter and its value must be "do\_import".
If you want to change this name, do the following.

    Sub::Exporter::setup_exporter
          ({
              as => $YourUtils::SubExporterImport = '__do_import',
              exports => [...],
              groups  => { ... },
          });

# AUTHOR

Ktat, `<ktat at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-util-any at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Any](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Any).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Util::Any

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Util-Any](http://annocpan.org/dist/Util-Any)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Util-Any](http://cpanratings.perl.org/d/Util-Any)

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Util-Any](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Util-Any)

- Search CPAN

    [http://search.cpan.org/dist/Util-Any](http://search.cpan.org/dist/Util-Any)

# REPOSITORY

    svn co http://svn.coderepos.org/share/lang/perl/Util-Any/trunk Util-Any

Subversion repository of Util::Any is hosted at http://coderepos.org/share/.
patches and collaborators are welcome.

# SEE ALSO

The following modules can work with Util::Any.

[Exporter](https://metacpan.org/pod/Exporter), [Exporter::Simple](https://metacpan.org/pod/Exporter::Simple), [Sub::Exporter](https://metacpan.org/pod/Sub::Exporter) and [Perl6::Export::Attrs](https://metacpan.org/pod/Perl6::Export::Attrs).

The following is new module Util::All, based on Util::Any.

    http://github.com/ktat/Util-All

# ACKNOWLEDGEMENTS

# COPYRIGHT & LICENSE

Copyright 2008-2010 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
