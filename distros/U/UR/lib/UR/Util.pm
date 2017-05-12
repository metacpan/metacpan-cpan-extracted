
package UR::Util;

use warnings;
use strict;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use Cwd;
use Data::Dumper;
use Clone::PP;
use Config;
use Module::Runtime v0.014 qw(module_notional_filename);

sub on_destroy(&) {
    my $sub = shift;
    unless ($sub) {
        Carp::confess("expected an anonymous sub!")
    }
    return bless($sub, "UR::Util::CallOnDestroy");
}

# used only by the above sub
# the local $@ ensures that we this does not stomp on thrown exceptions
sub UR::Util::CallOnDestroy::DESTROY { local $@; shift->(); }

sub d {
    Data::Dumper->new([@_])->Terse(1)->Indent(0)->Useqq(1)->Dump;
}

sub null_sub { }

sub used_libs {
    my @extra;
    my @compiled_inc = UR::Util::compiled_inc();
    my @perl5lib = split(':', $ENV{PERL5LIB});
    map { $_ =~ s/\/+$// } (@compiled_inc, @perl5lib);   # remove trailing slashes
    map { $_ = Cwd::abs_path($_) || $_ } (@compiled_inc, @perl5lib);
    for my $inc (@INC) {
        $inc =~ s/\/+$//;
        my $abs_inc = Cwd::abs_path($inc) || $inc; # should already be expanded by UR.pm
        next if (grep { $_ =~ /^$abs_inc$/ } @compiled_inc);
        next if (grep { $_ =~ /^$abs_inc$/ } @perl5lib);
        next if ((File::Spec->splitdir($inc))[-1] eq $Config{archname});
        push @extra, $inc;
    }

    unshift @extra, ($ENV{PERL_USED_ABOVE} ? split(":", $ENV{PERL_USED_ABOVE}) : ());

    map { $_ =~ s/\/+$// } @extra;   # remove trailing slashes again
    @extra = _unique_elements(@extra);

    return @extra;
}

sub _unique_elements {
    my @list = @_;
    my %seen = ();
    my @unique = grep { ! $seen{$_} ++ } @list;
    return @unique;
}

sub used_libs_perl5lib_prefix {
    my $prefix = "";
    for my $i (used_libs()) {
        $prefix .= "$i:";    
    }
    return $prefix;
}

sub touch_file {
    my $filename = shift;
    open(my $fh, '>>', $filename);
}

my @compiled_inc;
BEGIN {
    use Config;

    my @var_list = (
        'updatesarch', 'updateslib',
        'archlib', 'privlib',
        'sitearch', 'sitelib', 'sitelib_stem',
        'vendorarch', 'vendorlib', 'vendorlib_stem',
        'extrasarch', 'extraslib',
    );

    for my $var_name (@var_list) {
        if ($var_name =~ /_stem$/ && $Config{$var_name}) {
            my @stem_list = (split(' ', $Config{'inc_version_list'}), '');
            push @compiled_inc, map { $Config{$var_name} . "/$_" } @stem_list
        } else {
            push @compiled_inc, $Config{$var_name} if $Config{$var_name};        
        }
    }

    # UR locks in relative paths when loaded so instead of adding '.' we add cwd
    push @compiled_inc, Cwd::cwd() if (${^TAINT} == 0);

    map { $_ =~ s/\/+/\//g } @compiled_inc;
    map { $_ =~ s/\/+$// } @compiled_inc;
}
sub compiled_inc {
    return @compiled_inc;
}

sub deep_copy {
    return Clone::PP::clone($_[0]);
}

sub value_positions_map {
    my ($array) = @_;
    my %value_pos;
    for (my $pos = 0; $pos < @$array; $pos++) {
        my $value = $array->[$pos];
        if (exists $value_pos{$value}) {
            die "Array has duplicate values, which cannot unambiguously be given value positions!"
                . Data::Dumper::Dumper($array);
        }
        $value_pos{$value} = $pos;
    }
    return \%value_pos;
}

sub positions_of_values {
    # my @pos = positions_of_values(\@unordered_crap, \@correct_order);
    # my @fixed = @unordered_crap[@pos];
    my ($unordered_array,$ordered_array) = @_;
    my $map = value_positions_map($unordered_array);
    my @translated_positions;
    $#translated_positions = $#$ordered_array;
    for (my $pos = 0; $pos < @$ordered_array; $pos++) {
        my $value = $ordered_array->[$pos];
        my $unordered_position = $map->{$value};
        $translated_positions[$pos] = $unordered_position;
    }
    # self-test:
    #    my @now_ordered = @$unordered_array[@translated_positions];
    #    unless ("@now_ordered" eq "@$ordered_array") {
    #        Carp::confess()
    #    }
    return @translated_positions;
}


# Get all combinations of values
# input is a list of listrefs of values
sub combinations_of_values {
    return [] unless @_;

    my $first_values = shift;

    $first_values = [ $first_values ] unless (ref($first_values) and ref($first_values) eq 'ARRAY');

    my @retval;
    foreach my $sub_combination ( &combinations_of_values(@_) ) {
        foreach my $value ( @$first_values ) {
            push @retval, [$value, @$sub_combination];
        }
    }

    return @retval;
}

# generate a method
sub _define_method {
    my $class = shift;
    my (%opts) = @_;

    # create method name
    my $method = $opts{pkg} . '::' . $opts{property};

    # determine return value type
    my $retval;
    if (defined($opts{value}))
    {
        my $refval = ref($opts{value});
        $retval = ($refval) ? $refval : 'SCALAR';
    }
    else
    {
        $retval = 'SCALAR';
    }

    # start defining method
    my $substr = "sub $method { my \$self = shift; ";

    # set default value
    $substr .= "\$self->{$opts{property}} = ";
    my $dd = Data::Dumper->new([ $opts{value} ]);
    $dd->Terse(1); # do not print ``$VAR1 =''
    $substr .= $dd->Dump; 
    $substr .= " unless defined(\$self->{$opts{property}}); ";

    # array or scalar?
    if ($retval eq 'ARRAY') {
        if ($opts{access} eq 'rw') {
            # allow setting of array
            $substr .= "\$self->{$opts{property}} = [ \@_ ] if (\@_); ";
        }

        # add return value
        $substr .= "return \@{ \$self->{$opts{property}} }; ";
    }
    else { # scalar
        if ($opts{access} eq 'rw') {
            # allow setting of scalar
            $substr .= "\$self->{$opts{property}} = \$_[0] if (\@_); ";
        }

        # add return value
        $substr .= "return \$self->{$opts{property}}; ";
    }

    # end the subroutine definition
    $substr .= "}";

    # actually define the method
    no warnings qw(redefine);
    eval($substr);
    if ($@) {
        # fatal error since this is like a failed compilation
        die("failed to defined method $method {$substr}:$@");
    }
    return 1;
}

=pod

=over

=item path_relative_to

  $rel_path = UR::Util::path_relative_to($base, $target);

Returns the pathname to $target relative to $base.  If $base
and $target are the same, then it returns '.'.  If $target is
a subdirectory of of $base, then it returns the portion of $target
that is unique compared to $base.  If $target is not a subdirectory
of $base, then it returns a relative pathname starting with $base.

=back

=cut

sub path_relative_to {
    my($base,$target) = @_;

    $base = Cwd::abs_path($base);
    $target = Cwd::abs_path($target);

    my @base_path_parts = split('/', $base);
    my @target_path_parts = split('/', $target);
    my $i;
    for ($i = 0;
         $i < @base_path_parts and $base_path_parts[$i] eq $target_path_parts[$i];
         $i++
    ) { ; }

    my $rel_path = '../' x (scalar(@base_path_parts) - $i)
                      .
                      join('/', @target_path_parts[$i .. $#target_path_parts]);
    $rel_path = '.' unless length($rel_path);
    return $rel_path;
}
 
=pod

=over

=item generate_readwrite_methods

  UR::Util->generate_readwrite_methods
  (
      some_scalar_property => 1,
      some_array_property => []
  );

This method generates accessor/set methods named after the keys of its
hash argument.  The type of function generated depends on the default
value provided as the hash key value.  If the hash key is a scalar, a
scalar method is generated.  If the hash key is a reference to an
array, an array method is generated.

This method does not overwrite class methods that already exist.

=back

=cut

sub generate_readwrite_methods
{
    my $class = shift;
    my %properties = @_;

    # get package of caller
    my $pkg = caller;

    # loop through properties
    foreach my $property (keys(%properties)) {
        # do not overwrite defined methods
        next if $pkg->can($property);

        # create method
        $class->_define_method
        (
            pkg => $pkg,
            property => $property,
            value => $properties{$property},
            access => 'rw'
        );
    }

    return 1;
}

=pod

=over

=item generate_readwrite_methods_override

  UR::Util->generate_readwrite_methods_override
  (
      some_scalar_property => 1,
      some_array_property => []
  );

Same as generate_readwrite_function except that we force the functions
into the namespace even if the function is already defined

=back

=cut

sub generate_readwrite_methods_override
{
    my $class = shift;
    my %properties = @_;

    # get package of caller
    my $pkg = caller;

    # generate the methods for each property
    foreach my $property (keys(%properties)) {
        # create method
        $class->_define_method
        (
            pkg => $pkg,
            property => $property,
            value => $properties{$property},
            access => 'rw'
        );
    }

    return 1;
}

=pod

=over

=item generate_readonly_methods

  UR::Util->generate_readonly_methods
  (
      some_scalar_property => 1,
      some_array_property => []
  );

This method generates accessor methods named after the keys of its
hash argument.  The type of function generated depends on the default
value provided as the hash key value.  If the hash key is a scalar, a
scalar method is generated.  If the hash key is a reference to an
array, an array method is generated.

This method does not overwrite class methods that already exist.

=back

=cut

sub generate_readonly_methods
{
    my $class = shift;
    my %properties = @_;

    # get package of caller
    my ($pkg) = caller;

    # loop through properties
    foreach my $property (keys(%properties)) {
        # do no overwrite already defined methods
        next if $pkg->can($property);

        # create method
        $class->_define_method
        (
            pkg => $pkg,
            property => $property,
            value => $properties{$property},
            access => 'ro'
        );
    }

    return 1;
}

=pod

=over

=item object

  my $o = UR::Util::object($something);

Return the object form of the supplied argument.  For regular objects, it
returns the argument unchanged.  For singleton class names, it returns the
instance of the Singleton.  For other class names, it throws an exception.

=back

=cut

sub object {
    my $it = shift;

    unless (ref $it) {
        if ($it->isa('UR::Singleton')) {
            $it = $it->_singleton_object();
        } else {
            Carp::croak("Expected an object instance or Singleton class name, but got '$it'");
        }
    }
    return $it;
}

=pod 

=over

=item mapreduce_grep

    my @matches = UR::Util->map_reduce_grep { shift->some_test } @candidates;

Works similar to the Perl C<grep> builtin, but in a possibly-parallel fashion.
If the environment variable UR_NR_CPU is set to a number greater than one, it
will fork off child processes to perform the test on slices of the input
list, collect the results, and return the matching items as a list.

The test function is called with a single argument, an item from the list to
be tested, and should return a true of false value.

=back

=cut

sub mapreduce_grep($&@) {
    my $class = shift;
    my $subref = shift;
#$DB::single = 1;


    # First check fast... should we do parallel at all?
    if (!$ENV{'UR_NR_CPU'} or $ENV{'UR_NR_CPU'} < 2) {
        #return grep { $subref->($_) } @_;
        my @ret = grep { $subref->($_) } @_;
        return @ret;
    }

    my(@read_handles, @child_pids);
    my $cleanup = sub {
        foreach my $handle ( @read_handles ) {
            $handle->close();
        }

        kill 'TERM', @child_pids;

        foreach my $pid ( @child_pids ) {
            waitpid($pid,0);
        }
    };

    my @things_to_check = @_;
    my($children, $length,$parent_last);
    if ($ENV{'UR_NR_CPU'}) {
        $length = POSIX::ceil(scalar(@things_to_check) / $ENV{'UR_NR_CPU'});
        $children = $ENV{'UR_NR_CPU'} - 1;
    } else {
        $children = 0;
        $parent_last = $#things_to_check;
    }

    # FIXME - There needs to be some code in here to disconnect datasources
    # Oracle in particular (maybe all DBs?), stops working right unless you
    # disconnect before forking

    my $start = $length;  # First child starts checking after parent's range
    $parent_last = $length - 1;
    while ($children-- > 0) {
        my $pipe = IO::Pipe->new();
        unless ($pipe) {
            Carp::carp("pipe() failed: $!\nUnable to create pipes to communicate with child processes to verify transact+ion, falling back to serial verification");
            $cleanup->();
            $parent_last = $#things_to_check;
            last;
        }

        my $pid = fork();
        if ($pid) {
            $pipe->reader();
            push @read_handles, $pipe;
            $start += $length;

        } elsif (defined $pid) {
            $pipe->writer();
            my $last = $start + $length;
            $last = $#things_to_check if ($last > $#things_to_check);

            #my @objects = grep { $subref->($_) } @things_to_check[$start .. $last];
            my @matching;
            for (my $i = $start; $i <= $last; $i++) {
                if ($subref->($things_to_check[$i])) {
                    push @matching, $i;
                }
            }
            # FIXME - when there's a more general framework for passing objects between
            # processes, use that instead
            #$pipe->printf("%s\n%s\n",$_->class, $_->id) foreach @objects;
            $pipe->print("$_\n") foreach @matching;


            exit;

        } else {
            Carp::carp("fork() failed: $!\nUnable to create child processes to ver+ify transaction, falling back to seri+al verification");
            $cleanup->();
            $parent_last = $#things_to_check;
        }
    }
    my @matches = grep { $subref->($_) } @things_to_check[0 .. $parent_last];

    foreach my $handle ( @read_handles ) {
        READ_FROM_CHILD:
        while(1) {
            my $match_idx = $handle->getline();
            last READ_FROM_CHILD unless $match_idx;
            chomp $match_idx;

            push @matches, $things_to_check[$match_idx];
            #my $match_class = $handle->getline();
            #last READ_FROM_CHILD unless $match_class;
            #chomp($match_class);

            #my $match_id = $handle->getline();
            #unless (defined $match_id) {
            #    Carp::carp("Protocol error.  Tried to get object ID for class $match_class while verifying transaction"+);
            #    last READ_FROM_CHILD;
            #}
            #chomp($match_id);

            #push @objects, $match_class->get($match_id);
        }
        $handle->close();
    }

    $cleanup->();

    return @matches;
}


# Used in several places when printing out hash-like parameters
# to the user, such as in error messages
sub display_string_for_params_list {
    my $class = shift;

    my %params;
    if (ref($_[0]) =~ 'HASH') {
        %params = %{$_[0]};
    } else {
        %params = @_;
    }

    my @strings;
    foreach my $key ( keys %params ) {
        my $val = $params{$key};
        $val = defined($val) ? "'$val'" : '(undef)';
        push @strings, "$key => $val";
    }
    return join(', ', @strings);
}

# why isn't something like this in List::Util?
# Return a list of 3 listrefs:
# 0: items common to both lists
# 1: items in the first list only
# 2: items in the second list only
sub intersect_lists {
    my ($m,$n) = @_;
    my %shared;
    my %monly;
    my %nonly;
    @monly{@$m} = @$m;
    for my $v (@$n) {
        if ($monly{$v}) {
            $shared{$v} = delete $monly{$v};
        }
        else{
            $nonly{$v} = $v;
        }
    }
    return (
        [ values %shared ],
        [ values %monly ],
        [ values %nonly ],
    );
}

sub is_valid_property_name {
    my $property_name = shift;
    return $property_name =~ m/^[_[:alpha:]][_[:alnum:]]*$/;
}

sub is_valid_class_name {
    my $class = shift;
    return $class =~ m/^[[:alpha:]]\w*((::|')\w+)*$/;
}

{
    my %subclass_suffix_for_builtin_symbolic_operator = (
        '='     => "Equals",
        '<'     => "LessThan",
        '>'     => "GreaterThan",
        '[]'    => "In",
        'in []' => "In",
        'ne'    => "NotEquals",
        '<='    => 'LessOrEqual',
        '>='    => 'GreaterOrEqual',
    );
    my %subclass_suffix_for_builtin_symbolic_operator_negation = (
        '<'     => 'GreaterOrEqual',  # 'not less than' is the same as GreaterOrEqual
        '<='    => 'GreaterThan',
        '>'     => 'LessOrEqual',
        '>='    => 'LessThan',
        'ne'    => 'Equals',
        'false' => 'True',
        'true'  => 'False',
    );

    sub class_suffix_for_operator {
        my $comparison_operator = shift;
        my $not = 0;
        if ($comparison_operator and $comparison_operator =~ m/^(\!|not)\s*(.*)/) {
            $not = 1;
            $comparison_operator = $2;
        }

        if (!defined($comparison_operator) or $comparison_operator eq '') {
            $comparison_operator = '=';
        }

        my $suffix;
        if ($not) {
            $suffix = $subclass_suffix_for_builtin_symbolic_operator_negation{$comparison_operator};
            unless ($suffix) {
                $suffix = $subclass_suffix_for_builtin_symbolic_operator{$comparison_operator} || ucfirst(lc($comparison_operator));
                $suffix = "Not$suffix";
            }
        } else {
            $suffix = $subclass_suffix_for_builtin_symbolic_operator{$comparison_operator} || ucfirst(lc($comparison_operator));
        }
        return $suffix;
    }
}

# From DBI::quote()
# needed in a few places where we need to quote some SQL but don't
# have access to a database handle to call quote() on
sub sql_quote {
    my $str = shift;
    return "NULL" unless defined $str;
    $str =~ s/'/''/g; # ISO SQL2
    return "'$str'";
}

# Module::Runtime's use_package_optimistically will not throw an exception if
# the package cannot be found or if it fails to compile but will if the package
# has upstream exceptions, e.g. a missing dependency.  We're a little less
# "optimistic" so we check if the package is in %INC so we can report whether
# it was believed to be loaded or not.
sub use_package_optimistically {
    my $name = Module::Runtime::use_package_optimistically(shift);
    my $file = module_notional_filename($name);
    return $INC{$file};
}

# return a hashref of subroutine names => coderefs
sub coderefs_for_package {
    my $package = shift;

    my %stash = do {
        no strict 'refs';
        my $stash_name = $package . '::';
        %$stash_name;
    };

    my %subs;
    local $@;
    foreach my $name ( keys %stash ) {
        my $glob = $stash{$name};
        next unless my $coderef = eval { *$glob{CODE} };  # constants are SCALAR refs, not typeglobs
        $subs{$name} = $coderef;
    }
    return \%subs;
}

# Given a key in a hashref, if the value is a scalar, wrap it in an arrayref
# used by the class initializer to allow some keys in a class definition to
# be specified as simple scalars that are normalized to be an arrayref.
# Returns false if the value isn't an arrayref or scalar.
sub ensure_arrayref {
    my($new_class, $key) = @_;

    if ($new_class->{$key}) {
        if (!ref($new_class->{$key})) {
            # If it's a plain string, wrap it into an arrayref
            $new_class->{$key} = [ $new_class->{$key} ];
        } elsif (ref($new_class->{$key}) ne 'ARRAY') {
            my $class_name = $new_class->{class_name};
            return 0;
        }
    } else {
        $new_class->{$key} = [];
    }
    return 1;
}



1;

=pod

=head1 NAME

UR::Util - Collection of utility subroutines and methods

=head1 DESCRIPTION

This package contains subroutines and methods used by other parts of the 
infrastructure.  These subs are not likely to be useful to outside code.

=cut

