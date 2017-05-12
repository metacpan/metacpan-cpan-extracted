# Logging::Channel
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::Conf::Logging::Channel - Class implementing the channel
subdirective of the logging directive

=head1 SYNOPSIS

    use Unix::Conf::Bind8;
    my ($conf, $channel, $ret);

    $conf = Unix::Conf::Bind8->new_conf (
        FILE        => '/etc/named.conf',
        SECURE_OPEN => 1,
    ) or $conf->die ("couldn't open `named.conf'");

    # get an existing logging object
    $channel = $conf->get_logging ()->get_channel ('some_channel')
        or $channel->die ("couldn't get channel `some_channel'");

    # assuming previous output was syslog change output to file
    # and set severity to debug at level 3
    $ret = $channel->output ('file')
        or $ret->die ("couldn't set output to `file'");
    $ret = $channel->file ('my.log')
        or $ret->die ("couldn't set file to `my.log'");
    $ret = $channel->severity ( { NAME => 'debug', LEVEL => 3 } )
        or $ret->die ("couldn't set severity");

    # also enable print-severity
    $ret = $channel->print_severity ('yes')
        or $ret->die ("couldn't enable `print-severity'");

    # and delete the `print-category' channel directive
    # not delete is not the same as disabling by setting
    # print-severity to no
    $ret = $channel->delete_print_severity ()
        or $ret->die ("couldn't delete `print-severity'");

=head1 DESCRIPTION

=over 4

=cut

package Unix::Conf::Bind8::Conf::Logging::Channel;

use strict;
use warnings;
use Unix::Conf;

use Unix::Conf::Bind8::Conf;
use Unix::Conf::Bind8::Conf::Lib;

=item new ()

 Arguments
 PARENT	=> ref to a Unix::Conf::Bind8::Conf::Logging object
 NAME   => 'channel-name',
 OUTPUT => 'value',        # syslog|file|null
 FILE   => { 
             PATH     => 'file-name', # only if OUTPUT eq 'file'
             VERSIONS => value,       # 'unlimited' | NUMBER
             SIZE     => value, # 'unlimited' | 'default' | NUMBER
           }
 SYSLOG    => 'facility-name',# only if OUTPUT eq 'syslog'
 SEVERITY  => 'severity-name',
 'PRINT-TIME'     => 'value',        # yes|no
 'PRINT-SEVERITY' => 'value',        # yes|no
 'PRINT-CATEGORY' => 'value',        # yes|no

Class constructor
Creates a new Unix::Conf::Bind8::Logging::Channel object, initializes it
and returns it on success, or an Err object on failure.

=cut

sub new
{
	my $self = shift ();
	my %args = @_;
	my $new = bless ({ DIRTY => 0 });
	my $ret;
	
	return (Unix::Conf->_err ('new', "PARENT not specified"))
		unless ($args{PARENT});
	$ret = $new->_parent ($args{PARENT}) or return ($ret);
	return (Unix::Conf->_err ('new', "channel name not specified"))
		unless ($args{NAME});
	$ret = $new->name ($args{NAME}) or return ($ret);

	if ($args{OUTPUT}) {
		$ret = $new->output ($args{OUTPUT}) or return ($ret);

		if ($args{OUTPUT} eq 'file') {
			return (Unix::Conf->_err ('output', "no arguments set for channel output 'file'"))
				unless ($args{FILE});
			$ret = $new->file (%{$args{FILE}}) or return ($ret);
		}
		elsif ($args{OUTPUT} eq 'syslog') {
			return (Unix::Conf->_err ('output', "facility not specified for channel output `syslog'"))
				unless ($args{SYSLOG});
			$new->syslog ($args{SYSLOG});
		}
	}

	$ret = $new->severity (%{$args{SEVERITY}}) or return ($ret)
		if ($args{SEVERITY});
	$ret = $new->print_category ($args{'PRINT-CATEGORY'}) or return ($ret)
		if ($args{'PRINT-CATEGORY'});
	$ret = $new->print_severity ($args{'PRINT-SEVERITY'}) or return ($ret)
		if ($args{'PRINT-SEVERITY'});
	$ret = $new->print_time ($args{'PRINT-TIME'}) or return ($ret)
		if ($args{'PRINT-TIME'});
	return ($new);
}

