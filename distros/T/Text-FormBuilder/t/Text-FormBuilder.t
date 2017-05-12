# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-FormBuilder.t'

#########################

## use Test::More qw(no_plan);
use Test::More tests => 11;

BEGIN { use_ok('Text::FormBuilder'); };

my $p = Text::FormBuilder->new;
isa_ok($p, 'Text::FormBuilder', 'new parser');
isa_ok($p, 'Class::ParseText::Base', 'subclass of Class::Parsetext::Base');
can_ok($p, qw(parse_file parse_array parse_text parse)); # inherited parse_* methods

isa_ok($p->parse_text('')->build->form, 'CGI::FormBuilder',  'generated CGI::FormBuilder object (build->form)');
isa_ok($p->parse_text('')->form,        'CGI::FormBuilder',  'generated CGI::FormBuilder object (form)');

$p = Text::FormBuilder->parse_text('');
isa_ok($p, 'Text::FormBuilder', 'new parser (from parse_text as class method)');

$p = Text::FormBuilder->parse(\'');
isa_ok($p, 'Text::FormBuilder', 'new parser (from parse as class method)');


my $simple = <<END;
name
email
phone
END

my $form = $p->parse(\$simple)->form;
# we should have three fields
is(keys %{ $form->fields }, 3, 'correct number of fields');

# create some additional parsers, to make sure we aren't sharing data
my $p2 = Text::FormBuilder->parse_text($simple);
is(keys %{ $p2->form->fields }, 3, 'correct number of fields from parse_text');

my $p3 = Text::FormBuilder->parse_array(qw(code title semester instructor));
is(keys %{ $p3->form->fields }, 4, 'correct number of fields from parse_array');
