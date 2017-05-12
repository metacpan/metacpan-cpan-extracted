package WWW::Wikipedia::TemplateFiller::Template::Infoboxdisease;
use base 'WWW::Wikipedia::TemplateFiller::Template';

# XXX totally broken

use warnings;
use strict;

sub template_name { 'InfoboxDisease' }

sub fields {
  my $self = shift;

  return [
    -author    => $self->get_source_attr( isbn => 'author' ),
    -title     => $self->get_source_attr( isbn => 'title' ),
    -publisher => $self->get_source_attr( isbn => 'publisher' ),
    -location  => $self->get_source_attr( isbn => 'location' ),
    -year      => $self->get_source_attr( isbn => 'year' ),
    -pages     => '',
    -isbn      => $self->get_source_attr( isbn => 'isbn' ),
    -oclc      => '',
    -doi       => '',
  ];
}

sub output_fields {
  my( $self, %args ) = @_;
  my $show_accessdate = exists $args{show_accessdate} ? $args{show_accessdate} : 1;

  my @fields;
  push @fields, -accessdate => $self->__today_and_now if $show_accessdate;

  return \@fields;
}

1;
