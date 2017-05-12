#!/usr/bin/perl -w
use WebService::Validator::Feed::W3C;
my $val = WebService::Validator::Feed::W3C->new;
foreach my $validate_me (@ARGV) {
    printf "Validating feed $validate_me...\n";
    $success = $val->validate(uri => $validate_me);
    if ($success) {
      if ($val->errorcount != 0) { 
        printf "Invalid! %u error(s)", $val->errorcount; 
        printf "  * %s at line: %s column: %s \n", $_->{text}, $_->{line}, $_->{column} foreach $val->errors;
      } else { printf "Valid. "; }
      if ($val->warningcount != 0) { printf "(%u warning(s))", $val->warningcount;} 
      printf "\n";
    }
    else {    print "  Sorry! could not validate"; }
}

__END__

=head1 NAME

feedvalidate.pl - validate (check syntax) of online RSS or Atom feeds from the command line

=head1 USAGE

feedvalidate.pl uri [uri2 ...]

=head1 EXAMPLES

Use the URI of the online feed you want to check, the script will list the errors encountered:

  % ./feedvalidate.pl http://www.example.org/News.rss
  Validating feed http://www.w3.org/QA/News.rss...
  Invalid! 2 error(s)  
    * Missing channel element: description at line: 23 column: 0 
    * item must be a valid URI at line: 29 column: 0 

To batch validate several feeds, just give their addresses as a sequence separated by a space:

  % ./feedvalidate.pl http://www.example.org/News.rss % ./feedvalidate.pl http://www.example.org/Othernews.atom
  Validating feed http://www.example.org/News.rss...
  Invalid! 2 error(s)  
    * Missing channel element: description at line: 23 column: 0 
    * item must be a valid URI at line: 29 column: 0 
  Validating feed http://www.example.org/Othernews.atom
  Valid.

