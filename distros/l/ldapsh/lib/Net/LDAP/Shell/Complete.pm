package Net::LDAP::Shell::Completion;

use Exporter;

use vars qw(@EXPORT %CMDTYPES %TYPEFUNCS $SHELL $VERSION);

$VERSION = 1.00;

@EXPORT = qw(
	attemptCompletion
	registerCmd
);

%CMDTYPES = (
	'file' => [
		qw(cat cd ls edit clone rm)
	],
);

#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------
# completion stuff
# yay
#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
sub attemptCompletion {
	exit;
	unless (defined $Net::LDAP::Shell::SHELL) {
		die "There must be an instance of an LDAP Shell to use this package.\n";
	}
	$SHELL = $Net::LDAP::Shell::SHELL;

	my ($text, $line, $start, $end) = @_;

#	_debug(@_);

	$SHELL->term->Attribs->{attempted_completion_over} = 1;

	### Command completion ###
	# XXX no command completion yet...
	#if (substr($line, 0, $start) =~ /^\s*$/) {
	#   return _commandCompletion(@_);
	#}

	### Parameter Completion ###
	my $line2 = $line;
	$line2 =~ s/^\s+//;
	my ($cmd, $rest) = split(/\s+/, $line2, 2);

	if	  (grep $cmd, @{ $CMDTYPES{'file'} }) {
		return fileCompletion(@_);
	} else {
		return;
	}
}
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# fileComplete
sub fileComplete {
	my ($text, $line, $start, $end) = @_;

	$SHELL->term->Attribs->{completion_append_character} = "\0";

	# match the 'filtertype' portion of an LDAP filter (RFC 2254 and RFC 2251)

	my ($prefix, $attr, $extra, $partToComplete) = $text =~ m/(^|^.*\()([a-z][a-z0-9-]*)((?:;[a-z0-9-]*)?(?:=|~=|>=|<=))(.*)$/i;
	return undef unless defined($extra);

	my $result = $SHELL->search(
		attrs  => [$attr],
		filter => "$attr=$partToComplete*"
	);
	return undef unless defined($result);

	if ($result->code and $result->code == Net::LDAP::Constant::LDAP_NO_SUCH_OBJECT()) {
		return undef;
	}

	my @entries = $result->entries;
	return undef unless scalar(@entries);
	my @possible_entries = map {
		$prefix.$attr.$extra.scalar($_->get_value($attr))
	} @entries; # Bug: only uses first attribute value.

	my $common = maxCommon(@possible_entries);
	return $common, @possible_entries;
}
# fileComplete
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# maxCommon
sub maxCommon {
	return '' unless scalar(@_);
	my $firstElement = shift;
	my $common = '';
	for (my $i = 1; $i <= length($firstElement); $i++) {
		my $str = substr($firstElement, 0, $i);
		last if (grep {substr($_, 0, $i) ne $str} @_);
		$common = $str;
	}
}

