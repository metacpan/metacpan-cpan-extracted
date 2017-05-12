#!/usr/bin/perl

# parse_form ()
# read form data posted or query_string using GET
# return the hash in LIST context
sub parse_form {
  my (%FORM);
  my $buffer = "";

  if ($ENV{'REQUEST_METHOD'} eq 'POST') {
    read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  } else {
  	$buffer = $ENV{'QUERY_STRING'};
  }

  my @pairs = split(/&/, $buffer);

  foreach my $pair (@pairs) {
    my ($name, $value) = split (/=/, $pair);
    
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    
    $FORM{$name} .= ', ' if (defined($FORM{$name}));
    $FORM{$name} .= $value;
  }
 
  return %FORM;
}

1;
