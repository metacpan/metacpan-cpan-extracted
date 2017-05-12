package Zed::Plugin::Sys::Help;

use Zed::Plugin;
use Zed::Output;

=head1 SYNOPSIS

    Show help info
    ex:
        help
        help CMD

=cut

invoke "help" => sub {
    my $cmd = shift;
    my %plugins = Zed::Plugin::plugins;
    unless($cmd)
    {
        my %cmds;
        while(my($cmd, $class) = each %{$plugins{invoke}})
        {
            $class =~ /Zed::Plugin::(\w+)::/;
            next unless $1;
            push @{$cmds{$1}}, $cmd;
        }
        text("cmd list:");
        for(sort keys %cmds)
        {
            my @cmds = sort @{$cmds{$_}};
            text(sprintf "%10s:", $_);
            info(sprintf "%20s %20s %20s", splice @cmds, 0, 3) while @cmds;  
        }
    }else{
        Zed::Plugin::help($cmd);
    }

},sub {
    my %plugins = Zed::Plugin::plugins;
    sort keys %{$plugins{invoke}}
};

1
