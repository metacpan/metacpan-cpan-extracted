package Example::View::HTML::Page;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(html head meta title link body script br);

has 'page_title' => (is=>'ro', required=>1);
has 'scripts' => (
  is => 'rw',
  required => 1,
  default => sub { ['/static/ujs.js'] },
);

sub add_script($self, $url) {
  $self->scripts([@{$self->scripts}, $url]);
}

sub render($self, $c, $content) {
  return  html +{ lang=>'en' }, [
    head [
      title $self->page_title,
      meta +{ charset=>"utf-8" },
      meta +{ name=>"viewport", content=>"width=device-width, initial-scale=1, shrink-to-fit=no" },
      link +{ rel=>"icon", href=>"data:," },
      link +{ rel=>"stylesheet", type=>'text/css', href=>"/static/core.css" },
      link +{ rel=>"stylesheet",
              href=>"https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css",
              integrity=>'sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N',
              crossorigin=>"anonymous" },
      $self->content('css'),
    ],
    body [
      $content, br,
      $self->the_time,
      script +{ src=>'https://code.jquery.com/jquery-3.7.0.min.js',
                integrity=>'sha256-2Pmvv0kuTBOenSvLm6bvfBSSHrUJ+3A7x6P5Ebd07/g=',
                crossorigin=>"anonymous" }, '',
      script +{ src=>'https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js',
                integrity=>'sha384-Fy6S3B9q64WdZWQUiU+q4/2Lc9npb8tCaSX9FK7E8HnRr0Jz8D6OP9dO5Vg3Q9ct',
                crossorigin=>"anonymous" }, '',
      script +{ map=>$self->scripts, src=>sub {$_}  }, '',
      $self->content('js'),
    ],
  ];
}

1;