package t::testparser2;
use true;
use parent XML::Parser::Expat::Dispatched;

sub init{
  my ($package, @names) = @_;
  foreach my $name (@names){
    if ('CODE' ne ref $name){
      *{__PACKAGE__."::$name"} = sub {
	my ($s) = @_;
	$s->{__testparser_handlers_visited}{$name}=$_[0];
      }
    } else {
      *t::testparser::config_dispatched= sub{{transform => $name}};
    }
  }
}

sub handler_arguments{
  my ($s, $name) = @_;
  return $s->{__testparser_handlers_visited}{$name};
}
