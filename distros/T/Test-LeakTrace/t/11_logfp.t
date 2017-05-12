#!perl -w

use strict;
use Test::More tests => 16;

use Test::LeakTrace qw(:util);

my $content = '';

sub t{
	open local(*STDERR), '>', \$content;

	leaktrace{
		my @array;
		push @array, 42, \@array;
	} shift;
}

$\ = 'rs';
$_ = 'defsv';

my $file = __FILE__;
t(-simple);
like $content,   qr/from \Q$file\E line 15\./, -simple;
unlike $content, qr/15:\t\tpush \@array/, -lines;
unlike $content, qr/REFCNT/, -sv_dump;

t(-lines);
like $content, qr/from \Q$file\E line 15\./, -simple;
like $content, qr/15:\t\tpush \@array/, -lines;
unlike $content, qr/REFCNT/, -sv_dump;

t(-sv_dump);
like $content, qr/from \Q$file\E line 15\./, -simple;
unlike $content, qr/15:\t\tpush \@array/, -lines;
like $content, qr/REFCNT/, -sv_dump;

t(-verbose);
like $content, qr/from \Q$file\E line 15\./, -simple;
like $content, qr/15:\t\tpush \@array/, -lines;
like $content, qr/REFCNT/, -sv_dump;

t(-silent);
is $content, '', -silent;

eval{
	t(sub{ die });
};
is $content, '', 'died in callback';

is $\, 'rs',    '$\ is not affected';
is $_, 'defsv', '$_ is not affected';
