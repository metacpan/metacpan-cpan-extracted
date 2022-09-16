package Example::ActionRole::Authenticated;

use Moose::Role;

requires 'match', 'match_captures';

around ['match','match_captures'] => sub {
  my ($orig, $self, $ctx, @args) = @_; 
  return $self->$orig($ctx, @args) if $ctx->can('user') && $ctx->user->authenticated;
  return 0;
};

1;
