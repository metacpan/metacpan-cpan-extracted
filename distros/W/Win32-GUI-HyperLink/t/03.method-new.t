#!perl -w
# Check that the module's new method is OK
use strict;
use warnings;

  use Test::More tests => 16;

  use Win32::GUI::Hyperlink;
  my $hasWin32API = defined $Win32::API::VERSION; # WIn32::GUI loaded if available by HyperLink

  my ($obj, $alt_obj);

  my $callback = sub {};

  my $parent = Win32::GUI::Window->new();

  my $text = 'http://www.perl.org';

  # the constructor
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -text => $text,
  );

isa_ok($obj, 'Win32::GUI::HyperLink');

  # check inheritance
isa_ok($obj, 'Win32::GUI::Label');

  # the alternative constructor
  $alt_obj = $parent->AddHyperLink(
    -text => $text,
  );

isa_ok($alt_obj, 'Win32::GUI::HyperLink');

  # check inheritance
isa_ok($alt_obj, 'Win32::GUI::Label');

  # done with the alternate
  $alt_obj = undef;

  # -url not supplied, defaults to -text
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -text => $text,
  );
is($obj->Url(), $text, "-url defaults to -text");

  # -text not supplied, defaults to -url
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
  );
is($obj->Text(), $text, "-text defaults to -url");

  # neither -url or -text defined, both empty
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
  );
is($obj->Text(), "", "-text: -text and -url empty");
is($obj->Url(), "", "-url: -text and -url empty");

  # check that onMouseIn event is stored
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
    -onMouseIn => $callback,
  );
ok($obj->{-onMouseIn} == $callback, "MouseIn event callback stored");

  # check that onMouseOut event is stored
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
    -onMouseOut => $callback,
  );
ok($obj->{-onMouseOut} == $callback, "MouseOut event callback stored");

  # check underline

  # if never underline, no font handles stored, and no reference to new font
  # if hover, 2 font handles are stored and reference to new font;
  # if underline always, then no font handles, just reference to new font

  ###############
  # sub underline_state returns: 0 - never underline, 1 - underline on hover
  #                              2 - always underline, 3 - error
  sub underline_state
  {
      my ($o) = @_;
    if (defined $o->{_u_font_ref}) {
      if(defined $o->{_hNfont} and defined $o->{_hUfont}) {
        return 1;
      } 
      if(!defined $o->{_hNfont} and !defined $o->{_hUfont}) {
        return 2;
      }
      return 3;
    } else {
      if(defined $o->{_hNfont} or defined $o->{_hUfont}) {
        return 3;
      }
      return 0;
    }
  }

  # DEFAULT: underline should default to hover
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
  );

is( underline_state($obj), 1, "Default underline style");

  # SET NO UNDERLINE:
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
    -underline => 0,
  );

is( underline_state($obj), 0, "Never underline");

  # SET underline on hover - results as per default
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
    -underline => 1,
  );

is( underline_state($obj), 1, "underline on hover");

  # SET underline always
  $obj = undef;
  $obj = Win32::GUI::HyperLink->new(
    $parent,
    -url => $text,
    -underline => 2,
  );

is( underline_state($obj), 2, "Always underline");

    # check that a provided onClick handler is set
    $obj = undef;
    $callback = sub {};
    $obj = Win32::GUI::HyperLink->new(
      $parent,
      -url => $text,
      -onClick => $callback,
    );

  ok($obj->GetEvent("Click") == $callback, "override Click handler set");

    # check that a provided onMouseMove handler is set
    $obj = undef;
    $callback = sub {};
    $obj = Win32::GUI::HyperLink->new(
      $parent,
      -url => $text,
      -onMouseMove => $callback,
    );

  ok($obj->GetEvent("MouseMove") == $callback, "override MouseMove handler set");
