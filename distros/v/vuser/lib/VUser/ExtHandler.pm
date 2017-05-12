package VUser::ExtHandler;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ExtHandler.pm,v 1.51 2007-09-24 20:16:06 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.51 $'))[1];
our $VERSION = "0.5.0";

use lib qw(..);
use Getopt::Long;
use VUser::ExtLib;
use VUser::Meta;
use VUser::Log qw(:levels);

use Regexp::Common qw /number/;
#use Regexp::Common qw /number RE_ALL/;

sub DEFAULT_PRIORITY { 10; }

my $log;

sub new
{

    my $self = shift;
    my $class = ref($self) || $self;
    my $cfg = shift;
    $log = shift;

    if (not defined $log
	and defined $main::log
	and UNIVERSAL::isa($main::log, 'VUser::Log')
	) {
	$log = $main::log;
    } elsif (defined $log
	     and UNIVERSAL::isa($log, 'VUser::Log')
	     ) {
	# noop
    } else {
	$log = VUser::Log->new($cfg, 'vuser/eh');
    }

    # {keyword}{action}{tasks}[order][tasks (sub refs)]
    # {keyword}{action}{options}{option} = type
    # {keyword}{_meta}{option} = VUser::Meta
    my $me = {'keywords' => {},
	      'required' => {},
	      'descrs' => {},
	  };

    bless $me, $class;

    #$me->load_extensions(%$cfg);

    return $me;
}

sub register_keyword
{
    my $self = shift;
    my $keyword = shift;
    my $descr = shift;

    unless (exists $self->{keywords}{$keyword}) {
	$self->{keywords}{$keyword} = {};

	$log->log(LOG_DEBUG, "Reg keyword : $keyword");

	$self->{descrs}{$keyword} = {_descr => $descr};
    }
}

sub register_action
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $descr = shift;

    if ($action =~ /^-/) { 
	die "Unable to register action. Action may not start with a '-'.\n";
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register action on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	$log->log(LOG_DEBUG, "Reg action for $keyword: $action");
	$self->{keywords}{$keyword}{$action} = {tasks => [], options => {}};
	$self->{descrs}{$keyword}{$action} = {_descr => $descr};
    }
}

#$eh->register_option('key', 'action',
#                      $option, $type, $required, $descr, $widget
#			- OR -
#		      $meta, $required
#                      );
sub register_option
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    my $meta;
    my $required = 0;

    if (eval { $option->isa('VUser::Meta'); }) {
	$meta = $option;
	$required = shift;
    } else {
	if ($main::DEBUG) {
	    use Data::Dumper;
	    $log->log(LOG_DEBUG, 'Option: '.Dumper($option));
	}
	die "Option on $keyword|$action was not a VUser::Meta\n";
    }

    $log->log(LOG_DEBUG, "Reg Opt: $keyword|$action %s %s %s",
	      $meta->name, $meta->type, $required?'Req':'');

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register option on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	die "Unable to register option on unknown action '$action'.\n";
    }

#    if (exists $self->{keywords}{$keyword}{$action}{options}{$option}) {
    if (exists $self->{keywords}{$keyword}{$action}{options}{$meta->name}) {
	# Let's silently ignore duplicate option definitions the way we
	# do for keywords and actions. This will allow an extension to
	# register an option to guarantee that it's there rather than having
	# to rely on another extension to register the option.
	#die "Unable to register option for $keyword|$action. '$option' already exists.\n";
    } else {
	$self->{keywords}{$keyword}{$action}{options}{$meta->name} = $meta;
	if ($required) {
	    $self->{required}{$keyword}{$action}{$meta->name} = 1;
	} else {
	    $self->{required}{$keyword}{$action}{$meta->name} = 0;
	}
	$self->{descrs}{$keyword}{$action}{$meta->name} = {_descr => $meta->description};
    }

    # Q: Should I auto register meta data?
    # A: No. Let the extensions register the meta data they feel
    #    is important. This will yeild a nicer way of pulling in
    #    "standard" meta data for extensions that build on defaults.
    #$self->register_meta($keyword, $meta);
}

sub register_meta
{
    my $self = shift;
    my $keyword = shift;
    
    my $meta;
    
    if (ref $_[0] and $_[0]->isa('VUser::Meta')) {
	$meta = $_[0];
    } else {
	$meta = new VUser::Meta(@_);
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register option on unknown keyword: '$keyword'.\n";
    }

    if (defined $self->{$keyword}{'_meta'}{$meta->name}) {
	# Silently ignore duplicates.
    } else {
	$self->{$keyword}{'_meta'}{$meta->name} = $meta;
    }
}

