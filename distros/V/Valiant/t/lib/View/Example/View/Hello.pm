package View::Example::View::Hello;

use Moo;
use View::Example::View
  -tags => qw(div input hr p button_tag form_for link_to a ul li blockquote),
  -util => qw($sf content_for path ),
  -views => 'Layout', 'Fragments';

has name => (is=>'ro', required=>1);

sub form :Renders {
  my $self = shift;
  return $self->form_for($self, +{a=>1}, sub {
    my ($self, $fb) = @_;
    $fb->input('name'),
  }); 
}
sub simple :Renders {
  my $self = shift;
  return div "Hey";
}

sub bits :Renders {
  my $self = shift;
  return fragments->stuff4;
}

sub bits2 {
  my $self = shift;
  return $self->fragments->stuff4;
}

sub stuff :Renders {
  my $self = shift;
  return div "Hey", p [
    div "there",
    div "you",
  ];
}

sub stuff_long {
  my $self = shift;
  my $t = $self->tags;
  return $t->div("Hey") + $t->p(
    $t->div("there"),
    $t->div("you"),
  );
}

sub render {
  my ($self, $c) = @_;
  return blockquote layout page_title => 'Homepage', sub {
    my ($layout) = @_;
    return
      $self->content_for(css=>'sssssss'),
      fragments->stuff4,
      div +{id=>1}, $self->$sf("Hello {:name}"),
      p p p, $self->stuff2,
      $self->stuff3,
      div,
      div +{id=>33},
      div +{id=>2}, "hello",
      div "hello2",
      button_tag 'fff',
      button_tag +{id=>'ggg'}, 'ggg',
      hr,
      div +{id=>'morexxx'}, [
        div +{id=>3}, "more",
        div 'none',
        hr +{id=>'hr'},
        $self->stuff,
        div +{id=>4}, "more",
      ],
      div +{id=>3}, sub {
        my ($view) = @_;
        div +{id=>'loop', repeat=>[1,2,3]}, sub {
          my ($view, $item, $idx) = @_;
          div +{id=>$item}, $item;
        },
      },
      div form_for 'fff', sub {
        my ($self, $fb) = @_;
        $fb->input('foo'),
        $fb->input('bar'),
      },
      form_for [$self], +{a=>2}, sub {
        my ($fb) = @_;
        $fb->input('name'),
      },

      a {href=>path('test')},
      a {href=>path('test', +{foo=>'bar'})},
      a {href=>path('test', +{foo=>'bar'}, \'fragment')},

      div form_for [$self], +{b=>1}, sub {
        my ($self, $fb) = @_;
        $fb->input('name'),
      },

      link_to 'test', {class=>'linky'}, 'Link to Test item.',
      link_to 'test', 'Link to Test item.',
      link_to path('test', +{page=>1}), {class=>'linky'}, 'Link to Test item.',
      div $self->form_for($self, +{a=>1}, sub {
        my ($self, $fb) = @_;
        $fb->input('name'),
      }), 
    };
}

__PACKAGE__->config(status_codes => [200,201,400]);