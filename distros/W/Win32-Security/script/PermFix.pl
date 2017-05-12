#############################################################################
#
# PermFix.pl - script to fix permission inheritance mismatches under Win32
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
use File::DosGlob 'glob';
use Getopt::Long;
use Win32::Security::Recursor;

use strict;
use vars qw($counter $starttime);

$starttime = Win32::GetTickCount();

my $options = {};
GetOptions($options, qw(csv! dirsonly! verbose! quiet! recurse|s! help performance!)) or die "Invalid option.\n";

if (defined($options->{help})) {
	print <<ENDHELP;
!!!WARNING!!!   This script is still in beta!   !!!WARNING!!!

PermFix.pl options:
  -c[sv]         Output in CSV format
  -d[irsonly]    Check directories only
  -r[ecurse]     Recurse into subdirectories
  -s             Same as -r[ecurse]
  -v[erbose]     Provide verbose feedback
  -q[uiet]       Doesn\'t ask before implementing changes.  Only outputs
                 a list of fixed files unless -v[erbose] is also specified.
  -p[erformance] Outputs simple performance numbers
  -h[elp]        Print this message

PermFix.pl takes an optional list of files and/or directories to fix.  If
no list is passed, it will fix permissions for the current directory.

See PermDump.pl documentation for information on the permissions dump format.

ENDHELP
	exit;
}

{
	my(@osver) = Win32::GetOSVersion();
	die "PermFix.pl requires Windows 2000 or newer.\n" unless ($osver[4] == 2 && $osver[1] >= 5);
}

$| = 1;
select((select(STDERR), $|=1)[0]);

@ARGV = map {/[*?]/ ? glob($_) : $_ } @ARGV;
@ARGV = (".") unless scalar(@ARGV);

my $dumper = 

my $recursor = Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new($options,
		dumper => Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new({csv => $options->{csv}, inherited => $options->{verbose}}),

		[qw(_recurse superable)] => sub {
			my $self = shift;

			$self->reflect->addSlot(
				dumper => Class::Prototyped->new(
					'parent*' => $self->dumper(),
					[qw(nodes constant)] => $self->nodes(),
				)
			);

			$self->reflect->super('_recurse');
		},

		payload => sub {
			my $self = shift;

			$self->payload_count($self->payload_count()+1);

			my($node_name, $node_iscontainer, $node_namedobject, $node_dacl,
					$cont_namedobject, $cont_dacl) =
				$self->node_getinfo(
					node   => [qw(name iscontainer namedobject dacl)],
					parent => [qw(namedobject dacl)],
				);

			my $inheritance_blocked = $node_namedobject->control()->{SE_DACL_PROTECTED};

			my $inheritable = ($cont_dacl && !$inheritance_blocked ) ?
					$cont_dacl->inheritable($node_iscontainer ? 'CONTAINER' : 'OBJECT') :
					undef;

			my(@ace_comparison) = $node_dacl->compareInherited($inheritable, 1);

			my $output = 0;

			if (scalar(grep {$ace_comparison[$_*2+1] eq 'M' || $ace_comparison[$_*2+1] eq 'W'} 0..scalar(@ace_comparison)/2)) {
				if (!$options->{quiet} || $options->{verbose}) {
					$output = 1;
					print "\nExisting permissions:\n";
					$self->dumper->print_header();
					$self->dumper->payload();
				}

				my $answer = $options->{quiet} ? 1 : undef;

				until (defined $answer) {
					$output = 1;
					print "Do you want to fix the above problems? ";
					chomp(my $input = <STDIN>);
					$answer = 1 if $input =~ /^\s*y(?:es)?\s*$/i;
					$answer = 0 if $input =~ /^\s*n(?:o)?\s*$/i;
					if ($input =~ /^\s*q(?:uit)?\s*$/i) {
						print "Do you want to quit? ";
						chomp(my $input = <STDIN>);
						exit if $input =~ /^\s*y(?:es)?\s*$/i;
					}
					print "I didn't understand your answer.\n" unless defined $answer;
				}

				if ($answer) {
					my $new_dacl = $node_dacl->clone()->deleteAces(sub { $_->aceFlags->{INHERITED_ACE} });
					eval { $node_namedobject->dacl($new_dacl) };
					if ($@) {
						print STDERR "Unable to set permissions: $@";
					} else {
						delete($self->nodes->[-1]->{dacl});
						$node_dacl = eval { $self->node_getinfo(node => 'dacl') };
						if ($@) {
							print STDERR "Unable to read permissions: $@";
						} else {
							@ace_comparison = $node_dacl->compareInherited($inheritable, 1);

							if (scalar(grep {$ace_comparison[$_*2+1] eq 'M' || $ace_comparison[$_*2+1] eq 'W'} 0..scalar(@ace_comparison)/2)) {
								$output = 1;
								print "\nPermissions did not clean up properly:\n";
								$self->dumper->print_header();
								$self->dumper->payload();
							} elsif ($options->{quiet} && !$options->{verbose}) {
								print "$node_name\n";
							} else {
								$output = 1;
								print "\nNew permissions".($options->{verbose}?'':' (may be empty if no explicit permissions are present)').":\n";
								$self->dumper->print_header();
								$self->dumper->payload();
							}
						}
					}
				}
				$output and print '-' x 75, "\n";
			}
		},

		debug => 0,
	);

foreach my $name (@ARGV) {
	$recursor->recurse($name);
}

if ($options->{performance}) {
	my $elapsed = Win32::GetTickCount()-$starttime;
	print STDERR sprintf("%i in %0.2f seconds (%i/s  %0.2f ms)\n", $recursor->{payload_count},
			($elapsed)/1000, $recursor->{payload_count}*1000/($elapsed || 1),
			$elapsed/($recursor->{payload_count} || 1)
		);
	print STDERR sprintf("%i unique ACEs, %i unique ACLs\n",
			scalar(keys %{Win32::Security::ACE::SE_FILE_OBJECT->_rawAceCache()}),
			scalar(keys %{Win32::Security::ACL::SE_FILE_OBJECT->_rawAclCache()}) );
}
