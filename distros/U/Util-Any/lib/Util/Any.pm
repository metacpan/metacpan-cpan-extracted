package Util::Any;

use ExportTo ();
use Clone ();
use Carp ();
use warnings;
use strict;

our $Utils = {
              list   => [ qw/List::Util List::MoreUtils List::Pairwise/ ],
              data   => [ qw/Scalar::Util/ ],
              hash   => [ qw/Hash::Util/ ],
              debug  => [ ['Data::Dumper', '', ['Dumper']] ],
              string => [ qw/String::Util String::CamelCase/ ],
             };

$Utils->{'scalar'} = $Utils->{data};
# I'll delete no dash group in the above, in future.
$Utils->{'-' . $_} = $Utils->{$_} foreach keys %$Utils;

our $SubExporterImport = 'do_import';

sub _default_kinds { }

# borrow from List::MoreUtils
sub _any (&@) {
    my $f = shift;
    return if ! @_;
    for (@_) {
        return 1 if $f->();
    }
    return 0;
}

sub _uniq (@) {
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}
# /end

sub import {
  my ($pkg, $caller) = (shift, (caller)[0]);
  return $pkg->_base_import($caller, @_) if @_ and $_[0] =~/^-[A-Z]\w+$/o;

  my %opt;
  if (@_ > 1 and ref $_[-1] eq 'HASH') {
    @opt{qw/prefix module_prefix debug smart_rename plugin/}
      = (delete @{$_[-1]}{qw/prefix module_prefix debug smart_rename plugin/});
    pop @_ unless %{$_[-1]};
  }
  $opt{$_} ||= 0 foreach qw/prefix module_prefix debug smart_rename/;
  if (not defined $opt{plugin}) {
    $opt{plugin} = 'lazy';
  } elsif ($opt{plugin} and $opt{plugin} ne 'eager') {
    Carp::croak "wrong option is passed for plugin: " . $opt{plugin};
  }

  @_ = %{$_[0]} if @_ == 1 and ref $_[0] eq 'HASH';

  my $config = Clone::clone(do { no strict 'refs'; ${$pkg . '::Utils'} });
  if ($pkg->can('_plugins')) {
    if ($opt{plugin} eq 'eager') {
      foreach my $plugin ($pkg->plugins) {
        eval "require $plugin";
        my $util = $plugin->utils;
        foreach my $kind (keys %$util) {
          push @{$config->{$kind} ||= []}, @{$util->{$kind}};
        }
      }
    }
  }
  my ($arg, $want_kind) = $pkg->_arrange_args
    ([
      @_ ? ($_[0] =~m{^[-:]?all$}i ?  ($_[0], $pkg->_default_kinds, @_[1 .. $#_]) : ($pkg->_default_kinds, @_))
         : ($pkg->_default_kinds)
     ],
     $config, $caller, \%opt);
  foreach my $kind (keys %$want_kind) {
    # Carp::croak "$pkg doesn't have such kind of functions : $kind"
    # unless exists $config->{$kind};
    $pkg->_kind_exporter($caller, $config->{$kind}, (lc(join "", $kind =~m{(\w+)}go)), $want_kind->{$kind}, \%opt);
  }
}

sub _kind_exporter {
  my ($pkg, $caller, $kind_config, $kind_word, $import_setting, $opt) = @_;
  my ($wanted_funcs, $local_definition, $kind_prefix, $kind_args) = $pkg->_func_definitions($import_setting);
  my ($prefix, %exported, %class_func);

  foreach my $class_config (@$kind_config) { # $class_config is class name or array ref
    my ($class, $module_prefix, $config_options) = ref $class_config ? @$class_config : ($class_config, '', '');

    my $evalerror = '';
    if ($evalerror = do { local $@; eval {my $path = $class; $path =~s{::}{/}go; require $path. ".pm"; $evalerror = $@ }; $@}) {
      # if ($evalerror = do { local $@; eval "require $class"; $evalerror = $@ }) {
      $opt->{debug} == 2 ? Carp::croak $evalerror : Carp::carp $evalerror;
    }

    $prefix = $kind_prefix                       ? $kind_prefix                           :
      ($opt->{module_prefix} and $module_prefix) ? $module_prefix                         :
      $opt->{prefix}                             ? lc($kind_word) . '_'                   :
      $opt->{smart_rename}                       ? $pkg->_create_smart_rename($kind_word) : '';

    my (@funcs, %rename);
    if (ref $config_options eq 'HASH') {
      # -kind => {'first' => 'list_first', # first as list_first
      #           'min'   => \&build_min_reformatter,
      #           -select => ['first', 'sum', 'shuffle'] }

      if (exists $config_options->{-select}) {
        Carp::croak "cannot use -except & -select in same time." if exists $config_options->{-except};
        @funcs = @{$config_options->{-select}}
      } elsif (exists $config_options->{-except}) {
        my %except;
        @except{@{$config_options->{-except}}} = ();
        @funcs = grep !exists $except{$_}, @{_all_funcs_in_class($class)};
      } elsif (not @funcs) {
        @funcs = @{_all_funcs_in_class($class)};
      }
      foreach my $function (@$wanted_funcs ? (grep {defined $config_options->{$_}} @$wanted_funcs) : grep !/^-/, keys %$config_options) {
        if (ref(my $gen = $config_options->{$function}) eq 'CODE') {
          # Like Sub::Exporter generator
          if (exists $local_definition->{$function}) {
            foreach my $def (@{$local_definition->{$function}}) {
              my %arg;
              $arg{$_} = $def->{$_} for grep !/^-/, keys %$def;
              ExportTo::export_to($caller => {($def->{-as} || $function)
                                              => $gen->($pkg, $class, $function, \%arg, $kind_args)});
            }
          } else {
            if ($function ne '.') {
              ExportTo::export_to($caller => {$prefix . $function => $gen->($pkg, $class, $function, {}, $kind_args)});
            } else {
              $gen->($pkg, $class, $function, {}, $kind_args);
            }
          }
          $exported{$function} = undef;
        } elsif (defined &{$class . '::' . $function}) {
          push @funcs, $function;
          $rename{$function} = $config_options->{$function};
        }
      }
    } else {
      @funcs = ref $config_options eq 'ARRAY' ? @$config_options : @{_all_funcs_in_class($class)};
    }
    $class_func{$class} = [\@funcs, \%rename];
  }
  my %want_funcs;
  @want_funcs{@$wanted_funcs} = ();
  foreach my $class (keys %class_func) {
    _do_export($caller, $class, $class_func{$class}->[0], \%want_funcs, \%exported,
               $local_definition, $class_func{$class}->[1], $prefix, $kind_prefix);
  }
}

sub _do_export {
  my ($caller, $class, $funcs, $want_funcs, $exported, $local_definition, $rename, $prefix, $kind_prefix) = @_;
  my %reverse_rename = reverse %$rename;
  if (%$local_definition) {
    foreach my $func (keys %$local_definition) {
      next if exists $exported->{$func};
      next if %$want_funcs and not exists $want_funcs->{$func};

      foreach my $def (@{$local_definition->{$func}}) {
        if (ref $def eq 'HASH') {
          my $local_rename = $def->{-as} || '';
          my $original_func = $reverse_rename{$func} || $func;
          if (do { no strict 'refs'; defined &{$class . '::' . $original_func} }) {
            my $function_name =
              ($local_rename ? $local_rename                                                :
               $prefix       ? (ref $prefix eq 'CODE' ? $prefix->($func) : $prefix . $func) : $func);
            ExportTo::export_to($caller => {$function_name => $class . '::' . $original_func});
          }
        } else {
          Carp::croak("setting for fucntions must be hash ref for : $func => "
                      . (ref $def eq 'ARRAY' ? "[". join(", ",@$def) ."]" : $def));
        }
      }
    }
  } elsif (@$funcs) {
    no strict 'refs';
    @$funcs = grep defined &{$class . '::'. $_}, @$funcs;
    return unless @$funcs;
  }

  my @export_funcs = grep !exists $local_definition->{$_}, @$funcs;
  @export_funcs = grep exists $want_funcs->{$_}, @export_funcs if %$want_funcs;
  if ($prefix or %$rename) {
    if (ref $prefix eq 'CODE') {
      ExportTo::export_to($caller => {map { $prefix->($_) => $class . '::' . $_} @export_funcs});
    } else {
      ExportTo::export_to($caller => {map { $prefix . ($rename->{$_} || $_) => $class . '::' . $_} @export_funcs});
    }
  } else {
    ExportTo::export_to($caller => [map $class . '::' . $_, _uniq @export_funcs]);
  }
}

sub _create_smart_rename {
  my ($pkg, $kind) = @_;
  return sub {
    my $str = shift;
    my $prefix = '';
    if ($str =~s{^(is_|has_|enable_|disable_|isnt_|have_|set_)}{}) {
      $prefix = $1;
    }
    if ($str !~ m{^$kind} and $str !~ m{$kind$}) {
      return $prefix . $kind . '_' . $str;
    } else {
      return $prefix . $str;
    }
  };
}

{
  my %tmp;
  sub _all_funcs_in_class {
    my ($class) = @_;
    return $tmp{$class} if exists $tmp{$class};
    my %f;
    {
      no strict 'refs';
      @f{@{$class . '::EXPORT_OK'}, @{$class . '::EXPORT'}} = ();
    }
    return $tmp{$class} = [grep defined &{$class . '::' . $_}, keys %f];
  }
}

sub _arrange_args {
  my ($pkg, $org_args, $config, $caller, $opt) = @_;
  my (@arg, %want_kind);
  my $import_module = $pkg->_use_import_module;
  my $all_improt = 0;
  if (@$org_args) {
    @$org_args = %{$org_args->[0]} if ref $org_args->[0] and (ref $org_args->[0]) eq 'HASH';
    $opt->{'plugin'} ||= '';
    if ($org_args->[0] =~ /^([:-])?all/i) {
      my $all_import = shift @$org_args;
      my $inherit_all = $1;
      $pkg->_lazy_load_plugins_all($config) if $opt->{'plugin'} eq 'lazy' and $pkg->can('_plugins');
      # import all functions which Util::Any proxy
      @want_kind{keys %$config} = ();
      if ($inherit_all and $import_module) {
        if ($import_module eq 'Exporter' or $import_module eq 'Exporter::Simple') {
          no strict 'refs'; no warnings;
          push @arg, ':all' if ${$pkg . '::EXPORT_TAGS'}{"all"};

        } elsif ($import_module eq 'Sub::Exporter') {
          push @arg, '-all';
        }
      }
    } elsif ($opt->{'plugin'} eq 'lazy' and $pkg->can('_plugins')) {
      $pkg->_lazy_load_plugins($config, $org_args);
    }
    if (_any {ref $_} @$org_args) {
      for (my $i = 0; $i < @$org_args; $i++) {
        my $kind = $org_args->[$i];
        my $ref = ref $org_args->[$i + 1];
        my $import_setting =  $ref ? $org_args->[++$i] : undef;
        if ($ref eq 'ARRAY' and !@$import_setting) {
          $import_setting = [''];
        }
        _insert_want_arg($config, $kind, $import_setting, \%want_kind, \@arg);
      }
    } else {
      # export specified kinds
      foreach my $kind (@$org_args) {
        _insert_want_arg($config, $kind, undef, \%want_kind, \@arg);
      }
    }
  }
  if ($import_module) {
    $pkg->_do_base_import($import_module, $caller, \@arg) if @arg or !@$org_args;
  } else {
    Carp::carp("unknown arguments: @arg") if @arg;
  }
  return \@arg, \%want_kind;
}

sub _insert_want_arg {
  # distinct arguments to want(for Util::Any) and args(for other).
  my ($config, $kind, $import_setting, $want_kind, $arg) = @_;
  $kind = lc $kind;
  if (exists $config->{$kind}) {
    $want_kind->{$kind} = $import_setting;
  } else {
    push @$arg, $kind, defined $import_setting ? $import_setting : ();
  }
}

sub _lazy_load_plugins_all {
  my ($pkg, $config) = @_;
  foreach my $plugin (@{$pkg->_plugins}) {
    eval "require $plugin";
    next if $@;
    my $util = $plugin->utils;
    foreach my $kind (keys %$util) {
      push @{$config->{$kind} ||= []}, @{$util->{$kind}};
    }
  }
}

sub _lazy_load_plugins {
  my ($pkg, $config, $org_args) = @_;
  my (@all, @kinds);
  for my $i (0 .. $#{$org_args}) {
    next if ref $org_args->[$i];
    my $k = $org_args->[$i];
    $k =~ s{\W+}{}g;
    $k =~ s{_}{::}g;
    $k =~ s{^(.+)::all$}{$1|$1::\\w+} and push @all, $i;
    push @kinds, $k;
  }
  return unless @kinds;

  my $regex = "^${pkg}::Plugin::(?:". join("|", @kinds) . ')';
  my $all_regex = '';
  if (@all) {
    $org_args->[$_] =~s{_all$}{} for @all;
    $all_regex = "^${pkg}::Plugin::(?:".join("|", map {m{(\w+)}} @{$org_args}[@all]). ')';
  }
  foreach my $plugin (@{$pkg->_plugins}) {
    if ($plugin =~m{$regex\W}i or $plugin =~m{$regex$}i) {
      eval "require $plugin";
      next if $@;
      my $util = $plugin->utils;
      foreach my $kind (keys %$util) {
        push @{$config->{$kind} ||= []}, @{$util->{$kind}};
        if ($all_regex and ($plugin =~ m{$all_regex\W}i or $plugin =~ m{$all_regex$}i)) {
          push @$org_args, $kind;
        }
      }
    }
  }
}

sub _func_definitions {
  my ($pkg, $want_func_definition) = @_;
  my ($kind_prefix, $kind_args, @wanted_funcs, %funcs, %local_definition);
  if (ref $want_func_definition eq 'HASH') {
    # list => {func => {-as => 'rename'}}; list => {-prefix => 'hoge_' }
    $kind_prefix = $want_func_definition->{-prefix}
      if exists $want_func_definition->{-prefix};
    $kind_args = $want_func_definition->{-args}
      if exists $want_func_definition->{-args};
    foreach my $f (grep !/^-/, keys %$want_func_definition) {
      $local_definition{$f} = [$want_func_definition->{$f}];
    }
  } elsif (ref $want_func_definition eq 'ARRAY') {
    foreach (my $i = 0; $i < @$want_func_definition; $i++) {
      my ($k, $v) = @{$want_func_definition}[$i, $i + 1];
      if ($k eq '-prefix') {
        $kind_prefix = $v;
        $i++;
      } elsif ($k eq '-args') {
        $kind_args = $v;
        $i++;
      }elsif (ref $v) {
        $i++;
        push @wanted_funcs, $k;
        push @{$local_definition{$k} ||= []}, $v;
      } else {
        push @wanted_funcs, $k;
      }
    }
    @wanted_funcs = _uniq @wanted_funcs;
  }
  return \@wanted_funcs, \%local_definition, $kind_prefix || '', $kind_args || {};
}

sub _do_base_import {
  # working with other modules like Expoter
  my ($pkg, $import_module, $caller, $arg) = @_;
  my $pkg_utils;
  {
    no strict 'refs';
    no warnings;
    $pkg_utils = ${$pkg . '::Utils'};
  }
  if ($import_module eq 'Exporter::Simple') {
    eval "package $caller; $pkg" . '->Exporter::Simple::import(@$arg);';
  } elsif ($import_module eq 'Exporter') {
    eval "package $caller; $pkg" . '->Exporter::import(@$arg);';
  } elsif ($import_module eq 'Sub::Exporter') {
    no strict 'refs';
    no warnings;
    my $import_name = ${"${pkg}::SubExporterImport"} || $Util::Any::SubExporterImport;
    eval "package $caller; $pkg" . '->$import_name(@$arg);';
  }
  die $@ if $@;
}

sub _base_import {
  my ($pkg, $caller, @flgs) = @_;
  {
    no strict 'refs';
    push @{"${caller}::ISA"}, __PACKAGE__;
  }
  my @unknown;
  while (@flgs and my $flg = lc shift @flgs) {
    no strict 'refs';
    if ($flg eq '-subexporter') {
      eval { require Sub::Exporter };
      *{$caller . '::_use_import_module'} = sub { 'Sub::Exporter' };
    } elsif ($flg eq '-exportersimple') {
      eval { require Exporter::Simple };
      *{$caller . '::_use_import_module'} = sub { 'Exporter::Simple' };
    } elsif ($flg eq '-exporter') {
     require Exporter;
      push @{"${caller}::ISA"}, 'Exporter';
      *{$caller . '::_use_import_module'} = sub { 'Exporter' };
    } elsif ($flg eq '-base') {
      # nothing to do
    } elsif ($flg eq '-pluggable') {
      # pluggable
      require Module::Pluggable;
      Module::Pluggable->import(require => 0, search_path => [$caller . '::Plugin'], inner => 0);
      my @plugins = $pkg->plugins;
      *{$caller . '::_plugins'} = sub { \@plugins };
    } else {
      push @unknown, $flg;
    }
  }
  Carp::croak "cannot understand the option: @unknown" if @unknown;
}

sub _use_import_module { 0 }

=head1 NAME

Util::Any - to export any utilities and to create your own utility module

=cut

our $VERSION = '0.25';

=head1 SYNOPSIS

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

If you want to import functions with prefix(ex. list_, scalar_, hash_)

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

=head1 DESCRIPTION

For the people like the man who cannot remember C<uniq> function is in whether List::Util or List::MoreUtils.
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

see C<CREATE YOUR OWN Util::Any>, in detail.

=head1 HOW TO USE

=head2 use Util::Any (KIND)

 use Util::Any -list, -hash;

Give list of kinds of modules. All functions in modules are exported.

=head2  use Util::Any KIND => [FUNCTIONS], ...;

NOTE THAT kind '-all', 'all' or ':all' cannot take this option.

 use Util::Any -list => ['uniq'], -hash => ['lock_keys'];

Give hash whose key is kind and value is function names as array ref.
Selected functions are exported.

you can write it as hash ref.

 use Util::Any {-list => ['uniq'], -hash => ['lock_keys']};

=head2  use Util::Any ..., {OPTION => VALUE};

Util::Any can take last argument as option, which should be hash ref.

=over 4

=item prefix => 1

add kind prefix to function name.

 use Util::Any -list, {prefix => 1};
 
 list_uniq(1,2,3,4,5); # it is List::More::Utils's uniq function

=item module_prefix => 1

see L<PREFIX FOR EACH MODULE>.
Uti::Any itself doesn't have such a definition.

=item smart_rename => 1

see L<SMART RENAME FOR EACH KIND>.

=item plugin => 'lazy' / 'eager' / 0 (default is 'lazy')

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

C<_all> is special keyword. see L<"NOTE ABOUT all KEYWORD">.

=item debug => 1/2

Util::Any doesn't say anything when loading module fails.
If you pass debug value, warn or die.

 use Util::Any -list, {debug => 1}; # warn
 use Util::Any -list, {debug => 2}; # die

=back

=head1 EXPORT

Kinds of functions and list of exported functions are below.
Note that these modules and version are on my environment(Perl 5.8.4).
So, it must be different on your environment.

=head2 -data

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

=head2 -hash

from Hash::Util (0.05)

 hash_seed
 lock_hash
 lock_keys
 lock_value
 unlock_hash
 unlock_keys
 unlock_value

=head2 -list

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

=head2 -string

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

=head2 -debug

from Data::Dumper (2.121)

 Dumper

=head1 EXPORTING LIKE Sub::Exporter

Like Sub::Exporter, Util::Any can export function name as you like.

 use Util::Yours -list => {-prefix => 'list__', miin => {-as => "lmin"}};

functions in -list, are exported with prefix "list__" except 'min' and 'min' is exported as C<lmin>.

=head1 PRIORITY OF THE WAYS TO CHANGE FUNCTION NAME

There are some ways to change function name.
Their priority is the following.

=over 4

=item 1 rename

 -list => {uniq => {-as => 'luniq'}}

=item 2 kind_prefix

 -list => {-prefix => list}

=item 3 module_prefix

Only if module's prefix is defined

 ..., {module_prefix => 1}

=item 4 prefix

 ..., {prefix => 1}

=item 5 smart_rename

 ..., {smart_rename => 1}

=back

I don't recommend to use 3, 4, 5 in same time, because it may confuse you.

=over 4

=item 3 + 4

if module's prefix is defined in class(not defined in Util::Any), use 3, or use 4.

=item 3 + 5

3 or 5. reason is as same as the above.

=item 3 + 4 + 5

5 is ignored.

=item 4 + 5

5 is ignored.

=back

=head1 NOTE ABOUT all KEYWORD

B<all> is special keyword, so it has some restriction.

=head2 use module with 'all' cannot take its arguments

 use Util::Any -all; # or 'all', ':all'

This cannot take sequential arguments for "all". For example;

 NG: use Util::Any -all => ['shuffle'];

When sequential arguments is kind's, it's ok.

 use Util::Any -all, -list => ['unique'];

=head2 -plugin_module_all cannot take its arguments

 use Util::Yours -plugin_name_all;

This cannot take sequential arguments for it. For example:

 NG: use Util::Yours -plugin_name_all => ['some_function'];

=head1 CREATE YOUR OWN Util::Any

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

=head2 $Utils STRUCTURE

=head3 overview

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

=head3 Key must be lower character.

 NG $Utils = { LIST => [qw/List::Util/]};
 OK $Utils = { list => [qw/List::Util/]};
 OK $Utils = { -list => [qw/List::Util/]};
 OK $Utils = { ':list' => [qw/List::Util/]};

=head3 C<all> cannot be used for key.

 NG $Utils = { all    => [qw/List::Util/]};
 NG $Utils = { -all   => [qw/List::Util/]};
 NG $Utils = { ':all' => [qw/List::Util/]};

=head3 Value is array ref which contained scalar or array ref.

Scalar is module name. Array ref is module name and its prefix.

 $Utils = { list => ['List::Utils'] };
 $Utils = { list => [['List::Utils', 'prefix_']] };

see L<PREFIX FOR EACH MODULE>

=head2 PREFIX FOR EACH MODULE

If you want to import many modules and they have same function name.
You can specify prefix for each module like the following.

 use base qw/Util::Any/;
 
 our $Utils = {
      list => [['List::Util' => 'lu_'], ['List::MoreUtils' => 'lmu_']]
 };

In your code;

 use Util::Yours qw/list/, {module_prefix => 1};

=head2 SMART RENAME FOR EACH KIND

smart_rename option rename function name by a little smart way.
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

In this definition, use C<prefix => 1> is not good idea. If you use it:

 is_utf8      => utf8_is_utf8
 utf8_upgrade => utf8_utf8_upgrade
 downgrade    => utf8_downgrade

That's too bad. If you use C<smart_rename => 1> instead:

 is_utf8      => is_utf8
 utf8_upgrade => utf8_upgrade
 downgrade    => utf8_downgrade

rename rule is represented in _create_smart_rename in Util::Any.

=head2 CHANGE smart_rename BEHAVIOUR

To define _create_smart_rename, you can change smart_rename behaviour.
_create_smart_rename get 2 argument, package name and kind of utility,
and should return code reference which get function name and return new name.
As an example, see Util::Any's _create_smart_rename.

=head2 OTHER WAY TO EXPORT FUNCTIONS

=head3 SELECT FUNCTIONS

Util::Any automatically export functions from modules' @EXPORT and @EXPORT_OK.
In some cases, it is not good idea like Data::Dumper's Dumper and C<DumperX>.
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


=head3 SELECT FUNCTIONS EXCEPT

Inverse of -select option. Cannot use this option with -select.

 our $Utils = {
      -debug => [
                ['Data::Dumper', '',
                 { -except => ['DumperX'] }, # export functions except DumperX
                ]
               ],
 };

=head3 RENAME FUNCTIONS

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

=head3 USE Sub::Exporter's GENERATOR WAY

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

If you don't specify C<-as>, exported function as C<min>.
But, of course, the following doesn't work.

 use SubExporterGenerator -test => [
       min => {under => 20},
       min => {under => 5},
     ];

Util::Any try to export duplicate function C<min>, one of both should fail.

=head4 GIVE DEFAULT ARGUMENTS TO CODE GENERATOR

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

thousands_sep and int_curr_symbol are given to all of -number kind of function.

=head2 DO SOMETHING WITHOUT EXPORTING ANYTHING

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

=head2 ADD DEFAULT ARGUMENT FOR EXPORTING

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

=head2 ADD PLUGGABLE FEATURE FOR YOUR MODULE

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

=head2 WORKING WITH EXPORTER-LIKE MODULES

NOTE THAT: I don't recommend this usage, because using this may confuse user;
some of import options are for Util::Any and others are for exporter-like module
(especially, using with Sub::Exporter is confusing).

CPAN has some modules to export functions.
Util::Any can work with some of such modules, L<Exporter>, L<Exporter::Simple> and L<Sub::Exporter>.
(note that: L<Perl6::Export::Attrs> is not supported after version 0.25 and the above)
If you want to use other modules, please inform me or implement import method by yourself.

If you want to use module mentioned above, you have to change the way to inherit these modules.

=head3 DIFFERENCE between 'all' and '-all' or ':all'

If your utility module which inherited Util::Any has utility functions and export them by Exporter-like module,
behaviour of 'all' and '-all' or ':all' is a bit different.

 'all' ... export all utilities defined in your package's $Utils variables.
 '-all' or ':all' ... export all utilities including functions in your util module itself.

=head3 ALTERNATIVE INHERITING

Normally, you use;

 package YourUtils;
 
 use Util::Any -Base; # or "use base qw/Util::Any/;"

But, if you want to use L<Exporter>, L<Exporter::Simple> or L<Perl6::Export::Attrs>.
write as the following, instead.

 # if you want to use Exporter
 use Util::Any -Exporter;
 # if you want to use Exporter::Simple
 use Util::Any -ExporterSimple;
 # if you want to use Sub::Exporter
 use Util::Any -SubExporter;

That's all.
Note that B<don't use base the above modules in your utility module>.

There is one notice to use Sub::Exporter.

 Sub::Exporter::setup_exporter
       ({
           as => 'do_import', # name is important
           exports => [...],
           groups  => { ... },
       });

You must pass "as" option to setup_exporter and its value must be "do_import".
If you want to change this name, do the following.

 Sub::Exporter::setup_exporter
       ({
           as => $YourUtils::SubExporterImport = '__do_import',
           exports => [...],
           groups  => { ... },
       });

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-util-any at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Any>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Util::Any

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Util-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Util-Any>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Util-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/Util-Any>

=back

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Util-Any/trunk Util-Any

Subversion repository of Util::Any is hosted at http://coderepos.org/share/.
patches and collaborators are welcome.

=head1 SEE ALSO

The following modules can work with Util::Any.

L<Exporter>, L<Exporter::Simple>, L<Sub::Exporter> and L<Perl6::Export::Attrs>.

The following is new module Util::All, based on Util::Any.

 http://github.com/ktat/Util-All

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Util-Any
