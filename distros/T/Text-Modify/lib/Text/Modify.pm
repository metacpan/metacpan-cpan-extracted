package Text::Modify;
#================================================================
# (C)2004-2005, lammel@cpan.org
#================================================================
# - Multiline replace is NOT supported currently
# - only simple regex and string replacement probably works the
#   way it should
#================================================================

use strict;
use File::Temp qw(tempfile);
use File::Copy;
use Text::Modify::Rule;
use Text::Buffer;
use vars qw($VERSION);

BEGIN {
	$VERSION="0.5";
}

sub new {
    my $class = shift;
    my %default = (
    	backup		=> 1,		# The node id if available (used only for correlation with OMC db)
    	backupExt	=> '.bak',	# The ip address of the core network interface
    	dryrun		=> 0,
    	writeto		=> undef,	# Output file to use, by default a temp. file is created and input file is overwritten 
    	_debug		=> 0
    );
    my $self = bless {%default}, $class;
    # Processing of arguments, either ->new("filename")
    # or ->new(file => "test.txt", writeto => "test.out")
    my %opts;
    if (scalar(@_) > 1) {
    	%opts = @_;
	    if ($opts{debug}) { $self->{_debug} = $opts{debug}; } 
    	foreach (qw(file writeto dryrun backup backupExt)) {
    		if (exists($opts{$_})) {
    			$self->_debug("Setting option: $_ = " . (defined($opts{$_}) ? $opts{$_} : "undef"));
    			$self->{$_} = $opts{$_};
    		}
    	}
    	if ($self->{writeto}) { $self->{backup} = 0; }
    }
    else { $self->{file} = shift; }
    if (!$self->{writeto} && $self->{file}) { $self->{writeto} = $self->{file}}
    $self->_debug("Created object $class as $self (" . ref($self) . ")");
    $self->_clearError();
    $self->{ruleorder} = [];
    $self->{blockorder} = [];
    # Define the "ALL" block, which includes the whole file and is used
    # for rules with no specific block defined
    
    return $self;
}

# Block processing not implemented yet
#sub defineBlock {
#	my $self = shift;
#	my $name = shift;
#	my %opts = @_;
#	if (exists($self->{block}->{$name})) {
#		$self->_setError("Block $name already defined");
#		return 0;
#	}
#	if ($opts{fromline}) {
#		$self->{block}->{$name}->{from} = $opts{fromline};
#	} elsif ($opts{frommatch}) {
#		$self->{block}->{$name}->{frommatch} = $opts{frommatch};
#	} else {
#		$self->{block}->{$name}->{from} = 0;
#	}
#	if ($opts{toline}) {
#		$self->{block}->{$name}->{to} = $opts{toline};
#	} elsif ($opts{frommatch}) {
#		$self->{block}->{$name}->{tomatch} = $opts{tomatch};
#	} else {
#		$self->{block}->{$name}->{to} = 999999;
#	}
#	push @{$self->{blockorder}},$name;
#	return 1;
#}
#
#sub undefineBlock {
#	my $self = shift;
#	my $name = shift;
#	if (exists($self->{block}->{$name})) {
#		$self->_debug("Undefining block $name");
#		delete($self->{block}->{$name});
#		my @tmp = @{$self->{blockorder}};
#		@{$self->{blockorder}} = grep($_ ne $name, @tmp);    
#	} else {
#		$self->_debug("Block $name not defined, ignoring");
#	}
#	return 1;
#}
#
#sub listMatchBlocks {
#	my $self = shift;
#	return (grep { !defined($self->{block}->{$_}->{from}) || !defined($self->{block}->{$_}->{to}) } $self->listBlocks());
#}
#
#sub listCurrentBlocks {
#	my $self = shift;
#	return (grep { $self->{block}->{$_}->{active} } $self->listBlocks());
#}
#
#sub listBlocks {
#	my $self = shift;
#	return @{$self->{blockorder}};
#}

### TODO Need to define all methods and also options like
### TODO addIfMissing to add a required line even if it is not found at end/start of file or block
# ->replace( replace => "SAD", with => "FUNNY", ignorecase => 1, addIfMissing => 1 )
# ->replace( repalce => "sad (\d+) day", with => "funny \$1 week", ignorecase => 1, addIfMissing => 1 )

