package MyBar;

use lib 't/lib';
use MyConstraint;

use Exporter 'import';

our @EXPORT_OK;
push @EXPORT_OK, qw(bar_hello);

our %EXPORT_TAGS = (
    types => \@MyBar::KURA,
);

use kura Bar1 => MyConstraint->new;
use kura Bar2 => MyConstraint->new;
use kura Bar3 => MyConstraint->new;

sub bar_hello { 'Hello, Bar!' }

1;
