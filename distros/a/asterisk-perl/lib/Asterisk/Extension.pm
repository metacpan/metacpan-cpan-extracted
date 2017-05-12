package Asterisk::Extension;

require 5.004;

=head1 NAME

Asterisk::Extension - Stuff to deal with asterisk extension config

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;

$VERSION = '0.01';

$DEBUG = 1;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'exten'} = {};
	$self->{'contexts'} = {};
	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub exten {
	my ($self, $context, $extension, $priority, $value) = @_;

	$self->{'exten'}{$context}{$extension}[$priority] = $value;
}

sub getextensionarr {
	my ($self, $context, $extension) = @_;

	return @{$self->{'exten'}{$context}{$extension}};
}

sub getextensionlist {
	my ($self, $context) = @_;

	my @list = ();
#whats the best way to sort here
	foreach $ext (sort keys %{$self->{'exten'}{$context}} ) {
		push(@list, $ext);
	}
	
	return @list;
}


sub setvar {
	my ($self, $context, $var, $val) = @_;

	$self->{'vars'}{$context}{$var} = $val;
}

sub static {
	my ($self, $static, $context) = @_;

	$self->{'vars'}{$context}{'static'} = $static if defined($static);
	return $self->{'vars'}{$context}{'static'};
}

sub writeprotect {
	my ($self, $wp, $context) = @_;

	$self->{'vars'}{$context}{'writeprotect'} = $wp if defined($wp);
	return $self->{'vars'}{$context}{'writeprotect'};
}

sub matchpattern {
	my ($self, $dialednum, $extension) = @_;
	my $expr = '';
#N 1-9
#X 0-9
#. any one character
#_ or - ignore
	foreach $chr (split(//,$extension)) {
		if (($chr eq '-')||($chr eq '_')) {
			next;
		} elsif ($chr eq 'N') {
			$expr .= '[1-9]';
		} elsif ($chr eq 'X') {
			$expr .= '[0-9]';
		} else {
			$expr .= $chr;
		}
	}

	if ($dialednum =~ /^$expr$/) {
		return 1;
	} else {
		return 0;
	}


}

sub matchextension {
	my ($self, $context, $dialed) = @_;

	my %included = ();

	return 0 if (!defined($context)||!defined($dialed));
	my @contextlist = ( $context );

	foreach $cont (@contextlist) {
		foreach $ext ($self->getextensionlist($cont)) {
			if ($self->matchpattern($dialed, $ext)) {
				return ($ext, $cont);
			}
		}
	

		foreach $inccont (keys %{$self->{'contexts'}{$cont}}) {
			if (!defined($included{$inccont})) {
				push(@contextlist, $inccont);
			}
		}
	}

}

sub context {
	my ($self, $context, $include) = @_;

	if (!defined($self->{'contexts'}{$context}) ) {
		$self->{'contexts'}{$context} = {};
		$self->{'exten'}{$context} = {};
	}

	if (defined($include)) {
		$self->{'contexts'}{$context}{$include} = 1;
	}


}

sub getcontextarr {
	my ($self) = @_;


	my @arr = ();
	foreach $context ( keys %{$self->{'contexts'}} ) {
		push(@arr, $context);
	}

	return @arr;
}


sub writeconfig {
	my ($self, $filename) = @_;

	return if (!defined($filename));

	open(CFG, ">$filename") || die $!;
#	my @contextarr = ( 'general' );
	push(@contextarr, $self->getcontextarr());

	foreach $context (@contextarr) {
		print CFG "[$context]\n";
		foreach $var (keys %{$self->{'vars'}{$context}}) {
			print CFG "$var = " . $self->{'vars'}{$context}{$var} . "\n";
		}

		foreach $exten ($self->getextensionlist($context)) {
			my @extarr = $self->getextensionarr($context, $exten);
			for ($x=0; $x<=$#extarr; $x++) {
				print CFG "exten => $exten,$x,$extarr[$x]\n" if ($extarr[$x]);
			}
		}
				


	}


}

sub readconfig {
	my ($self, $filename) = @_;

	my $context = '';
	my $line = '';

	$filename = '/etc/asterisk/extensions.conf' if (!defined($filename));

	open(FN, "<$filename") || die $!;
	while ($line = <FN>) {
		chop($line);


		$line =~ s/;(.*)$//;
		$line =~ s/\s*$//;
		if ($line =~ /^;/)  {
			next;
		} elsif ($line =~ /^\s*$/) {
			next;
		} elsif ($line =~ /^static\s*[=>]\s*(.*)$/i) {
			$self->static($1,$context);
		} elsif ($line =~ /^writeprotect\s*[=>]\s*(.*)$/i) {
			$self->writeprotect($1,$context);
		} elsif ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			print STDERR "Context: $context\n" if ($DEBUG>3);
			$self->context($context);
		} elsif ($line =~ /^include\s*[=>]+>\s*(.+)$/) {
			my $include = $1;
			print STDERR "Include: $include\n" if ($DEBUG>3);
			$self->context($context, $include);
		} elsif ($line =~ /^exten\s*[=>]+\s*(.+)/) {
			my $extenstr = $1;
			print STDERR "ExtensionString: $extenstr\n" if ($DEBUG>3);
			my @extarr = split(/,/,$extenstr);
			my $exten = shift(@extarr);
			my $pri = shift(@extarr);
			my $addtl = join(',', @extarr);
			$self->exten($context, $exten, $pri, $addtl);
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}


	}

	close(FN);



}




1;
