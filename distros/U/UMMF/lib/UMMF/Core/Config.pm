package UMMF::Core::Config;

use 5.6.0;
use strict;
use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/10/10 };
our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Config - Configuration object.

=head1 SYNOPSIS

  my $config = UMMF::Core::Config->new('argv' => \@ARGV,
                                                     'env'  => \%ENV,
                                                    );

  my $value = $config->config_value($modelElement, $name, $default);

=head1 DESCRIPTION

This class is used by bin/ummf.pl to allow the user to specify overrides for configuration.

=head1 USAGE

  my $value = $config->config_*($model_element, $key, $default);

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/10/10

=head1 SEE ALSO

L<UMMF::Core::Configurable|UMMF::Core::Configurable>

=head1 VERSION

$Revision: 1.6 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Object);

#######################################################################

use UMMF::Core::Util qw(:all);

use Carp qw(confess);

#######################################################################


my %instance;

sub instance
{
  my ($self) = @_;

  $instance{ref($self) || $self};
}


sub instance_or_new
{
  my ($self, @args) = @_;

  $instance{ref($self) || $self} ||= $self->new(@args);
}


#######################################################################


sub initialize
{
  my ($self) = @_;
  
  $self->SUPER::initialize;

  $self->{'override'} ||= { };

  $self;
}


#######################################################################

sub set_value
{
  my ($self, $val) = @_;

  my (@opts) = split('/', $val, 3);
  @opts = unshift(@opts, ('*') x (@opts - 3));
  my ($kind, $name, $key) = @opts;
  
  my $value = shift;
  $self->override->{$kind}{$name}{$key} = $value;

  $self;
}

#######################################################################



sub _config
{
  my ($self, $model_element, $key, $default, $proc, $kind) = @_;

  # $DB::single = 1 if ref($self) =~ /Profile/;

  $kind || confess();
  my $name = ref($model_element) ? ModelElement_name_qualified($model_element) : $model_element;

  no warnings;

  my $value;

  # Try overrides:
  my $over = $self->override;

  # Direct match.
  $value = $over->{$kind}{$name}{$key}
  unless defined $value;

  # $name wild.
  $value = $over->{$kind}{'*'}{$key}
  unless defined $value;

  # $kind wild.
  $value = $over->{'*'}{$name}{$key}
  unless defined $value;

  # $name, $kind wild.
  $value = $over->{'*'}{'*'}{$key}
  unless defined $value;

  $value;
}



#######################################################################


=head2 config_enabled

=cut
sub config_enabled
{
  my ($self, $model_element, $key, $default) = @_;

  my $value = $self->{'config_enabled_force'} ||
    $self->config_value_inherited_true($model_element, $key, $default);

  if ( 0 ) {
    no warnings;
    print STDERR "config_enabled($model_element->{name}, $key, $default) = $value\n";
  }

  $value;
}


=head2 config_value

  my $value = $self->config_value($model_element, $key, $default);

Returns the configuration value for $key for a $model_element.

The result defaults to $default, if no match value is found.

=cut
sub config_value
{
  my ($self, $model_element, $key, $default) = @_;

  my $value = $self->_config($model_element, $key, $default, 'direct');

  $value;
}


=head2 config_value_inherited

  my $value = $self->config_value_inherited($model_element, $key, $default);

Same as C<config_value> but searches up the $model_element's namespace for a matching TaggedValue.

This allows control values to be defined in a Package that will be inherited from all ModelElements under the Package.

=cut
sub config_value_inherited
{
  my ($self, $model_element, $key, $default) = @_;

  my $value = $self->_config($model_element, $key, $default, 'inherited');

  $value;
}


=head2 config_value_true

  my $value = $self->config_value($model_element, $key, $default);

Returns true if the $self->config_value(...) is a 'true' value.

=cut
sub config_value_true
{
  my ($self, $model_element, @args) = @_;

  String_toBoolean($self->config_value($model_element, @args));
}


=head2 config_value_inherited_true

  my $value = $self->config_value_inherited_true($model_element, $key, $default);

Returns true if the $self->config_value_inherited(...) is a 'true' value.

=cut
sub config_value_inherited_true
{
  my ($self, $model_element, @args) = @_;

  String_toBoolean($self->config_value_inherited($model_element, @args));
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/10/10 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

