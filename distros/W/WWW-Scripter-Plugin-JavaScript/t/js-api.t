#!perl -w

# Tests for the plugin object’s API.

use lib 't';

use WWW::Scripter;

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

$js = use_plugin{$w = new WWW'Scripter}JavaScript;

use tests 1; # init callback interface (fixed in 0.002)
{
 my $name = "args to init callback";
 my $passed;
 my $m = new WWW::Scripter;
 my $M = 0+$m; # to avoid circular refs
 $m->use_plugin('JavaScript', init => sub {
  @_ == 1 and shift == $M and $passed = pass $name
 });
 $m->get(data_url '<script>1+1</script>');
 fail $name unless $passed;
}

use tests 1; # eval
get{$w2 = new WWW'Scripter}'data:text/html,<body><p>hello';
is $js->eval($w2, 'document.body.firstChild.firstChild.data'), 'hello';

use tests 1; # new_function
$js->new_function('spext', sub { 'twed' });
is $w->eval('spext()'), 'twed', 'new_function';

use tests 1; # set
$js->set($w, "smit", "glile", "snew");
is $w->eval('smit.glile'), 'snew', 'set';

use tests 2; # bind_classes
{
 my $inited;
 my $js =(my $w = new WWW::Scripter)->use_plugin(
  JavaScript, init => sub { ++$inited }
 );
 $js->bind_classes({ Quor => {}, Prat::Hin => Quor });
 ok !$inited, 'bind_classes does not immediately create the JS env';
 is $js->eval($w,'0,function(o){ return ""+o }')->(bless[], 'Prat::Hin'),
   '[object Quor]',
   'bind_classes';
}
