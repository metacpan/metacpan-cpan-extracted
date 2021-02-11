package Test::XML::Loy;
use Mojo::Base -base;
use Mojo::Util 'encode';
use XML::Loy;
use Test::More;

has [qw!loy success!];

# Constructor
sub new {
  my $self = shift->SUPER::new;
  $self->loy(XML::Loy->new(shift));
  return $self
};


# Check for exact attribute match
sub attr_is {
  my ($self, $selector, $attr, $value, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{exact match for attribute "$attr" at selector "$selector"}
  );
  return $self->_test(
    'is', $self->_attr($selector, $attr), $value, $desc
  );
};


# Check for attribute mismatch
sub attr_isnt {
  my ($self, $selector, $attr, $value, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{no match for attribute "$attr" at selector "$selector"}
  );
  return $self->_test(
    'isnt', $self->_attr($selector, $attr), $value, $desc
  );
};


# Check for attribute similarity
sub attr_like {
  my ($self, $selector, $attr, $regex, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{similar match for attribute "$attr" at selector "$selector"}
  );
  return $self->_test(
    'like', $self->_attr($selector, $attr), $regex, $desc
  );
};


# Check for attribute dissimilarity
sub attr_unlike {
  my ($self, $selector, $attr, $regex, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{no similar match for attribute "$attr" at selector "$selector"}
  );
  return $self->_test(
    'unlike',
    $self->_attr($selector, $attr), $regex, $desc
  );
};


# Check for plain text match
sub content_is {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'is',
    $self->_loy_text,
    $value,
    _desc($desc, 'exact match for content')
  );
};


# Check for plain text mismatch
sub content_isnt {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'isnt',
    $self->_loy_text,
    $value,
    _desc($desc, 'no match for content')
  );
};


# Check for plain text similarity
sub content_like {
  my ($self, $regex, $desc) = @_;
  return $self->_test(
    'like',
    $self->_loy_text,
    $regex,
    _desc($desc, 'content is similar')
  );
};


# Check for plain text dissimilarity
sub content_unlike {
  my ($self, $regex, $desc) = @_;
  return $self->_test(
    'unlike',
    $self->_loy_text,
    $regex,
    _desc($desc, 'content is not similar')
  );
};


# Test for element occurrences
sub element_count_is {
  my ($self, $selector, $count, $desc) = @_;
  my $size = $self->loy->find($selector)->size;
  return $self->_test(
    'is',
    $size,
    $count,
    _desc($desc, qq{element count for selector "$selector"})
  );
};


# Test for element existence
sub element_exists {
  my ($self, $selector, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{element for selector "$selector" exists}
  );
  return $self->_test(
    'ok',
    $self->loy->at($selector),
    $desc
  );
};


# Test for missing element
sub element_exists_not {
  my ($self, $selector, $desc) = @_;
  $desc = _desc(
    $desc,
    qq{no element for selector "$selector"}
  );
  return $self->_test(
    'ok',
    !$self->loy->at($selector),
    $desc
  );
};


# Test for exact pcdata match
sub text_is {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test(
    'is',
    $self->_text($selector),
    $value,
    _desc($desc, qq{exact match for selector "$selector"})
  );
};


# Test for pcdata mismatch
sub text_isnt {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test(
    'isnt',
    $self->_text($selector),
    $value,
    _desc($desc, qq{no match for selector "$selector"})
  );
};


# Test for pcdata similarity
sub text_like {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test(
    'like',
    $self->_text($selector),
    $regex,
    _desc($desc, qq{similar match for selector "$selector"})
  );
};


# Test for pcdata dissimilarity
sub text_unlike {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test(
    'unlike',
    $self->_text($selector),
    $regex,
    _desc($desc, qq{no similar match for selector "$selector"})
  );
};


sub _desc {
  encode 'UTF-8', shift || shift;
};


sub _attr {
  my ($self, $selector, $attr) = @_;
  return '' unless my $e = $self->loy->at($selector);
  return $e->attr($attr) || '';
};


sub _test {
  my ($self, $name, @args) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return $self->success(!!Test::More->can($name)->(@args));
};


sub _text {
  return '' unless my $e = shift->loy->at(shift);
  return $e->text;
};


