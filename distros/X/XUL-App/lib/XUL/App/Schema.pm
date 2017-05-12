package XUL::App::Schema;

use strict;
use warnings;
#use Smart::Comments;
use XUL::App::XULFile;
use XUL::App::JSFile;
use XUL::App::XPIFile;
use XUL::App;

use Object::Declare (
    mapping => {
        xulfile => sub { XUL::App::XULFile->new({@_}) },
        jsfile => sub { XUL::App::JSFile->new({@_}) },
        xpifile => sub { XUL::App::XPIFile->new({@_}) },
    },
    aliases => {
        generated => 'generated_from',
        requires => 'prereqs',
        includes => 'prereqs',
    },
    copula => {
        is => '',
        are => '',
        from => '',
        #overlays => '',
        #targets => 'targets',
        #requires => '',
    },
);

use base 'Exporter';
our @EXPORT = qw(
    schema xulfile jsfile xpifile
    overlays includes requires targets
);

sub overlays ($) { overlays is @_; }
sub includes (@) {
    if (@_ == 1) {
        includes is $_[0];
    } else {
        includes are @_;
    }
}

sub requires (@) {
    if (@_ == 1) {
        requires is $_[0];
    } else {
        requires are @_;
    }
}

sub targets ($) { targets are @_; }

sub schema (&) {
    my $code = shift;
    my $from = caller;

    no warnings 'redefine';
    my @params = &declare($code);
    #### @params
    XUL::App->FILES({@params});
    my $files = XUL::App->FILES();
    ### files: $files
    no strict 'refs';
    push @{$from . '::ISA'}, 'XUL::App';
    return ();
}

1;

