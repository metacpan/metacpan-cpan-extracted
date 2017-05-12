package Unix::PasswdFileOps;

=head1 NAME

Unix::PasswdFileOps - Operations on Unix Passwd file

=head1 SYNOPSIS

  use Unix::PasswdFileOps;

  my $pass = Unix::PasswdFileOps->new('passwd' => '/etc/passwd');
  print $pass->passwd();
  $pass->verbose(1);
  $pass->protect_zero(1);
  if($pass->sort_passwd())
  {
     print $pass->error;
  }

=head1 DESCRIPTION

This module will perform sorting on a standard UNIX passwd file, the sort is 
performed against the UID by default although this can be altered using the 
sort_field() function.

Additionally it can populate an internal hash of arrays with line information
this provides a nice interface to find information about user accounts.

=cut

use 5.008007;
use strict;
use warnings;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw/new validate identify barcode type/;
@EXPORT      = qw//;
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION     = "0.4";

# Preloaded methods go here.

=head1 FUNCTIONS

=head2 new

my $passwd = Unix::PasswdFileOps->new('passwd' => '/etc/passwd');

You can pass in the optional parameters 'passwd', 'protect_zero'
'verbose' and 'sort_field'

=cut

sub new {
	my $class  = "Unix::PasswdFileOps";
	my %params = @_;
	my $self   = {};
	$self->{'passwd'}       = $params{'passwd'}       || undef;
	$self->{'protect_zero'} = $params{'protect_zero'} || undef;
	$self->{'verbose'}      = $params{'verbose'}      || undef;
	$self->{'sort_field'}   = $params{'sort_field'}   || undef;
	bless $self, $class;
	return $self;
}

###
# Internal function
#

sub _error_msg {
   my $self = shift;
   $self->{'error'} = shift;
}

=head2 passwd

my $passwd_file = $pass->passwd();
# or
$pass->passwd('/etc/passwd');

This function will allow you to view or set the passwd file 
parameter, if you pass a parameter it will set the passwd file to 
that parameter, if you do not it will just return the 
currently set file.

=cut

sub passwd {
	my ($self, $new_val) = @_;
	$self->{'passwd'} = $new_val if $new_val;
	return $self->{'passwd'};
}

=head2 protect_zero

my $zero = $pass->protect_zero();
# or
$pass->protect_zero(1);

This function will allow you to view or set the protect_zero 
parameter, if you pass a parameter it will set the protect_zero option
to 1, if you do not it will just return the currently set parameter.

If the protect_zero option is set all 0 uids will be unsorted and 
left at the top of the file, this is useful if you have more than 
one user with UID 0.

=cut

sub protect_zero {
	my ($self, $new_val) = @_;
	$self->{'protect_zero'} = 1 if $new_val;
	return $self->{'protect_zero'};
}

=head2 unprotect_zero

my $zero = $pass-unprotect_zero();
# or
$pass->unprotect_zero(1);

This function will allow you to view or unset the protect_zero 
parameter, if you pass a parameter it will set the protect_zero option
to undef, if you do not it will just return the currently set parameter.

If the protect_zero option is set all 0 uids will be unsorted and 
left at the top of the file, this is useful if you have more than 
one user with UID 0.

=cut

sub unprotect_zero {
	my ($self, $new_val) = @_;
	$self->{'protect_zero'} = undef if $new_val;
	return $self->{'protect_zero'};
}

=head2 verbose

my $verbose = $pass->verbose();
# or
$pass->verbose(1);

This function will allow you to view or set the verbose 
parameter, if you pass a parameter it will set the verbose option
to that parameter, if you do not it will just return the 
currently set parameter.

This is only useful during the passwd_sort function output 
will be printed to screen if this is enabled

=cut

sub verbose {
	my ($self, $new_val) = @_;
	$self->{'verbose'} = $new_val if $new_val;
	return $self->{'verbose'};
}

=head2 sort_field

my $sort_field = $pass->sort_field();
# or
$pass->sort_field(1);

This function will allow you to view or set the sort_field 
parameter, if you pass a parameter it will set the sort_field option
to that parameter, if you do not it will just return the 
currently set parameter.

The sort_field option determines which field to sort the passwd 
file by, the default is field 2 the UID field.

=cut

sub sort_field {
	my ($self, $new_val) = @_;
	if (($new_val) && ($new_val >= 0) && ($new_val <= 6)) {
		$self->{'sort_field'} = $new_val;
	}
	else {
		_error_msg($self, "$new_val not within 0 - 6 range");
		return 1;
	}
	return $self->{'sort_field'};
}

