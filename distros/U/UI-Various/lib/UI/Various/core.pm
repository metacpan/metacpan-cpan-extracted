package UI::Various::core;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::core - core functions of L<UI::Various>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various;

=head1 ABSTRACT

This module is the main worker module for the L<UI::Various> package.

=head1 DESCRIPTION

The documentation of this module is mainly intended for developers of the
package itself.

Basically the module is a singleton providing a set of functions to be used
by the other modules of L<UI::Various>.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Carp;
use Storable ();

our $VERSION = '0.44';

use UI::Various::language::en;

#########################################################################

=head1 EXPORT

No data structures are exported, the core module is only accessed via its
functions (and initialised with the L<import|/import - initialisation of
UI::Various package> method indirectly called via C<use UI::Various;>).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;

our @ISA = qw(Exporter);
# 1st row: public functions of the package UI::Various
# 2nd/3rd row: internal functions of the package UI::Various
our @EXPORT = qw(language logging stderr using
		 fatal error warning info debug message msg
		 construct access set get access_varref dummy_varref);

#########################################################################
#
# internal constants and data:

use constant _ROOT_PACKAGE_ => substr(__PACKAGE__, 0, rindex(__PACKAGE__, "::"));

use constant UI_ELEMENTS =>
    qw(Box Button Check Dialog Input Listbox Main Optionmenu Radio Text Window);

use constant COMPOUND_ELEMENTS => (map {('Compound::' . $_)} qw(FileSelect));

our @CARP_NOT =
    (	_ROOT_PACKAGE_,
	map {( _ROOT_PACKAGE_ . '::' . $_ )}
	(qw(core base container),
	 map {( $_, "Tk::$_", "Curses::$_", "RichTerm::$_", "PoorTerm::$_" )}
	 UI_ELEMENTS,
	 COMPOUND_ELEMENTS)
    );

# global data-structure holding internal configuration:
my $UI =
{
 log => 1,			# see constant array LOG_LEVELS below
 language => 'en',
 stderr => 0,			# 0: immediate, 2: on exit, 3: suppress
 messages => '',		# stored messages
 T				# reference to all text strings
 => \%UI::Various::language::en::T,
};

# currently supported packages (GUI, terminal-based and last-resort):
use constant GUI_PACKAGES => qw(Tk);
use constant TERM_PACKAGES => qw(Curses RichTerm);
use constant FINAL_PACKAGE => 'PoorTerm';
use constant UNIT_TEST_PACKAGE => '_Zz_Unit_Test'; # only used in test regexp;
# currently supported languages:
use constant LANGUAGES => qw(en de);

# logging levels (with 2 aliases):
use constant LOG_LEVELS =>
    qw(FATAL ERROR WARN INFO DEBUG_1 DEBUG_2 DEBUG_3 DEBUG_4);

# which package identifier must checked with which Perl module:
use constant PACKAGE_MAP =>
    ('Tk' => 'Tk',
     'Curses' => 'Curses::UI',
     # note that both *Term use only Perl core modules, so both should load
     # successful with those examples here:
     'RichTerm' => 'Term::ANSIColor',
     'PoorTerm' => 'Term::ReadLine',
     # this dummy package is only used for failing unit tests:
     '_Zz_Unit_Test' => 'ZZ::Unit::Test',
    );

use constant PACKAGES => (GUI_PACKAGES, TERM_PACKAGES);

my $re_languages = '^' . join('|', LANGUAGES) . '$';
my %log_level = ();
{
    my $n = 0;
    %log_level = map { ($_ => $n++) } LOG_LEVELS;
}
$log_level{WARNING} = $log_level{WARN};
$log_level{INFORMATION} = $log_level{INFO};

#########################################################################
#########################################################################

=head1 METHODS and FUNCTIONS

=cut

#########################################################################

=head2 B<import> - initialisation of L<UI::Various> package

see L<UI::Various::import|UI::Various/import - import and initialisation of
UI::Various package>

