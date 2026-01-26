package XS::JIT::Builder;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.07';

use Exporter 'import';
our @EXPORT_OK = qw(
    INLINE_NONE INLINE_GETTER INLINE_SETTER 
    INLINE_HV_GETTER INLINE_HV_SETTER
    TYPE_ANY TYPE_DEFINED TYPE_INT TYPE_NUM TYPE_STR
    TYPE_REF TYPE_ARRAYREF TYPE_HASHREF TYPE_CODEREF
    TYPE_OBJECT TYPE_BLESSED
);
our %EXPORT_TAGS = (
    inline => [qw(INLINE_NONE INLINE_GETTER INLINE_SETTER 
                  INLINE_HV_GETTER INLINE_HV_SETTER)],
    types  => [qw(TYPE_ANY TYPE_DEFINED TYPE_INT TYPE_NUM TYPE_STR
                  TYPE_REF TYPE_ARRAYREF TYPE_HASHREF TYPE_CODEREF
                  TYPE_OBJECT TYPE_BLESSED)],
);

require XSLoader;
XSLoader::load('XS::JIT::Builder', $VERSION);

sub write_file {
    my ($self, $filename) = @_;

    die "write_file requires a filename" unless defined $filename;

    open my $fh, '>', $filename
        or die "Cannot open '$filename' for writing: $!";
    print $fh $self->code;
    close $fh
        or die "Cannot close '$filename': $!";

    return $self;
}

=head1 NAME

XS::JIT::Builder - interface for building XS/C code strings

=head1 SYNOPSIS

    use XS::JIT;
    use XS::JIT::Builder;
    use File::Temp qw(tempdir);

    my $cache_dir = tempdir(CLEANUP => 1);
    my $b = XS::JIT::Builder->new;
    
    # Build a simple accessor
    $b->xs_function('get_name')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'name', 4, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end;
    
    # Compile and use
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyClass',
        cache_dir => $cache_dir,
        functions => {
            'MyClass::name' => { source => 'get_name', is_xs_native => 1 },
        },
    );
    
    my $obj = bless { name => 'Alice' }, 'MyClass';
    print $obj->name;  # prints "Alice"

=head1 DESCRIPTION

This module is experimental, the api and the code generated will evolve over time.

XS::JIT::Builder provides a interface for generating C code dynamically. 
It handles indentation automatically and provides convenient methods for 
common XS patterns.

All methods return C<$self> to enable method chaining. The generated code
can be retrieved with C<code()> and passed to C<XS::JIT-E<gt>compile()>.

=head1 METHODS

=head2 Lifecycle

=over 4

=item new(%options)

Create a new builder.

    my $b = XS::JIT::Builder->new;
    my $b = XS::JIT::Builder->new(use_tabs => 1);
    my $b = XS::JIT::Builder->new(indent_width => 2);

Options:

=over 4

=item use_tabs

Use tabs for indentation instead of spaces (default: false).

=item indent_width

Number of spaces per indentation level when not using tabs (default: 4).

=back

=item code()

Return the accumulated C code as a string.

    my $c_code = $b->code;

=item reset()

Clear the builder and reset state for reuse.

    $b->reset;
    # Builder is now empty, can build new code

=item write_file($filename)

Write the accumulated C code to a file. This is useful for:

=over 4

=item * Distribution - Generate the XS file once, ship it with your module

=item * Debugging - Inspect the generated code

=item * Performance - Skip runtime JIT compilation entirely

=back

    $b->write_file('MyModule.c');
    # Now you can compile MyModule.c as a regular XS/C extension

Returns C<$self> to enable method chaining.

=back

=head2 Low-level Output

=over 4

=item line($text)

Add a line with current indentation.

    $b->line('int x = 42;');

=item raw($text)

Add raw text without automatic indentation or newline.

    $b->raw('/* inline comment */');

=item comment($text)

Add a C comment.

    $b->comment('This is a comment');
    # Generates: /* This is a comment */

=item blank()

Add a blank line.

=back

=head2 XS Structure

=over 4

=item xs_function($name)

Start an XS function definition.

    $b->xs_function('my_function');
    # Generates: XS_EUPXS(my_function) {

=item xs_preamble()

Add standard XS preamble (dVAR, dXSARGS, etc.).

    $b->xs_function('my_func')
      ->xs_preamble;

=item xs_end()

Close an XS function.

    $b->xs_end;
    # Generates: }

=item xs_return($count)

Add XSRETURN statement.

    $b->xs_return('1');
    # Generates: XSRETURN(1);

=item xs_return_undef()

Return undef from XS function.

    $b->xs_return_undef;
    # Generates: ST(0) = &PL_sv_undef; XSRETURN(1);

=item method_start($name, $min_args, $max_args, $usage)

Start a method with argument checking.

    $b->method_start('set_value', 2, 2, '$self, $value');
    # Generates function with items check and usage croak

=back

=head2 Control Flow

=over 4

=item if($condition)

Start an if block.

    $b->if('items > 1');

=item elsif($condition)

Add an elsif clause.

    $b->elsif('items == 1');

=item else()

Add an else clause.

    $b->else;

=item endif()

Close an if/elsif/else block.

    $b->if('x > 0')
      ->return_pv('positive')
    ->endif;

=item for($init, $cond, $incr)

Start a for loop.

    $b->for('int i = 0', 'i < 10', 'i++');

=item while($condition)

Start a while loop.

    $b->while('ptr != NULL');

=item endloop() / endfor() / endwhile()

Close a loop. All three are aliases.

    $b->for('int i = 0', 'i < n', 'i++')
      ->raw('sum += array[i];')
    ->endfor;

=item block()

Start a bare block.

    $b->block;
    # Generates: {

=item endblock()

Close a bare block.

    $b->block
      ->declare_iv('temp', 'x')
      ->raw('x = y; y = temp;')
    ->endblock;

=back

=head2 Variable Declarations

=over 4

=item declare($type, $name, $value)

Declare a variable of any type.

    $b->declare('int', 'count', '0');
    # Generates: int count = 0;

=item declare_sv($name, $value)

Declare an SV* variable.

    $b->declare_sv('arg', 'ST(1)');
    # Generates: SV* arg = ST(1);

=item declare_iv($name, $value)

Declare an IV (integer) variable.

    $b->declare_iv('count', 'items - 1');
    # Generates: IV count = items - 1;

=item declare_nv($name, $value)

Declare an NV (double) variable.

    $b->declare_nv('total', '0.0');
    # Generates: NV total = 0.0;

=item declare_pv($name, $value)

Declare a const char* variable.

    $b->declare_pv('str', 'SvPV_nolen(ST(0))');
    # Generates: const char* str = SvPV_nolen(ST(0));

=item declare_hv($name, $value)

Declare an HV* variable.

    $b->declare_hv('hash', '(HV*)SvRV(arg)');

=item declare_av($name, $value)

Declare an AV* variable.

    $b->declare_av('array', '(AV*)SvRV(arg)');

=item new_hv($name)

Declare and create a new hash.

    $b->new_hv('hv');
    # Generates: HV* hv = newHV();

=item new_av($name)

Declare and create a new array.

    $b->new_av('results');
    # Generates: AV* results = newAV();

=item assign($var, $value)

Assign a value to an existing variable.

    $b->assign('count', 'count + 1');
    # Generates: count = count + 1;

=back

=head2 Type Checking

=over 4

