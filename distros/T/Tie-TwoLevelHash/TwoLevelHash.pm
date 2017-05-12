package Tie::TwoLevelHash;

# $Id: TwoLevelHash.pm,v 1.2 1998/10/30 13:52:04 kmeltz Exp kmeltz $

# $Log: TwoLevelHash.pm,v $
# Revision 1.2  1998/10/30 13:52:04  kmeltz
# Fixed FETCH so it will return correctly when doing %foo = %bar; when using a tie to a HoH's. Still not working right for hash in the HoH's, so the GetHash method stays.
#
#
# Revision 1.1  1998/10/27 15:43:47  kmeltz
# Changed croaks to carps for Hash Invalid warning. May need to continue script, so let script die and module return undef.
# Changed CLEAR to not erase TLH file when clearing hash in HoH's, or resetting it.
# Added exported method GetHash. This allows for user to import hash values into their script, and change values before setting them to TLH file.
# Changed a bunch in the POD.
#

use FileHandle;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter); 
@EXPORT = qw();
use strict;

($VERSION = substr(q$Revision: 1.2 $, 10)) =~ s/\s+$//;

sub TIEHASH {
	my $self = shift;
	my $path = shift;
	my $mode = shift || 'r';
	my $oneHash = "";	
	my ($comment, %tlhash, %unihash, $key);
	my $single=0;

	# Check to see if $path has two elements
	if ($path =~ /,/) {
		($path, $oneHash) = split(/,/,$path);
	}

	if (@_) {
		croak ("usage: tie(\%hash, \$file[, Hash name], [mode])");
	}

	# Nice-ify $path:
	$path =~ s#/$##;

	# Can we make changes to the database?
	my $clobber = ($mode eq 'rw' ? 1 : 0);

	unless (-e $path) {
		if ($clobber) {
			# Create the tlh if it does not exist
			unless (open(FH,">$path")) {croak("Can't create $path: $!");}
		} else {
			croak("$path does not exist");
		}
	#croak "File does not exist\n";
	}
	close FH;

	# Get a filehandle and open the file:
	my $fh = new FileHandle;
	open($fh, $path) or croak("can't open $path: $!");

	my $tlh;

	# Showing one hash
	if ($oneHash ne "") {
		$oneHash =~ s/^\s//;
		($comment, %unihash) = $self->_get_HoH($path);
		#%tlhash = $self->_get_SingHash("$oneHash", $path);
		foreach $key (keys %unihash) {
			if ($key eq $oneHash) {
				%tlhash->{$key} = $unihash{$key};
			}
		}
		$single=1;
	# Show HoH's
	}else{
		($comment, %tlhash) = $self->_get_HoH($path);
	}

	my $node = {
		PATH    => $path,
		CLOBBER	=> $clobber,
		HANDLE	=> $fh,
		SINGLEHASH => $single,
	};
		$node->{BIHASH} = \%tlhash;
		$node->{UNIHASH} = \%unihash if defined(%unihash);
		$node->{UNIHASHNAME} = $oneHash if defined(%unihash);
		$node->{COMMENTS} = $comment if defined($comment);

if ($oneHash ne "" ) { $node->{SINGLEHASH} = 1; }else{$node->{SINGLEHASH} = 0;}

	return bless $node => $self;
	
}

#-------------------------------------------------------#

sub FETCH { 
	my $self = shift;
	my $key	= shift;
	
	# If showing one hash
	if ($self->{SINGLEHASH}) {
		my $uniname = $self->{UNIHASHNAME};
	if ($key eq $uniname) {
		my %return = $self->GetHash();
		return \%return;
	}
	        unless (exists $self->{BIHASH}->{$uniname}->{$key}) {
			carp "Hash invalid";
			return undef;
            	 }
		if (defined $self->{BIHASH}->{$uniname}->{$key}) {
        		return $self->{BIHASH}->{$uniname}->{$key};
       		 } else {
        	       return carp("Fetch failed for $key");
       		 }
	}
	
	# If showing HoH's
        unless (exists $self->{BIHASH}->{$key}) {
		carp "Hash invalid";
		return undef;
             }
	if (defined $self->{BIHASH}->{$key}) {
        	return $self->{BIHASH}->{$key};
        } else {
               return carp("Fetch failed for $key");
        }
}

#-------------------------------------------------------#

