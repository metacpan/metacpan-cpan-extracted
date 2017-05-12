package TestMunger;

sub munge {
   my ($class, $vars, $tmpl) = @_;

   my $newvars = {};
   $newvars->{thingy} = $vars->{t}{item} || $vars->{p}{item};
   $tmpl->log->debug('Running TestMunger::munge');

   return int rand(2) ? $newvars : undef;
}

sub change {
   my ($class, $vars, $tmpl) = @_;

   my $newvars = {};
   $newvars->{thingy} = $vars->{t}{item} || $vars->{p}{item};
   $tmpl->log->debug('Running TestMunger::change');

   return int rand(2) ? $newvars : undef;
}

sub never {
   my ($class, $vars, $tmpl) = @_;
   $tmpl->log->debug('Running TestMunger::never');
   return;
}

sub always {
   my ($class, $vars, $tmpl) = @_;

   my $newvars = {};
   $newvars->{thingy} = $vars->{t}{item} || $vars->{p}{item};
   $tmpl->log->debug('Running TestMunger::always');

   return $newvars;
}

1;
