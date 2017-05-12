package WebSource::Filter::script;
use strict;
use Carp;

use File::Temp qw/tmpnam/;

use WebSource::Filter;
our @ISA = ('WebSource::Filter');

=head1 NAME

WebSource::Filter::script - Use a script for filtering

=head1 DESCRIPTION

A filter operator of type script allows to determine what to do with
the input based on an inline or external script. The data of the input
is passed as an argument to the script.

=head1 SYNOPSIS

B<In wsd file...>

<ws:filter name="somename" type="script" forward-to"somemodules">
<!-- put your script here -->
</ws:filter>

or

<ws:filter name="somename" type="script" script-file="somefile" 
           forward-to="somemodules" />

=head1 METHODS

=cut



sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless \%params, $class;
  $self->SUPER::_init_;

  $self->{seen} = {};  
  my $wsd = $self->{wsdnode};
  if($wsd) {
    if($wsd->hasAttribute("script-file")) {
      $self->{scriptfile} = $wsd->getAttribute("script-file");
    } else {
      my $sf;
      ($sf,$self->{scriptfile}) = tmpnam();
      my $content = $wsd->textContent;
      $content =~ s/^[\s\n]+//;
      print $sf $content;
      close($sf);
      system("chmod +x " . $self->{scriptfile});
    }
  }
  $self->{scriptfile} or die "No script file set for ",$self->{name},"\n";
  -x $self->{scriptfile} or die $self->{scriptfile}, " is not executable\n";
  return $self;
}

sub handle {
  my $self = shift;
  return map { $self->keep($_) ? $_ : () } @_;
}

sub keep {
  my $self = shift;
  my $env = shift;
  my $val = $env->dataString;
  my $script = $self->{scriptfile};
  my $res = system($script,$val);
  return $res == 0;
}

=head1 SEE ALSO

WebSource

=cut

1;

