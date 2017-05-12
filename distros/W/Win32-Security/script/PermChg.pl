#############################################################################
#
# PermChg.pl - script to do intelligent permissions enumeration under Win32
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

use Data::Dumper;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Indent = 1;

use File::DosGlob 'glob';
use Getopt::Long;
use Text::ParseWords qw();
use Win32::Security::SID;
use Win32::Security::Recursor;

use strict;
use vars qw($dumper);

my $options = {};
GetOptions($options, qw(help csv! replace! verbose! quiet! owner=s propagateowner! allow=s@ deny=s@ block! file=s)) or die "Invalid option.\n";

if (defined($options->{help}) || scalar(keys %{$options}) == 0) {
	print <<ENDHELP;
!!!WARNING!!!   This utility is still in beta!   !!!WARNING!!!

PermChg.pl options:
  -c[sv]            Output/input in CSV format
  -r[eplace]        Replace ACL instead of editing it
  -v[erbose]        Provide verbose feedback
  -q[uiet]          Doesn\'t ask before implementing changes.  Only provides
                    feedback if -v[erbose] is also specified.

  -o[wner]=user          Set owner    !!!! NOT COMPLETELY IMPLEMENTED !!!!
  -[no]p[ropagateowner]  Ownership should be propagated through the tree

  -a[llow]=user:[mask[(flags)]]  Allow permissions.
  -d[eny]=user:[mask[(flags)]]   Deny permissions.

  -[no]b[lock]    Specify whether inherited permissions should be blocked.
                  If unspecified, leaves inheritance setting as it was.

  -f[ile]=file    Use passed filename as input in CSV or TDF format in same
                  format as PermDump.pl.  Using '-' opens STDIN.  The -o[wner],
                  -a[llow], -d[eny], and -[no]b[lock] options are not valid in
                  conjunction with -f[ile].  The -p[ropagateowner] option is
                  is presumed if any O records are passed, unless it is
                  explicitly turned off with -nop[propagateowner].

Multiple -a and -d options can be specified in a single call.  The user for an
-a or -d option should be specified as Domain\\Username.

Valid mask values include:
    R    Read and Execute
    M    Modify
    F    Full Control
If no mask value is specified, it is presumed that permissions for that
user should be removed.  The : (colon) is still required.

Valid flags values (which should be enclosed in parentheses) include:
    CI   Container Inherit
    OI   Object Inherit
    FI   Full Inherit (both CI and OI)
    IO   Inherit Only (ACE does not apply to current directory)
    FO   This folder only
    NP   No Propagate Inherit ACE
If no flags are specified, it is presumed that FI (full inherit) is desired.

Both perm and flags can also be specified using any legal output from
PermDump.pl, multiple values can be strung together using the | (pipe) 
character, and an integer can be used in place of the constants.

If -nob[lock] is specified, all inheritable permissions from the parent object
will be inherited on this object and on all descendents that don\'t have
inheritance blocking turned on.  Use this in conjunction with -r[eplace] to
wipe out any explicit permissions set on this object.

If -b[lock] is specified, inheritance blocking will be turned on for the
object.  If inheritance blocking is currently not in place, the previously
inherited permissions will be copied as explicit unless the -r[eplace] option
is passed.  If the -r[eplace] option is specified, all existing permissions
(including those previously inherited) will be removed.

When the Desc field is parsed if the -f[ile] option is used, only the last
non-whitespace character of the field is inspected.  It should be an
X (eXplicit permission), B (inherited permissions Blocked), or O (Owner).  If
a CSV file is passed to the -f[ile] option, the -c[sv] option should be
passed to indicate such.

If the -f[ile] option is passed, the files and directories to modify are found 
in the file.  If -f[ile] is not passed, PermChg.pl takes an optional list of 
files and/or directories to modify.  If no list is passed, it will change 
permissions for the current directory.

See PermDump.pl documentation for information on the permissions dump format.

ENDHELP
	exit;
}

{
	my(@osver) = Win32::GetOSVersion();
	die "PermChg.pl requires Windows 2000 or newer.\n" unless ($osver[4] == 2 && $osver[1] >= 5);
}

$| = 1;

$dumper = Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new({csv => $options->{csv}, inherited => 1});

&parse_options($options);
&check($options) unless $options->{quiet};
&permset_chg($options);
&ownerset_chg($options);