=item delete ()

 Arguments

Object method.
Deletes the invocant.
Returns true on success, an Err object otherwise.

=cut

sub delete
{
	my $self = $_[0];
	my $ret;

	return (Unix::Conf->_err ("delete", "channel still in use, cannot delete"))
		if (keys (%{$self->{categories}}));

	$ret = Unix::Conf::Bind8::Conf::Logging::_del_channel ($self->_parent (), $self->name ()) 
		or return ($ret);
	$self->__dirty (1);
	return (1);
}

=item name ()

 Arguments
 'CHANNEL-NAME',

Object method
Get/Set name attribute for the invoking object. 
If called with an argument, sets channel name and returns true 
on success, an Err object otherwise. Returns channel name if 
invoked without an argument.

=cut

sub name
{
	my ($self, $name) = @_;

	if (defined ($name)) {
		my $ret;
		return (UNix::Conf->_err ('name', "illegal channel name `$name'"))
			unless ($name);
		return (Unix::Conf->_err ('name', "channel `$name' is predefined"))
			if (Unix::Conf::Bind8::Conf::Logging::_is_predef_channel ($name));
		if ($self->{name}) {
			$ret = Unix::Conf::Bind8::Conf::Logging::_del_channel ($self)
				or return ($ret);
		}
		$self->{name} = $name;
		$ret = Unix::Conf::Bind8::Conf::Logging::_add_channel ($self)
			or return ($ret);
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{name} ? $self->{name} :
			Unix::Conf->_err ('name', "channel `$name' not defined")
	);
}

=item output ()

 Arguments
 'OUTPUT',             # syslog|file|null

Object method.
Get/set attributes for the invoking object. 
If called with an argument, tries to set the output to argument and 
returns true if successful, an Err object otherwise. Returns the 
currently set output if set, an Err object otherwise if called without 
an argument.

=cut

sub output
{
	my ($self, $output) = @_;

	if ($output) {
		return (Unix::Conf->_err ('output', "illegal channel output `$output'"))
			if ($output !~ /^(syslog|file|null)$/);
		$self->{output} = $output;
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{output} ? $self->{output} : 
			Unix::Conf->_err ('output', "channel output not defined")
	);
}

=item file ()

 Arguments
 PATH      => 'path_name',
 VERSIONS  => versions_allowed,  # 'unlimited' | NUMBER
 SIZE      => size_spec,         # 'unlimited' | 'default' | NUMBER

Object method.
Get/set file attributes for the invoking object.
If argument is passed, the method tries to set the file parameters and 
returns true if successful, an Err object otherwise. Returns a hash ref 
containing information in the same format as the argument, if defined, 
an Err object otherwise, if called without an argument.

=cut

sub file
{
	my $self = shift ();
	my %args = @_;

	if ($args{PATH}) {
		$self->{path} = $args{PATH};
		__valid_string ($self->{path});
		if (defined ($args{VERSIONS})) {
			return (Unix::Conf->_err ('file', "illegal versions argument `$args{VERSIONS}'"))
				if ($args{VERSIONS} !~ /^(\d+|unlimited)$/);
			$self->{versions} = $args{VERSIONS};
		}
		if (defined ($args{SIZE})) {
			return (Unix::Conf->_err ('file', "illegal size argument `$args{SIZE}'"))
				unless (__valid_sizespec ($args{SIZE}));
			$self->{size} = $args{SIZE};
		}
		$self->__dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ('file', "file path not defined"))
		unless ($self->{path});
	return ({ PATH => $self->{path}, VERSIONS => $self->{versions}, SIZE => $self->{size} });	
}

=item syslog ()

 Arguments
 facility,  # kern|user|mail|daemon|auth|syslog|lpr|news|uucp|cron
            # |authpriv|ftp|local0|local1|local2|local3|local4|local5
            # local6|local7
Object method.
Get/Set the syslog attribute of the invoking channel object. 
If called with an argument, the method tries to set the facility and 
returns true if successful, an Err object otherwise. Returns defined 
facility if called without an argument, an Err object otherwise.

=cut

