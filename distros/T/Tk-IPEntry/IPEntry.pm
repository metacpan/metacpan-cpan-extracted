package Tk::IPEntry;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.9 $';
our $CheckinDate        = '$Date: 2002/12/11 16:24:03 $';
our $CheckinUser        = '$Author: xpix $';
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::Graph ----------------------------
#-------------------------------------------------

# -------------------------------------------------------
#
# Tk/IPEntry.pm
#
# A Megawidget for Input Ip-Adresses Ipv4 and Ipv6
#

=head1 NAME

Tk::IPEntry - A megawidget for input of IP-Adresses IPv4 and IPv6

=head1 SYNOPSIS

 use Tk;
 use Tk::IPEntry;

 my $mw = MainWindow->new();
 my $ipadress;

 my $entry = $mw->IPEntry(
	-variable  => \$ipadress,
 )->pack(-side => 'left');

 $ipadress = '129.2.32.1';

 MainLoop;

=cut

# -------------------------------------------------------
# ------- S O U R C E -----------------------------------
# -------------------------------------------------------
use strict;
use Carp;

use Tk;
use Tk::NumEntry;
use Tk::HexEntry;
use Tie::Watch;
use Net::IP;

# That's the Base
use base qw/Tk::Frame/;

# ... and construct the Widget!
Construct Tk::Widget 'IPEntry';

# ------------------------------------------
sub ClassInit {
# ------------------------------------------
    # ClassInit is called once per MainWindow, and serves to 
    # perform tasks for the class as a whole.  Here we create
    # a Photo object used by all instances of the class.

    my ($class, $mw) = @_;

    $class->SUPER::ClassInit($mw);

} # end ClassInit