=item check_items($min, $max, $usage)

Check argument count, croak if wrong. Use max=-1 for no upper limit.

    $b->check_items(1, 2, '$self, $value?');

=item check_defined($sv, $error_msg)

Croak if SV is not defined.

    $b->check_defined('ST(1)', 'value required');

=item check_hashref($sv, $error_msg)

Croak if SV is not a hash reference.

    $b->check_hashref('ST(0)', 'expected hashref');

=item check_arrayref($sv, $error_msg)

Croak if SV is not an array reference.

    $b->check_arrayref('arg', 'expected arrayref');

=back

=head2 SV Conversion

=over 4

=item sv_to_iv($result_var, $sv)

Convert SV to integer.

    $b->sv_to_iv('count', 'ST(1)');
    # Generates: IV count = SvIV(ST(1));

=item sv_to_nv($result_var, $sv)

Convert SV to double.

    $b->sv_to_nv('value', 'ST(1)');

=item sv_to_pv($result_var, $len_var, $sv)

Convert SV to string with length.

    $b->sv_to_pv('str', 'len', 'ST(1)');
    # Generates: STRLEN len; const char* str = SvPV(ST(1), len);

=item sv_to_bool($result_var, $sv)

Convert SV to boolean.

    $b->sv_to_bool('flag', 'ST(1)');

=item new_sv_iv($result_var, $value)

Create new SV from integer.

    $b->new_sv_iv('result', 'count');
    # Generates: SV* result = newSViv(count);

=item new_sv_nv($result_var, $value)

Create new SV from double.

    $b->new_sv_nv('result', 'total');

=item new_sv_pv($result_var, $str, $len)

Create new SV from string.

    $b->new_sv_pv('result', 'buffer', 'len');
    # Generates: SV* result = newSVpvn(buffer, len);

=back

=head2 Return Helpers

=over 4

=item return_iv($value)

Return an integer value.

    $b->return_iv('42');
    $b->return_iv('count');

=item return_nv($value)

Return a double value.

    $b->return_nv('3.14');
    $b->return_nv('result');

=item return_pv($str)

