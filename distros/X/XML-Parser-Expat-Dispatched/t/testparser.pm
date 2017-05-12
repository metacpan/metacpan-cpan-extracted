package t::testparser;
use true;
use parent XML::Parser::Expat::Dispatched;

sub init{
  my ($package, @names) = @_;
  foreach my $name (@names){
    if ('CODE' ne ref $name){
      *{"t::testparser::$name"} = sub {
	my $s = shift;
	push @{$s->{__testparser_handlers_visited}{$name}},[@_];
      }
    } else{
      *t::testparser::config_dispatched= sub{{transform => $name}};
    }
  }
}

sub handler_arguments{
  my ($s, $name) = @_;
  return $s->{__testparser_handlers_visited}{$name};
}

sub reset_handlers{
  my ($package, @names) = @_;
  foreach my $name (@names){
    undef *{t::testparser::}->{$name}
  }
}
