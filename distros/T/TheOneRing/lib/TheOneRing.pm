# Copyright (C) 2009 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
package TheOneRing;

use strict;
use UNIVERSAL;
use Getopt::GUI::Long;

our $VERSION = '0.3';

our %master_arguments =
  (
   'commit' =>
   [
   ["m|message|msg=s" => "Commit message"],
   ["N|non-recursive"  => "Don't decend into subdirectiories"],
   ["q|quiet"               => "Update quietly as possible"],
   ],

   'diff' =>
   [
   ["r|revision|msg=s" => "Revision to diff against"],
   ["N|non-recursive"  => "Don't decend into subdirectiories"],
   ],

   'update' =>
   [
   ["r|revision=s"          => "Revision to update to"],
   ["N|non-recursive"       => "Don't decend into subdirectiories"],
   ["q|quiet"               => "Update quietly as possible"],
   ],

   'annotate' =>
   [
   ["r|revision=s"          => "Revision to update to"],
   ["N|non-recursive"       => "Don't decend into subdirectiories"],
   ],

   'status' =>
   [
    ["q|quiet"          => "Quiet output"],
   ],

   'info' =>
   [
    ["q|quiet"          => "Quiet output"],
   ],

   'add' =>
   [
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'remove' =>
   [
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'list' =>
   [
    ["r|revision=s"          => "Revision to update to"],
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'export' =>
   [
    ["r|revision=s"          => "Revision to update to"],
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'log' =>
   [
    ["r|revision=s"          => "Revision to update to"],
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'revert' =>
   [
    ["N|non-recursive"     => "Don't decend into subdirectiories"],
    ["q|quiet"             => "Quiet output"],
   ],

   'move' =>
   [
   ],

   'ignore' =>
   [
   ],

   # XXX: multiple things offer recursive
   #  (need a way to specify that -N means *don't* do -R or something

   #XXX: log
   #XXX: push
   #XXX: pull
   #XXX: tag
   #XXX: move
   #XXX: mkdir
   #XXX: cat
   #XXX: resolve(d)
   #XXX: import?
   #XXX: lock? / unlock
   #XXX: create?
   #XXX: property sets
   #XXX: switch

  );

# XXX: any benifit to making this per-object?  local overrides by object user?
our %aliases =
  (
   blame => 'annotate',
   ann   => 'annotate',

   co    => 'checkout',

   ci    => 'commit',

   di    => 'diff',

   ls    => 'list',
	 	
   st    => 'status',
   stat  => 'status',

   up    => 'update',
  );


# note: this new clause is used by most sub-modules too, altering it
# will alter them.
sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    $self->{'options'} = {@_};
    bless($self, $class);
    $self->init();
    return $self;
}

# prototype for children to optionally override
sub init {
}

# the meat of the work
sub dispatch {
    my ($self, $command, @args) = @_;

    my $repotype;

    if (exists($aliases{$command})) {
	$command = $aliases{$command};
    }

    # do checkout/stuff first
    if ($command eq 'checkout' || $command eq 'co' ||
	$command eq 'export') {
	# XXX
	return 1;
    }

    #
    # we could do a bunch of autoloading tricks to have each module
    # self-identify, but that would be a lot slower.  By only loading
    # the module we need and hard coding this determination list it
    # should make the one ring a bit faster to run.
    #

    # determine based on what's in the directory
    if (-d '.svn') {
	# that's an easy check.
	$repotype = 'SVN';
    } elsif (-d 'CVS') {
	# that's an easy check.
	$repotype = 'CVS';
    } elsif (-d '.git' || -d '../.git'  || -d '../../.git' 
	     || -d '../../../.git' || -d '../../../../.git'
	     || -d '../../../../.git' || -d '../../../../../.git') {
	# that's an easy check.
	# XXX: yeah, that'll scale...  needs to recursively go up
	$repotype = 'GIT';
    } else {
	$repotype = $self->find_cached_type();
	if (!defined($repotype)) {
	    # XXX: try dynamic system of some kind here now that the speed
	    # attempt is done?
	    $self->ERROR("Failed to determine the type of repository we're in.");
	}
    }
    $self->debug("found subtype $repotype");

    my $submodule = $self->load_subtype($repotype);
    $self->ERROR("failed to load $repotype: \n", $@) if (!$submodule);

    $self->debug("running $repotype->$command");

    # they have a method defined
    if ($submodule->can($command)) {
	$submodule->$command(@args);
	return 1;
    }

    # see if they have a defined command mapping
    if (exists($submodule->{'mapping'}{$command})) {
	# process and run it
	$submodule->map_and_run($command,
				$submodule->{'mapping'}{$command},
				@args);
	return 1;
    }

    $self->ERROR("ERROR: The \"$repotype\" module does know the command \"$command\"");
}

sub expect_string {
    my ($self, $value, @args) = @_;
    if (!defined($value)) {
	return $value; #XXX: should be an error?
    }
    if (ref($value) eq 'CODE') {
	return $value->($self, @args);
    } elsif ($value eq 'ARRAY' && ref($value->[0]) eq 'CODE') {
	my $code = shift @$value;
	return $code->($self, @$value, @args);
    } elsif ($value eq 'ARRAY') {
	$self->ERROR("Expected a generic STRING and got an ARRAY");
    } elsif ($value eq 'HASH') {
	$self->ERROR("Expected a generic STRING and got a HASH");
    }
    return $value;
}

sub expect_array {
    my ($self, $value, @args) = @_;
    if (ref($value) eq 'ARRAY' && ref($value->[0]) ne 'CODE') {
	return $value;
    } elsif (ref($value) eq 'ARRAY' && ref($value->[0]) eq 'CODE') {
	my $code = shift @$value;
	my $result = $code->($self, @$value, @args);
	return $result if (ref($result) eq 'ARRAY');
	return [$result];
    } elsif (ref($value) eq 'ARRAY') {
	return $value;
    } elsif (ref($value) eq 'CODE') {
	my $result = $value->($self, @args);
	return $result if (ref($result) eq 'ARRAY');
	return [$result];
    }

    return [$self->expect_string($value, @args)];
}

sub save_ARGV {
    my ($self, $newargv, @newargs) = @_;

    # save the current program name
    $self->{'savedprog'} = $main::0;
    $main::0 = $newargv if (defined($newargv));

    # save the existing ARGV arguments (just in case)
    @{$self->{'savedARGV'}} = @main::ARGV;
    @main::ARGV = @newargs;
}

sub restore_ARGV {
    my ($self) = @_;
    @main::ARGV = @{$self->{'savedARGV'}} if (defined($self->{'savedARGV'}));
    $main::0 = $self->{'savedprog'} if (defined($self->{'savedprog'}));
    delete $self->{'savedprog'};
}


sub map_args {
    my ($self, $subcmd, $map, @args) = @_;
    my %opts = @{$self->{$subcmd}{'defaults'} || []};

    # first process against the known arguments
    my $cmdoptions = $master_arguments{$subcmd};
    unshift @$cmdoptions, ["GUI:otherargs_text", "   "];

    # though it's discouraged to add more on a per-submodule, we do support it.
    push @$cmdoptions, @{$self->{'master_arguments'}}
      if (exists($self->{'master_arguments'}));

    Getopt::GUI::Long::Configure(qw(display_help no_ignore_case no_gui
				    require_order allow_zero));

    # save the current program name
    $self->save_ARGV("$main::0 [OR OPTIONS] $subcmd", @args);

    # and process our local arguments, and return everything to normal
    GetOptions(\%opts, @$cmdoptions) || exit;

    my @remainingargs = @main::ARGV;

    # restore the saved args
    $self->restore_ARGV();

    # process %opts

    my $newcommand = $self->expect_string($self->{'command'}, @remainingargs);
    my $newsubcmd  =
      $self->expect_string($map->{'command'}, @remainingargs) || $subcmd;

    my $argsmap = $map->{'args'};

    # build a list of options for the called command based on the
    # options for our command.
    my @options;
    @options = (@{$self->expect_array($map->{'options'}, @remainingargs)})
      if (exists($map->{'options'}));
    foreach my $optkey (keys(%opts)) {
	if (!exists($argsmap->{$optkey})) {
	    $self->ERROR("\"$newcommand $newsubcmd\" does not support the -$optkey option");
	}
	if ($argsmap->{$optkey} =~ /^-/) {
	    # argument with a value indicated by a leading -
	    push @options, "$argsmap->{$optkey}", $opts{$optkey};
	} else {
	    # singular argument
	    push @options, "-$argsmap->{$optkey}";
	}
    }
    return ($newcommand, $newsubcmd, \@options, \@remainingargs, \%opts);
}

sub map_and_run {
    my ($self, $subcmd, $map, @args) = @_;

    my ($cmd, $options, $otherargs);
    ($cmd, $subcmd, $options, $otherargs) =
      $self->map_args($subcmd, $map, @args);

    $self->System($cmd, $subcmd, @$options, @$otherargs);
}

sub load_subtype {
    my ($self, $type) = @_;

    # try and load it
    my $havesubmod = eval "require TheOneRing::$type;";
    return if (!$havesubmod);

    # once loaded, create an instance
    my $submod = eval "new TheOneRing::$type();";

    # copy in our running options
    $submod->{'options'} = $self->{'options'};

    return $submod;
}

sub get_cwd {
    require Cwd;
    return Cwd::getcwd();
}

sub get_config_dir {
    my ($self) = @_;

    my $ordir = $self->{'configdir'} || $ENV{'HOME'} . "/.theonering/";
    if (! -d $ordir) {
	mkdir($ordir);
    }
    return $ordir;
}

sub get_config_file {
    my ($self, $filename) = @_;

    my $dir = $self->get_config_dir();
    return "$dir/$filename";
}

sub find_cached_type {
    my ($self, $cwd) = @_;

    $cwd ||= $self->get_cwd();

    # check the current cache if possible
    my $type = $self->check_known_types($cwd);
    return $type if (defined($type));

    # ok, failing that lets try and create a fresh list.
    $self->debug("building a fresh list\n");
    $self->build_known_types();

    # Then try again now that we have a fresh list
    return $self->check_known_types($cwd);
}

sub check_known_types {
    my ($self, $cwd) = @_;

    $cwd ||= $self->get_cwd();

    my $typecache = $self->get_config_file('typecache');

    if (-f $typecache) {
	open(DIRTYPES, $typecache);
	while (<DIRTYPES>) {
	    chomp();
	    my ($dir, $type) = split;
	    if ($dir eq $cwd) {
		close(DIRTYPES);
		return $type;
	    }
	}
	close(DIRTYPES);
    }
    return; # fail!
}

sub build_known_types {
    my ($self) = @_;
    # do some things to build the 

    my $typecache = $self->get_config_file('typecache');

    my $dir = $self->get_config_dir;
    open(DIRTYPES,">$typecache");

    # svk map the existing checkout list
    open(SVKLIST, "svk co --list|");
    while (<SVKLIST>) {
	last if (/==========/);
    }
    while (<SVKLIST>) {
	my @stuff = split();
	printf DIRTYPES "%-60s SVK\n",$stuff[$#stuff];
    }
    close(SVKLIST);

    close(DIRTYPES);
}

sub debug {
    my $self = shift;
    if ($self->{'options'}{'debug'}) {
	print STDERR (join(" ",@_), "\n");
    }
}

sub ERROR {
    my ($self, @args) = shift;
    print STDERR (join(" ",@_),"\n");
    exit 1;
}

sub System {
    my $self = shift;
    if ($self->{'options'}{'dryrun'}) {
	print STDERR "would run: '", join("' '",@_), "'\n";
    } else {
	$self->debug("running: ", join("' '",@_));
	system(@_);
    }
}

# used by submodules for adding lines (like "ignore file") to a static file
sub add_to_file {
    my ($self, $file, @params) = @_;
    open(IGFILE,">>$file");
    foreach my $line (@params) {
	print IGFILE "$line\n";
    }
    close(IGFILE);
}

#
# common functions
#
sub move_by_adddel {
    my ($self, @args) = @_;
    $self->ERROR("move can only take one OLD and one NEW file")
      if ($#args != 1);

    my ($old, $new) = @args;
    rename($old, $new);
    $self->dispatch("remove", "$old");
    $self->dispatch("add", "$new");
}

#
# XXX common argument processing needed
#  ideas: * have each submodule publish a hash ref of things it can accept
#           plus a mapping table of one ring arguments to sub-command args
#         * fail on unknown arg based on list
#         * --something for forced arg passing
#

#
# XXX: create an AUTOLOAD subroutine to throw an error when someone
# tries to run a command on a mode that doesn't exist.
#

1;

=head1 NAME

TheOneRing - A high level perl class to bind all VCs together

=head1 SYNOPSIS

 my $or = new TheOneRing();
 $or->dispatch("commit", "-m", "checking in some files", "file1", "file2");

=head1 DESCRIPTION

B<TheOneRing> is merely a wraper around child classes that knows how
to pick which child class to load based on the current working
directory.  IE, if in a CVS checkout directory then the
TheOneRing::CVS module is loaded and the child is called to process
the command.

B<or> is the command line wrapper around this class, and is what most
users are expected to need.

=head2 Programming Child Classes

Most commands can be processed by simple definitions without coding
that can be defined in the child's I<init()> function.  More complex
conversion requirements can be done by defining a subroutine name for
the action desired.

The TheOneRing::CVS module is actually a good reference module since
it uses both the automatic command line mapping features as well as
subroutines to implement it's goals.

Yes, much more documentation is needed here.

=head1 SEE ALSO

The command line wrapper: or(1)

=head1 AUTHOR

Wes Hardaker <hardaker ATAT users.sourceforge.net>

=cut

