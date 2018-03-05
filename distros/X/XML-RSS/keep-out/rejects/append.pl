# This function was present in the lib/XML/RSS.pm sources for a long time
# and has been completely unused. Our guess was that it introduced to later
# serve in refactoring the module and was never used. It was not moved to
# this file, to possibly be used for future reference.

sub append {
	my($self, $inside, $cdata) = @_;

	my $ns = $self->namespace($self->current_element);

	# If it's in the default RSS 1.0 namespace
	if ($ns eq 'http://purl.org/rss/1.0/') {
		#$self->{'items'}->[$self->{num_items}-1]->{$self->current_element} .= $cdata;
		$inside->{$self->current_element} .= $cdata;
	}

	# If it's in another namespace
	#$self->{'items'}->[$self->{num_items}-1]->{$ns}->{$self->current_element} .= $cdata;
	$inside->{$ns}->{$self->current_element} .= $cdata;

	# If it's in a module namespace, provide a friendlier prefix duplicate
	$self->{modules}->{$ns} and $inside->{$self->{modules}->{$ns}}->{$self->current_element} .= $cdata;

	return $inside;
}