sub parse_options {
	my($options) = @_;

	if ($options->{file}) {
		open(FILE, "<$options->{file}") or die "Unable to open '$options->{file}' for reading.\n";
		scalar(@ARGV) and die "Additional command line arguments are unsupported with -f[ile].\n".Data::Dumper->Dump([\@ARGV]);
		my $hashlist = {};
		my $delim = $options->{csv} ? ',' : "\t";
		while (<FILE>) {
			/\S/ or next;
			chomp;
			/^Path${delim}Trustee${delim}Mask${delim}Inheritance${delim}Desc$/i and next;
			(my $line = $_) =~ s/\\/\\\\/g;
			my $data = [&Text::ParseWords::parse_line($delim, 0, $line)];
			scalar(@$data) == 5 or die "FATAL ERROR: Unable to parse line:\n'$_'\nIf it is a CSV file, you need to pass the option -c.\n";
			push(@{$hashlist->{lc $data->[0]}}, $data);
		}

		foreach my $i (keys %$hashlist) {
			my $lines = $hashlist->{$i};

			my $name = $lines->[0]->[0];
			my($permset, $ownerset);

			foreach my $line (@$lines) {
				my($trustee, $mask, $flags, $desc) = @{$line}[1..4];
				$desc =~ s/\s//g;
				my $rec_type = uc(substr($desc, -1));

				if ($rec_type eq 'X' || $rec_type eq 'B') {
					$permset ||= {
							allow_strip => {},
							deny_strip => {},
							container_aces => [],
							object_aces => [],
							block => $options->{replace} ? 0 : undef,
						};

					if ($rec_type eq 'X') {
						my $type = 'ALLOW';
						if ($mask =~ /^(DENY|ALLOW):(.*)$/i) {
							($type, $mask) = (uc($1), $2);
						}

						if ($mask =~ /\S/) {
							$flags = '' if $flags eq 'FO';
							$flags = '' if $flags eq 'THIS_FOLDER_ONLY';

							my $ace = Win32::Security::ACE::SE_FILE_OBJECT->new($type, $flags, $mask, $trustee);
							push(@{$permset->{container_aces}}, $ace);
							my $new_flags = {%{$ace->aceFlags()}};
							unless ($new_flags->{INHERIT_ONLY_ACE}) {
								$new_flags->{CONTAINER_INHERIT_ACE} = 0;
								$new_flags->{OBJECT_INHERIT_ACE} = 0;
								$new_flags->{NO_PROPAGATE_INHERIT_ACE} = 0;
								push(@{$permset->{object_aces}}, Win32::Security::ACE::SE_FILE_OBJECT->new($type, $new_flags, $mask, $trustee));
							}
						}

						$permset->{lc($type).'_strip'}->{&Win32::Security::SID::ConvertNameToSid($trustee)} = undef;

					} elsif ($rec_type eq 'B') {
						$mask =~ /^INHERITANCE_(UN)?BLOCKED$/i or die "FATAL ERROR: B record needs INHERITANCE_BLOCKED or INHERITANCE_UNBLOCKED for '$name'.\n";
						$permset->{block} = $1 ? 0 : 1;
					}
				} elsif ($rec_type eq 'O') {
					defined $ownerset and die "FATAL ERROR: Multiple O records specified for '$name'.\n";
					$ownerset = {
						owner          => $trustee,
						ownerSid       => &Win32::Security::SID::ConvertNameToSid($trustee),
					};
					$options->{propagateowner} = 1 unless defined $options->{propagateowner};
				} else {
					die "FATAL ERROR: The -f[ile] option does not accept records of type '$desc'.\n";
				}
			}

			my $longfullname = lc(Win32::GetLongPathName(scalar(Win32::GetFullPathName($name)))) or
					die "FATAL ERROR: Unable to find object\n  '$name'\n";

			if (defined $permset) {
				$permset->{name} = $name;
				exists $options->{permset}->{$longfullname} and
						die "FATAL ERROR: Object referred to by different names:  '$options->{permset}->{$longfullname}->{name}'\n  '$name'\n";
				$options->{permset}->{$longfullname} = $permset;
			}

			if (defined $ownerset) {
				$ownerset->{name} = $name;
				$ownerset->{longfullname} = $longfullname;
				exists $options->{ownerset}->{$longfullname} and
						die "FATAL ERROR: Object referred to by different names:  '$options->{ownerset}->{$longfullname}->{name}'\n  '$name'\n";
				$options->{ownerset}->{$longfullname} = $ownerset;
			}
		}
	} else {
		my($permset, $ownerset);

		if ($options->{replace} || $options->{allow} || $options->{deny} || $options->{block}) {
			$permset ||= {
					allow_strip => {},
					deny_strip => {},
					container_aces => [],
					object_aces => [],
					block => $options->{block},
				};
			delete $options->{block};
		}

		foreach my $type ('deny', 'allow') {
			foreach my $string (@{$options->{$type} || []}) {
				$string =~ /^([^:()]+):(?:([^:()]+)(?:\(([^:()]+)\))?)?$/ or
						die "Unable to parse -$type option '$string'\n";
				my($trustee, $mask, $flags) = ($1, $2, $3);

				if ($mask =~ /\S/) {
					$flags ||= 'FI';
					$flags = '' if $flags eq 'FO';
					$flags = '' if $flags eq 'THIS_FOLDER_ONLY';

					my $ace = Win32::Security::ACE::SE_FILE_OBJECT->new(uc($type), $flags, $mask, $trustee);
					push(@{$permset->{container_aces}}, $ace);
					my $new_flags = {%{$ace->aceFlags()}};
					unless ($new_flags->{INHERIT_ONLY_ACE}) {
						$new_flags->{CONTAINER_INHERIT_ACE} = 0;
						$new_flags->{OBJECT_INHERIT_ACE} = 0;
						$new_flags->{NO_PROPAGATE_INHERIT_ACE} = 0;
						push(@{$permset->{object_aces}}, Win32::Security::ACE::SE_FILE_OBJECT->new(uc($type), $new_flags, $mask, $trustee));
					}
				}
				$permset->{lc($type).'_strip'}->{&Win32::Security::SID::ConvertNameToSid($trustee)} = undef;
			}

			delete $options->{$type};
		}

		if (exists $options->{owner}) {
			$ownerset = {
					owner          => $options->{owner},
					ownerSid       => &Win32::Security::SID::ConvertNameToSid($options->{owner}),
				};
			delete $options->{owner};
			delete $options->{propagateowner};
		}

		my(@filelist) = map {/[*?]/ ? glob($_) : $_ } @ARGV;
		@filelist = (".") unless scalar(@filelist);

		foreach my $name (@filelist) {
			my $longfullname = lc(Win32::GetLongPathName(scalar(Win32::GetFullPathName($name)))) or
					die "FATAL ERROR: Unable to find object\n  '$name'\n";

			if (defined $permset) {
				$permset->{name} = $name;
				exists $options->{permset}->{$longfullname} and
						die "FATAL ERROR: Object referred to by different names:  '$options->{permset}->{$longfullname}->{name}'\n  '$name'\n";
				$options->{permset}->{$longfullname} = $permset;
			}

			if (defined $ownerset) {
				$ownerset->{name} = $name;
				$ownerset->{longfullname} = $longfullname;
				exists $options->{ownerset}->{$longfullname} and
						die "FATAL ERROR: Object referred to by different names:  '$options->{ownerset}->{$longfullname}->{name}'\n  '$name'\n";
				$options->{ownerset}->{$longfullname} = $ownerset;
			}
		}
	}

	foreach my $set (qw(owner perm)) {
		next if $set eq 'owner' && !$options->{propagateowner};
		my $parents = {};

		my(@filelist) = reverse sort keys %{$options->{"${set}set"}};
		defined(my $lastparent = pop @filelist) or next;
		$parents->{$lastparent} = {};
		while (@filelist) {
			my $file = pop @filelist;
			if (my $temp = &isparent($lastparent, $file)) {
				if ($temp == -1) {
					$parents->{$lastparent}->{$file} = undef;
				} else {
					$parents->{$lastparent}->{$lastparent} = undef;
					$parents->{$file} = $parents->{$lastparent};
					delete $parents->{$lastparent};
					$lastparent = $file;
				}
			} else {
				foreach my $testparent (sort keys %$parents) {
					if (my $temp = &isparent($testparent, $file)) {
						if ($temp == -1) {
							$parents->{$testparent}->{$file} = undef;
							$lastparent = $testparent;
						} else {
							$parents->{$testparent}->{$testparent} = undef;
							$parents->{$file} = $parents->{$testparent};
							delete $parents->{$testparent};
							$lastparent = $file;
						}
						next;
					}
				}
				$parents->{$file} = {};
				$lastparent = $file;
			}
		}

		$options->{"${set}_parents"} = $parents;
	}
}

