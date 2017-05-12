use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 0.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use lib qw(../lib . t/);

plan tests => 4;

require Tk::Wizard;

ok($Tk::Wizard::VERSION, 'Loaded main');

# No import list
$_ = eval '$Tk::Wizard::Choices::VERSION';
ok( (not $@ and not $_), 'x10n not yet loaded') or BAIL_OUT;

Tk::Wizard->import( ':use' => [qw[Choices FileSystem]], );
$_ = eval '$Tk::Wizard::Choices::VERSION';
ok( (not $@ and $_), 'x10n a loaded') or BAIL_OUT;

$_ = eval '$Tk::Wizard::FileSystem::VERSION';
ok( (not $@ and $_), 'x10n b loaded') or BAIL_OUT;
