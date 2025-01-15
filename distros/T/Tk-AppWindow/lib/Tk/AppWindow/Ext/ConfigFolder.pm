package Tk::AppWindow::Ext::ConfigFolder;

=head1 NAME

Tk::AppWindow::Ext::ConfigFolder - save your settings files in a ConfigFolder

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";

use File::Path qw(make_path);
use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';


use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-configfolder> I<hookable>

The default value depends on your operating system.

On Windows: $ENV{LOCALAPPDATA}/appname
Others: $ENV{HOME}/.local/share/appname

You can overwrite it at launch by setting a folder yourself.

=back

=cut

my $configfolder;
if ($Config{osname} eq 'MSWin32') {
	$configfolder = $ENV{LOCALAPPDATA} . '\\' 
} else {
	$configfolder = $ENV{HOME} . '/.local/share/'
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->configInit(
		-configfolder => ['ConfigFolder', $self, $configfolder . $self->configGet('-appname')],
	);

	return $self;
}

=head1 METHODS

=over 4

=item B<confFileName>I<($file)>

Prepends the config folder location to $file and returns it.

=cut

sub confFileName {
	my ($self, $file) = @_;
	if ($mswin) {
		return $self->ConfigFolder . "\\$file"
	} else {
		return $self->ConfigFolder . "/$file"
	}
}

=item B<confFileName>I<($file)>

Returns true if $file exists in the config folder.

=cut

sub confExists {
	my ($self, $file) = @_;
	my $target = $self->confFileName($file);
	return -e $target;
}

sub ConfigFolder {
	my $self = shift;
	if (@_) { $self->{CONFIGFOLDER} = shift }
	my $f = $self->{CONFIGFOLDER};
	unless (-e $f) {
		unless (make_path($f)) {
			die "Could not create path $f";
		}
	}
	return $self->{CONFIGFOLDER}
}

=item B<loadHash>I<($file, $id)>

Loads the hash stored in $file. $id is the file id on the first line of the file it should match.

=cut

sub loadHash {
	my ($self, $file, $id) = @_;
	my $target = $self->confFileName($file); 
	my %hash = ();
	if (open(OFILE, "<", $target)) {
		my $fid = <OFILE>;
		chomp $fid;
		if ($fid eq $id) {
			while (<OFILE>) {
				my $l = $_;
				chomp($l);
				if ($l =~ s/^([^=]+)=//) {
					my $key = $1;
					$hash{$key} = $l;
				} else {
					warn "Error in format of file $file\n";
				} 
			}
		} else {
			warn "File id does not match for $file"
		}
		close OFILE;
	} else {
		warn "cannot open file $file\n";
	}
	return %hash
}

=item B<loadList>I<($file, $id)>

Loads the list stored in $file. $id is the file id on the first line of the file it should match.

=cut

sub loadList {
	my ($self, $file, $id) = @_;
	my $target = $self->confFileName($file); 
	my @list = ();
	if (open(OFILE, "<", $target)) {
		my $fid = <OFILE>;
		chomp $fid;
		if ($fid eq $id) {
			while (<OFILE>) {
				my $l = $_;
				chomp($l);
				push @list, $l
			}
		} else {
			warn "File id does not match for $file"
		}
		close OFILE;
	} else {
		warn "cannot open file $file\n";
	}
	return @list
}

=item B<loadSectionedList>I<($file, $id)>

Loads the sectioned list stored in $file. $id is the file id on the first line of the file it should match.

=cut

sub loadSectionedList {
	my ($self, $file, $id) = @_;
	my $target = $self->confFileName($file); 
	my @list = ();
	if (open(OFILE, "<", $target)) {
		my $section;
		my %inf = ();
		my $fid = <OFILE>;
		chomp $fid;
		if ($fid eq $id) {
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ /^\[([^\]]+)\]/) { #new section
#	 				print "new section $1\n";
					if (defined $section) {
#	 					print "pushing $section\n";
						my %o = %inf;
						push @list, [$section, \%o];
					}
					$section = $1;
					%inf = ();
				} elsif ($line =~ s/^([^=]+)=//) { #new key
					$inf{$1} = $line;
				} else {
					warn "Error in format of file $file\n";
				}
			}
		} else {
			warn "File id does not match for $file"
		}
		if ((%inf) and (defined $section)) {
			push @list, [$section, \%inf];
		}
		close OFILE;
	} else {
		warn "cannot open file $file\n";
	}
	return @list
}

=item B<saveHash>I<($file, $id, %hash)>

Saves %hash to $file. $id is the file id and is written as the first line.

=cut

sub saveHash {
	my ($self, $file, $id, %hash) = @_;
	my $target = $self->confFileName($file); 
	if (open(OFILE, ">", $target)) {
		print OFILE $id . "\n";
		for (sort keys %hash) {
			my $key = $_;
			my $val = $hash{$key};
			print OFILE "$key=$val\n"
		}		
		close OFILE
	}
}

=item B<saveList>I<($file, $id, @list)>

Saves @list to $file. $id is the file id and is written as the first line.

=cut

sub saveList {
	my ($self, $file, $id, @list) = @_;
	my $target = $self->confFileName($file); 
	if (open(OFILE, ">", $target)) {
		print OFILE $id . "\n";
		for (@list) { print OFILE $_ . "\n" }		
		close OFILE
	}
}

=item B<saveSectionedList>I<($file, $id, @list)>

Saves @list as a sectioned list $file. $id is the file id and is written as the first line.

=cut

sub saveSectionedList {
	my ($self, $file, $id, @list) = @_;
	my $target = $self->confFileName($file); 
	if (open(OFILE, ">", $target)) {
		print OFILE $id . "\n";
		for (@list) {
			my ($section, $hash) = @$_;
			print OFILE "[$section]\n";
			my %h = %$hash;
			for (sort keys %h) {
				my $key = $_;
				my $val = $h{$key};
				print OFILE "$key=$val\n"
			}		
		}		
		close OFILE
	}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=back

=cut

1;