sub _loy_text {
  my $self = shift;
  return $self->{_data} if $self->{_data};
  $self->{_data} = $self->loy->to_pretty_xml;
  return $self->{_data};
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Test::XML::Loy - Test XML and XML::Loy objects


=head1 SYNOPSIS

  use Test::XML::Loy;

  my $t = Test::XML::Loy->new(<<'XML');
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <env>
    <header>
      <!-- My Greeting -->
      <greetings>
        <title style="color: red">Hello!</title>
      </greetings>
    </header>
    <body date="today">
      <p>That&#39;s all!</p>
    </body>
  </env>
  XML

  $t->attr_is('env title', 'style', 'color: red')
    ->attr_is('env body', 'date', 'today')
    ->text_is('body > p', "That's all!");


=head1 DESCRIPTION

L<Test::XML::Loy> allows to test XML documents in the same way
as L<Test::Mojo> tests X(HT)ML responses using L<Mojo::DOM>.
The code is heavily based on L<Test::Mojo> and implements
the same API. The documentation is heavily based on
L<Test::Mojo>.


=head1 ATTRIBUTES

L<Test::XML::Loy> inherits all attributes from
L<Mojo::Base> and implements the following new ones.

=head2 loy

  print $t->loy->to_pretty_XML;

The L<XML::Loy> object to test against.


=head2 success

  my $bool = $t->success;
  $t       = $t->success($bool);

True if the last test was successful.


=head1 METHODS

L<Test::XML::Loy> inherits all methods from
L<Mojo::Base> and implements the following new ones.

=head2 new

  my $xml = Test::XML::Loy->new(<<'EOF');
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <entry>
    <fun>Yeah!</fun>
  <entry>
  EOF

Constructs a new L<Test::XML::Loy> document.
Accepts all parameters supported by L<XML::Loy>.


=head2 attr_is

  $t = $t->attr_is('img.cat', 'alt', 'Grumpy cat');
  $t = $t->attr_is('img.cat', 'alt', 'Grumpy cat', 'right alt text');

Checks text content of attribute with L<Mojo::DOM/"attr"> at the CSS selectors
first matching HTML/XML element for exact match with L<Mojo::DOM/"at">.


=head2 attr_isnt

  $t = $t->attr_isnt('img.cat', 'alt', 'Calm cat');
  $t = $t->attr_isnt('img.cat', 'alt', 'Calm cat', 'different alt text');

Opposite of L</"attr_is">.


=head2 attr_like

  $t = $t->attr_like('img.cat', 'alt', qr/Grumpy/);
  $t = $t->attr_like('img.cat', 'alt', qr/Grumpy/, 'right alt text');

Checks text content of attribute with L<Mojo::DOM/"attr"> at the CSS selectors
first matching HTML/XML element for similar match with L<Mojo::DOM/"at">.


=head2 attr_unlike

  $t = $t->attr_unlike('img.cat', 'alt', qr/Calm/);
  $t = $t->attr_unlike('img.cat', 'alt', qr/Calm/, 'different alt text');

Opposite of L</"attr_like">.

=head2 content_is

  $t = $t->content_is(<<'XML');
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <Test foo="bar">
    <baum>Check!</baum>
  </Test>
  XML

Check textual serialization for exact match.

=head2 content_isnt

  $t = $t->content_isnt(<<'XML');
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <Test foo="bar">
    <baum>Check!</baum>
  </Test>
  XML

Opposite of L</"content_is">.

=head2 content_like

  $t = $t->content_like(qr/Check!/);
  $t = $t->content_like(qr/Check!/, 'right content');

Check textual serialization for similar match.

=head2 content_unlike

  $t = $t->content_unlike(qr/Check!/);
  $t = $t->content_unlike(qr/Check!/, 'right content');

Opposite of L</"content_like">.


=head2 element_count_is

  $t = $t->element_count_is('div.foo[x=y]', 5);
  $t = $t->element_count_is('html body div', 30, 'thirty elements');

Checks the number of HTML/XML elements matched by the CSS selector with
L<Mojo::DOM/"find">.


=head2 element_exists

  $t = $t->element_exists('div.foo[x=y]');
  $t = $t->element_exists('html head title', 'has a title');

Checks for existence of the CSS selectors first matching HTML/XML element with
L<Mojo::DOM/"at">.

=head2 element_exists_not

  $t = $t->element_exists_not('div.foo[x=y]');
  $t = $t->element_exists_not('html head title', 'has no title');

Opposite of L</"element_exists">.

=head2 text_is

  $t = $t->text_is('div.foo[x=y]' => 'Hello!');
  $t = $t->text_is('html head title' => 'Hello!', 'right title');

Checks text content of the CSS selectors first matching HTML/XML element for
exact match with L<Mojo::DOM/"at">.


=head2 text_isnt

  $t = $t->text_isnt('div.foo[x=y]' => 'Hello!');
  $t = $t->text_isnt('html head title' => 'Hello!', 'different title');

Opposite of L</"text_is">.

=head2 text_like

  $t = $t->text_like('div.foo[x=y]' => qr/Hello/);
  $t = $t->text_like('html head title' => qr/Hello/, 'right title');

Checks text content of the CSS selectors first matching HTML/XML element for
similar match with L<Mojo::DOM/"at">.

=head2 text_unlike

  $t = $t->text_unlike('div.foo[x=y]' => qr/Hello/);
  $t = $t->text_unlike('html head title' => qr/Hello/, 'different title');

Opposite of L</"text_like">.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2020 Sebastian Riedel and others.

Copyright (c) 2020-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
