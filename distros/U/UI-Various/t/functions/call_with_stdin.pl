#!/bin/false
# not to be used stand-alone
#
# helper function to reassign STDIN:

sub _call_with_stdin($$)
{
    my ($stdin_text, $function) = @_;
    no warnings 'newline';	# otherwise -f would fail for real text
    if (-f $stdin_text)
    {
	local $/;		# local slurp mode
	my $input;
	open $input, '<', $stdin_text
	    or  die "can't open ", $stdin_text, ': ', $!, "\n";
	$stdin_text = <$input>;
	$stdin_text = join('', <$input>);
	close $input;
    }
    my $orgin = undef;
    open $orgin, '<&', \*STDIN  or  die "can't duplicate STDIN\n";
    close STDIN;
    open STDIN, '<', \$stdin_text  or  die "can't reassign STDIN\n";
    &$function();
    close STDIN;
    open STDIN, '<&', $orgin  or  die "can't restore STDIN\n";
}

1;