# ------------------------------------------
sub Populate {
# ------------------------------------------
	my ($obj, $args) = @_;
	my %specs;
#-------------------------------------------------
	$obj->{type} = delete $args->{-type}  || 'ipv4';

=head2 -type (I<ipv4>|ipv6) 

The format of Ip-Number.

=cut

#-------------------------------------------------


=head1 METHODS

Here come the methods that you can use with this Widget.

=cut


#-------------------------------------------------

#-------------------------------------------------
	$specs{-variable}     	= [qw/METHOD  variable   Variable/, undef ];

=head2 $IPEntry->I<variable>(\$ipnumber);

Specifies the name of a variable. The value of the variable is a text string 
to be displayed inside the widget; if the variable value changes then the widget 
will automatically update itself to reflect the new value. 
The way in which the string is displayed in the widget depends on the particular 
widget and may be determined by other options, such as anchor or justify. 

=cut

#-------------------------------------------------
	$specs{-set}		= [qw/METHOD  set	Set/,	 undef];

=head2 $IPEntry->I<set>($ipnumber);

Set the IP number to display. You can use all standart format for IP-Adresses 
in Version 4 and Version 6. Here comes some examples, please look also in perldoc
from Net::IP:

  A Net::IP object can be created from a single IP address: 
  $ip->set('193.0.1.46') || die ...
  

  Or from a Classless Prefix (a /24 prefix is equivalent to a C class): 
  $ip->set('195.114.80/24') || die ...

  Or from a range of addresses: 
  $ip->set('20.34.101.207 - 201.3.9.99') || die ...
  

  Or from a address plus a number: 
  $ip->set('20.34.10.0 + 255') || die ...
 

  The set() function accepts IPv4 and IPv6 addresses 
  (it's necessary set -type option to 'ipv6'): 
  $ip->set('dead:beef::/32') || die ...


Very interesting feature, you can give Ip-Ranges and the user can only choice a 
Ip-Adress in this Range. The other Numbers is disabled. I.E.:

  $ip->set('195.114.80/24') || die ...
  $ip->set('dead:beef::/32') || die ...


=cut

#-------------------------------------------------
	$specs{-get}     	= [qw/METHOD  get        Get/, 	 undef ];

=head2 $IPEntry->I<get>();  

Here you can get IP number from display. This is also a Interface to Net::IP,
in example you will get the binary code from displayed IP-Number then you can
call:

  $IPEntry->get('binip');
  
Please look for all allow commands to Net::IP. 

=cut

#-------------------------------------------------
	$specs{-error}     	= [qw/METHOD  error      Error/, undef ];

=head2 $IPEntry->I<error>();  

This prints the last error.

=cut

	# Ok, here the important structure from the widget ....
	$obj->SUPER::Populate($args);

	$obj->ConfigSpecs(
		-get   	    => [qw/METHOD  get        Get/, 	 undef ],
		-error      => [qw/METHOD  error      Error/, 	 undef ],
		%specs,
	);

	# Widgets in the Megawidget
	# Next, we need 4 NumEntrys(ipv4)
	if(uc($obj->{type}) eq 'IPV4') 
	{
		foreach my $n (0..3) {
			$obj->{nummer}->[$n] = $obj->NumEntry(
				-width	      => 3,
				-minvalue     => 0,
				-maxvalue     => 255,
				-bell	      => 1, 
			)->pack(
				-side => 'left'
			);
			# Bindings
			$obj->{nummer}->[$n]->bind('<Key>', 	sub { $obj->fullip } );
			$obj->{nummer}->[$n]->bind('<Button>', 	sub { $obj->fullip } );
			$obj->{nummer}->[$n]->bind('<Leave>', 	sub { $obj->fullip } );
			$obj->{nummer}->[$n]->bind('<FocusOut>',sub { $obj->fullip } );
		}
	} 
	elsif(uc($obj->{type}) eq 'IPV6') 
	{
		foreach my $n (0..7) {
			$obj->{nummer}->[$n] = $obj->HexEntry(
				-width	      => 4,
				-minvalue     => 0x0000,
				-maxvalue     => 0xFFFF,
				-bell	      => 1, 
			)->pack(
				-side => 'left'
			);
		}
	}
	$obj->clear;
}

# ------------------------------------------
sub fullip {
# ------------------------------------------
	my ($obj) = @_;
	my $ok;
	foreach my $v (@{$obj->{minivrefs}}) {
		$ok = 1 if($v);
	}

	if( $ok ) {
		foreach my $v (@{$obj->{minivrefs}}) {
			$v = 0 unless($v);
		}
	}


}

# ------------------------------------------
sub clear {
# ------------------------------------------
	my ($obj) = @_;
	my $c = -1;
	foreach my $w (@{$obj->{nummer}}) {
		$c++;
		$obj->{minivrefs}->[$c] = undef;
		$obj->{nummer}->[$c]->configure(
			-textvariable => \$obj->{minivrefs}->[$c]
		);
		$w->delete('0','end');
	}
}

# ------------------------------------------
sub set {
# ------------------------------------------
	my ($obj, $adress) = @_;

	unless($adress) {
		$obj->clear();
		return;
	}

	unless(defined $obj->{IP}) {
		$obj->{IP} = Net::IP->new($adress) 
			|| return $obj->error( Net::IP::Error() );
	} else {
		$obj->{IP}->set($adress) 
			|| return $obj->error( $obj->{IP}->error() );
	}

	my ($first_ip, $last_ip) = $obj->ip_to_range($adress);
#	printf "First: %s, Last: %s\n",$first_ip, $last_ip;

	my $delm = (uc($obj->{type}) eq 'IPV4' ? '.' : ':');

	my @first = split( "\\$delm", $first_ip );
	my @last = split( "\\$delm", $last_ip );

	my $c = -1;
	foreach my $num ( split( "\\$delm", $obj->{IP}->ip ) ) {
		$c++;
		$obj->{minivrefs}->[$c] = $obj->check($num);
		$obj->{nummer}->[$c]->configure(
			-state => ( $first_ip ne $last_ip && $first[$c] eq $last[$c] ? 'disabled' : 'normal' ),
			-minvalue => ( $first[$c] eq $last[$c] ? (uc($obj->{type}) eq 'IPV4' ? 0 : 0x0000) : (uc($obj->{type}) eq 'IPV4' ? $first[$c] : hex($first[$c])) ),
			-maxvalue => ( $first[$c] eq $last[$c] ? (uc($obj->{type}) eq 'IPV4' ? 0xFF : 0xFFFF) : (uc($obj->{type}) eq 'IPV4' ? $last[$c] : hex($last[$c])) ),
			-textvariable => \$obj->{minivrefs}->[$c]
		);
	}
}

# ------------------------------------------
sub get {
# ------------------------------------------
	my ($obj, $ip_common) = @_;
	my ($addr);

	my $c = 0;
	my $delm = (uc($obj->{type}) eq 'IPV4' ? '.' : ':');

	foreach my $num ( @{ $obj->{minivrefs} } ) {
		next unless(defined $num);
		$addr .= $delm if($c++);
		$addr .= $obj->check($num);
	}

	$obj->{IP}->set($addr) 
			|| return $obj->error( $obj->{IP}->error() );

	if($ip_common) {
		return $obj->{IP}->$ip_common()
			|| return $obj->error( $obj->{IP}->error() );
	}

	return $addr;
}

# ------------------------------------------
sub check {
# ------------------------------------------
	my ($obj, $num) = @_;
	
	# Format
	$num = substr(lc($num), 0, 4)
		if(uc($obj->{type}) eq 'IPV6');

	# wrong?
	if( uc($obj->{type}) eq 'IPV4' && ! $num ) {
		return $num;		
	} elsif(uc($obj->{type}) eq 'IPV4' && (int($num) < 0 || int($num) > 255)) {
		$obj->error("Number($num) incorrect in IpRange");
		$num = ($num < 0 ? 0 : 255);
	}
	if(uc($obj->{type}) eq 'IPV6' && (! hex($num) && $num !~ /[0]+/)) {
		$obj->error("Number($num) incorrect in IpRange");
		$num = '0000';
	}
	return $num;
}

# ------------------------------------------
sub variable {
# ------------------------------------------
	my ($obj, $vref) = @_;
	
	$obj->{vref} = $vref
		unless(defined $obj->{vref});
	
	my $st = [sub {
		my ($watch, $new_val) = @_;
		my $argv= $watch->Args('-store');
		$argv->[0]->set($new_val);
		$watch->Store($new_val);
	}, $obj];

	my $fetch = [sub {
		my($self, $new) = @_;
		my $var = $self->Fetch;
		my $getvar = $obj->get();
		$self->Store($getvar)
			if($getvar);
		return ($getvar ? $getvar : $var);
	}, $obj];

	$obj->{watch} = Tie::Watch->new(
		-variable => $vref, 
		-store => $st, 
		-fetch => $fetch
	);

	$obj->OnDestroy( [sub {$_[0]->{watch}->Unwatch}, $obj] );

} # end variable

# ------------------------------------------
sub ip_to_range {
# ------------------------------------------
	my ($obj, $ip) = @_;

	my $addr = Net::IP->new($ip) 
		or return error("Cannot create IP object $_: ".Net::IP::Error());
		
#	printf ("%18s    %15s - %-15s [%s]\n",$addr->print(),$addr->ip(),$addr->last_ip(), $addr->size());

	return ($addr->ip(),$addr->last_ip());
}

# ------------------------------------------
sub error {
# ------------------------------------------
	my $self = shift;
	my ($package, $filename, $line, $subroutine, $hasargs,
    		$wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
	my $msg = shift || return undef;
	warn sprintf("ERROR in %s:%s #%d: %s",
		$package, $subroutine, $line, sprintf($msg, @_));
	unless($msg) {
		my $err = $self->{error};
		$self->{error} = '';
		return $err;
	}
	$self->{error} = $msg;
	return undef;
} 


1;
=head1 EXAMPLES

Please see for examples in 'demos' directory in this distribution.

=head1 AUTHOR

xpix@netzwert.ag

=head1 SEE ALSO

Tk;
Tk::NumEntry;
Tie::Watch;
Net::IP;

__END__