sub is_required
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    if ($self->{required}{$keyword}{$action}{$option}) {
	return 1;
    } else {
	return 0;
    }
}

sub check_required
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $opts = shift;

    foreach my $option (grep { $self->is_required($keyword, $action, $_); }
			keys %{$self->{required}{$keyword}{$action}}) {
	if (not exists($opts->{$option})) {
	    return $option;
	}
    }
    return '';
}

sub register_task
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $handler = shift;        # sub ref. Takes 4 params: The tied config
				#  the options ref, the action, and the
                                #  ::ExtHandler
    my $priority = shift;

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register task on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	die "Unable to register task on unknown action '$action'.\n";
    }

    # Default priority is 10.
    $priority = DEFAULT_PRIORITY unless defined $priority;
    if ($priority =~ /^[+-]\s*\d+/) {
	$priority =~ s/\s//g; # remove any excess whitespace
	$priority = DEFAULT_PRIORITY() + $priority;
	$priority = 0 if $priority < 0;
    }

    if (defined $self->{keywords}{$keyword}{$action}{tasks}[$priority]) {
	push @{$self->{keywords}{$keyword}{$action}{tasks}[$priority]}, $handler;
    } else {
	$self->{keywords}{$keyword}{$action}{tasks}[$priority] = [$handler];
    }
}

sub get_keywords
{
    my $self = shift;

    return sort keys %{ $self->{keywords}};
}

sub is_keyword
{
    my $self = shift;
    my $keyword = shift;

    if (defined $self->{keywords}{$keyword}) {
	return 1;
    } else {
	return 0;
    }
}

sub get_actions
{
    my $self = shift;
    my $keyword = shift;

    return sort keys %{ $self->{keywords}{$keyword} };
}

sub get_options
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    
    my $real_act = $action;
    if (not defined $self->{keywords}{$keyword}{$action}
        and defined $self->{keywords}{$keyword}{'*'}) {
        $real_act = '*';
    }

    return sort keys %{ $self->{keywords}{$keyword}{$real_act}{options}};
}

# Return unsorted list of VUser::Meta objects;
sub get_meta
{
    my $self = shift;
    my $keyword = shift;
    my $option = shift;

    my @meta = ();

    return undef if not defined $self->{$keyword};

    if (defined $option) {
	push @meta, $self->{$keyword}{'_meta'}{$option};
    } else {
	foreach my $opt (keys %{$self->{$keyword}{'_meta'}}) {
	    push @meta, $self->{$keyword}{'_meta'}{$opt};
	}
    }

    return @meta;
}

sub get_description
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    if ($keyword and $action and $option) {
	return $self->{descrs}{$keyword}{$action}{$option}{_descr};
    } elsif ($keyword and $action) {
	return $self->{descrs}{$keyword}{$action}{_descr};
    } elsif ($keyword) {
	return $self->{descrs}{$keyword}{_descr};
    }
}

sub load_extensions
{
    my $self = shift;
    my $cfg = shift;

    $self->{'_loaded'} = {};
    $self->{'_loadorder'} = [];

    my $exts = $cfg->{ vuser }{ extensions };
    $exts = '' unless $exts;
    VUser::ExtLib::strip_ws($exts);
    $log->log(LOG_DEBUG, "Cfg extensions: $exts");

    my @exts = split / /, $exts;
    eval { $self->load_extensions_list($cfg, @exts) };
}

sub load_extensions_list {
    my $self = shift;
    my $cfg = shift;
    my @exts = @_;

    $self->{'_loaded'} = {};
    $self->{'_loadorder'} = [];

    $self->load_extension('CORE');
    $log->log(LOG_DEBUG, "Cfg extensions: ".join(',', @exts));
    foreach my $extension (@exts)
    {
	eval { $self->load_extension( $extension, $cfg ); };
	$log->log(LOG_DEBUG, "Unable to load %s: %s", $extension, $@) if $@;
    }
}

