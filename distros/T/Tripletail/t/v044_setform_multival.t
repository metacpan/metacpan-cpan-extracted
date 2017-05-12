#! perl -w

use strict;
use warnings;

use Test::More;
use Tripletail '/dev/null';

plan tests =>
  +1 # 01.
  +1 # 02.
  +1 # 03.
  +1 # 04a.
  +1 # 04b.
  +1 # 04c.
  +1 # 04d.
  +1 # 05.
  ;

&test01_text();
&test02_textarea();
&test03_checkbox();
&test04a_select_dropdown();
&test04b_select_dropdown_few();
&test04c_select_dropdown_empty();
&test04d_select_dropdown_none();
&test05_select_multisel();

sub test01_text
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	$html .= qq{<input type="text" name="txt" value="a" />\n};
	$html .= qq{<input type="text" name="txt" value="b" />\n};
	$html .= qq{<input type="text" name="txt" value="c" />\n};
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		txt => [1, 2],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	$exp .= qq{<input type="text" name="txt" value="1" />\n};
	$exp .= qq{<input type="text" name="txt" value="2" />\n};
	$exp .= qq{<input type="text" name="txt" value="c" />\n};
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'text with multi values, set on each tags');
}

sub test02_textarea
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	$html .= qq{<textarea name="tea">a</textarea>\n};
	$html .= qq{<textarea name="tea">b</textarea>\n};
	$html .= qq{<textarea name="tea">c</textarea>\n};
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		tea => [3, 4],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	$exp .= qq{<textarea name="tea">3</textarea>\n};
	$exp .= qq{<textarea name="tea">4</textarea>\n};
	$exp .= qq{<textarea name="tea">c</textarea>\n};
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'textarea with multi values, set on each tags');
}

sub test03_checkbox
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	$html .= qq{<input type="checkbox" name="chk" value="9"  />\n};
	$html .= qq{<input type="checkbox" name="chk" value="10" />\n};
	$html .= qq{<input type="checkbox" name="chk" value="a" />\n};
	$html .= qq{<input type="checkbox" name="chk" value="b" checked="checked" />\n};
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		chk => [9, 10],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	$exp .= qq{<input type="checkbox" name="chk" value="9" checked="checked" />\n};
	$exp .= qq{<input type="checkbox" name="chk" value="10" checked="checked" />\n};
	$exp .= qq{<input type="checkbox" name="chk" value="a" />\n};
	$exp .= qq{<input type="checkbox" name="chk" value="b" />\n};
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'checkbox with multi values');
}

sub test04a_select_dropdown
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	for (1..2)
	{
		$html .= qq{<select name="sel">\n};
		$html .= qq{<option value="5">five</option>\n};
		$html .= qq{<option value="6">six</option>\n};
		$html .= qq{<option value="x">x</option>\n};
		$html .= qq{<option value="y" selected="selected">y</option>\n};
		$html .= qq{<option value="">none</option>\n};
		$html .= qq{</select>\n};
	}
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		sel => [5, 6],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	for my $i (1..2)
	{
		my $five_selected = $i == 1 ? ' selected="selected"' : '';
		my $six_selected  = $i == 2 ? ' selected="selected"' : '';
		my $x_selected    = '';
		my $y_selected    = '';
		$exp .= qq{<select name="sel">\n};
		$exp .= qq{<option value="5"$five_selected>five</option>\n};
		$exp .= qq{<option value="6"$six_selected>six</option>\n};
		$exp .= qq{<option value="x"$x_selected>x</option>\n};
		$exp .= qq{<option value="y"$y_selected>y</option>\n};
		$exp .= qq{<option value="">none</option>\n};
		$exp .= qq{</select>\n};
	}
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'select as drodown form');
}

sub test04b_select_dropdown_few
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	for (1..2)
	{
		$html .= qq{<select name="sel">\n};
		$html .= qq{<option value="5">five</option>\n};
		$html .= qq{<option value="6">six</option>\n};
		$html .= qq{<option value="x">x</option>\n};
		$html .= qq{<option value="y" selected="selected">y</option>\n};
		$html .= qq{<option value="">none</option>\n};
		$html .= qq{</select>\n};
	}
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		sel => [5],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	for my $i (1..2)
	{
		# 1st => "5" (five).
		# 2nd => "" (none).
		my $five_selected = $i == 1 ? ' selected="selected"' : '';
		my $six_selected  = '';
		my $x_selected    = '';
		my $y_selected    = '';
		my $none_selected = $i == 2 ? ' selected="selected"' : '';
		$exp .= qq{<select name="sel">\n};
		$exp .= qq{<option value="5"$five_selected>five</option>\n};
		$exp .= qq{<option value="6"$six_selected>six</option>\n};
		$exp .= qq{<option value="x"$x_selected>x</option>\n};
		$exp .= qq{<option value="y"$y_selected>y</option>\n};
		$exp .= qq{<option value=""$none_selected>none</option>\n};
		$exp .= qq{</select>\n};
	}
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'select as drodown form with few set value');
}

