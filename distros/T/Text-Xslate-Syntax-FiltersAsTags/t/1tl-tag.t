use strict;
use warnings;
use Test::More;
use Text::Xslate qw(html_builder);

{ package My::Own::Syntax;
  use Mouse;

  my @more_symbols = qw(TL);
  sub more_symbols { @more_symbols }

  no Mouse;
  __PACKAGE__->meta->make_immutable;
  1
}

{ package My::Own::Syntax1;
  use Mouse;

  extends 'My::Own::Syntax', 'Text::Xslate::Syntax::TTerse';
  with 'Text::Xslate::Syntax::FiltersAsTags';

  no Mouse;
  __PACKAGE__->meta->make_immutable;
  1
}

{ package My::Own::Syntax2;
  use Mouse;

  extends 'My::Own::Syntax', 'Text::Xslate::Syntax::Kolon';
  with 'Text::Xslate::Syntax::FiltersAsTags';

  no Mouse;
  __PACKAGE__->meta->make_immutable;
  1
}

plan tests => 4;

our $lang;

sub translate_switch {
	my $v = shift;
	$v =~ s/^\s?//; $v =~ s/\s$//;
	my @tl = split /\s?\[_(\w+)\]\s?/, $v, -1;
	shift @tl;
	my %tl = @tl;
	$tl{$lang} // scalar((
		warn "missing translation $lang/$tl[1]\n"),
						 $tl[1])
}

my %functions = (function => +{
	tl      => html_builder(\&translate_switch),
});

my $tx1 = Text::Xslate->new(
	syntax => 'My::Own::Syntax1',
	%functions
   );

my $tx2 = Text::Xslate->new(
	syntax => 'My::Own::Syntax2',
	%functions
   );

my $tmpl1 = 'Prelude [% TL %][_en] observation period [_de] Beobachtungszeitraum[% END %] Postlude';
my $tmpl2 = 'Prelude <: TL{ :>[_en] observation period [_de] Beobachtungszeitraum<: } :> Postlude';

$lang = 'de';
is($tx1->render_string($tmpl1), 'Prelude Beobachtungszeitraum Postlude');
is($tx2->render_string($tmpl2), 'Prelude Beobachtungszeitraum Postlude');

$lang = 'en';
is($tx1->render_string($tmpl1), 'Prelude observation period Postlude');
is($tx2->render_string($tmpl2), 'Prelude observation period Postlude');
