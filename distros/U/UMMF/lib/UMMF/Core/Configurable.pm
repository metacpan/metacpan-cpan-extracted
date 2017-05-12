package UMMF::Core::Configurable;

use 5.6.0;
use strict;
use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/08/05 };
our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Configurable - Configurable object base class.

=head1 SYNOPSIS

  use base qw(UMMF::Core::Configurable)

  my $configurable = ...->new();

  my $value = $configurable->config_value($modelElement, $name, $default);

=head1 DESCRIPTION

This superclass is used by UMMF::UML::Export and UMMF::UML::XForm to get configuration data for a particular ModelELement, from mulitple sources:

=over

=item * the defined C<override> hash

=item * command line options (to be implemented)

=item * the ModelElement's taggedValues


=back

This minimizes coupling between the Model, the Model transforms applied and control of the Model transforms.


The $self->C<config_*>($model_element, $key, $default) methods all search for values in a particular order:

=over

=item 1. $self->{'override'}{$kind}{$name}{$key}

=item 2. $self->{'override'}{$kind}{'*'}{$key}

=item 3. $self->{'override'}{'*'}{$name}{$key}

=item 4. $self->{'override'}{'*'}{'*'}{$key}

=item 5. the $model_elements TaggedValues:

=item 5.1. "ummf.$kind.$key"

=item 5.2. "ummf.$key"

=item 6. Any specified profile, via C<UMMF::Config::Profile>.

=item 7. finally, the $default value.

=back

where C<$name> is the fully-qualified name of the C<$model_element>, and C<$kind> is $self->config_kind.


If $default is a CODE ref, the $default->() result is used.

This allows options during Model processing to be handled in a general manner, and be specific for a particular transformation.

Thus, 'ummf.Perl.foobar' will be selected before 'ummf.foobar' if $self->config_kind eq 'Perl'.


=head1 USAGE

  my $value = $configurable->config_*($model_element, $key, $default);

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/08/05

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.9 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Config);

#######################################################################

use UMMF::Core::Util qw(:all);
use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;
  
  $self->SUPER::initialize;

  $self;
}


#######################################################################


=head2 config_kind

Returns the prefix used for this configurable object.

For example, C<UMMF::UML::Export::Perl::config_kind> returns C<'Perl'> to select C<'ummf.Perl.*'> TaggedValues before others.

Subclasses must define this.

=cut
sub config_kind
{
  my ($self) = @_;

  confess(ref($self) . "::config_kind(): not implemented");
}


#######################################################################


my $foundIn;


sub _config
{
  my ($self, $model_element, $key, $default, $proc) = @_;

  my $kind = $self->config_kind;
  my $name = $model_element->namespace ? ModelElement_name_qualified($model_element) : '';

  $foundIn = undef;
  my $value = __config($self, $model_element, $key, $default, $proc, $kind, $name);

  if ( 0 ) {
    no warnings;
    print STDERR ref($model_element), " $kind/$name/$key = '$value'\n";
    print STDERR "  foundIn=", scalar ModelElement_name_qualified($foundIn), "\n\n";
  }

  $value;
}


sub __config
{
  my ($self, $model_element, $key, $default, $proc, $kind) = @_;

  no warnings;

  my $value;

  confess() if ref($proc);

  while ( $model_element ) {
    my $name = $model_element->namespace ? ModelElement_name_qualified($model_element) : '';

    $foundIn = $model_element;

    # Try Options.
    my $config = UMMF::Core::Config->instance;
    $value = $config->_config($name, $key, $default, $proc, $kind);
    return $value if defined $value;
    
    # Try overrides:
    $value = $self->SUPER::_config($name, $key, $default, $proc, $kind);
    return $value if defined $value;
    
    # Try tagged values of node:
    
    # $kind.
    $value = ModelElement_taggedValue_name($model_element, join('.', grep(defined $_, "ummf.$kind", $key)));
    return $value if defined $value;
    
    # without $kind.
    $value = ModelElement_taggedValue_name($model_element, join('.', grep(defined $_, "ummf", $key)));
    return $value if defined $value;
    
    # Try Profile:
    if ( my $prof = UMMF::Config::Profile->instance ) {
      # Check profile as Config.
      $value = $prof->_config($name, $key, $default, $proc, $kind);
      return $value if defined $value;
    }
    
    last unless $proc eq 'inherited';

    $model_element = ModelElement_taggedValue_inheritsFrom($model_element);
  }

  # Default value.
  $default = $default->() if ref($default) eq 'CODE'; # Lazy eval.
  $value = $default;

  $value;
}



#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