Return a string value. The string is automatically quoted if it doesn't
start with a letter/underscore (i.e., if it's not a C variable name).

    $b->return_pv('hello');      # Returns literal "hello"
    $b->return_pv('buffer');     # Returns C variable buffer
    $b->return_pv('"quoted"');   # Returns literal "quoted"

=item return_sv($sv)

Return an SV.

    $b->return_sv('result');
    $b->return_sv('sv_2mortal(newSViv(42))');

=item return_yes()

Return true (C<&PL_sv_yes>).

=item return_no()

Return false (C<&PL_sv_no>).

=item return_undef()

Return undef.

=item return_self()

Return the invocant (C<$self>).

    $b->return_self;
    # For method chaining

=back

=head2 Self/Object Methods

=over 4

=item get_self()

Get the invocant as SV*.

    $b->get_self;
    # Generates: SV* self = ST(0);

=item get_self_hv()

Get the invocant and its underlying hash.

    $b->get_self_hv;
    # Generates: SV* self = ST(0); HV* hv = (HV*)SvRV(self);

=item mortal($result_var, $sv_expr)

Create a mortal copy of an SV.

    $b->mortal('result', 'newSViv(42)');
    # Generates: SV* result = sv_2mortal(newSViv(42));

=back

=head2 Hash Operations

=over 4

=item hv_fetch($hv, $key, $len, $result_var)

Fetch from a hash with a literal string key.

    $b->hv_fetch('hv', 'name', 4, 'val');
    # Generates: SV** val = hv_fetch(hv, "name", 4, 0);

=item hv_fetch_sv($hv, $key_expr, $len_expr, $result_var)

Fetch from a hash with a C expression key.

    $b->hv_fetch_sv('hv', 'key', 'key_len', 'val');
    # Generates: SV** val = hv_fetch(hv, key, key_len, 0);

=item hv_store($hv, $key, $len, $value)

Store into a hash with a literal string key.

    $b->hv_store('hv', 'name', 4, 'newSVpv("Alice", 0)');
    # Generates: (void)hv_store(hv, "name", 4, newSVpv("Alice", 0), 0);

=item hv_store_sv($hv, $key_expr, $len_expr, $value)

Store into a hash with a C expression key.

    $b->hv_store_sv('hv', 'key', 'key_len', 'newSVsv(val)');

=item hv_store_weak($hv, $key, $key_len, $value_expr)

Store a value into a hash, weakening it if it's a reference.
Useful for parent/owner pointers that should not hold strong references.

    $b->hv_store_weak('hv', 'parent', 6, 'newSVsv(ST(1))');

=item hv_fetch_return($hv, $key, $len)

Fetch from hash and return the value (or undef if not found).

    $b->hv_fetch_return('hv', 'name', 4);

=item hv_delete($hv, $key, $len)

Delete a key from a hash.

    $b->hv_delete('hv', 'name', 4);

=item hv_exists($hv, $key, $len, $result_var)

Check if a key exists in a hash.

    $b->hv_exists('hv', 'name', 4, 'found');

=back

=head2 Array Operations

=over 4

=item av_fetch($av, $index, $result_var)

Fetch from an array.

    $b->av_fetch('av', 'i', 'elem');
    # Generates: SV** elem = av_fetch(av, i, 0);

=item av_store($av, $index, $value)

Store into an array.

    $b->av_store('av', 'i', 'newSViv(42)');

=item av_push($av, $value)

Push onto an array.

    $b->av_push('results', 'newSViv(n)');

=item av_len($av, $result_var)

Get the highest index of an array.

    $b->av_len('av', 'last_idx');
    # Generates: SSize_t last_idx = av_len(av);

=back

=head2 Callbacks & Triggers

Methods for calling Perl code from generated XS functions.

=over 4

=item call_sv($cv_expr, \@args)

Generate code to call a coderef with given arguments. Uses G_DISCARD so
return values are discarded. Useful for calling callbacks, event handlers,
or triggers.

    $b->call_sv('cb', ['self', 'new_val']);
    # Generates: dSP; ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(self); ...

=item call_method($method_name, $invocant, \@args)

Generate code to call a method by name on an invocant. Uses G_DISCARD
so return values are discarded. Useful for calling hooks like BUILD,
DEMOLISH, triggers, or callbacks.

    $b->call_method('_on_change', 'self', ['old_val', 'new_val']);
    # Generates: call_method("_on_change", G_DISCARD);

=item rw_accessor_trigger($func_name, $attr, $len, $trigger_method)

Generate a read/write accessor that calls a trigger method after setting.
The trigger method is called with the object and new value as arguments.

    $b->rw_accessor_trigger('MyClass::name', 'name', 4, '_on_name_change');
    # Accessor calls $self->_on_name_change($new_val) after setting

=item accessor_lazy_builder($func_name, $attr, $len, $builder_method)

Generate a read/write accessor with lazy initialization. On first read,
if the value is undefined, calls the builder method to compute and cache
the value.

    $b->accessor_lazy_builder('MyClass::computed', 'computed', 8, '_build_computed');
    # First read calls $self->_build_computed() and caches result

=item destroy_with_demolish($func_name)

Generate a DESTROY method that checks for and calls DEMOLISH if it exists.
Passes C<$in_global_destruction> as the second argument to DEMOLISH.

    $b->destroy_with_demolish('MyClass::DESTROY');
    # DESTROY calls $self->DEMOLISH($in_global_destruction) if defined

=back

=head2 Control Flow & Extended Patterns

Advanced control flow helpers and expression builders.

=over 4

=item do_loop() / end_do_while($condition)

Generate a do-while loop that executes at least once.

    $b->do_loop
      ->line('/* loop body */')
    ->end_do_while('ptr != NULL');
    # Generates: do { ... } while (ptr != NULL);

=item if_list_context()

Branch on list context. Use with C<else> and C<endif>.

    $b->if_list_context
      ->return_list(['key_sv', 'val_sv'])
    ->else
      ->line('ST(0) = val_sv;')
      ->line('XSRETURN(1);')
    ->endif;

=item if_scalar_context()

Branch on scalar context. Use with C<else> and C<endif>.

    $b->if_scalar_context
      ->line('ST(0) = count_sv;')
    ->else
      ->return_list(['@items'])
    ->endif;

=item extend_stack($count_expr)

Extend the stack to hold more return values.

    $b->extend_stack('num_items');
    # Generates: EXTEND(SP, num_items);

=item return_list(\@values)

Return multiple values from XS, handling stack extension and mortalization.

    $b->return_list(['newSViv(1)', 'newSViv(2)', 'newSViv(3)']);
    # Generates: EXTEND(SP, 3); ST(0) = sv_2mortal(...); ... XSRETURN(3);

=item declare_ternary($type, $name, $cond, $true_expr, $false_expr)

Declare a variable with ternary initialization.

    $b->declare_ternary('SV*', 'val', 'items > 1', 'ST(1)', '&PL_sv_undef');
    # Generates: SV* val = (items > 1) ? ST(1) : &PL_sv_undef;

=item assign_ternary($var, $cond, $true_expr, $false_expr)

Ternary assignment to existing variable.

    $b->assign_ternary('result', 'found', '*svp', '&PL_sv_undef');
    # Generates: result = (found) ? *svp : &PL_sv_undef;

=item delegate_method($func_name, $attr, $len, $target_method)

Generate a method that delegates to an attribute's method.
Passes through all arguments and returns the result.

    $b->delegate_method('get_name', 'delegate_obj', 12, 'name');
    # Generates: sub get_name { $self->{delegate_obj}->name(@_) }

=back

=head2 Singleton Pattern

Methods for implementing the singleton design pattern.

=over 4

=item singleton_accessor($func_name, $class_name)

Generate a class method that returns the singleton instance, creating it on
first access. The instance is stored in a package variable C<$Class::_instance>.

    $b->singleton_accessor('instance', 'MyApp::Config');
    # MyApp::Config->instance always returns same object

=item singleton_reset($func_name, $class_name)

Generate a class method that clears the singleton instance. The next call to
the singleton accessor will create a fresh instance.

    $b->singleton_reset('reset_instance', 'MyApp::Config');
    # MyApp::Config->reset_instance clears the singleton

=back

=head2 Registry Pattern

These methods generate registry pattern accessors for storing and retrieving
items in a hash attribute by key.

=over 4

=item registry_add($func_name, $registry_attr)

Generate a method to add an item to a registry hash. Creates the registry
hash automatically if it doesn't exist. Returns $self for chaining.

    $b->registry_add('register_handler', '_handlers');
    # Usage: $obj->register_handler(click => sub { ... });

=item registry_get($func_name, $registry_attr)

Generate a method to retrieve an item from a registry hash by key.
Returns undef if the key doesn't exist.

    $b->registry_get('get_handler', '_handlers');
    # Usage: my $handler = $obj->get_handler('click');

=item registry_remove($func_name, $registry_attr)

Generate a method to remove and return an item from a registry hash.
Returns undef if the key doesn't exist.

    $b->registry_remove('unregister_handler', '_handlers');
    # Usage: my $old = $obj->unregister_handler('click');

=item registry_all($func_name, $registry_attr)

Generate a context-aware method to retrieve all registry items.
In list context, returns key-value pairs. In scalar context, returns a
shallow copy of the registry as a hashref.

    $b->registry_all('all_handlers', '_handlers');
    # List context: my %handlers = $obj->all_handlers;
    # Scalar context: my $hashref = $obj->all_handlers;

=back

=head2 Method Modifiers

These methods generate Moose/Moo-style method modifiers that wrap existing
methods with before, after, or around hooks.

=over 4

=item wrap_before($func_name, $orig_name, $before_cv_name)

Generate a wrapper that calls a "before" hook before the original method.
The before hook receives the same arguments as the original. Its return
value is discarded. The original's return value is preserved.

    $b->wrap_before('save_with_log', 'MyClass::_orig_save', 'MyClass::_log_before');
    # Calls _log_before(@args), then _orig_save(@args)

=item wrap_after($func_name, $orig_name, $after_cv_name)

Generate a wrapper that calls an "after" hook after the original method.
The after hook receives the same arguments as the original. Its return
value is discarded. The original's return value is preserved.

    $b->wrap_after('save_with_notify', 'MyClass::_orig_save', 'MyClass::_notify_after');
    # Calls _orig_save(@args), then _notify_after(@args)

=item wrap_around($func_name, $orig_name, $around_cv_name)

Generate a wrapper with "around" semantics. The around hook receives the
original coderef as its first argument, followed by the original arguments.
The around hook has full control and can modify arguments, skip the original,
or modify return values.

    $b->wrap_around('save_cached', 'MyClass::_orig_save', 'MyClass::_cache_around');
    # _cache_around receives ($orig, @args)
    # Can call: $orig->(@args) or skip or modify

=back

=head2 Role/Mixin Composer

Generate multiple related methods that compose behavioral patterns.

=over 4

=item role($role_name, \%opts)

Generate all methods for a single role. Available roles:

B<Comparable> - Comparison methods (compare by a key attribute):

    $b->role('Comparable');                        # Uses 'id' as compare key
    $b->role('Comparable', { compare_key => 'name' });  # Uses 'name'

Generates: C<compare($other)>, C<equals($other)>, C<lt($other)>, C<gt($other)>,
C<le($other)>, C<ge($other)>.

B<Cloneable> - Object cloning:

    $b->role('Cloneable');

Generates: C<clone()> - shallow clone of hash-based object.

B<Serializable> - Serialization methods:

    $b->role('Serializable');

Generates: C<TO_JSON()>, C<TO_HASH()> - return hashref copy (JSON::XS compatible).

B<Observable> - Observer pattern:

    $b->role('Observable');
    $b->role('Observable', { observers_attr => '_watchers' });

Generates: C<add_observer($callback)>, C<remove_observer($callback)>,
C<notify_observers(@args)>.

=item with_roles(\@roles, \%opts)

Compose multiple roles in a single call:

    $b->with_roles(['Comparable', 'Cloneable', 'Serializable']);

    # With options:
    $b->with_roles(['Comparable', 'Observable'], {
        compare_key    => 'name',
        observers_attr => '_listeners',
    });

This is a convenience method that calls C<role()> for each role in the list.

=back

=head2 Prebuilt Patterns

These methods generate complete XS functions for common patterns.

=head3 Constructors

=over 4

=item new_simple($func_name)

Generate a minimal constructor: C<bless {}, $class>.
Fastest possible constructor with no argument processing.

    $b->new_simple('new');
    # Generates: my $obj = Class->new;

=item new_hash($func_name)

Generate a flexible constructor that accepts either flat hash or hashref args.
All provided args are copied into the object.

    $b->new_hash('new');
    # Supports both:
    # my $obj = Class->new(name => 'Alice', age => 30);
    # my $obj = Class->new({ name => 'Alice', age => 30 });

=item new_array($func_name, $num_slots)

Generate an array-based constructor (Meow-style). Creates a blessed arrayref
with pre-allocated slots initialized to undef.

    $b->new_array('new', 5);
    # my $obj = Class->new;  # $obj->[0..4] are undef

=item new_with_required($func_name, \@required_attrs)

Generate a constructor that validates required attributes. Croaks if any
required attribute is missing or undef.

    $b->new_with_required('new', ['name', 'id']);
    # Class->new(name => 'Alice');  # croaks: "Missing required attribute 'id'"
    # Class->new(name => 'Alice', id => 123);  # OK

Accepts either flat hash or hashref arguments, like C<new_hash>.

=item new_with_build($func_name)

Generate a constructor that calls BUILD if it exists. Moose/Moo compatible.
Accepts flat hash or hashref, and passes the args hash to BUILD.

    $b->new_with_build('new');
    # Supports:
    # my $obj = Class->new(name => 'Alice');
    # Calls: $obj->BUILD(\%args) if BUILD is defined

=item new_complete($func_name, \@attr_specs, $call_build)

Generate a unified constructor with full Moose/Moo-like attribute handling.
Supports required, defaults, basic types, weak refs, coercion, and BUILD in one call.

    use XS::JIT::Builder qw(:types);
    
    $b->new_complete('new', [
        {
            name     => 'id',
            required => 1,
            type     => TYPE_INT,
            type_msg => 'id must be an integer',
        },
        {
            name       => 'name',
            default_pv => 'anonymous',
        },
        {
            name       => 'items',
            default_av => 1,           # empty []
            type       => TYPE_ARRAYREF,
        },
        {
            name       => 'meta',
            default_hv => 1,           # empty {}
        },
        {
            name       => 'count',
            default_iv => 0,
        },
        {
            name => 'parent',
            weak => 1,                 # weaken stored reference
        },
        {
            name   => 'age',
            coerce => 'to_int',        # call Class->to_int($val)
        },
    ], 1);  # 1 = call BUILD if exists

Attribute spec options:

    name       - (required) Attribute name
    required   - Croak if missing or undef
    type       - TYPE_* constant for validation
    type_msg   - Error message for type failure
    weak       - Weaken stored reference (prevents circular refs)
    coerce     - Method name to call for coercion
    default_iv - Default integer value
    default_nv - Default numeric value
    default_pv - Default string value
    default_av - If true, default to empty []
    default_hv - If true, default to empty {}

Processing order: coercion → required check → type validation → 
defaults → weak refs → BUILD.

=item constructor($func_name, \@attrs)

Generate a constructor with specific attributes. Attrs is arrayref of
C<[$name, $len]> pairs or simple attribute name strings.

    $b->constructor('new', [
        ['name', 4],
        ['age', 3],
    ]);
    
    # Or with auto-calculated lengths:
    $b->constructor('new', ['name', 'age']);

=back

=head3 Accessors

=over 4

=item accessor($attr_name, \%options)

Generate a read-write accessor (or read-only with C<readonly =E<gt> 1>).
The function name is the attribute name.

    $b->accessor('name');                        # read-write
    $b->accessor('id', { readonly => 1 });       # read-only

=item ro_accessor($func_name, $attr_name, $attr_len)

Generate a complete read-only accessor function.

    $b->ro_accessor('get_name', 'name', 4);

=item rw_accessor($func_name, $attr_name, $attr_len)

Generate a complete read-write accessor function.

    $b->rw_accessor('name', 'name', 4);

=item rw_accessor_typed($func_name, $attr_name, $attr_len, $type, $error_msg)

Generate a read-write accessor with inline type validation. On set, validates
the value against the specified type and croaks with C<$error_msg> if invalid.

    use XS::JIT::Builder qw(:types);
    
    $b->rw_accessor_typed('age', 'age', 3, TYPE_INT, 'age must be an integer');
    $b->rw_accessor_typed('items', 'items', 5, TYPE_ARRAYREF, 'items must be an arrayref');

Type constants (from C<:types> export tag):

    TYPE_ANY        - No validation
    TYPE_DEFINED    - Must be defined (not undef)
    TYPE_INT        - Must be an integer
    TYPE_NUM        - Must be a number
    TYPE_STR        - Must be a string (not a reference)
    TYPE_REF        - Must be a reference
    TYPE_ARRAYREF   - Must be an arrayref
    TYPE_HASHREF    - Must be a hashref
    TYPE_CODEREF    - Must be a coderef
    TYPE_OBJECT     - Must be a blessed object

Note: C<undef> values bypass type checking (except for C<TYPE_DEFINED>).

=item rw_accessor_weak($func_name, $attr_name, $attr_len)

Generate a read-write accessor that auto-weakens stored references.
Use this for parent/owner references to prevent circular reference leaks.

    $b->rw_accessor_weak('parent', 'parent', 6);
    # $child->parent($parent);  # stored as weak reference
    # Prevents: $parent->{children} = [$child]; $child->{parent} = $parent;

The reference is weakened only if it's actually a reference. Scalars and
undef are stored normally.

=item predicate($attr_name)

Generate a predicate method (C<has_$attr_name>).

    $b->predicate('name');
    # Generates has_name() that returns true if 'name' key exists

=item clearer($attr_name)

Generate a clearer method (C<clear_$attr_name>).

    $b->clearer('cache');
    # Generates clear_cache() that deletes 'cache' key

=back

=head3 Cloning

=over 4

=item clone_hash($func_name)

Generate a shallow clone method for hash-based objects. Creates a new object
with copies of all key/value pairs, blessed into the same class.

    $b->clone_hash('clone');
    # my $copy = $obj->clone;
    # $copy is independent - modifying it doesn't affect $obj

Note: This is a shallow clone. Nested references point to the same data.

=item clone_array($func_name)

Generate a shallow clone method for array-based objects. Creates a new object
with copies of all elements, blessed into the same class.

    $b->clone_array('clone');
    # my $copy = $obj->clone;  # blessed arrayref copy

Note: This is a shallow clone. Nested references point to the same data.

=back

=head1 COMPLETE EXAMPLES

=head2 Simple Class with Accessors

    use XS::JIT;
    use XS::JIT::Builder;
    use File::Temp qw(tempdir);

    my $cache = tempdir(CLEANUP => 1);
    my $b = XS::JIT::Builder->new;

    # Constructor
    $b->xs_function('person_new')
      ->xs_preamble
      ->new_hv('hv')
      ->if('items >= 2')
        ->hv_store('hv', 'name', 4, 'newSVsv(ST(1))')
      ->endif
      ->if('items >= 3')
        ->hv_store('hv', 'age', 3, 'newSVsv(ST(2))')
      ->endif
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv("Person", GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;

    # Name accessor (read-write)
    $b->rw_accessor('person_name', 'name', 4)->blank;

    # Age accessor (read-only) 
    $b->ro_accessor('person_age', 'age', 3);

    XS::JIT->compile(
        code      => $b->code,
        name      => 'Person',
        cache_dir => $cache,
        functions => {
            'Person::new'  => { source => 'person_new', is_xs_native => 1 },
            'Person::name' => { source => 'person_name', is_xs_native => 1 },
            'Person::age'  => { source => 'person_age', is_xs_native => 1 },
        },
    );

    my $p = Person->new('Alice', 30);
    say $p->name;        # Alice
    $p->name('Bob');     # set name
    say $p->age;         # 30

=head2 Class with Inheritance

    my $b = XS::JIT::Builder->new;
    
    # Base class constructor
    $b->xs_function('animal_new')
      ->xs_preamble
      ->new_hv('hv')
      ->hv_store('hv', 'name', 4, 'items > 1 ? newSVsv(ST(1)) : newSVpv("", 0)')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv(SvPV_nolen(ST(0)), GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;
    
    # Dog constructor (overrides Animal)
    $b->xs_function('dog_new')
      ->xs_preamble
      ->new_hv('hv')
      ->hv_store('hv', 'name', 4, 'items > 1 ? newSVsv(ST(1)) : newSVpv("", 0)')
      ->hv_store('hv', 'breed', 5, 'items > 2 ? newSVsv(ST(2)) : newSVpv("mutt", 0)')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv("Dog", GV_ADD));')
      ->return_sv('self')
      ->xs_end;
    
    # Compile and set up inheritance
    XS::JIT->compile(...);
    
    package Dog;
    use parent -norequire => 'Animal';

=head2 Ultra-fast Array-based Objects with Inline Ops

For maximum performance, use array-based objects with inline ops.
This bypasses XS call overhead entirely at compile time:

    use XS::JIT;
    use XS::JIT::Builder qw(:inline);
    
    # Generate op-based accessors
    my $b = XS::JIT::Builder->new;
    $b->op_ro_accessor('get_name', 0);  # slot 0 is read-only
    $b->op_rw_accessor('age', 1);       # slot 1 is read-write
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Cat',
        cache_dir => $cache,
        functions => {
            'Cat::name' => { source => 'get_name', is_xs_native => 1 },
            'Cat::age'  => { source => 'age', is_xs_native => 1 },
        },
    );
    
    # Register inline ops for compile-time optimization
    XS::JIT::Builder::inline_init();
    XS::JIT::Builder::inline_register(\&Cat::name, INLINE_GETTER, 0);
    XS::JIT::Builder::inline_register(\&Cat::age, INLINE_SETTER, 1);
    
    # Now function calls are replaced with custom ops at compile time!
    package Cat;
    sub new { bless [$_[1], $_[2]], $_[0] }
    
    package main;
    my $cat = Cat->new('Whiskers', 3);
    say $cat->name;      # Inline op - no XS call overhead
    $cat->age(4);        # Inline setter

=head2 Inline Op Types

The following constants are available via C<:inline> export tag:

=over 4

=item INLINE_NONE (0)

No inlining.

=item INLINE_GETTER (1)

Read-only slot accessor. Replaces C<< $obj->name >> with a custom op
that reads directly from C<< $obj->[slot] >>.

=item INLINE_SETTER (2)

Read-write slot accessor. Supports both getter and setter modes.

=item INLINE_HV_GETTER (3)

Read-only hash accessor (not yet implemented).

=item INLINE_HV_SETTER (4)

Read-write hash accessor (not yet implemented).

=back

=head2 Custom Op Builder Methods

These methods generate code for building custom Perl ops, enabling
compile-time optimization through call checkers.

=head3 PP Function Builders

PP (push-pop) functions are the runtime handlers for custom ops.

=over 4

=item pp_start($name)

Start a pp function definition.

    $b->pp_start('pp_my_op');
    # Generates: OP* pp_my_op(pTHX) {

=item pp_end()

End a pp function with C<return NORMAL>.

    $b->pp_end;
    # Generates: return NORMAL; }

=item pp_dsp()

Add dSP declaration for stack access.

    $b->pp_dsp;
    # Generates: dSP;

=item pp_get_self()

Get the invocant from the stack without popping.

    $b->pp_get_self;
    # Generates: SV* self = TOPs;

=item pp_pop_self()

Pop the invocant from the stack.

    $b->pp_pop_self;
    # Generates: SV* self = POPs;

=item pp_pop_sv($name)

Pop an SV from the stack.

    $b->pp_pop_sv('value');
    # Generates: SV* value = POPs;

=item pp_pop_nv($name)

Pop a numeric value from the stack.

    $b->pp_pop_nv('amount');
    # Generates: NV amount = POPn;

=item pp_pop_iv($name)

Pop an integer value from the stack.

    $b->pp_pop_iv('count');
    # Generates: IV count = POPi;

=item pp_get_slots()

Get the slots array from self (for array-based objects).

    $b->pp_get_slots;
    # Generates: AV* slots = (AV*)SvRV(self);

=item pp_slot($name, $index)

Access a specific slot from the slots array.

    $b->pp_slot('name_sv', 0);
    # Generates: SV* name_sv = *av_fetch(slots, 0, 0);

=item pp_return_sv($expr)

Return an SV to the stack.

    $b->pp_return_sv('name_sv');
    # Generates: SETs(name_sv); RETURN;

=item pp_return_nv($expr)

Return a numeric value.

    $b->pp_return_nv('result');
    # Generates: SETn(result); RETURN;

=item pp_return_iv($expr)

Return an integer value.

    $b->pp_return_iv('count');
    # Generates: SETi(count); RETURN;

=item pp_return_pv($expr)

Return a string value.

    $b->pp_return_pv('str');
    # Generates: SETs(sv_2mortal(newSVpv(str, 0))); RETURN;

=item pp_return()

Return without modifying the stack.

    $b->pp_return;
    # Generates: return NORMAL;

=back

=head3 Call Checker Builders

Call checkers run at compile time to replace subroutine calls with custom ops.

=over 4

=item ck_start($name)

Start a call checker function.

    $b->ck_start('ck_my_method');
    # Generates: OP* ck_my_method(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {

=item ck_end()

End a call checker with fallback.

    $b->ck_end;
    # Generates: return ck_entersub_args_proto_or_list(...); }

=item ck_preamble()

Add standard call checker preamble to extract arguments.

    $b->ck_preamble;
    # Extracts pushmark, args, method from the optree

=item ck_build_unop($pp_func, $targ_expr)

Build a custom unary op (one argument).

    $b->ck_build_unop('pp_my_getter', 'slot_num');
    # Generates code to create OP_CUSTOM with the specified pp function

=item ck_build_binop($pp_func, $targ_expr)

Build a custom binary op (two arguments).

    $b->ck_build_binop('pp_my_setter', 'slot_num');

=item ck_fallback()

Fall through to default call checking.

    $b->ck_fallback;
    # Generates: return ck_entersub_args_proto_or_list(...);

=back

=head3 XOP Helpers

XOP (extended op) declarations register custom ops with Perl.

=over 4

=item xop_declare($name, $pp_func, $desc)

Declare a custom op descriptor.

    $b->xop_declare('my_xop', 'pp_my_op', 'my custom op');
    # Generates static XOP declaration and registration

=item register_checker($cv_expr, $ck_func, $ckobj_expr)

Register a call checker for a CV.

    $b->register_checker('cv', 'ck_my_method', 'newSViv(slot)');
    # Generates: cv_set_call_checker(cv, ck_my_method, ckobj);

=back

=head3 Custom Op Example

    my $b = XS::JIT::Builder->new;
    
    # Declare the XOP
    $b->xop_declare('slot_getter_xop', 'pp_slot_getter', 'slot getter');
    
    # Build the pp function
    $b->pp_start('pp_slot_getter')
      ->pp_dsp
      ->pp_get_self
      ->pp_get_slots
      ->line('IV slot = PL_op->op_targ;')
      ->pp_slot('val', 'slot')
      ->pp_return_sv('val')
      ->pp_end;
    
    # Build the call checker
    $b->ck_start('ck_slot_getter')
      ->ck_preamble
      ->ck_build_unop('pp_slot_getter', 'SvIV(ckobj)')
      ->ck_end;

=head2 Direct AvARRAY Access

These methods generate code for ultra-fast array slot access, bypassing av_fetch/av_store.
Inspired by Meow's optimized accessors.

=over 4

=item av_direct($result_var, $av_expr)

Get direct array pointer for fast slot access.

    $b->av_direct('slots', '(AV*)SvRV(self)');
    # Generates: SV** slots = AvARRAY((AV*)SvRV(self));

=item av_slot_read($result_var, $slots_var, $slot)

Read a slot value with undef fallback.

    $b->av_slot_read('val', 'slots', 0);
    # Generates: SV* val = slots[0] ? slots[0] : &PL_sv_undef;

=item av_slot_write($slots_var, $slot, $value)

Write a value to a slot with ref counting.

    $b->av_slot_write('slots', 0, 'new_val');
    # Generates proper SvREFCNT_dec and SvREFCNT_inc

=back

=head2 Type Checking

Generate type validation code. Constants can be exported via C<:types> tag.

    use XS::JIT::Builder qw(:types);
    
    $b->check_value_type('val', TYPE_ARRAYREF, undef, 'value must be an arrayref');

=over 4

=item check_value_type($sv, $type, $classname, $error_msg)

Generate a type check with croak on failure.

    $b->check_value_type('ST(1)', TYPE_HASHREF, undef, 'Expected hashref');
    # Generates: if (!(SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV)) croak(...);

Type constants:

    TYPE_ANY        - No check
    TYPE_DEFINED    - SvOK
    TYPE_INT        - SvIOK
    TYPE_NUM        - SvNOK or SvIOK
    TYPE_STR        - SvPOK
    TYPE_REF        - SvROK
    TYPE_ARRAYREF   - SvROK + SVt_PVAV
    TYPE_HASHREF    - SvROK + SVt_PVHV
    TYPE_CODEREF    - SvROK + SVt_PVCV
    TYPE_OBJECT     - sv_isobject
    TYPE_BLESSED    - sv_derived_from($classname)

=back

=head2 Lazy Initialization

Generate accessors that lazily initialize with a default value.

=over 4

=item lazy_init_dor($func_name, $attr_name, $attr_len, $default_expr, $is_mortal)

Generate lazy init accessor using //= (defined-or-assign).

    $b->lazy_init_dor('MyClass_items', 'items', 5, 'newRV_noinc((SV*)newAV())', 0);
    # sub items { $self->{items} //= [] }

=item lazy_init_or($func_name, $attr_name, $attr_len, $default_expr, $is_mortal)

Generate lazy init accessor using ||= (or-assign).

    $b->lazy_init_or('MyClass_name', 'name', 4, 'newSVpvn("default", 7)', 0);
    # sub name { $self->{name} ||= 'default' }

=item slot_lazy_init_dor($func_name, $slot, $default_expr, $is_mortal)

Slot-based lazy init with //=.

    $b->slot_lazy_init_dor('get_cache', 2, 'newRV_noinc((SV*)newHV())', 0);

=item slot_lazy_init_or($func_name, $slot, $default_expr, $is_mortal)

Slot-based lazy init with ||=.

=back

=head2 Setter Patterns

=over 4

=item setter_chain($func_name, $attr_name, $attr_len)

Generate a setter that returns $self for chaining.

    $b->setter_chain('set_name', 'name', 4);
    # $obj->set_name('foo')->set_age(42)

=item slot_setter_chain($func_name, $slot)

Slot-based setter chain.

=item setter_return_value($func_name, $attr_name, $attr_len)

Generate a setter that returns the value set.

    $b->setter_return_value('set_name', 'name', 4);
    # my $v = $obj->set_name('foo');  # $v is 'foo'

=back

=head2 Array Attribute Operations

Generate methods for manipulating array attributes in hash-based objects.

=over 4

=item attr_push($func_name, $attr_name, $attr_len)

    $b->attr_push('add_item', 'items', 5);
    # push @{$self->{items}}, @values

=item attr_pop($func_name, $attr_name, $attr_len)

    $b->attr_pop('pop_item', 'items', 5);
    # pop @{$self->{items}}

=item attr_shift($func_name, $attr_name, $attr_len)

    $b->attr_shift('shift_item', 'items', 5);
    # shift @{$self->{items}}

=item attr_unshift($func_name, $attr_name, $attr_len)

    $b->attr_unshift('prepend_item', 'items', 5);
    # unshift @{$self->{items}}, @values

=item attr_count($func_name, $attr_name, $attr_len)

    $b->attr_count('item_count', 'items', 5);
    # scalar @{$self->{items}}

=item attr_clear($func_name, $attr_name, $attr_len)

    $b->attr_clear('clear_items', 'items', 5);
    # @{$self->{items}} = ()

=back

=head2 Hash Attribute Operations

Generate methods for manipulating hash attributes.

=over 4

=item attr_keys($func_name, $attr_name, $attr_len)

    $b->attr_keys('cache_keys', 'cache', 5);
    # keys %{$self->{cache}}

=item attr_values($func_name, $attr_name, $attr_len)

    $b->attr_values('cache_values', 'cache', 5);
    # values %{$self->{cache}}

=item attr_delete($func_name, $attr_name, $attr_len)

    $b->attr_delete('delete_cache', 'cache', 5);
    # delete $self->{cache}{$key}

=item attr_hash_clear($func_name, $attr_name, $attr_len)

    $b->attr_hash_clear('clear_cache', 'cache', 5);
    # %{$self->{cache}} = ()

=back

=head2 Conditional DSL (Struct::Conditional Format)

Generate conditional C code from declarative Perl data structures. This uses
the same format as L<Struct::Conditional>, allowing you to define conditionals
as data rather than imperative code.

=over 4

=item conditional(\%struct)

Generate C code from a Struct::Conditional-compatible hashref. Supports
C<if/elsif/else> and C<given/when> patterns.

B<Basic if/else:>

    $b->conditional({
        if => {
            key  => 'num',      # C variable to test
            gt   => 0,          # expression: greater than
            then => {
                line => 'XSRETURN_IV(1);'
            }
        },
        else => {
            then => {
                line => 'XSRETURN_IV(0);'
            }
        }
    });

B<if/elsif/else chain:>

    $b->conditional({
        if => {
            key  => 'type_sv',
            eq   => 'int',
            then => { line => 'handle_int(val);' }
        },
        elsif => {
            key  => 'type_sv',
            eq   => 'str',
            then => { line => 'handle_str(val);' }
        },
        else => {
            then => { line => 'handle_default(val);' }
        }
    });

B<Multiple elsif (as arrayref):>

    $b->conditional({
        if => { key => 'n', gt => 100, then => { return_iv => '3' } },
        elsif => [
            { key => 'n', gt => 50, then => { return_iv => '2' } },
            { key => 'n', gt => 0,  then => { return_iv => '1' } },
        ],
        else => { then => { return_iv => '0' } }
    });

B<given/when (switch-style):>

    $b->conditional({
        given => {
            key => 'type_sv',
            when => {
                int     => { line => 'XSRETURN_IV(1);' },
                str     => { line => 'XSRETURN_IV(2);' },
                array   => { line => 'XSRETURN_IV(3);' },
                default => { line => 'XSRETURN_IV(0);' }
            }
        }
    });

B<given/when with array (ordered matching):>

    $b->conditional({
        given => {
            key => 'country',
            when => [
                { m => 'Thai', then => { return_iv => '1' } },
                { m => 'Indo', then => { return_iv => '2' } },
            ],
            default => { return_iv => '0' }
        }
    });

B<Logical chaining (and/or):>

    $b->conditional({
        if => {
            key => 'x',
            gt  => 0,
            and => {
                key => 'y',
                gt  => 0
            },
            then => { line => 'handle_positive_quadrant();' }
        }
    });

    $b->conditional({
        if => {
            key => 'status',
            eq  => 'active',
            or  => {
                key => 'status',
                eq  => 'pending'
            },
            then => { line => 'process();' }
        }
    });

B<Expression operators:>

    gt   => N     # SvIV(key) > N
    lt   => N     # SvIV(key) < N
    gte  => N     # SvIV(key) >= N
    lte  => N     # SvIV(key) <= N
    eq   => 'str' # strEQ(SvPV_nolen(key), "str")
    ne   => 'str' # !strEQ(...)
    m    => 'pat' # strstr(SvPV_nolen(key), "pat") != NULL
    im   => 'pat' # case-insensitive match
    nm   => 'pat' # NOT match
    inm  => 'pat' # case-insensitive NOT match
    exists => 1   # SvOK(key)
    true   => 1   # SvTRUE(key)

B<Then block actions:>

    then => { line => '...' }        # raw C line
    then => { return_iv => 'N' }     # XSRETURN_IV(N)
    then => { return_nv => 'N' }     # return double
    then => { return_pv => '"str"' } # XSRETURN_PV(str)
    then => { return_sv => 'expr' }  # return SV expression
    then => { croak => 'message' }   # croak("message")
    then => [ {...}, {...} ]         # multiple actions

=back

=head3 Complete Conditional Example

    use XS::JIT;
    use XS::JIT::Builder;

    my $b = XS::JIT::Builder->new;

    $b->xs_function('classify_number')
      ->xs_preamble
      ->declare_iv('num', 'SvIV(ST(0))')
      ->conditional({
          if => {
              key => 'num',
              gt  => 0,
              then => { return_pv => '"positive"' }
          },
          elsif => {
              key => 'num',
              lt  => 0,
              then => { return_pv => '"negative"' }
          },
          else => {
              then => { return_pv => '"zero"' }
          }
      })
      ->xs_end;

    XS::JIT->compile(
        code => $b->code,
        name => 'NumClass',
        functions => {
            'NumClass::classify' => { source => 'classify_number', is_xs_native => 1 }
        }
    );

    say NumClass::classify(42);   # "positive"
    say NumClass::classify(-5);   # "negative"
    say NumClass::classify(0);    # "zero"

=head2 Switch Statement Helper

The C<switch> method provides an optimized way to generate multi-branch conditionals
on a single key, avoiding Perl's hash duplicate-key limitation with C<elsif>. It
automatically detects whether all cases use the same comparison type and applies
optimizations.

=over 4

=item switch($key, \@cases, [\%default])

Generate optimized switch-style conditional code. The key is a C variable name,
cases is an arrayref of clause hashrefs, and default is an optional hashref of
actions for the default case.

B<Basic string switch:>

    $b->switch('type_str', [
        { eq => 'int',   then => { return_iv => '1' } },
        { eq => 'str',   then => { return_iv => '2' } },
        { eq => 'array', then => { return_iv => '3' } },
    ], { return_iv => '0' });

This generates optimized C code that:

=over 4

=item * Caches C<SvPV()> once at the start

=item * Uses C<memEQ()> with length pre-check for efficient string comparison

=item * Generates an if/elsif/else chain

=back

B<Numeric switch:>

    $b->switch('code', [
        { eq => 200, then => { return_pv => '"OK"' } },
        { eq => 404, then => { return_pv => '"Not Found"' } },
        { eq => 500, then => { return_pv => '"Server Error"' } },
    ], { return_pv => '"Unknown"' });

For numeric comparisons, this generates code that:

=over 4

=item * Caches C<SvIV()> once at the start

=item * Uses direct numeric comparison

=back

B<Range-based switch:>

    $b->switch('score', [
        { gte => 90, then => { return_pv => '"A"' } },
        { gte => 80, then => { return_pv => '"B"' } },
        { gte => 70, then => { return_pv => '"C"' } },
        { gte => 60, then => { return_pv => '"D"' } },
    ], { return_pv => '"F"' });

B<Complex switch with AND/OR:>

    $b->switch('status_code', [
        { gte => 200, lte => 299, then => { return_pv => '"success"' } },
        { gte => 300, lte => 399, then => { return_pv => '"redirect"' } },
        { gte => 400, lte => 499, then => { return_pv => '"client_error"' } },
        { gte => 500, lte => 599, then => { return_pv => '"server_error"' } },
    ], { return_pv => '"unknown"' });

=back

=head3 Complete Switch Example

    use XS::JIT;
    use XS::JIT::Builder;

    my $b = XS::JIT::Builder->new;

    $b->xs_function('get_type_id')
      ->xs_preamble
      ->declare_sv('type', 'ST(0)')
      ->switch('type', [
          { eq => 'integer', then => { return_iv => '1' } },
          { eq => 'string',  then => { return_iv => '2' } },
          { eq => 'float',   then => { return_iv => '3' } },
          { eq => 'boolean', then => { return_iv => '4' } },
          { eq => 'array',   then => { return_iv => '5' } },
          { eq => 'hash',    then => { return_iv => '6' } },
      ], { return_iv => '0' })
      ->xs_end;

    XS::JIT->compile(
        code => $b->code,
        name => 'TypeID',
        functions => {
            'TypeID::get' => { source => 'get_type_id', is_xs_native => 1 }
        }
    );

    say TypeID::get('integer');  # 1
    say TypeID::get('string');   # 2
    say TypeID::get('unknown');  # 0

=head3 Switch vs Conditional

Use C<switch> when:

=over 4

=item * You have multiple conditions on the same key

=item * All cases compare the same variable

=item * You want automatic optimization for string/numeric comparisons

=item * You want cleaner syntax without repeating the key

=back

Use C<conditional> when:

=over 4

=item * Conditions involve different variables

=item * You need complex nested AND/OR logic

=item * You're matching patterns with C<m>/C<im>

=item * You prefer the Struct::Conditional format

=back

=head2 Bulk Code Generators

These methods generate multiple related functions from a single declarative specification.

=head3 Enum/Constant Generator

=over 4

=item enum($name, \@values, [\%options])

Generate a set of related constants with validation functions. This is useful for
creating type-safe enumerated values with minimal boilerplate.

    $b->enum('Status', [qw(PENDING ACTIVE INACTIVE DELETED)]);

B<Generates the following XS functions:>

=over 4

=item * C<STATUS_PENDING()> - returns 0

=item * C<STATUS_ACTIVE()> - returns 1

=item * C<STATUS_INACTIVE()> - returns 2

=item * C<STATUS_DELETED()> - returns 3

=item * C<is_valid_status($val)> - returns true if value is valid enum (0-3)

=item * C<status_name($val)> - returns string name for numeric value

=back

B<Options:>

=over 4

=item * C<start> - Starting numeric value (default: 0)

=item * C<prefix> - Prefix for constant names (default: uc($name) . '_')

=back

    # Custom start value
    $b->enum('Priority', [qw(LOW MEDIUM HIGH CRITICAL)], { start => 1 });
    # Generates: PRIORITY_LOW => 1, PRIORITY_MEDIUM => 2, etc.

    # Custom prefix
    $b->enum('Color', [qw(RED GREEN BLUE)], { prefix => 'CLR_' });
    # Generates: CLR_RED => 0, CLR_GREEN => 1, CLR_BLUE => 2

=item enum_functions($name, $package)

Get a hashref of function definitions for use with C<XS::JIT-E<gt>compile()>.
This returns the correct mapping for all functions generated by C<enum()>.

    my $b = XS::JIT::Builder->new;
    $b->enum('Status', [qw(PENDING ACTIVE INACTIVE DELETED)]);

    my $functions = $b->enum_functions('Status', 'MyApp::Status');

    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyApp::Status',
        functions => $functions,
    );

    # Now you can use:
    print MyApp::Status::STATUS_PENDING();           # 0
    print MyApp::Status::STATUS_ACTIVE();            # 1
    print MyApp::Status::is_valid_status(2);         # true
    print MyApp::Status::status_name(1);             # "ACTIVE"