sub STORE {
	my $self = shift;
	my $key	= shift;
	my $value;# = shift || "";
	my ($inKey);
	my $file = $self->{PATH};
	my ($foo,$val,$bar,$str, %value);
	my (%foo);
	my $single = $self->{SINGLEHASH};
	my %bihash = %{$self->{'BIHASH'}};
	my (%unihash);

	if ($single) {%unihash = %{$self->{'UNIHASH'}}; $value = shift;}else{$value=shift || "";}

	# HoH's AND no value/undef
	if (!$single && $value eq "") {
		if (!$self->EXISTS($key)) {
			carp("Tried deleting $key which doesn't exist");	
			return 0;
		}
		
		if (!$self->_deleteRecord($key)) {
			return 0;
		} else {
			return 1;
		}
	}

	if (!$single) {
		%value = %$value;  
	}  

	unless ($self->{CLOBBER}) {
		carp ("No write access for $self->{'PATH'}");
		return;
	} 

	my $fh;
	unless ($fh = new FileHandle(">$file")) {
	#unless ($fh = new FileHandle("$file")) { # DEBUG
		croak ("Can't open $file: $!");
	}

	# Set the new value in original hash
	if (!$single) {
		foreach $inKey (sort keys %value) {
		#print "$inKey $value{$inKey}\n"; # DEBUG
			if ($inKey eq "") {
				undef $bihash{$key}{$inKey};
				next;
			}
		$bihash{$key}{$inKey} = $value{$inKey};
		}
	} else {
		if (!defined($value)) {
		undef $unihash{$self->{UNIHASHNAME}}{$key};
		undef $bihash{$key};
		
		}

	$unihash{$self->{UNIHASHNAME}}{$key} = $value;
	$bihash{$key} = $value;

	}# endif

	# If there were comments on the top, re-write them first
	if (defined($self->{COMMENTS})) {
		my $comment = $self->{COMMENTS};
		$str .= "$comment";
	}		


	# Run through HoH from memory and get out each Hash in %zog
	if (!$single) {
		foreach $foo (sort keys %bihash) {
			$str .= "\n$foo\n";
			my $zog = $bihash{$foo};
			my %zog=%$zog;
			# Get all values in %zog 
				foreach $bar (sort keys %zog) {
					$str .= "\t$bar\: $zog{$bar}\n" unless !defined($zog{$bar});
				}
		}
	} else {
		foreach $foo (sort keys %unihash) {
			$str .= "\n$foo\n";
			my $zog = $unihash{$foo};
			my %zog=%$zog;
			# Get all values in %zog 
				foreach $bar (sort keys %zog) {
					$str .= "\t$bar\: $zog{$bar}\n" unless !defined($zog{$bar});
				}
		}
	}
	$self->{'UNIHASH'} = \%unihash if defined(%unihash);
	$self->{'BIHASH'} = \%bihash;
	print $fh $str;
	close $fh;
	return 1;
}

#-------------------------------------------------------#

sub DELETE {
	my ($self) = shift;
	my ($key) = shift;
	if ($self->{SINGLEHASH}) {
		delete $self->{UNIHASH}->{$key};
		delete $self->{BIHASH}->{$key};
	}else{ 
		delete $self->{BIHASH}->{$key};
	}
}

#-------------------------------------------------------#

sub CLEAR { 
	my ($self) = shift;
	my ($key);
	my ($file) = $self->{'PATH'};

	if ($self->{SINGLEHASH}) {
		foreach $key (keys %{$self->{BIHASH}}) {
			$self->DELETE($key);
		}
	return 1;
	}
	foreach $key (keys %{$self->{BIHASH}}) {
        	$self->DELETE($key);
        }


	# Erase file, since it is being cleared

	unless ($self->{SINGLEHASH}) {
	my $fh;
		unless ($fh = new FileHandle(">$file")) {
		#unless ($fh = new FileHandle("$file")) { # DEBUG
			croak ("Can't open $file: $!");
		}
	close $fh;
	}
	# File erased, if tied to HoH

}

#-------------------------------------------------------#

sub EXISTS {
	my $self = shift;
	my $key	= shift;

        return exists $self->{BIHASH}->{$key};
}

#-------------------------------------------------------#

sub DESTROY {
	my $self = shift;
	my $node = {};
}

#-------------------------------------------------------#

sub FIRSTKEY {
        my $self = shift;
        my $a = keys %{$self->{BIHASH}};
        each %{$self->{BIHASH}}
}

#-------------------------------------------------------#