sub load_extension
{
    my $self = shift;
    my $ext = shift;
    my $cfg = shift;

    my $pm = 'VUser::'.$ext; # Module name

    # Don't load an extensions we've already seen.
    if ($self->{'_loaded'}{$ext}) {
	$log->log(LOG_INFO, "$ext is already loaded. Skipping");
	return;
    }

    # Import the extention module
    eval( "require $pm" );
    die $@ if $@;
    no strict "refs";

    # Check for module dependencies
    $log->log(LOG_DEBUG, "Checking dependencies for %s", $ext);    
    if ($pm->can('depends')) {
	my @depends = ();
	@depends = $pm->depends($cfg);

	foreach my $depend (@depends) {
	    next if not $depend; # Should not happen but let's be careful
	    $log->log(LOG_INFO, "$ext depends on $depend");
	    eval { $self->load_extension($depend, $cfg); };
	    die "Unable to load dependency $depend: $@\n" if $@;
	}
    }
       
    $log->log(LOG_INFO, "Loading extension: $ext");
    $self->{'_loaded'}{$ext} = 1;
    push (@{$self->{'_loadorder'}}, $ext);
    &{$pm.'::init'}($self, %{ $cfg });
}

sub unload_extensions
{
    my $self = shift;
    my %cfg = @_;

    # foreach my $ext (keys %{ $self->{'_loaded'} }) {
    foreach my $ext (reverse (@{$self->{'_loadorder'}})) {
	eval { $self->unload_extension($ext, %cfg); };
	warn "Unable to unload $ext: $@\n" if $@;
    }
}

sub unload_extension
{
    my $self = shift;
    my $ext = shift;
    my %cfg = @_;

    my $pm = 'VUser::'.$ext;

    no strict ('refs');
    $log->log(LOG_INFO, "Unloading extension: $ext");
    if (UNIVERSAL::can($pm, 'unload')) {
	&{$pm.'::unload'}($self, %cfg);
    }
}

sub run_tasks
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $cfg = shift;

    my %opts = @_;

    my $wild_action = 0;
    if (exists $self->{keywords}{$keyword}{$action}) {
	$wild_action = 0;
    } elsif (exists $self->{keywords}{$keyword}{'*'}) {
	$wild_action = 1;
    } else {
	die "Unknown action '$action'\n";
    }

    $log->log(LOG_DEBUG,"Keyword: '$keyword' Action: '$action' ARGV: @ARGV");

    eval { %opts = $self->process_options($keyword, $action, $cfg, %opts); };
    die $@ if $@;

    my @tasks = ();
    if ($wild_action) {
	@tasks = @{$self->{keywords}{$keyword}{'*'}{tasks}};
    } else {
	@tasks = @{$self->{keywords}{$keyword}{$action}{tasks}};
    }

    my @results = ();
    foreach my $priority (@tasks) {
	foreach my $task (@$priority) {
	    # Return values?
	    my $rs = &$task($cfg, \%opts, $action, $self);
	    if (not defined $rs) {
	    } elsif (UNIVERSAL::isa($rs, "VUser::ResultSet")) {
		push @results, $rs;
	    } elsif (UNIVERSAL::isa($rs, "ARRAY")) {
		# Someone sent us an array ref. Go through the list
		# and push any ::ResultSets on to the result list.
		foreach my $r (@$rs) {
		    if (UNIVERSAL::isa($r, "VUser::ResultSet")) {
			push @results, $r;
		    } elsif (UNIVERSAL::isa($r, 'ARRAY')) {
			push @results, $r;
		    }
		}
	    }
	}
    }

    return \@results;
}

sub cleanup
{
    my $self = shift;
    my %cfg = @_;

    eval { $self->unload_extensions(%cfg); };
    warn $@ if $@;
}

