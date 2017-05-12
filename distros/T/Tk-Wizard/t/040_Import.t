use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 0.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use lib qw(../lib . t/);

plan tests => 3;

require Tk::Wizard;

ok($Tk::Wizard::VERSION, 'Loaded main');

# No import list
$_ = eval '$Tk::Wizard::Choices::VERSION';
ok( (not $@ and not $_), 'x10n not yet loaded') or BAIL_OUT;

Tk::Wizard->import();
$_ = eval '$Tk::Wizard::Choices::VERSION';
ok( (not $@ and $_), 'x10n loaded with no import list') or BAIL_OUT;