sub NEXTKEY {
	my $self = shift;
        return each %{$self->{BIHASH}}
}

#-------------------------------------------------------#

sub _deleteRecord { 
	my $self = shift;
	my $record = shift;
	if (!defined($record)) {
		carp("Not enough args passed to _deleteRecord");
		return 0;
	}
	my $file = $self->{PATH};
	my ($foo,$str,$bar);
	my $fh;
	unless ($fh = new FileHandle(">$file")) {
	#unless ($fh = new FileHandle("$file")) { # DEBUG
		croak ("can't open $file: $!");
	}
	my %bihash = %{$self->{'BIHASH'}};
	$str .= $self->{'COMMENTS'} if defined($self->{'COMMENTS'});

	foreach $foo (sort keys %bihash) {
		#print "$foo $bihash{$foo} d\n";
		if ($foo eq $record) {
		#$bihash{$foo} = undef;
			next;
		}
		$str .= "\n$foo\n";
		my $zog = $bihash{$foo};
		my %zog=%$zog;
		# Get all values in %zog 
			foreach $bar (sort keys %zog) {
				$str .= "\t$bar\: $zog{$bar}\n" unless !defined($zog{$bar});
			}
	}

	$self->{'BIHASH'} = \%bihash;
print $fh $str;
close $fh;
return 1;
}

#-----------------------------------------------------------#

sub _get_HoH {
	my ($self) = shift;
	my ($slh) = shift;
	my ($key, $val);
	my ($name, @lines, $rec, $line);
	my (%HoH);
	my ($FH) = new FileHandle;

	if (!open($FH,"$slh")) {
		croak "Cannot open $FH $slh: $!";
	}

local $/ = "";

my @records = <$FH>;

# Make sure comments at top of TLH file stay
my $comment;
if ($records[0] && $records[0] =~ /^#/) {
	$comment = $records[0];
	chop $comment;
	shift @records;
}
	foreach $rec (@records) {

    ($name, @lines) = split /\n[\s]*/, $rec;

    foreach $line (@lines) {
        ($key, $val) = split /:\s*/, $line;
	$HoH{$name}->{$key} = $val;

    }
}
	if (!close($FH)) {
		croak "Cannot close $FH: $!";
	}

return ($comment, %HoH);
} # end _get_HoH

#-----------------------------------------------------------#

sub GetHash {
	my ($self) = shift;
	my ($hash, %hash);
	my $name = $self->{UNIHASHNAME} if ($self->{UNIHASHNAME} ne "");
	
	if (defined($name)) {
		$hash = $self->{BIHASH}->{$name};
	}else{
		$hash = $self->{BIHASH};
	}
	%hash = %$hash;

	return %hash;
}

#-----------------------------------------------------------#

1;

__END__

=head1 NAME

Tie::TwoLevelHash - Tied interface to multi-dimensional (Two-Level) hash files

=head1 SYNOPSIS

 # Tie to Hash-o-hashes	
 use Tie::TwoLevelHash;
 tie (%hash, 'Tie::TwoLevelHash', $file, 'rw');  # Open in read/write mode

 $hash{PEOPLE} = {YOU => "me"}; # Set value YOU in hash PEOPLE withing hash %hash to "me"
	
 # Tie to hash within a Hash-o-hashes
 use Tie::TwoLevelHash:
 tie (%hash, 'Tie::TwoLevelHash', "$file, <SingHash>" 'rw');  # Open in read/write mode

 $hash{YOU} = "me"; # Set key YOU in hash <SingHash> (within HoH's) to "me"

 untie %hash;
 
 tie (%hash, 'Tie::TwoLevelHash', $file);    # Defaults to read-only mode

 ...

 untie %hash;

=head1 DESCRIPTION

This is the Tie::TwoLevelHash module.  It is a TIEHASH interface which lets you
tie to a text file which is a multi-dimensional (two level) hash.

To use it, tie a hash to a directory:

 tie(%hash, 'Tie::TwoLevelHash', $file, 'rw');  # Open in read/write mode

If you pass 'rw' as the third parameter, you'll be in read/write mode,
and any changes you make to the hash will create or modify the file.
If you don't open in read/write mode you'll be in read-only mode, 
and any changes you make to the hash won't have any effect
in the given file. It's actually useless to tie to the file in read mode
and make write calls to it, or the hash you are tying to it. If you do, it 
may croak, depending on what you are trying. If you want to grab values and
play with them, do that in your script, and get the values out of the hash name
you are tying with, so you can write to a local hash, and not affect, or try to affect
the hash you are tying with.