=head2 error

my $err = $pass->error();

This function will allow you to view any error messages

=cut

sub error {
	my $self = shift;
	return $self->{'error'};
}

=head2 sort_passwd

my $zero = $pass->sort_passwd();
# or
$pass->sort_passwd();

This function performs a sort on the current passwd file, 
technically this is a safe process the sort type is determined 
by the sort_field option or the default field 2 (array element 2)
this has been tested on Linux, Solaris 8, and almost 200 System V R 4.3
machines.  It should be safe on any standard unix passwd file.

The file is read into the function and the sorted output is written 
back to the file, it is suggested that you create a backup of the 
passwd file before running this function.

=cut

sub sort_passwd {
	my $self         = shift;
	my %sort_lines   = ();
	my @unsort_lines = ();
	my $sort_field   = shift;

        if (($self->{'sort_field'}) && ($self->{'sort_field'} <= 0) && ($self->{'sort_field'} >= 6)) {
		_error_msg($self, $self->{'sort_field'}." not within 0 - 6 range");
		return 1;    
	}
        elsif (($self->{'sort_field'}) && ($self->{'sort_field'} >= 0) && ($self->{'sort_field'} <= 6))	{
       		$sort_field = $self->{'sort_field'};
	}
	else {
		$sort_field = 2;
	}

	defined($self->{'passwd'}) ? my $passwd = $self->{'passwd'} : return 1;
  
	open(PWD,"$passwd") || _error_msg($self, "Cannot open $passwd: $!") && return 1; 
	{
		while(<PWD>) {
			chomp();
			my $line = $_;
			my @lines = split(":", $_, 6);
            
			if (($lines[2] == 0) && ($self->{'protect_zero'})) {
				print "Not sorting: $line" if $self->{'verbose'};
				push(@unsort_lines, $line);
			}
			else {
				if ( $sort_lines{$lines[$sort_field]} ) {
					$sort_lines{$lines[$sort_field]} .= "\n".$line;
				}
				else {
					$sort_lines{$lines[$sort_field]} = $line;
				}
			}
		}
	}
	close(PWD);

	open(PASS2, ">$passwd") || _error_msg($self, "Cannot open $passwd: $!") && return 1; ;
	{
		foreach my $key (@unsort_lines) {
			print PASS2 "$key\n";
		}

        	if ($sort_field !~ /[23]/) {
			foreach my $key (sort { $a cmp $b } keys %sort_lines) {
				print $sort_lines{$key}."\n" if $self->{'verbose'};
				print PASS2 $sort_lines{$key}."\n";
			}
        	}
		else {
			foreach my $key (sort { $a <=> $b } keys %sort_lines) {
				print $sort_lines{$key}."\n" if $self->{'verbose'};
				print PASS2 $sort_lines{$key}."\n";
			}
		}
	}
	close(PASS2);

    return 0;
}

=head2 populate_stats

$pass->populate_stats();

This function will populate an internal hash of arrays with the 
contents of the passwd file.  You can access these using the following:

$pass->{'file_stats'}->{'username'}->{'list'}[0];

You can substitute 'username' with 'uid', 'gid', 'fullname', 'homedir', 
and 'shell'.

=cut

sub populate_stats {
	my $self = shift;

	defined($self->{'passwd'}) ? my $passwd = $self->{'passwd'} : return 1;
  
	open(PWD,"$passwd") || _error_msg($self, "Cannot open $passwd: $!") && return 1; 

	while(<PWD>) {
		chomp;
		my @lines = split(/:/, $_);

		push(@{ $self->{'file_stats'}->{'username'}->{'list'} }, $lines[0]);
  		push(@{ $self->{'file_stats'}->{'uid'}->{'list'} },      $lines[2]);
		push(@{ $self->{'file_stats'}->{'gid'}->{'list'} },      $lines[3]);
		push(@{ $self->{'file_stats'}->{'fullname'}->{'list'} }, $lines[4]);
		push(@{ $self->{'file_stats'}->{'homedir'}->{'list'} },  $lines[5]);
		push(@{ $self->{'file_stats'}->{'shell'}->{'list'} },    $lines[6]);
	}

	close(PWD);
}

1;
__END__

=head1 SEE ALSO

man passwd

=head1 AUTHOR

Ben Maynard, E<lt>cpan@geekserv.comE<gt> E<lt>http://www.benmaynard.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2011 by Ben Maynard, E<lt>cpan@geekserv.comE<gt> E<lt>http://www.benmaynard.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
