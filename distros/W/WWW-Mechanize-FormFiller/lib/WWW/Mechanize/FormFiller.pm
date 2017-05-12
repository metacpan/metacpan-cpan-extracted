package WWW::Mechanize::FormFiller;
use strict;
use Carp;

use vars qw( $VERSION @ISA );

$VERSION = '0.12';
@ISA = ();

sub load_value_class {
  my ($class) = @_;
  if ($class) {
    no strict 'refs';

    my $full_class = "WWW::Mechanize::FormFiller::Value::$class";

    unless (defined eval '${' . $full_class . '::VERSION}') {
      eval "use $full_class";
      Carp::confess $@ if $@;
    };
  } else {
    Carp::croak "No class name given to load" unless $class;
  };
};

sub new {
  my ($class,%args) = @_;
  my $self = {
    values => {},
    default => undef
  };
  bless $self, $class;

  if (exists $args{default}) {
    my ($class,@args) = @{$args{default}};
    load_value_class($class);
    no strict 'refs';
    $self->{default} = "WWW::Mechanize::FormFiller::Value::$class"->new(undef, @args);
  };

  if (exists $args{values}) {
    if (ref $args{values} eq 'ARRAY') {
      for my $value (@{$args{values}}) {
        if (ref $value eq 'ARRAY') {
          my ($name,$class,@args) = @$value;
          if ($class) {
            $self->add_filler( $name, $class, @args );
          } else {
            Carp::croak "Each element of the values array must have at least 2 elements (name and class)" unless defined $class;
            Carp::croak "Each element of the values array must have a class name" unless $class;
          };
        } else {
          Carp::croak "Each element of the values array must be an array reference";
        };
      }
    } else {
      Carp::croak "values parameter must be an array reference";
    };
  };
  return $self;
};

sub add_filler {
  my ($self,$name,$class,@args) = @_;
  load_value_class($class);

  if ($class) {
    no strict 'refs';
    $self->add_value( $name, "WWW::Mechanize::FormFiller::Value::$class"->new($name, @args));
  } else {
    Carp::croak "A value must have at least a class name and a field name (which may be undef though)" ;
  };
};

sub add_value {
  my ($self, $name, $value) = @_;
  if (ref $name and UNIVERSAL::isa($name,'Regexp')) {
    $self->{values}->{byre}->{$name} = $value;
  } else {
    $self->{values}->{byname}->{$name} = $value;
  };
  $value;
};

sub default {
  my ($self,$newdefault) = @_;
  my $result = $self->{default};
  $self->{default} = $newdefault if (@_ > 1);
  $result;
};

sub find_filler {
  my ($self,$input) = @_;
  croak "No input given" unless defined $input;
  my $value;
  if (exists $self->{values}->{byname}->{$input->name()}) {
    $value = $self->{values}->{byname}->{$input->name};
  } elsif (grep { $input->name =~ /$_/ } keys %{$self->{values}->{byre}}) {
    my $match = (grep { $input->name =~ /$_/ } keys %{$self->{values}->{byre}})[0];
    $value = $self->{values}->{byre}->{$match};
  } elsif ($input->type eq "image") {
    # Image inputs are really buttons, and if they have no (user) specified value,
    # we don't ask about them.
  } elsif ($self->default) {
    $value = $self->default();
  };
  $value;
};

sub fill_form {
  my ($self,$form) = @_;
  for my $input ($form->inputs) {
    my $value = $self->find_filler($input);
    # We leave all values alone whenever we don't know what to do with them
    if (defined $value) {
      # Hmm - who cares about whether a value was hidden/readonly ??
      no warnings;
      local $^W = undef;
      my $v = $value->value($input);
      undef $v if ($input->type() eq "checkbox" and $v eq "");
      eval { $input->value( $v ) };
      $@ and croak "Field '" .$input->name. "' had illegal value: $v";
    };
  };
};

sub fillout {
  my $self_class = shift;
  my $self = ref $self_class ? $self_class : $self_class->new();
  my $form;

  while (@_) {
    if (ref $_[0] and eval { UNIVERSAL::isa($_[0],'HTML::Form') }) {
      croak "Two HTML::Form objects passed into fillout()" if ($form);
      $form = shift;
    } else {
      my $field = shift;
      if (ref $_[0] eq 'ARRAY') {
        my $args = shift;
        $self->add_filler($field,@$args);
      } else {
        my $value = shift;
        $self->add_filler($field,'Fixed',$value);
      };
    };
  };
  $self->fill_form($form) if $form;
  $self;
};

1;
__END__

=head1 NAME

WWW::Mechanize::FormFiller - framework to automate HTML forms

=head1 SYNOPSIS

