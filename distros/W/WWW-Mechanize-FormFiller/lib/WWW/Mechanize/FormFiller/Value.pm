package WWW::Mechanize::FormFiller::Value;

use vars qw( $VERSION @ISA );
$VERSION = '0.12';
@ISA = ();

sub new {
  my ($class,$name) = @_;
  my $self = {
    name => $name,
  };

  bless $self,$class;

  $self;
};

# You're supposed to override this
sub value { undef };

# You can't set the name, but retrieve it
sub name { my $result = $_[0]->{name}; $_[0]->{name} = $_[1] if scalar @_ == 2; $result };

1;
__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value - Base class for HTML form values

=head1 SYNOPSIS

=begin example

  # This class is not used directly

=end example

=head1 DESCRIPTION

This class is the base class for different values - it defines the
interface implemented by the subclasses.

=over 4

=item new NAME

Creates a new value which will correspond to the HTML field C<NAME>.

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

L<WWW::Mechanize>,L<WWW::Mechanize::Shell>,L<WWW::Mechanize::FormFiller>,L<WWW::Mechanize::FormFiller::Value::Fixed>,
L<WWW::Mechanize::FormFiller::Value::Default>,L<WWW::Mechanize::FormFiller::Value::Random>,L<WWW::Mechanize::FormFiller::Value::Interactive>
