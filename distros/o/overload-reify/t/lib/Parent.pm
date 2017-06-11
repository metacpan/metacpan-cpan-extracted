package Parent;

use overload
  '+=' => 'plus_equals',
  '-=' => \&minus_equals,
  '0+' => sub { $_[0]->value },
  '""' => sub { $_[0]->value },
  '='  => \&clone,
  ;

use Storable 'dclone';

sub value {

    $_[0]{value} = $_[1] if @_ > 1;
    $_[0]{value};
}

sub logs { $_[0]{logs} }
sub clear_logs { $_[0]{logs} = [] }

sub new {
    my ( $class, %attr ) = @_;
    bless {
        value => 0,
        logs   => [],
        %attr
      },
      $class;
}

sub clone { dclone( $_[0] ) }

sub plus_equals {
    my ( $self, $other ) = @_;

    push @{ $self->logs }, [ __PACKAGE__ . "::+=" => $other ];
    $self->value( $self->value + $other );
    $self;
}

sub minus_equals {
    my ( $self, $other, $swap ) = @_;

    push @{ $self->logs }, [ __PACKAGE__ . "::-=" => $other ];
    $self->value( $self->value - $other );
    $self;
}


1;