=begin example

  use WWW::Mechanize::FormFiller;
  use HTML::Form;

  # Create a form filler that fills out google for my homepage

  my $html = "<html><body><form name='f' action='http://www.google.com/search'>
      <input type='text' name='q' value='' />
      <input type='submit' name=btnG value='Google Search' />
      <input type='hidden' name='secretValue' value='0xDEADBEEF' />
    </form></body></html>";

  my $f = WWW::Mechanize::FormFiller->new(
      values => [
                 [q => Fixed => "Corion Homepage"],
  							]);
  my $form = HTML::Form->parse($html,"http://www.google.com/intl/en/");
  $f->fill_form($form);

  my $request = $form->click("btnG");
  # Now we have a complete HTTP request, which we can hand off to
  # LWP::UserAgent or (preferrably) WWW::Mechanize

  print $request->as_string;

=end example

=for example_testing
  $_STDOUT_ =~ s/[\x0a\x0d]+$//;
  is($_STDOUT_,"GET http://www.google.com/search?q=Corion+Homepage&btnG=Google+Search&secretValue=0xDEADBEEF",'Got the expected HTTP query string');

Form fields can be specified by name or by a regular expression. A
field specified by name takes precedence over a matching regular
expression.

=for example
  use WWW::Mechanize::FormFiller;
  use HTML::Form;

=begin example

  my $html = "<html><body><form name='f' action='http://www.example.com/'>
      <input type='text' name='date_birth_spouse' value='' />
      <input type='text' name='date_birth' value='' />
      <input type='text' name='date_birth_kid_1' value='' />
      <input type='text' name='date_birth_kid_2' value='' />
      <input type='submit' name='fool'>
    </form></body></html>";

  my $f = WWW::Mechanize::FormFiller->new(
      values => [
                 [date_birth => Fixed => "01.01.1970"],

                 # We are less discriminate with the other dates
                 [qr/date_birth/ => 'Random::Date' => string => '%d.%m.%Y'],
  							]);
  my $form = HTML::Form->parse($html,"http://www.example.com");
  $f->fill_form($form);

  my $request = $form->click("fool");
  # Now we have a complete HTTP request, which we can hand off to
  # LWP::UserAgent or (preferrably) WWW::Mechanize

  print $request->as_string;

=end example

