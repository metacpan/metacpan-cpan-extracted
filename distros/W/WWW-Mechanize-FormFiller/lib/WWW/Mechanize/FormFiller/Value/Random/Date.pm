package WWW::Mechanize::FormFiller::Value::Random::Date;
use base 'WWW::Mechanize::FormFiller::Value';
use Carp qw(croak);

use vars qw( $VERSION );
use POSIX;
$VERSION = '0.12';

sub new {
  my ($class,$name,%args) = @_;
  my $self = $class->SUPER::new($name);
  %args = (string => '%Y%m%d') unless scalar (keys %args);
  $args{min} ||= undef;
  $args{max} ||= undef;

  $self->{args} = \%args;

  $self;
};

sub value {
  my ($self,$input) = @_;
  my $min = $self->{args}->{min};
  my $max = $self->{args}->{max};

  for ($min, $max) {
    $_ = strftime $self->{args}->{string}, gmtime()
      if $_ eq "now";
  };
  croak "Minimum timestamp is greater or equal maximum timestamp"
    if defined $max and defined $min and $max le $min;

  my $result;
  RANDOM: {
    my $timestamp = rand(0x7FFFFFFF);
    #warn $self->{args}->{string};
    #warn gmtime($timestamp);
    $result = strftime $self->{args}->{string}, gmtime($timestamp);
    redo RANDOM if defined $min and $result lt $min;
    redo RANDOM if defined $max and $result ge $max;
  };
  $result;
};

1;

__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Random::Date - Fill a timestamp into an HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random::Date;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "born"

  my $born = WWW::Mechanize::FormFiller::Value::Random::Date->new(
    born => string => '%Y%m%d', min => '20000101', max => '20373112' );
  $f->add_value( born => $born );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $last_here = $f->add_filler( last_here => Random::Date => string => '%H%M%S', min => '000000', max => 'now');

=for example end

=for example_testing
  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=born />
  <input type=text name=last_here />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  like( $form->value('born'), qr/^(\d{8})$/, "born gets set");
  like( $form->value('last_here'), qr/^(\d{6})$/, "last_here gets set");

=head1 DESCRIPTION

This class provides a way to write a randomly chosen value into a HTML field.

=over 4

=item new NAME, %ARGS

Creates a new value which will correspond to the HTML field C<NAME>. The allowed
%ARGS are

  string => POSIX strftime string
  min    => minimum time stamp (inclusive)
  max    => maximum time stamp (exclusive)

The C<min> and C<max> time stamps must be in the same format as the C<string> supplies.

B<WARNING>

The algorithm to implement C<min> and C<max> barriers is very simplicistic - it
tries as many random values as necessary to meet the two criteria. This means that
your script may enter an infinite loop if the criteria can never be attained or
are too little apart.

=item name [NEWNAME]

Gets and sets the name of the HTML field this value corresponds to.

=item value FIELD

Returns the value to put into the HTML field.

=back

=head2 EXPORT

None by default.

=head2 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002,2003 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<Data::Random>,
L<WWW::Mechanize>, L<WWW::Mechanize::Shell>, L<WWW::Mechanize::FormFiller>, L<WWW::Mechanize::FormFiller::Value::Value>,
L<WWW::Mechanize::FormFiller::Value::Default>, L<WWW::Mechanize::FormFiller::Value::Fixed>, L<WWW::Mechanize::FormFiller::Value::Interactive>