=head1 Two Level Hash Files

A two level hash file (I use a .tlh extension) is a file after the same format as
the defunct(?) Windows .ini files. A simple example of a small TLH file is as follows:

=over 5

	# This is a TLH file
	# Comments on top of this file are allowed

	COLORS
		Red: #ff0000
		Black: #000000
		White: #ffffff

	PEOPLE
		Dog: Zeke
		Cat: Tigger
		PerlHacker: Randal
		Author: Kevin Meltzer

	EXTRA
		Key: Val
		Test: Vest


=back 

This file is a textual representation of a two-level hash, also known as a 
Hash of hashes. The file itself is the main hash, and each section contains another
hash. So, this file contains the hash COLORS the hash PEOPLE and the hash EXTRA. 
B<Tie::TwoLevelHash> allows for you to tie to the entire hash of hashes, or directly 
to one of the hashes within that hash of hashes. When you make a change in your 
script to the tied hash, it makes that change in your file.

=head1 EXAMPLES

=head2 Tying to hash of hashes

=over 5

	$file = "foo.tlh";
	tie(%hash, 'Tie::TwoLevelHash', $file, 'rw');

	# Set %foo to equal %hash
	%foo = %hash;

	# Grab value of BAR in hash FOO into $bar
	$bar = $hash{FOO}->{BAR};

	# Set existing value
	$hash{PEOPLE} = {You => "me"};

	# Set new value
	$hash{COLORS} = {YELLOW => "flowery"};	

	# Set new record
	$hash{HATS} = {BLACK => "Cowboy", RED => "Baseball", WHITE => "Beanie"}; 

	# Add new record with predefined hash
	%new = (ONE => "1",
		TWO => "2",
		THREE => "3",
		FOUR => "4",
		);

	$hash{NUM} = {%new}; # Works, or can use \%new instead of {%new}

	# Clear, set then delete entry
	$hash{PEOPLE} = {FOO => ""};
	$hash{PEOPLE} = {FOO => "Bar"};
	$hash{PEOPLE} = {FOO => undef};

	# Added new element to existing record
	$hash{PEOPLE} = {'FOO' => "FOObar"};

	$hash{EXTRA} = undef;

	untie %hash;
	

	The resulting TLH file would be (assuming you began with the TLH example above):

	# This is a TLH file
	# Comments on top of this file are allowed

	COLORS
		Black: #000000
		Red: #ff0000
		White: #ffffff
		Yellow: flowery

	HATS
		BLACK: Cowboy
		RED: Baseball
		WHITE: Pope hat


	NUM
		FOUR: 4
		ONE: 1
		THREE: 3
		TWO: 2

	PEOPLE
		Author: Kevin Meltzer
		Cat: Tigger
		Dog: Zeke
		FOO: FOObar
		PerlHacker: Randal

=back

=head2 Tying to a hash within a hash of hashes

=over 5

	tie(%hash, 'Tie::TwoLevelHash', "$file, PEOPLE", 'rw');
	
	# Set %foo to equal %hash
	%foo = %hash;

	# Grab value of FOO into $bar
	$bar = $hash{FOO};

	# Set existing value
	$hash{Cat} = "Gizmo";

	# Set new value	
	$hash{Someone} = "Larry"; 

	# Clear, set then delete entry
	$hash{FOO} = "";
	$hash{FOO} = "bar";
	$hash{FOO} = undef;

	untie %hash;

The resulting TLH file would be:

	# This is a TLH file
	# Comments on top of this file are allowed

	COLORS
		Red: #ff0000
		Black: #000000
		White: #ffffff

	PEOPLE
		Author: Kevin Meltzer
		Cat: Gizmo
		Dog: Zeke
		PerlHacker: Randal
		Someone: Larry

	EXTRA
		Key: Val
		Test: Vest

=back

=head2 Getting the value of your tied hash to your local script

When you are tied to the hash, tie doesn't actually export the values in that
hash (or HoH) by default. So, B<Tie::TwoLevelHash> exports a method that allows
you to muck around with the hash's actual values within your script. This can also be
useful if, for whatever reason, you don't want to write out the hash file whenever
you make a change, and wish to do it at a later time, while still working with
the new values.

=head3 With a hash-o-hashes

=over 5

	# Tie your hash, but use a scaler to be object-like 
	tie(%hash, "Tie::TwoLevelHash" , $file, 'rw');
	
	# Make untied copy of your tied HoH
	%bar = %hash;