Otherwise this method just exports the core functions to our other modules.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
    my $re_packages =
	'^' . join('|', PACKAGES,  FINAL_PACKAGE, UNIT_TEST_PACKAGE) . '$';
    my $re_gui_packages = '^' . join('|', GUI_PACKAGES) . '$';
    my $re_gui_pt_packages = '^' . join('|', GUI_PACKAGES,  FINAL_PACKAGE) . '$';
    my %ui_map = PACKAGE_MAP;

    sub import($;%)
    {
	my ($pkg, $rh_options) = @_;
	local $_;

	# checks (using standard croak during initialisation only!):
	ref($pkg)  and
	    fatal('bad_usage_of__1_pkg_is__2', __PACKAGE__, ref($pkg));
	$pkg eq __PACKAGE__  or
	    fatal('bad_usage_of__1_as__2', __PACKAGE__, $pkg);

	# manual export as we use own import method:
	UI::Various::core->export_to_level(1, $pkg, @EXPORT);

	# unless during initialisation in main module we ignore options and
	# check only that we are already initialised:
	my $caller = (caller())[0];
	unless ($caller eq _ROOT_PACKAGE_)
	{
	    # Q&D: special exception to avoid failing "testpodcoverage":
	    # uncoverable branch true
	    # uncoverable condition false
	    unless (defined(caller(4))  and  (caller(4))[0]  eq  'Pod::Coverage')
	    {
		defined $UI->{ui}  or
		    fatal('ui_various_core_must_be_1st_used_from_ui_various');
		return;
	    }
	    else		# else needed for correct coverage handling
	    {
		# needed for the "require" in other modules' "testpodcoverage",
		# in addition it sometimes is counted by coverage without being
		# run at all:
		$rh_options->{use} = [];
	    }
	}

	# check options:
	my @packages = PACKAGES;
	my $stderr = 0;
	my $include = 'all';
	if (defined $rh_options)
	{
	    ref($rh_options) eq 'HASH'  or
		fatal('options_must_be_specified_as_hash');
	    foreach (sort keys %$rh_options)
	    {
		if ($_ eq 'use')
		{
		    ref($rh_options->{$_}) eq 'ARRAY'  or
			fatal('use_option_must_be_an_array_reference');
		    foreach my $ui (@{$rh_options->{$_}})
		    {
			$ui =~ m/$re_packages/o  or
			    fatal('unsupported_ui_package__1', $ui);
		    }
		    @packages = @{$rh_options->{$_}};
		}
		elsif ($_ eq 'include')
		{   $include = $rh_options->{$_};   }
		elsif ($_ eq 'log')
		{
		    my $level = uc($rh_options->{$_});
		    defined $log_level{$level}  or
			fatal('undefined_logging_level__1', $level);
		    logging($rh_options->{$_});
		}
		elsif ($_ eq 'language')
		{
		    $rh_options->{$_} =~ m/$re_languages/o  or
			fatal('unsupported_language__1', $rh_options->{$_});
		    language($rh_options->{$_});
		}
		elsif ($_ eq 'stderr')
		{
		    $rh_options->{$_} =~ m/^[0-3]$/  or
			fatal('stderr_not_0_1_2_or_3');
		    $stderr = $rh_options->{$_};
		}
		else
		{
		    fatal('unknown_option__1', $_);
		}
	    }
	}

	# now check which package can actually be used:
	$ENV{UI}  and  unshift @packages, $ENV{UI};
	push @packages, FINAL_PACKAGE;
	foreach my $use (@packages)
	{
	    next if $use =~ m/$re_gui_packages/o  and  not $ENV{DISPLAY};
	    my $uipkg = $ui_map{$use};
	    debug(1, 'testing:   ', $use, ' / ', $uipkg);
	    if (eval "require $uipkg")
	    {
		info('using__1_as_ui', $use);
		$UI->{using} = $use;
		$UI->{is_gui} = $use =~ m/$re_gui_packages/o ? 1 : 0;
		$UI->{_is_gui_pt} = $use =~ m/$re_gui_pt_packages/o ? 1 : 0;
		$UI->{ui} = _ROOT_PACKAGE_ . '::' . $use;
		last;
	    }
	}

	# now we really know how to STDERR (e.g. for value 1):
	stderr($stderr);

	# finally we can import the automatically included modules:
	if (ref($include) eq '')
	{
	    if ($include eq 'all')
	    {   $include = [ UI_ELEMENTS, COMPOUND_ELEMENTS ];   }
	    elsif ($include eq 'none')
	    {   $include = [];   }
	    else
	    {   $include = [ $include ];   }
	}
	ref($include) eq 'ARRAY'  or
	    fatal('include_option_must_be_an_array_reference_or_a_scalar');
	foreach (@{$include})
	{
	    $_ = _ROOT_PACKAGE_ . '::' . $_;
	    unless (eval "require $_")
	    {   fatal('unsupported_ui_element__1__2', $_, $@);   }
	    $_->import;
	}
    }
}

