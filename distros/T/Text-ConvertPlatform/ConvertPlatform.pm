package Text::ConvertPlatform;
use strict;
use vars qw($VERSION);

$VERSION = '1.00';

sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{FILENAME} = undef;
	$self->{OLDCONTENTS} = undef;
	$self->{NEWCONTENTS} = undef;
	$self->{CONVERTTO} = undef;
	bless ($self, $class);
	return $self;

	}

sub convert_to {

	my $self = shift;
	if (@_) { $self->{CONVERTTO} = shift }
	return $self->{CONVERTTO};

	}

sub filename {

	my $self = shift;
	if (@_) { $self->{FILENAME} = shift }
	return $self->{FILENAME};

	}

sub newcontents {

	my $self = shift;
	if (@_) { $self->{NEWCONTENTS} = shift }
	return $self->{NEWCONTENTS};

	}

sub oldcontents {

	my $self = shift;
	if (@_) { $self->{OLDCONTENTS} = shift }
	return $self->{OLDCONTENTS};

	}


sub process_file {
	
	my $self = shift;
	my $mode = $self->{CONVERTTO};
	my $file = $self->{FILENAME};
	my $old = undef;
	my $results = undef;
	open (FILE, "$file");
	while (<FILE>) {
		$old .= $_;
		# convert everything to unix first
		s/\015\012/\012/g;
		s/\015/\012/g;
		# if they want dos format
		s/\012/\015\012/g if ($mode eq "dos");
		# if they want mac format
		s/\012/\015/g if ($mode eq "mac");
		$results .= $_;
		}
	close (FILE);
	$self->{OLDCONTENTS} = $old;
	$self->{NEWCONTENTS} = $results;

}

sub replace_file {

	my $self = shift;
	my $file = $self->{FILENAME};
	open (NEWFILE, ">".$file);
	print NEWFILE $self->{NEWCONTENTS};
	close (NEWFILE);


}

sub backup_file {

	my $self = shift;
	my $file = $self->{FILENAME};
	$file .= ".bak";
	open (BAKFILE, ">$file");
	print BAKFILE $self->{OLDCONTENTS};
	close (BAKFILE);


}

1;

__END__

=head1 NAME


Text::ConvertPlatform - an object class for formatting text between 
			different platforms.


=head1 SYNOPSIS

 # Initialization statement
 my $philip = new Text::ConvertPlatform; # or whatever you prefer

 $philip->filename("i_love_unix.html");	# file that is to be worked on
 $philip->filename;	# returns current FILENAME
 $philip->convert_to("unix");	# set conversion mode - default is "unix"
				# there is no need to set this if you are
				# using the default 
				# other modes are: "dos", "mac"
 $philip->process_file;	# convert FILENAME 
 $philip->replace_file;	# overwrite FILENAME with NEWCONTENTS
 $philip->backup_file;	# create a copy of FILENAME with a .bak extension
 $philip->oldcontents;	# returns original contents of processed file
 $philip->newcontents;	# returns results of a processed file

=head1 DESCRIPTION

I've been quite bored at work lately and decided to write an easy way to 
format text between different platforms. Specifically, it converts return 
characters and optionally backs up the file it works on. 

=head1 AUTHOR

Philip Mikal, "djphil@aztec.asu.edu". Co-authored by Phil Stracchino. 
Inspired from Adrian Scott's em.pl, which was given to me from Ken 
Berger. I'd also like to thank Randy Ray for answering questions I had 
when setting up this distribution. 

=head1 SEE ALSO

perl(1).

=cut
