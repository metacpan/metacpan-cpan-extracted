use Test::More tests => 15;
use Test::Exception;
use strict;
use warnings;
#use Smart::Comments;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}

END {
}

require Tripletail::Filter;

my $filter = Tripletail::Filter->_new;
my $defaults = [
	[type1     => undef],
];
$filter->_fill_option_defaults($defaults);
my $check = {
	type1 => [qw(defined)],
};
dies_ok {$filter->_check_options($check)} '_check_options die';

$filter = Tripletail::Filter->_new;
$defaults = [
	[type1     => ''],
];
$filter->_fill_option_defaults($defaults);
$check = {
	type1 => [qw(defined no_empty)],
};
dies_ok {$filter->_check_options($check)} '_check_options die';

$filter = Tripletail::Filter->_new;
$defaults = [
	[type1     => \123],
];
$filter->_fill_option_defaults($defaults);
$check = {
	type1 => [qw(defined scalar)],
};
dies_ok {$filter->_check_options($check)} '_check_options die';

$filter = Tripletail::Filter->_new;
$defaults = [
	[type1     => \123],
];
$filter->_fill_option_defaults($defaults);
$check = {
	type1 => [qw(defined array)],
};
dies_ok {$filter->_check_options($check)} '_check_options die';

$filter = Tripletail::Filter->_new;
$defaults = [
	[type1     => 1],
];
$filter->_fill_option_defaults($defaults);
$check = {
	type1 => [qw(defined test)],
};
dies_ok {$filter->_check_options($check)} '_check_options die';

$TL->setContentFilter('Tripletail::Filter::HTML');

dies_ok {$TL->getContentFilter->setHeader} 'setHeader die';
dies_ok {$TL->getContentFilter->setHeader(\123)} 'setHeader die';
dies_ok {$TL->getContentFilter->setHeader('X-TEST')} 'setHeader die';
dies_ok {$TL->getContentFilter->setHeader('X-TEST',\123)} 'setHeader die';

dies_ok {$TL->getContentFilter->addHeader} 'addHeader die';
dies_ok {$TL->getContentFilter->addHeader(\123)} 'addHeader die';
dies_ok {$TL->getContentFilter->addHeader('X-TEST')} 'addHeader die';
dies_ok {$TL->getContentFilter->addHeader('X-TEST',\123)} 'addHeader die';

ok($TL->getContentFilter->addHeader('X-TEST',123), 'addHeader');
ok($TL->getContentFilter->addHeader('X-TEST',1234), 'addHeader');

#dies_ok {$TL->getContentFilter->print(\123)} 'print die';