=back

=head3 Complete Enum Example

    use XS::JIT;
    use XS::JIT::Builder;
    use File::Temp qw(tempdir);

    my $cache_dir = tempdir(CLEANUP => 1);
    my $b = XS::JIT::Builder->new;

    # Generate enum for HTTP status categories
    $b->enum('HttpCategory', [qw(INFORMATIONAL SUCCESS REDIRECT CLIENT_ERROR SERVER_ERROR)]);

    XS::JIT->compile(
        code      => $b->code,
        name      => 'HTTP',
        cache_dir => $cache_dir,
        functions => $b->enum_functions('HttpCategory', 'HTTP'),
    );

    # Use the generated functions
    use constant {
        HTTP_INFORMATIONAL => HTTP::HTTPCATEGORY_INFORMATIONAL(),
        HTTP_SUCCESS       => HTTP::HTTPCATEGORY_SUCCESS(),
        HTTP_REDIRECT      => HTTP::HTTPCATEGORY_REDIRECT(),
        HTTP_CLIENT_ERROR  => HTTP::HTTPCATEGORY_CLIENT_ERROR(),
        HTTP_SERVER_ERROR  => HTTP::HTTPCATEGORY_SERVER_ERROR(),
    };

    sub categorize_status {
        my ($code) = @_;
        return HTTP_INFORMATIONAL if $code >= 100 && $code < 200;
        return HTTP_SUCCESS       if $code >= 200 && $code < 300;
        return HTTP_REDIRECT      if $code >= 300 && $code < 400;
        return HTTP_CLIENT_ERROR  if $code >= 400 && $code < 500;
        return HTTP_SERVER_ERROR  if $code >= 500 && $code < 600;
        return -1;
    }

    my $cat = categorize_status(404);
    print HTTP::is_valid_httpcategory($cat) ? "Valid" : "Invalid";  # "Valid"
    print HTTP::httpcategory_name($cat);                             # "CLIENT_ERROR"