#########################################################################

=head2 B<language> - get or set currently used language

internal implementation of L<UI::Various::language|UI::Various/language -
get or set currently used language>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub language(;$)
{
    my ($new_language) = @_;

    if (defined $new_language)
    {
	if ($new_language !~ m/$re_languages/o)
	{   error('unsupported_language__1', $new_language);   }
	else
	{
	    $UI->{language} = $new_language;
	    local $_ = _ROOT_PACKAGE_ . '::language::' . $new_language;
	    eval "require $_";	# require with variable needs eval!
	    $_ .= '::T';
	    no strict 'refs';
	    $UI->{T} = \%$_;
	}
    }
    return $UI->{language};
}

#########################################################################

=head2 B<logging> - get or set currently used logging-level

internal implementation of L<UI::Various::logging|UI::Various/logging -
get or set currently used logging-level>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub logging(;$)
{
    my ($new_level) = @_;

    if (defined $new_level)
    {
	local $_ = $log_level{uc($new_level)};
	if (defined $_)
	{   $UI->{log} = $_;   }
	else
	{   error('undefined_logging_level__1', $new_level);   }
    }
    return (LOG_LEVELS)[$UI->{log}];
}

#########################################################################

=head2 B<stderr> - get or set currently used handling of output

internal implementation of L<UI::Various::stderr|UI::Various/stderr -
get or set currently used handling of output>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
    my $orgerr = undef;

    sub stderr(;$)
    {
	my ($new_value) = @_;

	if (defined $new_value)
	{
	    if ($new_value !~ m/^[0-3]$/)
	    {
		error('stderr_not_0_1_2_or_3');
	    }
	    else
	    {
		if ($new_value == 1)
		{
		    $new_value = $UI->{_is_gui_pt} ? 0 : 2;
		}
		if ($new_value != $UI->{stderr})
		{
		    if ($UI->{stderr} == 0  and  not defined $orgerr)
		    {
			unless (open $orgerr, '>&', \*STDERR)
			{
			    # errors can't use standard messaging here:
			    print "\n***** can't duplicate STDERR: $! *****\n";
			    die;
			}
		    }
		    close STDERR;
		    my $rop = $new_value == 0 ? '>&' : '>>';
		    my $rc =
			open STDERR, $rop, ($new_value == 3 ? '/dev/null' :
					    $new_value == 2 ? \$UI->{messages} :
					    $orgerr);
		    # uncoverable branch true
		    if ($rc == 0)
		    {
			# errors can't use standard messaging here (like
			# above we have a paradox; the statement is covered
			# while the branch is not):
			print "\n***** can't redirect STDERR: $! *****\n";
		    }
		    binmode(STDERR, ':utf8');
		    if ($UI->{stderr} == 2  and  $new_value == 0)
		    {
			print STDERR $UI->{messages};
		    }
		    $UI->{messages} = '';
		    $UI->{stderr} = $new_value;
		}
	    }
	}
	return $UI->{stderr};
    }
}
END {
    stderr(0);
}

#########################################################################

=head2 B<using> - get currently used UI as text string

internal implementation of L<UI::Various::using|UI::Various/using - get
currently used UI>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub using()
{
    return $UI->{using};
}

#########################################################################

=head2 B<ui> - get currently used UI

    $interface = UI::Various::core::ui();

=head3 example:

    $_ = UI::Various::core::ui() . '::Main::_init';
    {   no strict 'refs';   &$_($self);   }

=head3 description:

This function returns the full name of the currently used user interface,
e.g. to access its methods.

=head3 returns:

full name of UI

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub ui(;$)
{
    return $UI->{ui};
}

#########################################################################

=head2 B<fatal> - abort with error message

    fatal($message_id, @message_data);

=head3 example:

    fatal('bad_usage_of__1_as__2', __PACKAGE__, $pkg);
    fatal('UI__Various__core_must_be_1st_used_from_UI__Various');

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

