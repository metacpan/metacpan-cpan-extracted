package Text::Modify::Rule;

# TODO Concept change to support blocks/insert/addIfMissing options
# maybe this has to be moved outside of rule, as a rule has no scope of work only a single line
# the concept has to be extended to working on the whole file/block, with a special concept to
# handle large files (>100KB) with autodetection of file size (slow but working)

use strict;
use vars qw($VERSION);
use Text::Buffer;

BEGIN {
	$VERSION="0.4";
}

#====================================================
# Possible usage and params:
# replace=>'texttoreplace',with=>'anothertext'
# 	optional:
#		ifMissing=>'insert|append|warn|fail'
#		match=>'first'	(last not implemented yet)
#====================================================
sub new {
	my $class = shift;
	my $self = {
				 addcount     => 0,
				 deletecount  => 0,
				 matchcount   => 0,
				 replacecount => 0,
				 ignorecase   => 1,
				 dryrun       => 0,
				 matchfirst   => 65535,
				 _debug       => 0
	};
	bless $self, $class;
	$self->_clearError();
	my %opts = @_;
	if ( $opts{debug} ) { $self->{_debug} = $opts{debug}; }
	$self->{'type'} = undef;
	if ( $opts{replace} ) {

		if ( defined( $opts{with} ) ) {
			$self->{type}  = 'replace';
			# TODO need to distinguish between string, wildcard, regex here
			$self->{replacetype} = $opts{type} || "regex";
			if ($self->{replacetype} eq "wildcard") {
				$self->{regex} = Text::Buffer->convertWildcardToRegex($opts{replace});
			}
			elsif ($self->{replacetype} eq "string") {
				$self->{regex} = Text::Buffer->convertStringToRegex($opts{replace});
			} else {
				$self->{regex} = $opts{replace};
			}
			# Set available options
			foreach (qw(replace string wildcard with dryrun ignorecase matchfirst ifmissing)) {
				$self->{$_} = $opts{$_} if ( defined( $opts{$_} ) );
			}
			$self->{with} =~ s?(^|[^\\])/?$1\\/?g;
			$self->_debug(sprintf("after escape: type=%s regex='%s' with='%s' (orig='%s')", $self->{replacetype}, $self->{regex}, $self->{with}, $opts{replace}));
			

			# Create the regex options from params
			$self->{opts} .= ( $self->{ignorecase} ? "i" : "" );
		}
	}
	elsif ( $opts{insert} ) {
		if ( defined( $opts{at} ) ) {
			$self->{type}  = 'insert';
			$self->{regex} = "";
			$self->{with} = $opts{insert};

			# Set available options
			foreach (qw(insert at dryrun ignorecase ifmissing)) {
				$self->{$_} = $opts{$_} if ( defined( $opts{$_} ) );
			}
		}
	}
	elsif ( $opts{delete} ) {
		$self->{type}  = 'delete';
		$self->{regex} = $opts{delete};

		# Set available options
		foreach (qw(dryrun ignorecase matchfirst)) {
			$self->{$_} = $opts{$_} if ( defined( $opts{$_} ) );
		}
	}
	elsif ( $opts{move} ) {

		# TODO move option not implemented
		if ( defined( $opts{to} ) ) {
			$self->{type}  = 'move';
			$self->{regex} = $opts{move};

			# Set available options
			foreach (qw(move to dryrun ignorecase matchfirst ifmissing)) {
				$self->{$_} = $opts{$_} if ( defined( $opts{$_} ) );
			}
		}
	}
	if ( !$self->{type} ) {
		$self->_debug( "Unknown type" );
		$self->_setError("Unknown Rule type");
		return undef;
	}
	if ( !defined( $self->{opts} ) ) { $self->{opts} = ""; }
	return $self;
}

sub getModificationStats {
	my $self = shift;
	return (($self->{matchcount} || 0), 
			($self->{addcount} || 0), 
			($self->{deletecount} || 0), 
			($self->{replacecount} || 0));
}