=for example_testing
  $_STDOUT_ =~ s/[\x0a\x0d]+$//;
  like($_STDOUT_,qr"^GET\shttp://www\.example\.com/
  	\?date_birth_spouse=\d\d.\d\d.\d\d\d\d
  	\&date_birth=01.01.1970
  	\&date_birth_kid_1=\d\d.\d\d.\d\d\d\d
  	\&date_birth_kid_2=\d\d.\d\d.\d\d\d\d$"x,'Got the expected HTTP query string');

You are not limited to fixed form values - callbacks and interactive
editing are also already provided :

=for example
  no warnings 'once';
  require HTML::Form;
  require WWW::Mechanize::FormFiller::Value::Interactive;
  local *WWW::Mechanize::FormFiller::Value::Interactive::ask_value = sub { "s3[r3t" }; #<-- not a good password

=for example begin

  # Create a form filler that asks us for the password

  # Normally, the HTML would come from a LWP::UserAgent request
  my $html = "<html><body><form name='f' action='/login.asp'>
    <input type='text' name='login'>
    <input type='password' name='password' >
    <input type='submit' name=Login value='Log in'>
    <input type='hidden' name='session' value='0xDEADBEEF' />
  </form></body></html>";

  my $f = WWW::Mechanize::FormFiller->new();
  my $form = HTML::Form->parse($html,"http://www.fbi.gov/super/secret/");

  $f->add_filler( password => Interactive => []);
  $f->fill_form($form);

  my $request = $form->click("Login");

  # Now we have a complete HTTP request, which we can hand off to
  # LWP::UserAgent or (preferrably) WWW::Mechanize
  print $request->as_string;

=for example end

=for example_testing
  isa_ok($f,"WWW::Mechanize::FormFiller");
  $_STDOUT_ =~ s/[\x0a\x0d]+$//;
  like($_STDOUT_,qr"^GET http://www.fbi.gov/login.asp\?login=&(password=.*?&)?Login=Log\+in&session=0xDEADBEEF",'Got the expected HTTP query string');

=head1 DESCRIPTION

The module is intended as a simple way to fill out HTML forms from a
set of predetermined values. You set up the form filler with value elements,
retrieve the HTML form, and let the form filler loose on that form.

There are value classes provided for many tasks - fixed values, values
to be queried interactively from the user, values taken randomly from
a list of values and values specified through a callback to some Perl code.

=over 4

=item new %ARGS

Creates a new instance. The C<%ARGS> hash has two possible keys :
C<default>, whose value should be an array reference consisting of the
name of a C<WWW::Mechanize::FormFiller::Value> subclass and the optional
constructor values.
C<values> must be an array reference, which contains array
and C<Files>, which takes an array reference to the filenames to
watch.

Example :

=begin example

  # This filler fills all unspecified fields
  # with the string "<purposedly left blank>"
  my $f = WWW::Mechanize::FormFiller->new(
    default => [ Fixed => "<purposedly left blank>" ]);

  # This filler automatically fills in a username
  # and asks for a password
  my $f = WWW::Mechanize::FormFiller->new(
                       values => [[ login => Fixed => "corion" ],
                                  [ password => Interactive => []],
                                 ]);

  # This filler only fills in a username
  # if it is the empty string, and still asks for the password :
  my $f = WWW::Mechanize::FormFiller->new(
                       values => [[ login => Default => "corion" ],
                                  [ password => Interactive => [],
                                 ]]);

=end example

=item add_filler NAME, CLASS, @ARGS

Adds a new value to the list of filled fields. C<NAME> is the name
of the form field, C<CLASS> is the name of the class in the
C<WWW::Mechanize::FormFiller::Value> namespace - it must live
below there ! C<@ARGS> is an optional array reference to the parameters
that the subclass constructor takes.

=item add_value NAME, VALUE

Adds a new WWW::Mechanize::FormFiller::Value subclass to the list
of filled fields. C<NAME> is the name of the form field, C<VALUE>
is an object that responds to the interface of C<WWW::Mechanize::FormFiller::Value>.

=item fill_form FORM

Sets the field values in FORM to the values returned by the
C<WWW::Mechanize::FormFiller::Value> elements. FORM should be
of type HTML::Forms or respond to the same interface.

=item fillout @ARGS

This is a very dwimmy routine that allows you to intuitively
set up values and fill out a form, if needed. It works as both
a constructor and a method. The parameters are decoded according
to the following examples :

=for example begin

  $filler = WWW::Mechanize::FormFiller->new();
  $filler->fillout(
    # For the the simple case, assumed 'Fixed' class,
    name => 'Mark',

    # With an array reference, create and fill with the right kind of object.
    widget_id => [ 'Random', (1..5) ],
  );

=for example end

=for example_testing
  isa_ok($filler,"WWW::Mechanize::FormFiller");

=for example
  $form = HTML::Form->parse('<html><body><form>
    <input name="name" type="text" />
    <input name="motto" type="text" />
  </form></body></html>','http://www.example.com/');

=for example begin

  $filler = WWW::Mechanize::FormFiller->new();
  $filler->fillout(
    # If the first parameter isa HTML::Form, it is
    # filled out directly
    $form,
    name => 'Mark',
    motto => [ 'Random::Word', size => 5 ],
  );

=for example end

=for example_testing
  isa_ok($filler,"WWW::Mechanize::FormFiller");
  is($form->value('name'),'Mark','Name is set');
  like($form->value('motto'),qr/^[-'\w]+( [-'\w]+){3} [-'\w]+$/,'Motto is set');

=for example
  $form2 = HTML::Form->parse('<html><body><form>
    <input name="name" type="text" />
    <input name="motto" type="text" />','http://www.example.com/');

=for example begin

  # This works as a direct constructor as well
  WWW::Mechanize::FormFiller->fillout(
    $form2,
    name => 'Mark',
    motto => [ 'Random::Word', size => 5 ],
  );

=for example end

=for example_testing
  isa_ok($filler,"WWW::Mechanize::FormFiller");
  is($form2->value('name'),'Mark','Name is set');
  like($form->value('motto'),qr/^[-'\w]+( [-'\w]+){3} [-'\w]+$/,'Motto is set');

=back

=head2 Value subclasses

The following WWW::Mechanize::FormFiller::Value subclasses are currently distributed :

=over 4

=item L<WWW::Mechanize::FormFiller::Value::Callback>

=item L<WWW::Mechanize::FormFiller::Value::Default>

=item L<WWW::Mechanize::FormFiller::Value::Fixed>

=item L<WWW::Mechanize::FormFiller::Value::Interactive>

=item L<WWW::Mechanize::FormFiller::Value::Keep>

=item L<WWW::Mechanize::FormFiller::Value::Random>

=item L<WWW::Mechanize::FormFiller::Value::Random::Word>

=item L<WWW::Mechanize::FormFiller::Value::Random::Chars>

=item L<WWW::Mechanize::FormFiller::Value::Random::Date>

=back

=head2 EXPORT

None by default.

=head2 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002,2003 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

Bug reports are best done via RT at https://rt.cpan.org

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::Shell>,L<WWW::Mechanize::FormFiller::Value>
