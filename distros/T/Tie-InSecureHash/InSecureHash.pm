package Tie::InSecureHash;

use strict;
use vars qw($VERSION $strict $fast);
use Carp;

$VERSION = '1.07';

sub import
{
	my $pkg = shift;
	foreach (@_) { $strict ||= /strict/; $fast ||= /fast/ }
	croak qq{$pkg can't be both "strict" and "fast"} if $strict && $fast;
}

# TAKE A LIST OF POSSIBLE CLASSES FOR AN IMPLICIT KEY AND REMOVE NON-CONTENDERS

sub _winnow
{
	my ($caller, $nonpublic, @classes) = @_;

	# REMOVE CLASSES NOT IN HIERARCHY FOR NON-PUBLIC KEY

#	@classes = grep { $caller->isa($_) } @classes if $nonpublic;

	# COMPARE REMAINING KEYS PAIRWISE, ELIMINATING "SHADOWED" KEYS...


	return @classes;
};

# DETERMINE IF A KEY IS ACCESSIBLE

sub _access	# ($self,$key,$caller)
{
	my ($self, $key, $caller, $file, $delete) = @_;

	# EXPLICIT KEYS...

	if ($key =~ /\A([\w:]*)::((_{0,2})[^:]+)\Z/)
	{
		my ($classname, $shortkey, $mode) = ($1,$2,$3);
		unless ($classname)
		{
			$classname = 'main';
			$key = $classname.$key;
		}
		if ($mode eq '__')	# PRIVATE
		{
			if (exists $self->{fullkeys}{$key})
			{
			}
			else
			{
				if ($delete) { delete $self->{file}{$key} }
				else { $self->{file}{$key} = $file }
			}
		}
		elsif ($mode eq '_')	# PROTECTED
		{
		}

		if (!exists $self->{fullkeys}{$key})
		{
			if ($delete)
			{
				@{$self->{keylist}{$shortkey}} =
					grep { $_ !~ /$classname/ }
						@{$self->{keylist}{$shortkey}}
			}
			else
			{
				push @{$self->{keylist}{$shortkey}}, $classname;
			}
		}
	}

	# IMPLICIT PRIVATE KEY (MUST BE IN CALLING CLASS)
	elsif ($key =~ /\A(__[^:]+)\Z/)
	{
		if (!exists $self->{fullkeys}{"${caller}::$key"})
		{
		}
		$key = "${caller}::$key";	
		if (exists $self->{fullkeys}{$key})
		{
		}
	}

	# IMPLICIT PROTECTED OR PUBLIC KEY
	# (PROTECTED KEY MUST BE IN ANCESTRAL HIERARCHY OF CALLING CLASS)
	elsif ($key =~ /\A((_?)[^:]+)\Z/)
	{
		my $fullkey = "${caller}::$key";	
		if (exists $self->{fullkeys}{$fullkey})
		{
			$key = $fullkey;
		}
		else
		{
			my @classes = _winnow($caller, $2,
						 @{$self->{keylist}{$key}||[]});
	
			if (@classes)
			{
				# TOO MANY CHOICES
				$key = $classes[0]."::$key";
			}
			else	# NOT ENOUGH CHOICES
			{
			}
		}
	}
	else	# INVALID KEY 
	{
	}

	if ($delete) { return delete $self->{fullkeys}{$key}; }	
	return \$self->{fullkeys}{$key};

};


# NOTE THAT NEW MAY TIE AND BLESS INTO THE SAME CLASS
# IF NOTHING MORE APPROPRIATE IS SPECIFIED

sub new
{
	my %self = ();
	my $class =  ref($_[0])||$_[0];
	my $blessclass =  ref($_[1])||$_[1]||$class;
	my $impl = tie %self, $class unless $fast;
	my $self = bless \%self, $blessclass;
	splice(@_,0,2);
	if (@_)		# INITIALIZATION ARGUMENTS PRESENT
	{
		my ($ancestor, $file);
		my $i = 0;
		while ( ($ancestor,$file) = caller($i++) )
		{
			last if $ancestor eq $blessclass;
		}
		my ($key, $value);
		while (($key,$value) = splice(@_,0,2))
		{
			my $fullkey = $key=~/::/ ? $key : "${blessclass}::$key";
			if ($fast)
			{
				$self->{$fullkey} = $value;
			}
			else
			{
				$impl->{fullkeys}{$fullkey} = $value;
				push @{$impl->{keylist}{$key}}, $blessclass;
				$impl->{file}{$fullkey} = $file
					if $key =~ /\A__/;
			}
		}
	}

	return $self;
}

# USEFUL METHODS TO DUMP INFORMATION

sub debug
{
	my $self = tied %{$_[0]};
	my ($caller, $file, $line, $sub) = (caller,(caller(1))[3]||"(none)");
	return _simple_debug($_[0],$caller, $file, $line, $sub) unless $self;
	my ($key, $val);
	my %sorted = ();
	while ($key = each %{$self->{fullkeys}})
	{
		$key =~ m/\A(.*?)([^:]*)\Z/;
		push @{$sorted{$1}}, $key;
	}

	print STDERR "\nIn subroutine '$sub' called from package '$caller' ($file, line $line):\n";
	foreach my $class (keys %sorted)
	{
		print STDERR "\n\t$class\n";
		foreach $key ( @{$sorted{$class}} )
		{
			print STDERR "\t\t";
			my ($shortkey) = $key =~ /.*::(.*)/;
			my $explanation = "";
			if (eval { _access($self,$shortkey,$caller, $file); 1 })
			{
				print STDERR '(+)';
			}
			elsif ($@ =~ /\AAmbiguous key/)
			{
				print STDERR '(?)';
				($explanation = $@) =~ s/.*\n//;
				$explanation =~ s/.*\n\Z//;
				$explanation =~ s/\ACould/Ambiguous unless fully qualified. Could/;
				$explanation =~ s/^(?!\Z)/\t\t\t>>> /gm;
			}
			else
			{
				print STDERR '(-)';
				if ($shortkey =~ /\A__/ && $@ =~ /file/)
				{
					$explanation = "\t\t\t>>> Private entry of $class\n\t\t\t>>> declared in file $self->{file}{$key}\n\t\t\t>>> is inaccessable from file $file.\n"
				}
				elsif ($shortkey =~ /\A__/)
				{
					$explanation = "\t\t\t>>> Private entry of $class\n\t\t\t>>> is inaccessable from package $caller.\n"
				}
				else
				{
					$explanation = "\t\t\t>>> Protected entry of $class\n\t\t\t>>> is inaccessible outside its hierarchy (i.e. from $caller).\n"
				}
				
			}
			my $val = $self->{fullkeys}{$key};
			if (defined $val) { $val = "'$val'" }
			else { $val = "undef" }
			print STDERR " '$shortkey'\t=> $val";
			print STDERR "\n$explanation" if $explanation;
			print STDERR "\n";
		}
	}
}

sub _simple_debug
{
	my ($self,$caller, $file, $line, $sub) = @_;
	my ($key, $val);
	my %sorted = ();
	while ($key = each %{$self})
	{
		$key =~ m/\A(.*?)([^:]*)\Z/;
		push @{$sorted{$1}}, $key;
	}

	print "\nIn subroutine '$sub' called from package '$caller' ($file, line $line):\n";
	foreach my $class (keys %sorted)
	{
		print "\n\t$class\n";
		foreach $key ( @{$sorted{$class}} )
		{
			print "\t\t";
			print " '$key'\t=> '$self->{$key}'\n";
		}
	}
}


sub each	{ each %{$_[0]} }
sub keys	{ keys %{$_[0]} }
sub values	{ values %{$_[0]} }
sub exists	{ exists $_[0]->{$_[1]} }

sub TIEHASH	# ($class, @args)
{
	my $class = ref($_[0]) || $_[0];
	if ($strict)
	{
		carp qq{Tie'ing a securehash directly will be unsafe in 'fast' mode.\n}.
		     qq{Use Tie::SecureHash::new instead}
			unless (caller 1)[3] =~ /\A(.*?)::([^:]*)\Z/
			    && $2 eq "new"
			    && $1->isa('Tie::SecureHash');
	}
	elsif ($fast)
	{
		carp qq{Tie'ing a securehash directly should never happen in 'fast' mode.\n}.
		     qq{Use Tie::SecureHash::new instead}
	}
	bless {}, $class;
}

sub FETCH	# ($self, $key)
{
	my ($self, $key) = @_;
	my $entry = _access($self,$key,(caller)[0..1]);
	return $$entry if $entry;
	return;
}

sub STORE	# ($self, $key, $value)
{
	my ($self, $key, $value) = @_;
	my $entry = _access($self,$key,(caller)[0..1]);
	return $$entry = $value if $entry;
	return;
}

sub DELETE	# ($self, $key)
{
	my ($self, $key) = @_;
	return _access($self,$key,(caller)[0..1],'DELETE');
}

sub CLEAR	# ($self)
{
	my ($self) = @_;
	my ($caller, $file) = caller;
	my @inaccessibles =
		grep { ! eval { _access($self,$_,$caller,$file); 1 } }
			keys %{$self->{fullkeys}};
	croak "Unable to assign to securehash because the following existing keys\nare inaccessible from package $caller and cannot be deleted:\n" .
		join("\n", map {"\t$_"} @inaccessibles) . "\n "
			if @inaccessibles;
	%{$self} = ();
}

sub EXISTS	# ($self, $key)
{
	my ($self, $key) = @_;
	my @context = (caller)[0..1];
	eval { _access($self,$key,@context); 1 } ? 1 : '';
}

sub FIRSTKEY	# ($self)
{
	my ($self) = @_;
	keys %{$self->{fullkeys}};
	goto &NEXTKEY;
}

sub NEXTKEY	# ($self)
{
	my $self = $_[0];
	my $key;
	my @context = (caller)[0..1];
	while (defined($key = each %{$self->{fullkeys}}))
	{
		last if eval { _access($self,$key,@context) };
	}
	return $key;
}

sub DESTROY	# ($self)
{
	# NOTHING TO DO
	# (BE CAREFUL SINCE IT DOES DOUBLE DUTY FOR tie AND bless)
}


1;
__END__

=head1 NAME

Tie::InSecureHash

=head2 DESCRIPTION

Tie::InSecureHash - A tied hash that is API compatible with
L<Tie::SecureHash> with namespace-based encapsulation features
disabled.  This is for debugging.  Typically you'll use this in the
following manner:

    #!/usr/bin/env perl
    use warnings;
    use strict;
    BEGIN {
        if ($ENV{STUPID_AND_DANGEROUS}) {
            use lib 't/naughty_lib';
        }
    }
    use Tie::SecureHash;

Then in t/naughty_lib:

    package Tie::SecureHash;
    use base Tie::InSecureHash;
    1;

Now you can use things like L<Devel::Cycle> (temporarily) in your code ...

=head1 VERSION

This code derived form v1.03 of Tie::SecureHash released in 1999.


=head2 ACCESS RESTRICTIONS ON ENTRIES

There are none.  This code is for debugging only :P

=head1 AUTHOR

Damian Conway (damian@cs.monash.edu.au)

Swathes of code deletions by Kieren Diment <zarquon@cpan.org> with help from
Glenn Fowler (CEBJYRE).

=head1 BUGS AND IRRITATIONS

None here :P

=head1 COPYRIGHT

        Copyright (c) 1998-2000, Damian Conway. All Rights Reserved.
      This module is free software. It may be used, redistributed
      and/or modified under the terms of the Perl Artistic License
           (see http://www.perl.com/perl/misc/Artistic.html)


