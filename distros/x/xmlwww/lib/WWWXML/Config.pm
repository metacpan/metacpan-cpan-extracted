package WWWXML::Config;
use strict;
use base 'Exporter';

use Config::General qw(ParseConfig);
use File::Spec::Functions qw(catfile splitdir);
use Getopt::Long;

our $action_handlers = {
    login       => '+Login',
    logout      => 'Login',
    register    => '+Profile',
    home        => 'Profile',
    cards       => 'Profile',
    numbers     => 'Profile',
    pay         => 'Transfer',
    pay2        => 'Transfer',
    history     => 'Transfer',
};

sub new {
    my ($class, $file, $cmdline_prefix, $cmdline) = @_;

    my %cmdlineargs;
    if($cmdline) {
        Getopt::Long::GetOptions(\%cmdlineargs, @$cmdline);
        for ( grep { /-/ } keys %cmdlineargs ) { my $val = delete $cmdlineargs{$_}; tr/-/_/; $cmdlineargs{$_} = $val; }
    }
    $cmdline_prefix .= "_" if defined $cmdline_prefix;

    my $CONFIG = {
        ParseConfig(
            -ConfigFile      => $file,
            -DefaultConfig   => { },
            -InterPolateVars => 1,
        ),

        (map { $cmdline_prefix.$_ => $cmdlineargs{$_} } keys %cmdlineargs),
    };

    return bless $CONFIG, $class;
}

1;