sub isparent {
	my($a, $b) = @_;

	$a =~ s/\\$//;
	$b =~ s/\\$//;
	return -1 if lc(substr($b, 0, length($a)+1)) eq lc($a).'\\';
	return 1 if lc(substr($a, 0, length($b)+1)) eq lc($b).'\\';
	return 0;
}


sub check {
	my($options) = @_;

	if (scalar keys %{$options->{permset}}) {
		print "\nPermissions for the following files will be ".($options->{replace} ? 'REPLACED' : 'MODIFIED')." as follows:\n";

		foreach my $lcname (sort keys %{$options->{permset}}) {
			my $perm = $options->{permset}->{$lcname};
			print " '$perm->{name}':\n";
			print "    Inheritable permissions blocked.\n" if $perm->{blocked} eq '1';
			print "    Inheritable permissions unblocked.\n" if $perm->{blocked} eq '0';

			my $node_iscontainer = -d $lcname;

			my(@aces) = @{$perm->{$node_iscontainer ? 'container_aces' : 'object_aces'}};
			my(%trustees);
			foreach my $ace (@aces) {
				push(@{$trustees{$ace->trustee()}}, $ace);
			}

			foreach my $trustee (sort keys %trustees) {
				print "    Existing ".($perm->{blocked} == 1 ? '' : 'explicit ')."perms for '$trustee' replaced with:\n";
				foreach my $ace (@{$trustees{$trustee}}) {
					my $aceType = $ace->aceType();
					$aceType =~ /^ACCESS_(?:ALLOWED|DENIED)_ACE_TYPE$/ or next;

					my $accessMask =  ($aceType eq 'ACCESS_DENIED_ACE_TYPE' ? 'DENY:' : '').
							join("|", sort keys %{$ace->explainAccessMask()});

					my $aceFlags = join("|", sort grep {$_ ne 'INHERITED_ACE'} keys %{$ace->explainAceFlags()});
					$aceFlags ||= 'THIS_FOLDER_ONLY' unless !$node_iscontainer;

					print "      ".join($options->{csv} ? "," : "\t",
								map {my $x = $_; $x =~ s/\"/\"\"/g; $x = '"'.$x.'"' if $x =~ /[\"\', ]/; $x}
								$accessMask, $aceFlags
							)."\n";
				}
			}
		}
	}

	if (scalar keys %{$options->{ownerset}}) {
		print "\Ownership for a whole bunch of files will be REPLACED!!!\n";
	}

	my $answer = undef;
	until (defined $answer) {
		print "Do you want to make these changes? ";
		chomp(my $input = <STDIN>);
		$answer = 1 if $input =~ /^\s*y(?:es)?\s*$/i;
		$answer = 0 if $input =~ /^\s*n(?:o)?\s*$/i;
		print "I didn't understand your answer.\n" unless defined $answer;
	}
	print "\n";
	$answer == 0 and exit;
}

sub permset_chg {
	my($options) = @_;

	scalar(keys %{$options->{permset}}) or return;

	if ($options->{verbose}) {
		print "Old permissions:\n";
		$dumper->print_header();
		foreach my $lcname (sort keys %{$options->{permset}}) {
			$dumper->recurse($options->{permset}->{$lcname}->{name});
		}
		print '-' x 75, "\n";
	}

	foreach my $rootname (sort keys %{$options->{perm_parents}}) {
		foreach my $name (sort keys %{$options->{perm_parents}->{$rootname}}) {
			eval { &perm_chg($options->{permset}->{$name}, noprop => 1, verbose => $options->{verbose}); };
			$@ and print STDERR "ERROR: $@";
		}
		eval { &perm_chg($options->{permset}->{$rootname}, noprop => 0, verbose => $options->{verbose}); };
		$@ and print STDERR "ERROR: $@";
	}

	if ($options->{verbose}) {
		print "New permissions:\n";
		$dumper->print_header();
		foreach my $lcname (sort keys %{$options->{permset}}) {
			$dumper->recurse($options->{permset}->{$lcname}->{name});
		}
		print '-' x 75, "\n";
	}
}

sub perm_chg {
	my($perm, %params) = @_;

	my $namedobject = Win32::Security::NamedObject::SE_FILE_OBJECT->new($perm->{name});
	my $dacl = $namedobject->dacl();

	my $new_dacl = $options->{replace} ? $dacl->new() : $dacl->clone();
	$new_dacl->deleteAces( sub {
					my $aceType = $_->aceType();
					($aceType eq 'ACCESS_ALLOWED_ACE_TYPE' && exists $perm->{allow_strip}->{$_->sid()}) ||
					 ($aceType eq 'ACCESS_DENIED_ACE_TYPE' && exists $perm->{deny_strip}->{$_->sid()});
			} );
	$new_dacl->addAces(@{$perm->{-d $perm->{name} ? 'container_aces' : 'object_aces'}});

	my $control = $namedobject->control();
	if (defined $perm->{block} && $perm->{block} != $control->{SE_DACL_PROTECTED}) {
		$namedobject->dacl($new_dacl, ($perm->{block} ? '' : 'UN').'PROTECTED_DACL_SECURITY_INFORMATION');
	} elsif ($params{noprop} && !$control->{SE_DACL_PROTECTED}) {
		$namedobject->dacl($new_dacl); # This used to be dacl_noprop, but I need to add support first for
				# detecting an interposed inheritance block between the parent folder and the child.
	} else {
		$namedobject->dacl($new_dacl);
	}
}



sub ownerset_chg {
	my($options) = @_;

	scalar(keys %{$options->{ownerset}}) or return;

	if ($options->{verbose}) {
		print "Ownership changes:\n";
		print join($options->{csv} ? "," : "\t", 'Path', 'Old_Owner', 'New_Owner')."\n";
	}

	if ($options->{propagateowner}) {
		my $owner_recursor = &get_owner_recursor($options);

		foreach my $parent (sort keys %{$options->{owner_parents}}) {
			$owner_recursor->recurse($parent);
		}
	} else {
		print STDERR "ERROR: Owner changing without propgateowner unsupported right now.\n";
		foreach my $name (sort keys %{$options->{ownerset}}) {
		}
	}

	if ($options->{verbose}) {
		print "Old permissions:\n";
		$dumper->print_header();
		foreach my $lcname (sort keys %{$options->{permset}}) {
			$dumper->recurse($options->{permset}->{$lcname}->{name});
		}
		print '-' x 75, "\n";
	}

	foreach my $rootname (sort keys %{$options->{perm_parents}}) {
		foreach my $name (sort keys %{$options->{perm_parents}->{$rootname}}) {
			eval { &perm_chg($options->{permset}->{$name}, noprop => 1, verbose => $options->{verbose}); };
			$@ and die $@;
		}
		eval { &perm_chg($options->{permset}->{$rootname}, noprop => 0, verbose => $options->{verbose}); };
		$@ and die $@;
	}

	if ($options->{verbose}) {
		print "New permissions:\n";
		$dumper->print_header();
		foreach my $lcname (sort keys %{$options->{permset}}) {
			$dumper->recurse($options->{permset}->{$lcname}->{name});
		}
		print '-' x 75, "\n";
	}
}



sub get_owner_recursor {
	my($options) = @_;

	my $setqueue;
	my $ownerset = $options->{ownerset};

	return Win32::Security::Recursor::SE_FILE_OBJECT->new(
		[qw(recurse superable)] => sub {
			my $parent = shift;
			my($name) = @_;

			$setqueue = [$ownerset->{$name}];
			$parent->reflect->super('recurse', $setqueue->[0]->{name});
		},

		payload => sub {
			my $self = shift;

			my($node_name, $node_namedobject, $node_ownerSid) = $self->node_getinfo(node => [qw(name namedobject ownerSid)]);

			my $longfullname = $setqueue->[0]->{longfullname} . lc(substr($node_name, length($setqueue->[0]->{name})));

			while (@$setqueue && &isparent($setqueue->[-1]->{longfullname}, $longfullname) != -1) {
				pop(@$setqueue);
			}

			if (exists $ownerset->{$longfullname}) {
				push(@$setqueue, $ownerset->{$longfullname});
			}

			scalar(@$setqueue) or die "FATAL BUG: Null sidqueue for '$node_name'.\n";

			if ($node_ownerSid ne $setqueue->[-1]->{ownerSid}) {
				if ($options->{verbose}) {
					print join($options->{csv} ? "," : "\t",
											map {my $x = $_; $x =~ s/\"/\"\"/g; $x = '"'.$x.'"' if $x =~ /[\"\', ]/; $x}
											$node_name, $self->node_getinfo(node => 'ownerTrustee'), $setqueue->[-1]->{owner}
										)."\n";
				}
				eval { $node_namedobject->ownerSid($setqueue->[-1]->{ownerSid}); };
				if (my $error = $@) {
					$error =~ s/\. at.+//s;
					print STDERR "ERROR_SET_OWNER: $error '$node_name'\n";
				}
			}

		},

		debug => 0,

		error_node_enumchildren => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			print STDERR "ERROR_ENUM_CHILDREN: '$node->{name}'\n";
			die;
		},

		error_node_fileattribs => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			print STDERR "ERROR_READ_FILEATTRIBS: '$node->{name}'\n";
			die;
		},

		error_node_ownerTrustee => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			print STDERR "ERROR_READ_OWNER: $error '$node->{name}'\n";
			die;
		},

		error_node_ownerSid => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			print STDERR "ERROR_READ_OWNER: $error '$node->{name}'\n";
			die;
		},

		error_node_dacl => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			print STDERR "ERROR_READ_DACL: $error '$node->{name}'\n";
			die;
		},

		error_node_isjunction => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			print STDERR "JUNCTION: '$node->{name}'\n";
			die;
		},
	);
}