#==================================
# Process block of lines
#==================================
sub process {
	my $self = shift;
	my $txt  = shift;
	if ( !( $txt && $txt->isa("Text::Buffer") ) ) { return undef; }
	my @insertblock;
	my @appendblock;

	# Start processing
	$self->_debug( "processing rule of type $self->{type}, regex is " . 
		(defined($self->{regex}) ? $self->{regex} : "undef" ) . 
		", with is " . (defined($self->{with}) ? $self->{with} : "undef" ));
	my $i   = 0;
	my $abs = 0;
	my ( $match, $opts ) = ( $self->{regex}, $self->{opts} );
	my $found = 0;
	my $rc    = 1;    # Return code for this function
	$txt->goto('top');
	my $string = $txt->get();

	if ($self->{type} ne "insert") {
		while ( defined($string) ) {
			$abs++;
			if ( $self->{matchcount} >= $self->{matchfirst} ) {
				$self->_debug( "First matches reached, ignoring rest for this rule" );
				last;
			}
			eval "\$found = (\$string =~ /$match/$opts);";
			$self->_debug( "Eval: \$found = ('$string' =~ /$match/$opts) = $found" );
			if ($found) {
				$self->{matchcount}++;
	
				# TODO complete all functionality here (replace,insert,delete,move)
				$self->_debug(  "Found match on line $abs (rel $i): $string" );
				if ( $self->{type} eq "delete" ) {
					$self->{deletecount}++;
	
					# Should be deleted from array
					$self->_debug(  "deleting line" );
					$txt->delete();
					$string = $txt->get();
					next;
				}
				elsif ( $self->{type} eq "move" ) {
	
					# Should be deleted from array
					$self->{addcount}++;
					$self->{deletecount}++;
					$self->_debug(  "moving line" );
					if ( $self->{to} eq "top" ) {
						$txt->insert($string);
					}
					else {
						$txt->append($string);
					}
					$txt->delete();
					$string = $txt->get();
					next;
				}
				elsif ( $self->{type} eq "replace" ) {
					$self->_debug(  "replacing with $self->{'with'}" );
					my $tmp = $string;
					eval "\$tmp =~ s/$match/$self->{with}/g$opts";
					if ( $tmp ne $string ) {
						$self->{replacecount}++;
					}
					$txt->set($tmp);
				}
				else {
					$self->_setError("not processed by any rule");
					return 0;
				}
			}
			$string = $txt->next();
		}
	}

	if ( $self->{type} eq "insert" ) {

		# Should be deleted from array
		$self->{addcount}++;
		if ( $self->{at} eq "insert" ) {
			$self->_debug( "inserting line:" . $self->{with});
			$txt->insert( $self->{with} );
		}
		else {
			$self->_debug( "appending line" . $self->{with} );
			$txt->append( $self->{with} );
		}
	}

	# process missing elements
	$self->_debug(
				   "Processing ifmissing: ifmissing="
					 . ( $self->{ifmissing} ? $self->{ifmissing} : "unset" )
					 . " matches="
					 . $self->{matchcount}
	);
	if ( $self->{ifmissing} && $self->{matchcount} == 0 ) {

		# Add the missing element now
		$self->{addcount}++;
		if ( $self->{ifmissing} eq "insert" ) {
			$self->_debug( "inserting missing line" );
			$txt->insert( $self->{with} );
		}
		elsif ( $self->{ifmissing} eq "append" ) {
			$self->_debug( "appending missing line" );
			$txt->append( $self->{with} );
		}
		elsif ( $self->{ifmissing} eq "ignore" ) {
			$self->_debug( "ignoring missing line" );
		}
		elsif ( $self->{ifmissing} eq "error" ) {
			$self->_setError("Required line $match not found");
			$rc = 0;
		}
	}

	if ( $self->{_debug} ) {
		$self->_debug( "=== OUT ===\n" . $txt->dumpAsString() . "=== EOF ===" );
	}

	return $rc;
}

sub isError { my $self = shift; return ( $self->{error} ne "" ); }
sub getError    { return shift->{error}; }
sub _clearError { my $self = shift; $self->{error} = ""; }
sub _setError   { my $self = shift; $self->{error} = shift; }

sub _debug {
	my $self = shift;
	if ($#_ == -1) {
		return $self->{_debug};
	}
	elsif ( $self->{_debug} ) {
		print "[DEBUG] @_\n";
	}
}

1;

__END__

=head1 NAME

Text::Modify::Rule - Modification rule, which can be used to process
a Text::Buffer object.

=head1 SYNOPSIS

  use Text::Modify::Rule;

  my $rule = new Text::Modify::Rule();

=head1 DESCRIPTION

C<Text::Modify::Rule> is a specific modification rule, to be applied
for a C<Text::Modify> object.

	my $rule = new Text::Modify::Rule();

C<Text::Modify> uses C<Text::Modify::Rule> to process the internal
C<Text::Buffer> object, representing the to be modified text.

=head1 Methods

=over 8

=item new

    $rule = new Text::Modify::Rule(%options);

This creates a new rule object, to be used with Text::Modify and 
perform the supplied modification tasks on the C<Text::Buffer> object.

# TODO lots of documenation missing for options to new

=item process

	my $changes = $rule->process($textbuf);

Process the C<Text::Buffer> object with this rule. Returns the number
of modifications performed on the text. Each operation (add, replace,
delete) is counted as a modification.

=item getModificationStats

	my ($match, $add, $del, $repl) = $rule->getModificationStats();
	
Returns to number of matches found, lines added, lines deleted and
the number of replacements performed.

=item isError

=item getError

	if ($rule->isError()) { print "Error: " . $rule->getError() . "\n"; }

Simple error handling routines. B<isError> returns 1 if an internal error
has been raised. B<getError> returns the textual error.

=back

=head1 BUGS

There definitly are some, if you find some, please report them.

=head1 LICENSE

This software is released under the same terms as perl itself. 
You may find a copy of the GPL and the Artistic license at 

   http://www.fsf.org/copyleft/gpl.html
   http://www.perl.com/pub/a/language/misc/Artistic.html

=head1 AUTHOR

Roland Lammel (lammel@cpan.org)

=cut