Now, you can generally use %bar as you would any other hash-o-hashes. Above we
tied to the entire hash-o-hashes, so %bar will be filled with hash
references. You could do something like the following to list all the
hash names, and values:

	foreach $key (keys %bar) {
	print "$key\n";
		$foo = $bar{$key};
		%foo = %$foo; # Deref the lower hash
		foreach $fookey (keys %foo) {
			print "\t$fookey\: $foo{$fookey}\n";
		}
	}

Now, say you wanted to change one of the values, but not change it in
your TLH file just yet. You can do this like:
	

	# This line changes the value in %bar
	$bar{PEOPLE}->{Comedian} = "Sienfeld";
	
	# This line writes the new value to your tied hash (and TLH)
	$hash{PEOPLE} = $bar{PEOPLE};

=back

=head3 With a hash in a hash-o-hashes

=over 5

This way is slightly different. Right now, trying to make a copy of your
hash the same way you do above, does not copy the hash correctly. So,
there is a method, B<GetHash> , which will export it correctly.

	# Tie your hash, but use a scaler to be object-like 
	$foo = tie(%hash, "Tie::TwoLevelHash" , "$file, PEOPLE", 'rw');

	# Now, we will call the method that exports the hash
	# We will import it into the hash %bar
	%bar = $foo->GetHash;

Now, you can generally use %bar as you would any other hash. Above we
tied only to one hash in the hash-o-hashes, so %bar will be one hash. 
You could do something like the following to list all the hash names, and values:

	foreach $key (keys %goo) {
		print "$key\: $goo{$key}\n";
	}

Now, if you wanted to change values before writting the new TLH file out via
your tie:

	# This line will set key Comedian to Sienfeld locally
	$bar{Comedian} = "Sienfeld";

	# Now, we write out the new hash
	%hash = %bar;


=back


=head1 CHANGING VALUES

I won't go into how to change value in a hash. When you are tying to 
a hash in the hash of hashes, you make your calls as usual. You make your
calls as usual when you are tied to the entire HoH's, except when you are setting
new values (anything that would call STORE).

Due to tie() not being very friendly while tying to HoH's, you can I<not> make 
a call such as 

$hash{FOO}->{BAR} = "zog";

when tied to a HoH's. So, you must make this call like:

$hash{FOO} = {BAR => "zog"};

You can see how/when to do this in the EXAMPLE section.
When you want to delete a key in a hash, use undef like:

$hash{FOO} = {BAR => undef};

or, when tying to single hash:

$hash{BAR} = undef;

%hash = (); 

This will CLEAR the hash, as well as remove ALL data from the file you are tied to.
Be B<sure> you want to do this when you call it.

=head1 INSTALLATION

You install Tie::TwoLevelHash, as you would install any perl module library,
by running these commands:

   perl Makefile.PL
   make
   make test
   make install
   make clean

=head1 AUTHOR

Copyright 1998, Kevin Meltzer.  All rights reserved.  It may
be used and modified freely, but I do request that this copyright
notice remain attached to the file.  You may modify this module as you
wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
kmeltz@cris.com

The author makes no warranties, promises, or gaurentees of this software. As with all
software, use at your own risk.

=head1 VERSION

Version $Revision: 1.2 $  $Date: 1998/10/30 13:52:04 $

=head1 CHANGES

$Log: TwoLevelHash.pm,v $
Revision 1.2  1998/10/30 13:52:04  kmeltz
Fixed FETCH so it will return correctly when doing %foo = %bar; when using a tie to a HoH's. Still not working right for hash in the HoH's, so the GetHash method stays.

Revision 1.1  1998/10/27 15:43:47  kmeltz
Changed croaks to carps for Hash Invalid warning. May need to continue script, so let script die and module return undef.
Changed CLEAR to not erase TLH file when clearing hash in HoH's, or resetting it.
Added exported method GetHash. This allows for user to import hash values into their script, and change values before setting them to TLH file.
Changed a bunch in the POD.


=head1 AVAILABILITY

The latest version of Tie::TwoLevelHash should always be available from:

    $CPAN/modules/by-authors/id/K/KM/KMELTZ/

Visit http://www.perl.com/CPAN/ to find a CPAN
site near you.

=head1 SEE ALSO

L<perl(1)>, L<perlfunc(1)>, L<perltie(1)>

=cut