sub test04c_select_dropdown_empty
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	for (1..2)
	{
		$html .= qq{<select name="sel">\n};
		$html .= qq{<option value="5">five</option>\n};
		$html .= qq{<option value="6">six</option>\n};
		$html .= qq{<option value="x">x</option>\n};
		$html .= qq{<option value="y" selected="selected">y</option>\n};
		$html .= qq{<option value="">none</option>\n};
		$html .= qq{</select>\n};
	}
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		sel => [],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	for my $i (1..2)
	{
		# empty value is treated as no value by $TL::Form.
		# 1st => "y" [keep].
		# 2nd => "y" [keep].
		my $five_selected = '';
		my $six_selected  = '';
		my $x_selected    = '';
		my $y_selected    = ' selected="selected"';
		my $none_selected = '';
		$exp .= qq{<select name="sel">\n};
		$exp .= qq{<option value="5"$five_selected>five</option>\n};
		$exp .= qq{<option value="6"$six_selected>six</option>\n};
		$exp .= qq{<option value="x"$x_selected>x</option>\n};
		$exp .= qq{<option value="y"$y_selected>y</option>\n};
		$exp .= qq{<option value=""$none_selected>none</option>\n};
		$exp .= qq{</select>\n};
	}
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'select as drodown form with empty set value');
}

sub test04d_select_dropdown_none
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	for (1..2)
	{
		$html .= qq{<select name="sel">\n};
		$html .= qq{<option value="5">five</option>\n};
		$html .= qq{<option value="6">six</option>\n};
		$html .= qq{<option value="x">x</option>\n};
		$html .= qq{<option value="y" selected="selected">y</option>\n};
		$html .= qq{<option value="">none</option>\n};
		$html .= qq{</select>\n};
	}
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	for my $i (1..2)
	{
		# 1st => "y" (y) [keep].
		# 2nd => "y" (y) [keep].
		my $five_selected = '';
		my $six_selected  = '';
		my $x_selected    = '';
		my $y_selected    = ' selected="selected"';
		my $none_selected = '';
		$exp .= qq{<select name="sel">\n};
		$exp .= qq{<option value="5"$five_selected>five</option>\n};
		$exp .= qq{<option value="6"$six_selected>six</option>\n};
		$exp .= qq{<option value="x"$x_selected>x</option>\n};
		$exp .= qq{<option value="y"$y_selected>y</option>\n};
		$exp .= qq{<option value=""$none_selected>none</option>\n};
		$exp .= qq{</select>\n};
	}
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'select as drodown form without value');
}

sub test05_select_multisel
{
	my $html = "";
	$html .= qq{<?xml?>\n};
	$html .= qq{<form action="">\n};
	for (1..2)
	{
		$html .= qq{<select name="sel" size="2">\n};
		$html .= qq{<option value="5">five</option>\n};
		$html .= qq{<option value="6">six</option>\n};
		$html .= qq{<option value="">none</option>\n};
		$html .= qq{</select>\n};
	}
	$html .= qq{</form>\n};

	my $form = $TL->newForm({
		sel => [5, 6],
	});
	my $tmpl = $TL->newTemplate->setTemplate($html);
	$tmpl->setForm($form);

	my $exp = "";
	$exp .= qq{<?xml?>\n};
	$exp .= qq{<form action="">\n};
	for my $i (1..2)
	{
		my $five_selected = ' selected="selected"';
		my $six_selected  = ' selected="selected"';
		$exp .= qq{<select name="sel" size="2">\n};
		$exp .= qq{<option value="5"$five_selected>five</option>\n};
		$exp .= qq{<option value="6"$six_selected>six</option>\n};
		$exp .= qq{<option value="">none</option>\n};
		$exp .= qq{</select>\n};
	}
	$exp .= qq{</form>\n};

	is($tmpl->toStr(), $exp, 'select as mutl-select list');
}

