package EmailMunger;

sub email_munge {
   my ($class, $vars) = @_;
   my $email = $ENV{TATEST_EMAIL_ADDY};
   return undef unless ($vars->{p}{From} =~ /\Q$email\E/i);
   
   my $body = $vars->{p}{BODY};
   my $newvars = {
      name    => 'dilbert'.int(rand(44444)).'m',
      problem => 'It still broke!',
   };
   
   # Subject
   $newvars->{subject} = $vars->{p}{Subject};
   $newvars->{subject} =~ s/^.*Email Alert - //;
   $newvars->{subject} =~ s/ \K(\d+)$/int($1 + 1)/e;
   
   # Ticket #
   return undef unless ($body =~ /^Ticket \#: TT(\d+)/m);
   $newvars->{ticket} = sprintf('TT%010u', int($1+1));
   
   return $newvars;
}

1;
