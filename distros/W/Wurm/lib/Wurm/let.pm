package Wurm::let;

use strict;
use warnings;

sub new {
  my ($class, $bulk) = @_;

  $bulk //= { };
  die "mangled grub bulk\n"
    unless 'HASH' eq ref $bulk;
  return bless {bulk => $bulk}, $class;
}

sub _at {
  die "mangled code\n" unless 'CODE' eq ref $_[-1];
  return @_;
}

sub molt {return $_[0]->{bulk}}

sub case {
  my ($self, $code) = _at(@_);
  $self->{bulk}{case} = $code;
  return $self;
}

sub pore {
  my ($self, $code) = _at(@_);
  $self->{bulk}{pore} = $code;
  return $self;
}

sub gate {
  my ($self, $code) = _at(@_);
  $self->{bulk}{gate} = $code;
  return $self;
}

sub tube {
  my ($self, $name, $wurm) = @_;

  die "tube with no name\n" unless defined $name;

  $wurm //= { };

  $self->{bulk}{tube}{$name} = $wurm;
  return $self;
}

sub grub {
  my ($self, $name, $grub) = @_;

  die "grub with no name\n" unless defined $name;

  $grub //= { };
  $grub = Wurm::let->new($grub)
    if 'HASH' eq ref $grub;

  $self->{bulk}{tube}{$name} = $grub->molt;
  return $grub;
}

sub neck {
  my ($self, $code) = _at(@_);
  $self->{bulk}{neck} = $code;
  return $self;
}

sub body {
  my ($self, $methods, $code) = _at(@_);

  $methods = [$methods] if '' eq ref $methods;
  die "\n" unless 'ARRAY' eq ref $methods;
  $self->{bulk}{body}{$_} = $code
    for @$methods;

  return $self;
}

sub get {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{get} = $code;
  return $self;
}

sub head {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{head} = $code;
  return $self;
}

sub post {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{post} = $code;
  return $self;
}

sub put {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{put} = $code;
  return $self;
}

sub delete {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{delete} = $code;
  return $self;
}

sub trace {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{trace} = $code;
  return $self;
}

sub options {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{options} = $code;
  return $self;
}

sub connect {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{connect} = $code;
  return $self;
}

sub patch {
  my ($self, $code) = _at(@_);
  $self->{bulk}{body}{patch} = $code;
  return $self;
}

sub tail {
  my ($self, $code) = _at(@_);
  $self->{bulk}{tail} = $code;
  return $self;
}

'.oOo.' # in wurm i trust
__END__

=pod

=head1 NAME

Wurm::let - Local Evaluation Tether

=head1 SYNOPSIS

  use Wurm qw(let);
  use Data::Dumper;

  # Re-implements the Hello, World app with let.
  sub build_grub {
    my ($name) = @_;

    return Wurm::let->new
    ->gate(sub {
      my $meal = shift;
      $meal->{vent}{to} = ucfirst $name;
      push @{$meal->{grit}{path}}, $name. '/gate';
      return;
    })
    ->neck(sub {
      my $meal = shift;
      push @{$meal->{grit}{path}}, $name. '/neck';
      return;
    })
    # The same as ->body(get       => sub { })
    # The same as ->body([qw(get)] => sub { })
    ->get(sub {
      my $meal = shift;
      push @{$meal->{grit}{path}}, $name. '/body:get';
      return;
    })
    ->tail(sub {
      my $meal = shift;
      push @{$meal->{grit}{path}}, $name. '/tail';
      return wrap_it_up($meal);
    })
  };

  sub wrap_it_up {
    my $meal = shift;

    my $path = join ', ', @{$meal->{grit}{path}};

    my $text = '';
    $text .= "$meal->{mind}{intro} $meal->{vent}{to},\n";
    $text .= "This is the path I took: $path\n";
    $text .= "This is what is in the tube: $meal->{tube}\n";
    $text .= "This is what I've seen: $meal->{seen}\n";

    return Wurm::_200('text/plain', $text);
  }

  # How many methods are called before the assignment is made?
  # This is the 'root' grub.
  my $grub = build_grub('root')
    ->case(sub {
      my $meal = shift;
      $meal->{vent}{to}   = 'Nobody';
      $meal->{grit}{path} = [ ];
      return $meal;
    })
    ->pore(sub {
      my ($res, $meal) = @_;
      $res->[2][0] = $res->[2][0]
        . ($res->[0] == 200 ? '' : "\n")
        . 'PSGI env: '. Dumper($meal->{env})
      ;
      return $res;
    })
  ;

  {
    # C<grub()> will make a new grub for us.
    # Or use what we give it.
    my $what = $grub->grub(wurm => build_grub('wurm'));

    # Grubs molt to become pretty butterflies.
    # If you believe nested hashes of anonymous sub-routines are
    # beautiful.  Or butterflies.

    # Tubes require molted grubs.
    $what->tube($_ => build_grub($_)->molt)
      for qw(foo bar baz);

    # I don't... better not to ask questions.  This looks nasty.
    $grub->grub($_ => $what->molt->{tube}{$_})
      for qw(foo baz);

    # qux is already molted inside $what.  eww.
    # I told you it was special.
    my $qux = $what->grub(qux => build_grub('qux'));
    $qux->gate(sub {
      my ($meal) = @_;
      $meal->{vent}{to} = 'Lord Qux';
      push @{$meal->{grit}{path}}, '*/gate';
      return wrap_it_up($meal);
    });
  }

  # Now turn the... uh... thing into an application.
  my $app = Wurm::wrapp($grub->molt, {intro => 'Hello'});
  $app