This function looks up the format (or simple) string passed in
C<$message_id> in the text hash of the currently used language, formats it
together with the C<@message_data> with sprintf and passes it on to
C<L<croak|Carp>>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub fatal($;@)
{
    my $message_id = shift;
    local $_ = sprintf(msg($message_id), @_); # using $_ to allow debugging
    croak($_);
}

#########################################################################

=head2 B<error> / B<warning> / B<info> - print error / warning / info message

    error($message_id, @message_data);
    warning($message_id, @message_data);
    info($message_id, @message_data);

=head3 example:

    warning('message__1_missing_in__2', $message_id, $UI->{language});

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

If the current logging level is lower than C<ERROR> / C<WARNING> / C<INFO>
these functions do nothing.  Otherwise they print the formatted message
using C<_message>.

C<_message> has logging level to be printed as additional 1st parameter.  It
checks the logging level, looks up the format (or simple) string passed in
C<$message_id> in the text hash of the currently used language, formats the
latter together with the C<@message_data> with sprintf and passes it on to
C<L<carp|Carp>> (in case of errors or warnings) or C<L<warn|perlfunc/warn>>
(in case of informational messages).

=head3 returns:

always C<undef> (to allow something like C<return error(...);> indicating
the error to the caller)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub error($;@)   {   _message(1, @_);   }
sub warning($;@) {   _message(2, @_);   }
sub info($;@)    {   _message(3, @_);   }

sub _message($$;@)
{
    my $level = shift;
    return undef if $UI->{log} < $level;

    my $message_id = shift;
    local $_ = msg($message_id);
    $_ = sprintf($_, @_)  unless  $_ eq $message_id;
    if ($level < 3  and  $_ !~ m/\n\z/)
    {   carp($_);   }
    else
    {   warn $_;   }
    return undef;
}

#########################################################################

=head2 B<message> - return formatted message

    $string = message($message_id, @message_data);

=head3 example:

    $_ = message('can_t_open__1__2', $_, $!);

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

This function just returns the formatted message for the given
C<$message_id> and C<@message_data>, e.g. to be used within a compound
widget.

=head3 returns:

the formatted message as string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub message($;@)
{
    my $message_id = shift;
    local $_ = msg($message_id);
    $_ = sprintf($_, @_)  unless  $_ eq $message_id;
    return $_;
}

#########################################################################

=head2 B<debug> - print debugging message

    debug($level, @message);

=head3 example:

    debug(1, __PACKAGE__, '::new');

=head3 parameters:

    $level              debug-level of the message (>= 1)
    @message            the text to be printed

=head3 description:

If the current logging level is lower than C<DEBUG_n> (with C<n> being the
C<$level> specified in the call) this function does nothing.  Otherwise it
prints the given text.  Note that debugging messages are always English, so
they can be added / removed / changed anytime without bothering about the
C<UI::Various::language> modules.  Also note that debug messages are printed
with C<L<warn|perlfunc/warn>> and prefixed with C<DEBUG> and some blanks
according to the debug-level.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub debug($$;@)
{
    my $level = shift;
    unless ($level =~ m/^\d$/  and  $level > 0)
    {
	error('bad_debug_level__1', $level);
	return;
    }
    return if $UI->{log} < $level + 3;
    local $_ = '  ' x --$level;
    my $message = join('', @_);
    $message =~ s/\n\z//;
    $message =~ s/\n/\n\t$_/g;
    warn "DEBUG\t", $_, $message, "\n";
}

#########################################################################

=head2 B<msg> - look-up text for currently used language

    $message = msg($message_id);

=head3 example:

    $_ = sprintf(msg($message_id), @_);

=head3 parameters:

    $message_id         ID of the text or format string in language module

=head3 description:

This method looks up the format (or simple) string passed in C<$message_id>
in the text hash of the currently used language and returns it.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub msg($)
{
    my ($message_id) = @_;

    if (defined $UI->{T}{$message_id}  and  $UI->{T}{$message_id} ne '')
    {
	return $UI->{T}{$message_id};
    }
    # for missing message we try a fallback to English, if possible:
    if ($UI->{language} ne 'en')
    {
	warning('message__1_missing_in__2', $message_id, $UI->{language});
	defined $UI::Various::language::en::T{$message_id}
	    and  return $UI::Various::language::en::T{$message_id};
    }
    error('message__1_missing_in__2', $message_id, 'en');
    return $message_id;
}