=head3 Enum Use Cases

=over 4

=item * B<Database status fields> - Track record states (pending, active, deleted)

=item * B<State machines> - Define valid states with validation

=item * B<Configuration options> - Type-safe config values

=item * B<Protocol codes> - HTTP status codes, error codes, message types

=back

=head3 Memoization Wrapper

Generate cached versions of expensive methods. The cache is stored in an object
attribute and can be cleared at any time.

=over 4

=item memoize($func_name, [\%options])

Generate a memoized wrapper for a method. The original method must be renamed
to C<_orig_$func_name> before compilation. The wrapper checks a cache before
calling the original, stores results, and optionally supports TTL expiration.

    $b->memoize('expensive_calc');

    # With options
    $b->memoize('fetch_data', {
        cache => '_fetch_cache',  # custom cache attribute name
        ttl   => 300,             # expire after 300 seconds
    });

B<Generates the following XS functions:>

=over 4

=item * C<$func_name()> - The memoized wrapper that checks cache first

=item * C<clear_$func_name_cache()> - Clears the cache for this function

=back

B<Options:>

=over 4

=item * C<cache> - Name of the hash attribute to store cache (default: '_memoize_cache')

=item * C<ttl> - Time-to-live in seconds. If set, cached values expire after this duration.

=back

B<Cache key generation:>