sub syslog 
{
	my ($self, $syslog) = @_;

	if ($syslog) {
		return (Unix::Conf->_err ('syslog', "illegal syslog facility"))
			if ($syslog !~ /^(kern|user|mail|daemon|auth|syslog|lpr|news|uucp|cron|authpriv|ftp|local[0-7])$/);
		$self->{syslog} = $syslog;
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{syslog} ? $self->{syslog} : Unix::Conf->_err ('syslog', "syslog facility not defined")
	);
}

=item severity ()

 Arguments
 NAME   => severity, # critical|error|warning|notice|info
                     # |debug|dynamic
 LEVEL  => number,   # debug level. to be specified only if 
                     # severity is debug.

Object method
Get/Set the severity attribute of the invoking object. 
If argument is specified the method tries to set the severity and 
returns true on success, an Err object on failure. Returns defined 
severity if called without an argument, an Err object otherwise.

=cut

sub severity 
{
	my $self = shift ();
	my %args = @_;

	if ($args{NAME}) {
		return (Unix::Conf->_err ('severity', "illegal severity `$args{NAME}'"))
			if ($args{NAME} !~ /^(critical|error|warning|notice|info|debug|dynamic)$/);
		return (Unix::Conf->_err ('severity', "LEVEL can be set only for severity `debug'"))
			if ($args{LEVEL} && $args{NAME} ne 'debug');
		$self->{severity} = $args{NAME};
		$self->{level} = $args{LEVEL};
		$self->__dirty (1);
		return (1);
	}
	return (Unix::Conf->_err ('severity', "severity not defined"))
		unless ($self->{severity});
	return (return ({ NAME => $self->{severity}, LEVEL => $self->{level}}));
}

=item print_time ()

 Arguments
 yes_no,

Object method.
Get/Set attribute of the invoking Channel object. 
If argument is passed, this method tries to set the value and returns 
true on success, an Err object on failure. Returns defined value of 
'print-time' if defined, an Err object otherwise, if called without an 
argument.

=cut

sub print_time
{
	my ($self, $print) = @_;

	if ($print) {
		return (Unix::Conf->_err ('print_time', "illegal argument `$print'"))
			unless (__valid_yesno ($print));
		$self->{'print-time'} = $print;
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{'print-time'} ? $self->{'print-time'} : 
			Unix::Conf->_err ('print_time', "print-time not defined")
	);
}

=item print_category ()

 Arguments
 yes_no,

Object method.
Get/Set attribute of the invoking Channel object. 
If argument is passed, this method tries to set the value and returns 
true on success, an Err object on failure. Returns defined value of 
'print-category' if defined, an Err object otherwise, if called without 
an argument.

=cut

sub print_category
{
	my ($self, $print) = @_;

	if ($print) {
		return (Unix::Conf->_err ('print_category', "illegal argument `$print'"))
			unless (__valid_yesno ($print));
		$self->{'print-category'} = $print;
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{'print-category'} ? $self->{'print-category'} : 
			Unix::Conf->_err ('print_category', "print-category not defined")
	);
}

=item print_severity ()

 Arguments
 yes_no,

Object method.
Get/Set attribute of the invoking Channel object. 
If argument is passed, this method tries to set the value and returns 
true on success, an Err object on failure. Returns defined value of 
'print-severity' if defined, an Err object otherwise, if called 
without an argument.

=cut

sub print_severity
{
	my ($self, $print) = @_;

	if ($print) {
		return (Unix::Conf->_err ('print_severity', "illegal argument `$print'"))
			unless (__valid_yesno ($print));
		$self->{'print-severity'} = $print;
		$self->__dirty (1);
		return (1);
	}
	return (
		$self->{'print-severity'} ? $self->{'print-severity'} : 
			Unix::Conf->_err ('print_severity', "print-severity not defined")
	);
}

my %Channel_Directives = (
	'output'			=> 1,
	'severity'			=> 1,
	'print-category'	=> 1,
	'print-severity'	=> 1,
	'print-time'		=> 1,
);

=cut delete_channeldir ()

 Arguments
 'directive-name',

Tries to delete the directive specified by argument if defined. 
Returns true on success, an Err object otherwise.

=cut