sub defineRule {
	my $self = shift;
	my %opts = @_;
	### TODO need to generate a better name if undefined
	my $name = $opts{name};
	if (!$name) {
		$name = "rule" . ($#{$self->{ruleorder}}+1);
	}
	return 0 if (!%opts);
	$self->_debug("Defining rule '$name': " . join(",",%opts));
	if (!$opts{replace} && !$opts{insert} && !$opts{'delete'}) {
		$self->_addError("Failed to define rule $name");
		return 0;
	}
	$self->{rule}->{$name} = new Text::Modify::Rule(%opts, debug => $self->{_debug});
	if (!$self->{rule}->{$name}) {
		$self->_setError("Could not init rule $name");
		return 0;
	}
	push @{$self->{ruleorder}},$name;
	return 1;	
}

sub undefineRule {
	my $self = shift;
	my $name = shift;
	if (exists($self->{rule}->{$name})) {
		$self->_debug("Undefining rule $name");
		delete($self->{rule}->{$name});
		my @tmp = @{$self->{ruleorder}};
		@{$self->{ruleorder}} = grep($_ ne $name, @tmp);    
	} else {
		$self->_debug("Rule $name not defined, ignoring");
	}
	return 1;
}

# Simple syntax ->replace("MY","HIS") or ->replaceLine("WHAT","WITH",ignorecase => 1) 
# supported options are: 
# 	dryrun		do not apply changes
#	ignorecase	ignore case for matching
#	ifmissing 	insert/append/ignore/fail string if missing (cannot use results of regex then)
# 	matchfirst	only match X times for replacing, 1 would only replace the first occurence
sub replace {
	my $self = shift;
	return $self->replaceRegex(@_);
}

sub replaceString {
	my ($self,$what,$with,%opts) = @_;
	$self->_debug("Adding string replace rule: '$what' with '$with'");
	return $self->defineRule(replace=>$what,type=>'string',string=>$what,with=>$with,%opts);
}

sub replaceWildcard {
	my ($self,$what,$with,%opts) = @_;
	$self->_debug("Adding wildcard replace rule: '$what' with '$with'");
	return $self->defineRule(replace=>$what,type=>'wildcard',wildcard=>$what,with=>$with,%opts);
}

sub replaceRegex {
	my ($self,$what,$with,%opts) = @_;
	$self->_debug("Adding regex replace rule: '$what' with '$with'");
	return $self->defineRule(replace=>$what,type=>'regex',regex=>$what,with=>$with,%opts);
}

# TODO sub replaceInBlock { }

# Usage: Delete line matching expressions MATCH
# Syntax: ->deleteLine("MATCH", ignorecase => 1, matchfirst => 1)
# supported options are: 
# 	dryrun		do not apply changes
#	ignorecase	ignore case for matching
#	ifmissing 	ignore|fail if missing
# 	matchfirst	only match X times for replacing, 1 would only replace the first occurence

sub delete { 
	my ($self,$what,%opts) = @_;
	$opts{'delete'} = $what;
	return $self->defineRule(%opts);
}
# TODO sub deleteInBlock { }

sub insert { 
	my ($self,$what,%opts) = @_;
	$opts{insert} = $what;
	$opts{at} = "top";
	return $self->defineRule(%opts);	
}
# TODO sub insertInBlock { }

sub append { 
	my ($self,$what,%opts) = @_;
	$opts{insert} = $what;
	$opts{at} = "bottom";
	return $self->defineRule(%opts);	
}

# TODO sub appendInBlock { }


sub listRules {
	### TODO maybe it would be better to place rules outside of blocks
	my $self = shift;
	$self->_debug("Returning ordered rules: " . join(", ",@{$self->{ruleorder}}));
	return @{$self->{ruleorder}};
}

sub backupExtension {
	my $self = shift;
	my $ext = shift;
	if (defined($ext)) {
		$self->{backupExt} = $ext;
		return 1;
	}
	return $self->{backupExt};
}

sub _getBackupFilename {
	my $self = shift;
	my $file = $self->{'file'} || shift;
	my $bakfile = $file . $self->{'backupExt'};
	
	if (-f $bakfile) {
		$self->_debug("Bakfile $bakfile already existing, using next available");
		# TODO Need to do backupfile rotation or merge into createBackup
		my $cnt = 1;
		while (-f "$bakfile.$cnt" && $cnt) {
			$cnt++;
		}
		$bakfile = "$bakfile.$cnt";
	}
	return $bakfile;
}

#=====================================================
# create backup of set or supplied file
#=====================================================
sub createBackup {
	my $self = shift;
	my $file = $self->{'file'} || shift;
	my $bakfile = $self->_getBackupFilename();
	### Create a backup if bakfile is set
	if ($bakfile && $bakfile ne $file) {
		$self->_debug("- Creating backup copy $bakfile");
		copy($file,$bakfile);
		# TODO restore permissions and ownership of file
	}
	return $bakfile;
}

sub process {
	my $self = shift;
	my $file = $self->{'file'};
	my $bakfile = "";
	if ($self->{'backup'}) {
		$self->_debug("Creating backup");
		$bakfile = $self->createBackup();
		if ($self->isError()) {
			Error($self->getError());
			return 0;
		}
	}
	my $txtbuf = Text::Buffer->new(file => $file);
	$self->{linesread} = $txtbuf->getLineCount();
	$self->{_buffer} = $txtbuf;
	$self->_debug("Read $self->{linesread} from $file");

	$self->{replacecount} = 0;
	$self->{matchcount} = 0;
	$self->{addcount} = 0;
	$self->{deletecount} = 0;
	$self->{lineschanged} = 0;
	$self->{linesprocessed} = 0;

	$self->_debug("Starting processing of data " . (defined($self->{data}) ? $self->{data} : "undef") . " (error=" . $self->isError(). ")");	
	foreach ($self->listRules()) {
		my $rule = $self->{rule}->{$_};
		$self->_debug("Processing rule $_");
		my $changecount = $rule->process($self->{_buffer});
		$self->{changecount} += $changecount;
		my ($match, $add, $del, $repl) = $rule->getModificationStats();
		$self->{replacecount} += $repl;
		$self->{matchcount} += $match;
		$self->{addcount} += $add;
		$self->{deletecount} += $del;
		$self->_debug("Stats rule $_ (change/match/repl/add/del): " . 
			"$self->{lineschanged}/$match/$repl/$add/$del");
		if ($rule->isError()) {
			$self->_addError($rule->getError());
			last;
		}
	}
	if ($self->isError()) {
		return 0;
	}
	
	### Now mv the temp. file to overwrite the original configfile
	if (!$self->{dryrun}) {
		# Force saving now
		$self->{_buffer}->setModified();
		if (!$self->{_buffer}->save($self->{writeto})) {
			$self->_debug("Error saving file to " . $self->{writeto});
			return 0;
		}
	} else {
		$self->_debug("Dryrun, not writing file");
	}
	$self->_debug("Statistics:
	Lines read: 	$self->{linesread}   
	Lines changed:  $self->{lineschanged}   
	Lines matched:  $self->{matchcount}   
	Lines replaced: $self->{replacecount}
	Lines added:	$self->{addcount}
	Lines deleted:	$self->{deletecount}");
	return 1;
}

sub dryrun {
	my $self = shift;
	my $old = $self->{dryrun};
	$self->{dryrun} = 1;
	my $rc = $self->process();
	$self->{dryrun} = $old;
	return $rc;
}

sub isDryRun          { return shift->{dryrun}; }
sub getLinesModified  { return shift->{lineschanged}; }
sub getLinesProcessed { return shift->{linesprocessed}; }
sub getReplaceCount   { return shift->{replacecount}; }
sub getMatchCount     { return shift->{matchcount}; }
sub getAddCount       { return shift->{addcount}; }
sub getDeleteCount    { return shift->{deletecount}; }


#=============================================================
# ErrorHandling Methods
#=============================================================
sub _addError { my $self = shift; $self->{error} .= shift; }
sub isError { return (shift->{'error'} ? 1 : 0); }
sub _setError { my $self = shift; $self->{error} = shift; }
sub getError {
	my $self = shift;
	my $error = $self->{error};
	$self->_clearError();
	return $error;
}
sub _clearError { shift->{error} = ""; }

#=============================================================
# Private methods (for internal use )
#=============================================================

# Only internal function for debug output
sub _debug {
	my $self = shift;
	if ($#_ == -1) {
		return $self->{_debug};
	}
	elsif ( $self->{_debug} ) {
		print "[DEBUG] @_\n";
	}
}

1;
__END__

=head1 NAME

Text::Modify - oo-style interface for simple, rule-based text modification

=head1 SYNOPSIS

  use Text::Modify;

  my $mod = new Text::Modify(-file=>'my.txt', -writeto=>'new.txt', dryrun=>0);
  $mod->replace("sad","funny");
  $mod->replace('.*?logalhos$',"127.0.0.1	localhost",ifmissing=>'append');
  my $count = $mod->process();

=head1 DESCRIPTION

C<Text::Modify> is a simple oo-style interface to perform variuos 
text modifcation tasks.

Instead of having to parse and modify textfiles with customized
routines over and over C<Text::Modify> provides a common ruleset, 
which allows simple to advanced editing tasks to be performend.

After instantiating a new C<Text::Modify> object, rules are defined
on it and finally processed.

	my $mod = new Text::Modify();

C<Text::Modify> uses C<Text::Buffer> internally to perform the 
editing tasks on the text-file.

=head1 Methods

=over 8

=item new

    $mod = new Text::Modify(%options);

This creates a new object, starting with an empty buffer unless the
B<-file> or B<-array> options are provided. The available
attributes are:

=item append

	$mod->append("new last line");

Add a rule to append a new line at enf of text.	
	
=item insert

	$mod->insert("new first line");

Add a rule to insert a new line at start of text.	

=item delete

	$mod->delete('.*DELETE ME$');

Add a rule to delete lines matching the supplied string. The string is
interpreted as a regular expression, so be sure to escape characters
accordingly.

=item replace

	$mod->replace("foo","bar", ifmissing=>append, ignorecase=>1);

Add a rule to replace all occurences of C<foo> with C<bar> in the text.	

=item replaceString

	$mod->replaceString("foo","bar", ifmissing=>append, ignorecase=>1);

Add a rule to replace all occurences of string C<foo> with C<bar> in the text.	

=item replaceWildcard

	$mod->replace("*foo?","bar", ifmissing=>append, ignorecase=>1);

Add a rule to replace all occurences matching the wildcard C<*foo?> with
C<bar> in the text.	'*' (asterisk) will match any characters (as much as
possible) and '?' (question mark) will match one character

=item replaceRegex

	$mod->replace("\s*foo\d+","bar", ifmissing=>append);
	$mod->replace("\s*foo(\d+)",'bar$1', ignorecase=>1);

Add a rule to replace all occurences matching the regular expression 
C<*foo?> with C<bar> in the text. Also regex parameters can be used in
the replacement string.

=item defineRule

	$mod->defineRule(replace=>'foo\s+bar',with=>'foobar', ifmissing=>append);

# TODO add pod for all options supported by defineRule()
Advanced interface to define a rule, which gives most flexibilty
to perform a given task the way you need it.

=item undefineRule

Delete a rule, that was created with the supplied name

=item listRules

Returns a list of rules in the order they will be executed.

=item createBackup

create a backup of the specified file

=item backupExtension

get/set the backup extension used for backup files

=item getLinesModified
=item getLinesProcessed
=item getDeleteCount
=item getAddCount
=item getMatchCount
=item getReplaceCount

Return statistics and counters of the processing performed

=item process

	$mod->process();

Start processing of the text, rule by rule. If dryrun is enabled, 
modification will be performed in memory, but are B<not> written
to file.

=item dryrun

	$mod->dryrun();

Start processing of the text, rule by rule with dryrun enabled. 
The setting for dryrun will be restored after processing.
Modification will be performed in memory, but are B<not> written
to file.

=item isDryRun

Returns 1 if dryrun has been enabled, no modifications will be written
to the text to process. Otherwise returns 0.

=item isError

=item getError

	if ($text->isError()) { print "Error: " . $text->getError() . "\n"; }

Simple error handling routines. B<isError> returns 1 if an internal error
has been raised. B<getError> returns the textual error.

=back

=head1 BUGS

There definitly are some, if you find some, please report them.

=head1 LICENSE

This software is released under the same terms as perl itself. 
You may find a copy of the GPL and the Artistic license at 

   http://www.fsf.org/copyleft/gpl.html
   http://www.perl.com/pub/a/language/misc/Artistic.html

=head1 AUTHOR

Roland Lammel (lammel@cpan.org)

=cut