The cache key is built by concatenating all arguments (except $self) with
ASCII field separator (0x1C). This handles most argument types correctly.

B<How it works:>

=over 4

=item 1. Arguments are joined to form a cache key

=item 2. Cache is checked for existing value

=item 3. If TTL is set, timestamp is verified

=item 4. On cache miss, calls C<$self-E<gt>_orig_$func_name(@args)>

=item 5. Result is stored in cache and returned

=back

=item memoize_functions($func_name, $package)

Get a hashref of function definitions for use with C<XS::JIT-E<gt>compile()>.

    my $functions = $b->memoize_functions('expensive_calc', 'MyClass');

    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyClass',
        functions => $functions,
    );

=back

=head3 Complete Memoization Example

    use XS::JIT;
    use XS::JIT::Builder;
    use File::Temp qw(tempdir);

    my $cache_dir = tempdir(CLEANUP => 1);
    my $b = XS::JIT::Builder->new;

    # Generate memoized wrapper for 'compute' method
    $b->memoize('compute', { ttl => 60 });  # 60 second TTL

    XS::JIT->compile(
        code      => $b->code,
        name      => 'Calculator',
        cache_dir => $cache_dir,
        functions => $b->memoize_functions('compute', 'Calculator'),
    );

    package Calculator;

    # The original method - renamed with _orig_ prefix
    sub _orig_compute {
        my ($self, $x, $y) = @_;
        # Expensive calculation...
        sleep 1;  # simulate slow operation
        return $x * $y;
    }

    sub new { bless {}, shift }

    package main;

    my $calc = Calculator->new;

    # First call - slow (calls _orig_compute)
    my $result1 = $calc->compute(6, 7);  # 42

    # Second call - instant (from cache)
    my $result2 = $calc->compute(6, 7);  # 42 (cached)

    # Different args - slow again
    my $result3 = $calc->compute(3, 4);  # 12

    # Clear cache
    $calc->clear_compute_cache;

    # Next call will be slow again
    my $result4 = $calc->compute(6, 7);  # 42 (recalculated)

=head3 Memoization Use Cases

=over 4

=item * B<Database query caching> - Cache expensive DB lookups

=item * B<API response caching> - Cache external API calls with TTL

=item * B<Expensive computations> - Cache results of CPU-intensive calculations

=item * B<Configuration lookups> - Cache parsed config values

=back

=head1 SEE ALSO

L<XS::JIT> - The main JIT compiler module

The C API is available in F<xs_jit_builder.h> for direct use from XS code.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
