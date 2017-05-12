
use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

#===============================================
package XML::Pastor::Pastorize;

use XML::Pastor;

use File::chdir;
use File::Path;
use File::Spec;
use Getopt::Long;
use Pod::Usage;

use vars qw($VERSION);
$VERSION	= '1.0.1';

#-------------------------------------------------------------
# METHOD
#-------------------------------------------------------------
sub new {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self = {@_};	
	return bless $self, $class;
}

#------------------------------------------------------------
# run(@opts) : Class method
#------------------------------------------------------------
sub run ($;@) {
	my $class = shift;
	my $opts = {@_};

	$opts->{class_prefix}	||= 'MyApp::Data::';	# should override
	$opts->{destination}	||= '/tmp/lib/perl/';	# should override		
	$opts->{mode}			||= 'eval';
	$opts->{module}			||= $opts->{class_prefix};		
	$opts->{style}			||= 'single';	
	$opts->{schema}			||= [];					# Will get it from @ARGV (multiple OK)
	$opts->{verbose}		||= 0;
			
	GetOptions($opts, 	
						'class_prefix|prefix|p:s',
						'complex_isa|complex|c:s',						
						'debug|g' 		=> sub {$opts->{verbose}=9, $opts->{debug}=1},
						'destination|dest|d:s',						
						'help|h+',
						'man+',												
						'mode|m:s',
						'module|u:s',
						'quiet|q' 		=> sub {$opts->{verbose}=0},
						'simple_isa|simple|i:s',												
						'style|s:s',
						'verbose|v:2',		
				);
						
	push @{$opts->{schema}}, @ARGV;
	
	$class->validate_opts($opts) or die "$0: Invalid syntax!\n";
	
	return $class->_run(%$opts);								
}


#-------------------------------------------------------------
# _run : private class method
#-------------------------------------------------------------
sub _run {
	my $class 			= shift;
	my $opts			= {@_};
	my $print_result	= 0;
	
	if (lc($opts->{mode}) eq 'print') {
		$print_result = 1;
		$opts->{mode} = 'return';
	}
	
	my $pastor = XML::Pastor->new();
	
	my $result = $pastor->generate(%$opts);
	
	if (lc($opts->{mode})  eq 'eval') {
		print "Pastorize: Eval OK.\n";
	}
	
	if ($print_result) {
		print "\n" . $result . "\n";
	}
	
}

#-------------------------------------------------------------
sub validate_opts($) {
	my $class 	= shift;
	my $opts	= shift;
	
	# Help wanted. Print SYNOPSIS and OPTIONS.
	if ($opts->{help}) {
		pod2usage(	-message => "Help message\n",
					-exitval => 0,
					-verbose => 1,
				 );
	}
	
	# Man page wanted. Print the entire manual
	if ($opts->{man}) {
		pod2usage(	-message => "MANUAL PAGE\n",
					-exitval => 0,
					-verbose => 2,
				 );
	}
	
	# Mode undefined. 
	unless ($opts->{mode}) {
		pod2usage(	-message => "Syntax error. Mode required!\n",
					-exitval => 1,
					-verbose	=> 2,
				 );
	}
	
	# convert to lower case
	my $mode 	= $opts->{mode}  = lc($opts->{mode});
	my $style 	= $opts->{style} = lc($opts->{style});	
	my $schema  = $opts->{schema};
		
	if ($mode eq 'offline') {
		# Destination undefined while we need to generate code.	
		unless ($opts->{destination}) {	
			pod2usage(	-message => "Syntax error. 'destination' required when 'mode' is offline!\n",
						-exitval => 1,
						-verbose	=> 2,
					 );
		}				

		# Module undefined while mode is generate and style is single. 
		if ($style eq 'single')  {
			unless ($opts->{module}) {	
				pod2usage(	-message => "Syntax error. 'module' required when 'mode' is offline and 'style' is single!\n",
							-exitval => 1,
							-verbose	=> 2,
					 	);	
			}		
		}
	
	}
	
	# We need at least one schema to work on.
	unless (scalar($schema)) {
		pod2usage(	-message => "Syntax error. At least one schema required as argument!\n",
					-exitval => 1,
					-verbose	=> 2,
				 );
	}
	
	# Everything is OK. Indicate success to the caller.
	return 1;
}

##############################################################################"
# Utility functions
##############################################################################"

#-------------------------------------------------------------
sub _run_cmd {
	my ($opts, $cmd) 	= @_;
	my $verbose 		= $opts->{verbose} || $opts->{debug};
	my $dryrun			= $opts->{dryrun};
	my $prompt			= $dryrun ? 'sys  would >  ' : 'sys  cmd >  ';
	return unless $cmd;
	
	print $prompt . $cmd . "\n" if $verbose;	
	
	my $output;
	unless ($dryrun) 	{	$output = `$cmd`;													}
	else 				{ 	$output = $dryrun ? 'Command NOT executed (dry-run mode)' : eval($cmd); }
	
	print "$output\n" if ($output && $verbose > 5);	
	
}

#-------------------------------------------------------------
sub _run_perl {
	my ($opts, $cmd) 	= @_;
	my $verbose 		= $opts->{verbose} || $opts->{debug};
	my $dryrun			= $opts->{dryrun};
	my $prompt			= $dryrun ? 'perl would >  ' : 'perl cmd >  ';
	
	return unless $cmd;
	
	print $prompt . $cmd . "\n" if $verbose;
	
	my $output;
	unless ($dryrun) 	{	$output = eval($cmd);													}
	else 				{ 	$output = $dryrun ? 'Command NOT executed (dry-run mode)' : eval($cmd); }
	
	print "$output\n" if ($output && $verbose > 5);	
}



1;


__END__

=head1 NAME

B<XML::Pastor::Pastorize> - Helper module for command line interface to B<XML::Pastor>

=head1 SYNOPSIS 

  # Here's the actual contents of the 'pastorize' script. 
  
  #!/usr/bin/perl -w

  use utf8;
  use XML::Pastor::Pastorize;

  XML::Pastor::Pastorize->run();

  1;
   
  
=head1 DESCRIPTION

This module is a helper module for creating a command line interface for L<XML::Pastor>.

The 'pastorize' command line script was written using this module. In fact, the entire 
script consists of the lines in the above SYNOPSIS section.

For more information on command line options, see L<pastorize>.
For more information on XML::Pastor, see L<XML::Pastor>.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2008 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, 
THERE IS NO WARRANTY FOR THE SOFTWARE, 
TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE 
THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, 
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. 
SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING 
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE 
AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, 
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE 
(INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY 
YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), 
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


=head1 SEE ALSO

See also L<XML::Pastor>, L<pastorize>

=cut

1;



