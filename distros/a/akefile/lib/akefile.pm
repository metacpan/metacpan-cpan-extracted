use File::Share();
use IO::All();
use Mo();
use Template::Toolkit::Simple();

package akefile;
use Mo qw'default builder';
our $VERSION = '0.08';

use IO::All;

has type => ();
has args => (default => sub{[]});
has data => (builder => 'get_data');
has target_file => (default => sub {'Makefile.PL'});
has run_command => (default => sub {"$^X Makefile.PL"});

sub import {
    my $pkg = shift;
    my $type = shift or return;
    my $self = $pkg->new(
        type => $type,
    );
    $self->args([@_]);

    my ($main, $e) = caller(0);
    return unless $main eq 'main' and $e eq '-e' or $e eq '-';

    my $path = File::Share::dist_file(__PACKAGE__, $type)
        or die "'$type' is not a currently know akefile type";
    my $template = io($path)->all;

    Template::Toolkit::Simple->new()
        ->path([File::Share::dist_dir(__PACKAGE__)])
        ->data($self->data)
        ->output($self->target_file)
        ->render(\$template);

    exec $self->run_command;
}

sub get_data {
    my $self = shift;
    my $data = {
        map {
            split '=', $_, 2;
        } grep {
            $_ =~ /=/;
        } @{$self->args}
    };
    return $data;
}

1;