sub delete_channeldir
{
	my ($self, $directive) = @_;

	return (Unix::Conf->_err ('delete_channeldir', "illegal channel directive `$directive'"))
		unless ($Channel_Directives{$directive});
	return (Unix::Conf->_err ("delete_channeldir", "channel directive `$directive' not defined"))
		unless ($self->{$directive});
	undef ($self->{$directive});
	$self->__dirty (1);
	return (1);
}

=item delete_output ()

=item delete_severity ()

=item delete_print_time ()

=item delete_print_category ()

=item delete_print_severity ()

Deletes the relevant directives and returns true, if defined, an Err object
otherwise.

=cut

for my $directive (keys (%Channel_Directives)) {
	no strict 'refs';
	my $meth = $directive;
	$meth =~ s/-/_/g;
	*{"delete_$meth"} = sub {
		my $self = $_[0];
		return (Unix::Conf->_err ("delete_$meth", "channel directive `$directive' not defined"))
			unless ($self->{$directive});
		undef ($self->{$directive});
		$self->__dirty (1);
		return (1);
	};
}

=item categories ()

Object method.
Returns the categories that have defined this channel. In scalar context
returns the number of categories, returns a list of category names in list
context.

=cut

sub categories ()
{
	return (keys (%{$_[0]->{categories}}));
}

sub _add_category ()
{
	my $self = shift ();

	return (Unix::Conf->_err ("_add_category", "categories to be added not passed"))
		unless (@_);
	
	@{$self->{categories}}{@_} = (1) x @_;
	return (1);
}

sub _delete_category ()
{
	my $self = shift ();

	return (Unix::Conf->_err ("_delete_category", "categories to be deleted not passed"))
		unless (@_);

	for (@_) {
		return (
			Unix::Conf->_err (
				"_delete_category", 
				sprintf ("category `$_' does not use %s", $self->name ())
			)
		) unless ($self->{categories}{$_});
	}
	delete (@{$self->{categories}}{@_});
	return (1);
}

sub __render 
{
	my $self = $_[0];
	my ($tmp, $rendered);

	$rendered = sprintf ("\tchannel %s {\n", $self->name ());
	if (($tmp = $self->output ()) eq 'file') {
		my $file;
		$file = $self->file () or return ($file);
		$rendered .= qq (\t\tfile "$file->{PATH}");
		$rendered .= " versions $file->{VERSIONS}"
			if ($file->{VERSIONS});
		$rendered .= " size $file->{SIZE}"
			if ($file->{SIZE});
		$rendered .= ";\n";
	}
	elsif ($tmp eq 'syslog') {
		# while the syntax in the man page indicates that
		# a syslog facility is mandatory, the sample named.conf
		# file that comes with named-8.2.3 has just such an
		# example
		my $facility;
		$rendered .= "\t\tsyslog";
		$rendered .= " $facility"
			if (($facility = $self->syslog ()));
		$rendered .= ";\n";
	}
	elsif ($tmp eq 'null') {
		$rendered .= "\t\tnull;\n";
	}

	if (($tmp = $self->severity ())) {
		$rendered .= "\t\tseverity $tmp->{NAME}";
		$rendered .= " $tmp->{LEVEL}"
			if ($tmp->{LEVEL});
		$rendered .= ";\n";
	}
	$rendered .= "\t\tprint-category $tmp;\n"
		if (($tmp = $self->print_category ()));
	$rendered .= "\t\tprint-severity $tmp;\n"
		if (($tmp = $self->print_severity ()));
	$rendered .= "\t\tprint-time $tmp;\n"
		if (($tmp = $self->print_time ()));
	$rendered .= "\t};\n";
	return ($rendered);
}

sub __dirty
{
	if (defined ($_[1])) {
		$_[0]->{PARENT}->dirty ($_[1]);
		return (1);
	}
	return ($_[0]->{PARENT}->dirty ());
}

# Stores the Logging object.
sub _parent
{
	my ($self, $parent) = @_;

	if ($parent) {
		# Do not allow resetting the PARENT ref. We don't use
		# PARENT for anything else except calling the dirty method.
		return (Unix::Conf->_err ('__parent', "PARENT already defined. Cannot reset"))
			if ($self->{PARENT});
		$self->{PARENT} = $parent;
		return (1);
	}
	return (
		$self->{PARENT} ? $self->{PARENT} : 
			Unix::Conf->_err ('_parent', "PARENT not defined")
	);
}

1;
__END__
