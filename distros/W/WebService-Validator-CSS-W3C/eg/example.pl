  use WebService::Validator::CSS::W3C;

  my $css = "p { color: not-a-color }";
  my $val = WebService::Validator::CSS::W3C->new;
  my $ok = $val->validate(string => $css);

  if ($ok and !$val->is_valid) {
      print "Errors:\n";
      printf "  * %s\n", $_->{message}
        foreach $val->errors
  }
