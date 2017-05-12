package WebSource::Extract::form;
use strict;
use WebSource::Parser;
use WebSource::Module;
use XML::LibXSLT;
use HTML::Form;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Extract - Extract a form by name from an HTML document

=head1 DESCRIPTION

This flavor of the B<Extract> operator allows to extract a form
by name.

The description of a form extraction operator should be as follows :

  <ws:extract type="form" name="opname" forward-to="ops">
    <parameters>
      <param name="form" value="form-name" />
    </parameters>
  </ws:extract>

=head1 METHODS

See WebSource::Module

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  $self->{form} or croak("No form name given");
}

sub handle {
  my $self = shift;
  my $env = shift;

  $self->log(5,"Got document ",$env->{baseuri});
  my @forms = HTML::Form->parse($env->dataString,$env->{baseuri});
  my @f = grep $_->attr("name") eq $self->{form}, @forms;
  if(@f) {
    $self->log(6,"Using form ",$f[0]);
    my %meta = %$env;
    $meta{data} = $f[0]->click;
    $meta{type} = "object/http-request";
    return WebSource::Envelope->new(%meta);
  } else {
    return ();
  }
}

=head1 SEE ALSO

WebSource::Extract

=cut

1;
