package WWW::CheckPad::Parser;

use strict;
use warnings;
use HTML::Parser;
use base qw(HTML::Parser);

sub new {
  my $class = shift;
  my $self = new HTML::Parser();
  return bless $self, $class;
}


sub convert_to_item {
  my ($self, $content, @args) = @_;
  return $self->_parse($content, @args);
}


############################################################
# Usage: YourParser->param(<key>[, <value>])
# Returns: The value related to <key>.
# 
# If you need to save any values during parsing the string.
# You can use this method to save it.
############################################################
sub param {
  my ($self, $key, $value) = @_;

  $self->{_CP_PARSER} = {} if not defined $self->{_CP_PARSER};
  $self->{_CP_PARSER}->{$key} = $value if defined $value;

  return $self->{_CP_PARSER}->{$key};
}


1;
