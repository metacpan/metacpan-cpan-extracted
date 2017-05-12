#-----------------------------------------------------------------
package DeltaX::Language;
#-----------------------------------------------------------------
# $Id: Language.pm,v 1.1 2003/03/17 13:01:36 spicak Exp $
#
# (c) DELTA E.S., 2002 - 2003
# This package is free software; you can use it under "Artistic License" from
# Perl.
#-----------------------------------------------------------------

$DeltaX::Language::VERSION = '1.0';

use strict;
use Carp;

#-----------------------------------------------------------------
sub new {
#-----------------------------------------------------------------
# CONSTRUCTOR
#
	my $pkg = shift;
	my $self = {};
	bless ($self, $pkg);

	my $filename = shift;
	croak ("You must supply filename!") unless defined $filename;
	$self->{filename} = $filename;
	if (@_ % 2) {
	$self->{separator} = shift || "\t";
	} else {
	$self->{separator} = "\t";
	}
	$self->{error}	= '';
	$self->{conflicts}= ();

	croak ("$pkg created with odd number of parameters - should be of the form option => value")
	if (@_ % 2);
	for (my $x = 0; $x <= $#_; $x += 2) {
	$self->{special}{$_[$x]} = $_[$x+1];
	}

	return $self;
}
# END OF new()

#-----------------------------------------------------------------
sub read {
#-----------------------------------------------------------------
#
	my $self = shift;

	local(*INF);
	if (! open INF, $self->{filename}) {
		$self->{error} = "cannot read file '".$self->{filename}."': $!";
		return undef;
	}

	my %ret;

	my $sep = $self->{separator};
	while (<INF>) {
		chomp;
		if (/^[ ]*#/) {
			s/^[ ]*#[ ]*//g;
			if (/^!(.*)$/) {
				my $tmp = $self->_special($1);
				if (! defined $tmp) { return undef; }
				foreach my $key (keys %{$tmp}) {
					if (exists $ret{$key}) {
						push @{$self->{conflicts}}, $key;
					}
					$ret{$key} = $tmp->{$key};
				}
				# separator may changed
				$sep = $self->{separator};
			}
		} else {
			my ($key, $val) = split(/$sep/, $_, 2);
			next if !$key;
			$val = $val ? $val : '';
			if (exists $ret{$key}) {
				push @{$self->{conflicts}}, $key;
			}
			if ($val and $val =~ /^%/) {
				if (exists $ret{substr($val, 1)}) {
					$val = $ret{substr($val, 1)};
				}
			}
			$ret{$key} = $val;
		}
				
	}
	close INF;

	return \%ret;
}
# END OF read()


#-----------------------------------------------------------------
sub get_error {
#-----------------------------------------------------------------
#
	my $self = shift;

	return $self->{error};
}
# END OF get_error()

#-----------------------------------------------------------------
sub get_conflicts() {
#-----------------------------------------------------------------

	my $self = shift;

	return @{$self->{conflicts}};
}
# END OF get_conflicts()


#-----------------------------------------------------------------
sub _special {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $token = shift;

	$token =~ s/^\s*//g;
	
	if ($token =~ /^include/) {
	$token =~ /^include\s+(\S+)\s*$/;
	return $self->_include($1);
	}
	if ($token =~ /^separator/) {
	$token =~ /^separator\s+(\S+)\s*$/;
	$self->{separator} = "$token";
	my %tmp;
	return \%tmp;
	}

	$token =~ /^(\S+)\s*(.*)$/s;
	my @args;
	if ($2) { @args = split(/,/, $2); }
	# other special command
	if (! exists $self->{special}{$1}) {
	$self->{error} = "unknown directive '$1'";
	return undef;
	}
	return $self->{special}{$1}->(@args);

}
# END OF _special

#-----------------------------------------------------------------
sub _include {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $arg  = shift;

	# relative path!
	if ($arg !~ /^\//) {
	if ($self->{filename} =~ /^(.*)\/[^\/]*$/) {
		if ($self->{special}{'include'}) {
		$arg = $self->{special}{'include'}->($arg);
		} else {
		$arg = "$1/$arg";
		}
	}
	}
	if (!$arg) { 
	$self->{error} = "include: no file found";
	return undef;
	}

	my @spec;
	foreach my $s (sort keys %{$self->{special}}) {
	push @spec, $s, $self->{special}{$s};
	} 
	my $inc = new DeltaX::Language($arg, @spec);
	my $ret = $inc->read();
	if (! defined $ret) {
	$self->{error} = "include: unable to read '$arg': ". $inc->get_error();
	return undef;
	}
	return $ret;
}
# END OF _include()

#-----------------------------------------------------------------
sub DESTROY {
#-----------------------------------------------------------------
#
	my $self = shift;

}
# END OF DESTROY()

1;

=head1 NAME

DeltaX::Language - Perl module for reading language files

     _____
    /     \ _____    ______ ______ ___________
   /  \ /  \\__  \  /  ___//  ___// __ \_  __ \
  /    Y    \/ __ \_\___ \ \___ \\  ___/|  | \/
  \____|__  (____  /____  >____  >\___  >__|
          \/     \/     \/     \/     \/        project


=head1 SYNOPSIS

 use DeltaX::Language;

 my $lang_file = new DeltaX::Language('my_lang.EN');
 my $texts = $lang_file->read();
 my @conflicts = $lang_file->get_conflicts();

 print $texts->{'text_id'};

=head1 FUNCTIONS

=head2 new()

Constructor. The first argument is a filename (required), second (optional)
field separator (default is a tabelator ('\t')), other arguments are in key =>
value form, they are directive definitions in "directive_name => sub reference"
form (see L<"DIRECTIVES">).

=head2 read()

This function reads given file and returns undef (in case of error) or reference
to a hash in which keys are text id's and values a texts themselfs.

=head2 get_error()

This function returns error in textual form (only valid after read() call).

=head2 get_conflicts()

This function returns array with text id's which occured more than once (in
result of read() function will be only the last one). Only valid after read()
call.

=head1 TEXT FILE STRUCTURE

Text files have a simple structure: one line = one record, in key<separator>text
form. Everything form # sign to end of line is a comment, except #!<directive>
(see L<"DIRECTIVES">). Everything other (empty lines, ...) is ignored.

Example:
 
 # this is comment
 #
 id1_This is text
 id2_This is another text
 #!include other_file

 [character _ means separator, often tabelator ('\t')]

=head1 DIRECTIVES

Directives are special form of comments: C<#!directive [parameters]>.
DeltaX::Config knows two of them:

=over

=item include

It includes given file. Filename of included file is the first and only
argument. If it is not absolute path, path is got from actually readed filename.

=item separator

It sets given character as a new separator, it can be in escaped form (for
example #!separator \t). You cannot set new line or space as a separator using
this directive.

=item every other

By setting parameter to new() you can define other directives and use it in your
files. Every definition must be sub reference. This sub will be called with all
arguments for this directive.

 Program:

  sub myspec_func {
    my $arg = shift;

    # return reference to a hash or undef in case of error
  }

  my $conf = new DeltaX::Language('my_lang.EN',myspec=>\&myspec_func);

 Configuration file:

  #!myspec something

=back

=cut
