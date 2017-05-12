package blx::xsdsql::ios::debuglogger;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::ut::ut qw(nvl);

sub _get_called_frame {
	my $h=$_[0];
	$h->{LEVEL}=0 unless defined $h->{LEVEL};
	$h->{LEVEL}=0 unless $h->{LEVEL}=~/^\d+$/; 
	$h->{LEVEL}+=1; # exclude the frame _debug
	my ($package,$file,$line)=caller($h->{LEVEL});
	unless (defined $package) {
		my $level=$h->{LEVEL};
		while(--$level >= 0) {
			($package,$file,$line)=caller($level);
			last if defined $package;
		}
	}
	{
			PACKAGE	=> $package
			,FILE	=> $file
			,LINE	=> $line
	}
}

sub _get_norm_info {
	my $h=$_[0];
	my $r=ref($h);
	return {
		LINE => $h
	} unless $r;
	return $h if $r eq 'HASH';
	return {
		PACKAGE	=> $h->[0]
		,LINE => $h->[1]
	} if $r eq 'ARRAY';
	croak "$r: not supported\n";
}

sub _dumper {
	my $r=Dumper($_[0]);
	$r=~s/^/\n/;
	$r=~s/;$//m;
	$r;
}

sub _debug {
	return $_[0] unless $_[0]->{DEBUG};
	my ($self,$info,@l)=@_;
	my $i=_get_norm_info($info);
	my $caller=defined $i->{PACKAGE} && defined $i->{LINE} ? {} : _get_called_frame($i);
	for my $k(qw(PACKAGE LINE)) {
		$i->{$k}=$caller->{$k} unless defined $i->{$k};
	}	
	print STDERR $i->{PACKAGE},' (D ',$i->{LINE},'): ',join(' ',map { ref($_) eq "" ? nvl($_) : _dumper($_); } @l),"\n"; 
	$self;
}


sub new {
	my ($class,%params)=@_;
	bless \%params,$class;
}


sub log {
	my $self=shift;
	$self->_debug(@_);
}


1;



__END__


=head1  NAME

blx::xsdsql::ios::debuglogger - class for debug log

=head1  NAME

blx::xsdsql::ios::debuglogger - log into stderr debug information

=cut

=head1 SYNOPSIS

use blx::xsdsql::ios::debuglogger

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions

new - constructor

PARAMS:
    DEBUG  => set the debug mode - the debug information is not emitted if the attribute DEBUG is false


log - emit debug line

PARAMS: none

the first argument is a caller info and rest of the arguments are emitted on stderr

$log->log(undef,' 1^ line')  emit  the line  "<caller_package_name> (<caller_line>): 1^ line\n"
$log->log({PACKAGE => 'mypack'},'2^ line',{ x => 1 }) emit the line "mypack (<caller_line): 2^ line
{
   'x' => 1
}\n

$log->log({PACKAGE => 'mypack',LINE => 'myline'},'3^ line') emit the line "mypack (myline): 3^ line\n!



=cut




=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