sub process_options {
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $cfg = shift;
    my %opts = @_;

    if ($main::DEBUG >= 1) {
	use Data::Dumper;
	$log->log(LOG_DEBUG, 'Options: '. Dumper(\%opts));
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unknown module '$keyword'\n";
    }

    my $wild_action = 0;
    if (exists $self->{keywords}{$keyword}{$action}) {
	$wild_action = 0;
    } elsif (exists $self->{keywords}{$keyword}{'*'}) {
	$wild_action = 1;
    } else {
	die "Unknown action '$action'\n";
    }

    # If we're processessing a wild action, we need to check the
    # '*' action instead of the passed in action.
    my $real_action = $wild_action? '*': $action;

    # If opts is not empty, we'll just use the option's we're given
    # otherwise, we'll get the options using GetOptions()

    if (%opts) {
	# We need to do some error checking here on the option type.
	# Getopt::Long takes care of it in the other case, but we need to
	# do that ourselves here.
	foreach my $opt (keys %{$self->{keywords}{$keyword}{$real_action}{options}}) {
	    my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt};

	    # Giant switch-type block to validate Getopt::Long types with the
	    # passed in values.
	    if ($type eq '!') {
		if ($opts{$opt}) {
		    $opts{$opt} = 1;
		} else {
		    $opts{$opt} = 0;
		}

		if ($opts{"no$opt"} or $opts{"no-$opt"}) {
		    $opts{$opt} = 0;
		}
	    } elsif ($type eq '+') {
		# All we can do here is make sure the option is an int.
		unless ($opts{$opt} =~ $RE{num}{int}) {
		    die "$opt is not an integer.\n";
		}
	    } elsif ($type =~ /^([=:])([siof])([@%])?$/) {
		if ($1 eq '='
		    and exists $opts{$opt}
		    and not defined $opts{$opt}) {
		    die "Missing required value: $opt\n";
		}

		my $d_type = $2;
		my $dest_type = $3;

		$log->log(LOG_DEBUG, "Key: %s; Act: %s, Opt: %s; Type: %s d_type: %s",
			  $keyword, $real_action, $opt, $type, $d_type);
		$log->log(LOG_DEBUG, "Req: %s Def: %s",
			  $self->is_required($keyword, $real_action, $opt)? 'Yes':'No',
			  defined $opts{$opt}?"Yes ($opts{$opt})":'No'
			  );

		if ($d_type eq 's') {
		    # There's nothing to verify here
		} elsif ($d_type eq 'i'
			 #and defined $opts{$opt}
			 # This line is causing the warnings.
			 #and not $opts{$opt} =~ /^$RE{num}{int}$/
			 ) {
		    # Ok, this is really stupid. I had to move this
		    # check into a seperate if because it was causing
		    # a weird warning about 'Use of uninitialized value
		    # in string eq at vuser-ng/lib/VUser/ExtHandler.pm
		    # line 339.'
		    if (defined $opts{$opt}
			and not $opts{$opt} =~ /^$RE{num}{int}$/) {
			die "$opt is not an integer.\n";
		    }
		} elsif ($d_type eq 'o'
			 and defined $opts{$opt}
			 and not ($opts{$opt} =~ /^$RE{num}{int}$/
				  or $opts{$opt} =~ /^$RE{num}{oct}$/
				  or $opts{$opt} =~ /^$RE{num}{hex}$/
				  )
			 ) {
		    die "$opt is not an extended integer.";
		} elsif ($2 eq 'f'
			 and defined $opts{$opt}
			 and not $opts{$opt} =~ /^$RE{num}{real}$/) {
		    die "$opt is not a real number.";
		}
	    } elsif ($type =~ /^:(-?\d+)([@%])?$/) {
		my $num = $1;
		if (defined $opts{$opt}) {
		    die "$opt is not an integer." unless $opts{$opt} =~ /$RE{num}{int}/;
		} else {
		    $opts{$opt} = $num;
		}
	    } elsif ($type =~ /^:+([@%])?$/) {
		if (defined $opts{$opt}) {
		    die "$opt is not an integer." unless $opts{$opt} =~ /$RE{num}{int}/;
		} else {
		    $opts{$opt}++;
		}
	    }
	}
    } else {
	# Prepare options for GetOptions();
	my @opt_defs = ();
	
	foreach my $opt (keys %{$self->{keywords}{$keyword}{$real_action}{options}}) {
	    my $gopt_type = '';
	    #my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt}a;
	    #$type = '' unless defined $type;

	    my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt}->type;
	    if ($type eq 'string') {
		$gopt_type = '=s';
	    } elsif ($type eq 'integer' or $type eq 'int') {
		$gopt_type = '=i';
	    } elsif ($type eq 'counter') {
		$gopt_type = '+';
	    } elsif ($type eq 'boolean' or $type eq 'bool') {
		$gopt_type = '!';
	    } elsif ($type eq 'float') {
		$gopt_type = '=f';
	    }

	    my $def = $opt.$gopt_type;
	    push @opt_defs, $def;
	}
	
	$log->log(LOG_DEBUG, "Opt defs: @opt_defs");
	if (@opt_defs) {
	    GetOptions(\%opts, @opt_defs);
	}
    }

    # Check for required options
    my $opt = $self->check_required ($keyword, $real_action, \%opts);
    if ($opt) {
	die "Missing required option '$opt'.\n";
    }

    if ($main::DEBUG >= 1) {
	use Data::Dumper;
	$log->log(LOG_DEBUG, 'Real Options: '. Dumper(\%opts));
    }

    return %opts;
}