#########################################################################

=head2 B<construct> - common constructor for UI elements

    $ui_element = UI::Various::Element->new(%attributes);

=head3 example:

    $ui_element = UI::Various::Element->new();
    $ui_element = UI::Various::Element->new(attr1 => $val1, attr2 => $val2);
    $ui_element = UI::Various::Element->new({attr1 => $val1, attr2 => $val2});

=head3 parameters:

    %attributes         optional hash with initial attribute values

=head3 description:

This function contains the common constructor code of all UI element classes
( C<UI::Various::[A-Z]*>).  Initial values can either be passed as an array
of key/value pairs or as a single reference to a hash containing those
key/value pairs.  Note that if the class defines a (private) setter method
C<_attr> (tried 1st) or a (public) accessor C<attr> (tried 2nd), it is used
to assign the value before falling back to a simple assignment.

The internal implementation has the following interface:

    $self = construct($attributes, $re_allowed_params, $self, @_);

It is used like this:

    sub new($;\[@$])
    {
        return construct({ DEFAULT_ATTRIBUTES },
                         '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
                         @_);
    }

The additional parameters are:

    $attributes           reference to hash with default attributes
    $re_allowed_params    regular expression matching all allowed parameters

    $self                 name of class or reference to other element of class
    @_                    parameters passed to caller's C<new>

=head3 returns:

blessed new UI element

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub construct($$@)		# not $$$@, that may put $self in wrong context!
{
    local ($Storable::Deparse, $Storable::Eval) = (1, 1);
    my $attributes = Storable::dclone(shift);
    my $re_allowed_parameters = shift;
    my $self = shift;
    my $class = ref($self) || $self;
    local $_;

    # sanity checks:
    ref($attributes) eq 'HASH'
	or  fatal('invalid_parameter__1_in_call_to__2',
		  '$attributes', (caller(1))[3]);
    ref($re_allowed_parameters) eq ''
	or  fatal('invalid_parameter__1_in_call_to__2',
		  '$re_allowed_parameters', (caller(1))[3]);
    $self->isa((caller(0))[0])
	or  fatal('invalid_object__1_in_call_to__2',
		  ref($self), (caller(1))[3]);

    # create (correct!) object:
    unless ($class =~ m/::Compound::/)
    {
	$class =~ s/.*:://;
	$class = ui() . '::' . $class;
    }
    $self = bless $attributes, $class;

    # handle optional initial attribute values:
    my $parameters = {};
    if (@_ == 1)
    {
	if (ref($_[0]) eq 'HASH')
	{   $parameters = $_[0];   }
	elsif (ref($_[0]) eq '')
	{   fatal('invalid_scalar__1_in_call_to__2', $_[0], (caller(1))[3]);   }
	else
	{
	    fatal('invalid_object__1_in_call_to__2',
		  ref($_[0]), (caller(1))[3]);
	}
    }
    elsif (@_ % 2 != 0)
    {
	fatal('odd_number_of_parameters_in_initialisation_list_of__1',
	      (caller(1))[3]);
    }
    else
    {
	$parameters = {@_};
    }
    foreach my $key (keys %$parameters)
    {
	$key =~ m/$re_allowed_parameters/
	    or  fatal('invalid_parameter__1_in_call_to__2',
		      $key, (caller(1))[3]);
	if ($self->can("_$key"))
	{   $_ = "_$key"; $_ = $self->$_($parameters->{$key});   }
	elsif ($self->can($key))
	{   $_ = $self->$key($parameters->{$key});   }
	else
	{   $attributes->{$key} = $parameters->{$key};   }
    }
    return $self;
}

#########################################################################

=head2 B<access> - common accessor for UI elements

    $value = $ui_element->attribute();
    $ui_element->attribute($value);

=head3 parameters:

    $value              optional value to be set

=head3 description:

This function contains the common accessor code of all UI element classes (
C<UI::Various::[A-Z]*>) aka implementing a combined standard getter /
setter.  When it's called with a value, the attribute is set.  In all cases
the current (after modification, if applicable) value is returned.  If the
value is a SCALAR reference it is stored as reference but returned as value.

The internal implementation has the following interface:

    $value = access($attribute, $sub_set, $self, $new_value);