=head1 DESCRIPTION

B<Wurm::let> is a utility module for helping create L<Wurm> applications.
It provides an easy-to-use OO interface for constructing folding rules
without requiring applications to be OO-enabled themselves.

You can enable 'let' in two way:

  use Wurm::let;

- or -

  use Wurm qw(let);

=head1 METHODS

All methods (with the exception of C<grub>) are meant for call chaining
by returning the C<Wurm::let> object.  The C<grub> method returns a new
C<Wurm::let> which can then be call-chained for setup.

=over

=item new($bulk)

Creates a C<Wurm::let> object for manipulating C<$bulk>.  If C<$bulk> is
not provided, it will be created as a C<HASH> reference.

=item molt()

Returns the C<$bulk>.  Since folding rules are references, C<molt()> can
be called any time while still allowing changes to the C<Wurm::let>.
This allows you to either forward construct down-stream application logic
and attach it in-whole to up-stream parts.  Or you can create up-sream
logic and generate down-stream pieces from it.

=item case($code)

Installs a C<case> handler.

=item pore($code)

Installs a C<pore> handler.

=item gate($code)

Installs a C<gate> handler.

=item neck($code)

Installs a C<neck> handler.

=item tail($code)

Installs a C<tail> handler.

=item tube($name, $wurm)

Installs a C<tube> handler tree with the key C<$name> and a folding ruleset
of C<$wurm>.  If C<$wurm> is not provided it will be created for you.  An
easy way to chain application parts together is to create C<Wurm::let>
objects and C<molt()> them into C<tube> or use C<grub> below.

  my $stub = Wurm::let->new
    ->gate(sub { })
    ->post(sub { })
  ;

  my $root = Wurm::let->new
    ->case(sub { })
    ->pore(sub { })
    ->tube(foo => $stub->molt)
    ->tube(bar => $stub->molt)
  ;

=item grub($name, $grub)

Installs a C<tube> handler tree with the key C<$name> and a folding ruleset
of C<$grub>.  If C<$grub> is not provided it will be created for you.  If it
is a C<HASH> reference, it will be converted to a C<Wurm::let> object which
is returned.

  my $root = Wurm::let->new;

  # /mirror/ now contains the same folding rules as $root
  $root->grub(mirror => $root)
       ->tail(sub { });          # changes /mirror/

  # /foo/ will respond to gate and body/{get,post}
  my $wurm = {gate => sub { ... }, ...};
  my $grub = $root->grub(foo => $wurm);
  $grub->body([qw(get post)] => sub { ... });

=item body($methods, $code)

Installs a C<body> handler.  C<$methods> can either be a simple string
or an C<ARRAY> reference.  If multiple methods are given, the same
handler is installed for all of them.

=item get($code)

Installs a body handler for the 'GET' HTTP method.

=item head($code)

Installs a body handler for the 'HEAD' HTTP method.

=item post($code)

Installs a body handler for the 'POST' HTTP method.

=item put($code)

Installs a body handler for the 'PUT' HTTP method.

=item delete($code)

Installs a body handler for the 'DELETE' HTTP method.

=item trace($code)

Installs a body handler for the 'TRACE' HTTP method.

=item options($code)

Installs a body handler for the 'OPTIONS' HTTP method.

=item connect($code)

Installs a body handler for the 'CONNECT' HTTP method.

=item patch($code)

Installs a body handler for the 'PATCH' HTTP method.

=back

=head1 SEE ALSO

=over

=item L<Wurm>

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
