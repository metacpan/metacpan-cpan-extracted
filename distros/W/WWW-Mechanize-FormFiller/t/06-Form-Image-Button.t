use strict;

use Test::More tests => 7;

use_ok("WWW::Mechanize::FormFiller");

SKIP: {
  eval { require HTML::Form };
  skip "Need HTML::Form to run the form image value test", 6 if $@;
  eval { require Test::MockObject };
  skip "Need Test::MockObject to run the form image value test", 6 if $@;

  {
    my $f = WWW::Mechanize::FormFiller->new();
    isa_ok($f,"WWW::Mechanize::FormFiller");

    my $value = $f->add_value("image1", Test::MockObject->new()->set_always('value','Returned Value'));
    my $form = HTML::Form->parse(<<HTML,"http://www.nowhere.org");
    <html><body><form>
      <input type='image' name='image1' value='Original Value'/>
    </form></body></html>
HTML

    $f->fill_form($form);
    my ($method,$args) = $value->next_call;
    is($method,"value","Image inputs get called if they are specified");
    my $filled_input = $form->find_input("image1");
    is($filled_input->value, 'Returned Value', "Returned image values get set")
  };

  {
    my $value = Test::MockObject->new()->set_always('value','Returned Value');
    $value->fake_module('WWW::Mechanize::FormFiller::Value::Test');
    $value->fake_new('WWW::Mechanize::FormFiller::Value::Test');

    my $f = WWW::Mechanize::FormFiller->new( default => [ 'Test' ] );
    isa_ok($f,"WWW::Mechanize::FormFiller");

    my $form = HTML::Form->parse(<<HTML,"http://www.nowhere.org");
    <html><body><form>
      <input type='image' name='image1' value='Original Value'/>
    </form></body></html>
HTML

    $f->fill_form($form);
    my ($method,$args) = $value->next_call;
    is($method,undef,"Image inputs don't get called if they are not explicitly specified");
    my $filled_input = $form->find_input("image1");
    is($filled_input->value, 'Original Value', "Returned image values stay what they are set to")
  };
};