It is used like this:

    sub attribute($;$)
    {
        return access('attribute', sub{ ... }, @_);
    }

    or simply

    sub attribute($;$)
    {
        return access('attribute', undef, @_);
    }

The additional parameters are:

    $attribute            name of the attribute
    $sub_set              optional reference to a subroutine called when
                          the function is used as a setter (see below)

    $self                 reference to the class object
    @_                    the optional new value and possible other parameters
                          passed to C<$sub_set>

The optional subroutine gets the new value passed in C<$_> and must return
the value to be set in C<$_> as well.  To allow for complicated tests and/or
side-effects it gets C<$self> and possible additional parameters passed in
C<@_>.  The return value of the subroutine itself decides, if the attribute
is modified: If it's C<undef>, the previous value is kept.  In all other
cases the attribute gets the new value as defined in C<$_>.  Note that the
subroutine gets the value even in case of a SCALAR reference.

If no additional code is needed, the parameter can be C<undef> as in the 2nd
example above.

=head3 returns:

the current value of the attribute (SCALAR references are dereferenced)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub access($$@)		# not $$$;@, that may put $self in wrong context!
{
    # additional parameter "attribute" is much cheaper than "(caller(0))[3]"
    # followed by "s/^.*::_?//":
    my $attribute = shift;
    my $sub_set = shift;
    my $self = shift;

    # sanity checks:
    $self->isa((caller(0))[0])
	or  fatal('invalid_object__1_in_call_to__2',
		  ref($self), (caller(1))[3]);
    defined $sub_set  and  ref($sub_set) ne 'CODE'
	and  fatal('invalid_parameter__1_in_call_to__2',
		   '$sub_set', (caller(1))[3]);

    # handle setter part, if applicable:
    if (exists $_[0])
    {
	my $val = shift;
	local $_ = ref($val) eq 'SCALAR' ? $$val : $val;
	if (defined $sub_set)
	{   defined &$sub_set($self, @_)  or  return $self->{$attribute};   }
	if (ref($val) eq 'SCALAR')
	{
	    $$val = $_;
	    # Curses needs to keep track of the references:
	    $self->can('_reference')  and  $self->_reference($val);
	}
	else
	{   $val = $_;   }
	$self->{$attribute} = $val;
    }
    return (ref($self->{$attribute}) eq 'SCALAR'
	    ? ${$self->{$attribute}}
	    :   $self->{$attribute});
}

#########################################################################

=head2 B<set> - common setter for UI elements

    $ui_element->attribute($value);

=head3 parameters:

    $value              mandatory value to be set

=head3 description:

This function contains the common setter code of all UI element classes (
C<UI::Various::[A-Z]*>).  Basically it's an accessor with a mandatory value
to be set.  Like C<L<access|/access - common accessor for UI elements>> it
returns the updated value.  If the value is a SCALAR reference it is
stored as reference but returned as value.

The internal implementation has the following interface:

    $value = set($attribute, $sub_set, $self, $new_value);

It is used like this:

    sub _attribute($$)
    {
        return set('attribute', sub{ ...; }, @_);
    }

    or simply

    sub _attribute($$)
    {
        return set('attribute', undef, @_);
    }

The additional parameters are:

    $attribute            name of the attribute
    $sub_set              optional reference to a subroutine called within the
                          setter

    $self                 name of class or reference to other element of class
    @_                    the new value and possible other parameters passed
                          to C<$sub_set>

The optional subroutine gets the new value passed in C<$_> and must return
the value to be set in C<$_> as well.  To allow for complicated tests and/or
side-effects it gets C<$self> and possible additional parameters passed in
C<@_>.  The return value of the subroutine itself decides, if the attribute
is modified: If it's C<undef>, the previous value is kept.  In all other
cases the attribute gets the new value as defined in C<$_>.  Note that the
subroutine gets the value even in case of a SCALAR reference.

If no additional code is needed, the parameter can be C<undef> as in the 2nd
example above.

=head3 returns:

the new value of the attribute (SCALAR references are dereferenced)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub set($$@)		    # not $$$@, that may put $self in wrong context!
{
    my $attribute = shift;
    my $sub_set = shift;
    my $self = shift;

    # sanity checks:
    $self->isa((caller(0))[0])
	or  fatal('invalid_object__1_in_call_to__2',
		  ref($self), (caller(1))[3]);
    defined $sub_set  and  ref($sub_set) ne 'CODE'
	and  fatal('invalid_parameter__1_in_call_to__2',
		   '$sub_set', (caller(1))[3]);

    # handle setter part, if applicable:
    my $val = shift;
    local $_ = ref($val) eq 'SCALAR' ? $$val : $val;
    if (defined $sub_set)
    {   defined &$sub_set($self, @_)  or  return $self->{$attribute};   }
    if (ref($val) eq 'SCALAR')
    {
	$$val = $_;
	# Curses needs to keep track of the references:
	$self->can('_reference')  and  $self->_reference($val);
    }
    else
    {   $val = $_;   }
    $self->{$attribute} = $val;
    return (ref($self->{$attribute}) eq 'SCALAR'
	    ? ${$self->{$attribute}}
	    :   $self->{$attribute});
}

#########################################################################

=head2 B<get> - common getter for UI elements

    $value = $ui_element->attribute();

=head3 description:

This function contains the common getter code of all UI element classes (
C<UI::Various::[A-Z]*>), implementing a very simple getter returning the
current value of the attribute (but still with all sanity checks).  Note
that if the attribute is a SCALAR reference it is nonetheless returned as
value.  (If you really need the reference itself, access it directly as
C<$ui_element->{attribute}>.)

The internal implementation has the following interface:

    $value = get($attribute, $self);

It is used like this:

    sub attribute($) { return get('attribute', @_); }

The additional parameters are:

    $attribute            name of the attribute

    $self                 name of class or reference to other element of class

=head3 returns:

the current value of the attribute (SCALAR references are dereferenced)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub get($@)		      # not $$, that may put $self in wrong context!
{
    my $attribute = shift;
    my $self = shift;

    # sanity checks:
    $self->isa((caller(0))[0])
	or  fatal('invalid_object__1_in_call_to__2',
		  ref($self), (caller(1))[3]);

    return (ref($self->{$attribute}) eq 'SCALAR'
	    ? ${$self->{$attribute}}
	    :   $self->{$attribute});
}

#########################################################################

=head2 B<access_varref> - special accessor for UI elements needing SCALAR ref.

    $value = $ui_element->attribute();
    $ui_element->attribute(\$variable);

=head3 parameters:

    $variable           optional SCALAR reference to be set

=head3 description:

This function contains a variant of the common accessor L<access|/access -
common accessor for UI elements> that is used by attributes needing a SCALAR
reference to a variable.  Those still always return the current value of the
variable when used as getter, but the setter directly uses the SCALAR
reference.

The internal implementation has the following interface (note the missing
subroutine):

    $value = access_varref($attribute, $self, $new_value);

It is used like this:

    sub attribute($;$)
    {
        return access_varref('attribute', @_);
    }

The additional parameters are:

    $attribute            name of the attribute
    $self                 reference to the class object
    $r_variable           the optional SCALAR reference

=head3 returns:

the current value of the attribute (the SCALAR reference is dereferenced)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub access_varref($@)	# not $$$;@, that may put $self in wrong context!
{
    my $attribute = shift;
    my $self = shift;

    # sanity checks:
    $self->isa((caller(0))[0])
	or  fatal('invalid_object__1_in_call_to__2',
		  ref($self), (caller(1))[3]);

    # handle setter part, if applicable:
    if (exists $_[0])
    {
	unless (ref($_[0]) eq 'SCALAR')
	{
	    error('_1_attribute_must_be_a_2_reference',
		  $attribute, 'SCALAR');
	    return undef;
	}
	my $varref = shift;
	$self->{$attribute} = $varref;
	# Curses needs to keep track of the references:
	$self->can('_reference')  and  $self->_reference($varref);
    }
    return ${$self->{$attribute}};
}

#########################################################################

=head2 B<dummy_varref> - create a dummy SCALAR reference

    $scalar = dummy_varref();

=head3 description:

This function returns a SCALAR reference to a dummy variable initialised
with an empty string.  Note that each call returns a reference to a
different variable.  The function can be used to initialise C<use constant>
constants.

=head3 returns:

a scalar reference to an empty variable

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BEGIN {
    sub dummy_varref()
    {   my $dummy = '';   return \$dummy;   }
}

# TODO L8R: add option to disable sanity checks

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
