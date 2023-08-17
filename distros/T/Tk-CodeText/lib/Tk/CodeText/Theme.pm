package Tk::CodeText::Theme;

=head1 NAME

Tk:CodeText::Theme - Theme object for highlight colors in L<Tk::CodeText>.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.40';

my %Attributes = (
	Alert => 1,
	Annotation => 1,
	Attribute => 1,
	BaseN => 1,
	BuiltIn => 1,
	Char => 1,
	Comment => 1,
	CommentVar => 1,
	Constant => 1,
	ControlFlow => 1,
	DataType => 1,
	DecVal => 1,
	Documentation => 1,
	Error => 1,
	Extension => 1,
	Float => 1,
	Function => 1,
	Import => 1,
	Information => 1,
	Keyword => 1,
	Normal => 1,
	Operator => 1,
	Others => 1,
	Preprocessor => 1,
	RegionMarker => 1,
	SpecialChar => 1,
	SpecialString => 1,
	String => 1,
	Variable => 1,
	VerbatimString => 1, 
	Warning => 1,
);

my $IdString = "Tk::CodeText theme file";

my %Options = (
	-background => 1,
	-foreground => 1,
	-slant => 1,
	-weight => 1,
);

=head1 SYNOPSIS

 require Tk::CodeText::Theme;
 my $theme= new Tk::CodeText::Theme;
 $theme->load($file);
 $theme->save($file);

=head1 METHODS

=over 4

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		POOL => {}
	};
	bless ($self, $class);
	$self->clear;
	return $self;
}

=item B<clear>

Clears all tag definitions.

=cut

sub clear {
	my $self = shift;
	my $pool = $self->Pool;
	for (keys %$pool) { delete $pool->{$_} };
	for ($self->tagList) {
		my $tag = $_;
		my %options = ();
		for ($self->optionList) {
			$options{$_} = ''
		}
		$pool->{$tag} = \%options
	}
}

=item B<getItem>I<($tag, $option)>

Returns the value of $option assigned to $tag.

=cut

sub getItem {
	my ($self, $tag, $option) = @_;
	my $pool = $self->Pool;
	if ($self->validTag($tag)) {
		if ($self->validOption($option)) {
			return $self->Pool->{$tag}->{$option}
		} else {
			warn "invalid option '$option' in getItem"
		}
	} else {
		warn "invalid tag name '$tag' in getItem"
	}
}

=item B<get>

Returns a list of tag/options pairs.

=cut

sub get {
	my $self = shift;
	my $pool = $self->Pool;
	my @result = ();
	for ($self->tagList) {
		my $tag = $_;
		push @result, $tag;
		my @options = ();
		for ($self->optionList) {
			my $val = $pool->{$tag}->{$_};
			push @options, $_, $val unless $val eq '';
		}
		push @result => \@options
	}
	return @result
}

=item B<load>I<($file)>

Loads a CodeText theme definition file.

=cut

sub load {
	my ($self, $file) = @_;
	if (open(OFILE, "<", $file)) {
		my $id = <OFILE>;
		chomp $id;
		unless ($id eq $IdString) {
			warn "$file is not a $IdString";
			close OFILE;
			return
		}
		my @values = ();
		my $section;
		my @inf = ();
		while (<OFILE>) {
			my $line = $_;
			chomp $line;
			if ($line =~ /^\[([^\]]+)\]/) { #new section
				push @values, $section, [ @inf ] if defined $section;
				$section = $1;
				@inf = ();
			} elsif ($line =~ s/^([^=]+)=//) {#new key
				push @inf, $1, $line;
			}
		}
		push @values, $section, [ @inf ] if defined $section;
		close OFILE;
		$self->put(@values);
	} else {
		warn "Cannot open '$file'"
	}
}

=item B<optionList>

Returns a list of available options to use.
They are:

 -background
 -foreground
 -slant
 -weight

=cut

sub optionList {
	return sort keys %Options;
}

sub Pool {
	return $_[0]->{POOL};
}

=item B<put>I<(@list)>

Assigns a @list of tag/option pairs.

=cut

sub put {
	my $self = shift;
	$self->clear;
	my $pool = $self->Pool;
	while (@_) {
		my $tag = shift;
		my $opt = shift;
		next unless $self->validTag($tag);
		my @options = @$opt;
		while (@options) {
			my $key = shift @options;
			my $value = shift @options;
			$pool->{$tag}->{$key} = $value if $self->validOption($key);
		}
	}
}

=item B<save>I<($file)>

Saves a CodeText theme definition file.

=cut

sub save {
	my ($self, $file) = @_;
	if (open(OFILE, ">", $file)) {
		print OFILE "$IdString\n";
		my @values = $self->get;
		while (@values) {
			my $tag = shift @values;
			print OFILE "[$tag]\n";
			my $options = shift @values;
			while (@$options) {
				my $key = shift @$options;
				my $value = shift @$options;
				print OFILE "$key=$value\n";
			}
		}
		close OFILE
	} else {
		warn "Cannot open '$file'"
	}
}

=item B<setItem>I<($tag, $option, $value)>

Assigns $value to $option in $tag.

=cut

sub setItem {
	my ($self, $tag, $option, $value) = @_;
	my $pool = $self->Pool;
	if ($self->validTag($tag)) {
		if ($self->validOption($option)) {
			$self->Pool->{$tag}->{$option} = $value if defined $value
		} else {
			warn "invalid option '$option' in setItem"
		}
	} else {
		warn "invalid tag name '$tag' in setItem"
	}
}

=item B<tagList>

Returns a list of available tags.
They are:

 Alert
 Annotation
 Attribute
 BaseN
 BuiltIn
 Char
 Comment
 CommentVar
 Constant
 ControlFlow
 DataType
 DecVal
 Documentation
 Error
 Extension
 Float
 Function
 Import
 Information
 Keyword
 Normal
 Operator
 Others
 Preprocessor
 RegionMarker
 SpecialChar
 SpecialString
 String
 Variable
 VerbatimString 
 Warning

=cut

sub tagList {
	return sort keys %Attributes;
}

=item B<validOption>I<($option)>

Returns true if $option is in the list of available options.

=cut

sub validOption {
	my ($self, $option) = @_;
	return exists $Options{$option};
}

=item B<validTag>I<($tag)>

Returns true if $tag is in the list of available tags.

=cut

sub validTag {
	my ($self, $tag) = @_;
	return exists $Attributes{$tag};
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::CodeText>

=back

=cut

1;

__END__