1;

__END__

=head1 NAME

VUser::ExtHandler - vuser extension handler.

=head1 SYNOPSIS

 my $eh = VUser::ResultSet->new($cfg);
 $eh->load_extentions($cfg);
 
 my @resultsets = ();
 eval { @resultsets = $eh->run_tasks($keyword, $action, $cfg); };
 die $@ if $@;
 
 $eh->cleanup();

Extension usage

 sub init {
     # $eh is a VUser::ExtHandler
     my ($cfg, $opts, $action, $eh) = @_;
 
     $eh->register_keyword('foo', 'Manage foos');
 
     $eh->register_meta('foo',
         VUser::Meta->new('name' => 'bar',
                          'type' => 'string',
                          'description' => 'Where to drink'));
     $eh->register_meta('foo',
         VUser::Meta->new('name' => 'drink',
                          'type' => 'string',
                          'description' => 'What to drink'));
  
     $eh->register_action('foo', 'add', 'Add a foo');
     $eh->register_option('foo', 'add',           # Required option
                          $eh->get_meta('foo', 'bar'), 'req');
     $eh->register_option('foo', 'add',           # Optional
                          $eh->get_meta('foo', 'bar'));
     $eh->register_task('foo', 'add', \&foo_add);
 }
 ...
 sub foo_add {}

=head1 DESCRIPTION

VUser::ExtHandler is the main control system for vuser extensions.

=head2 new($cfg[, $log])

Create a new VUser::ExtHandler object.

new() takes two options. The first is a reference to a Config::IniFiles
tied hash for the vuser configuration. The second, option argument is
a VUser::Log object. If it's not defined, the ExtHandler will look to see
if C<$main::log> is a VUser::Log and use that instead. If it's not, the
ExtHandler will create it's own VUser::Log object.

=head2 load_extensions($cfg);

Load extensions listed in the configuration file.

C<$cfg> is a reference to a Config::IniFiles tied hash.

=head2 load_extensions_list($cfg, @extensions)

Load a given list of extentions.

=over 4

=item $cfg

Reference to a Config::IniFiles tied hash.

=item @extensions

List of extension names.

=back

=head2 register_keyword($keyword[, $description])

Register a keyword.

=over 4

=item $keyword

=item $description

A description for this keyword that will be displayed by C<vuser help>

=back

=head2 register_meta($keyword, $meta)

Register a VUser::Meta object with the ExtHandler. Other extensions
can access the object with C<get_meta()>.

=over4

=item $keyword

The keyword to lookup meta data for.

=item $meta

The name of the meta data object to get.x

=back

=head2 register_action($keyword, $action, $description)

Register an action with the ExtHandler.

=over 4

=item $keyword

The keyword to add an action to.

=item $action

The action to register.

As a special case, C<$action> can be defined as a wildcard with 'I<*>'.
Wildcard actions are run for any unknown action.

=item $description

A description of the action to be displayed with C<vuser help>.

=back

=head2 register_option($keyword, $action, $meta[, $required])

Register an option for a keyword|action pair.

=over 4

=item $keyword

=item $action

=item $meta

A VUser::Meta object that defined the option.

=item $required (Optional)

If set to a true value, the option is required; otherwise the
option is optional and may be omitted.

=back

=head2 register_task($keyword, $action, $task[, $priority])

Register a fuction to be run for the keyword|action pair

=over 4

=item $keyword

=item $action

=item $task

C<$task> is a sub reference that is called with four arguments.

=over 8

=item A reference to the Config::IniFiles hash

=item A reference to a hash containing the options

=item The action run. Usuful if handling wildcard actions.

=item A reference to the VUser::ExtHandler that is running the tasks

=back

=item $priority (Optional)

The priority of the task to run. Tasks will be run in order of priority
(smaller numbers first) with tasks of equal priority run in the
order they were registered.

C<$proirity> can be set to negative numbers to lower the priority or
'+ N' to increase the priority by N. (Note the space between '+' and
the number.) The lowest priority is zero.

You can get the default priority by calling C<$eh->DEFAULT_PRIORITY;>.

=back

=head2 get_keywords

=head2 is_keyword($keyword)

=head2 get_meta($keyword, $meta_name)

=head2 get_actions($keyword)

=head2 get_options($keyword, $action)

=head2 get_description($keyword[, $action[, $option]])

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
