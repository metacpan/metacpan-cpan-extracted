=head1 NAME

Cli::Router - Routes commands to their implementation

=head1 DESCRIPTION

If you want to "register" a new command, do it here. For more information about how an actual implementation should look like
please refer to L<Wireguard::WGmeta::Cli::Commands::Command>.

=head1 METHODS

=cut

package Wireguard::WGmeta::Cli::Router;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';
use Wireguard::WGmeta::Cli::Commands::Show;
use Wireguard::WGmeta::Cli::Commands::Set;
use Wireguard::WGmeta::Cli::Commands::Help;
use Wireguard::WGmeta::Cli::Commands::Enable;
use Wireguard::WGmeta::Cli::Commands::Disable;
use Wireguard::WGmeta::Cli::Commands::Apply;
use Wireguard::WGmeta::Cli::Commands::Add;
use Wireguard::WGmeta::Cli::Commands::Remove;

use base 'Exporter';
our @EXPORT = qw(route_command);

our $VERSION = "0.3.2";

=head2 route_command($ref_list_input_args)

Routes the cmd (first argument of C<@ARGV>) to their implementation. The case of the commands to not matter.
Any unknown command is forwarded to L<Wireguard::WGmeta::Cli::Commands::Help>.

To add a new command add this to the C<for> block:

    /^your_cmd$/ && do {
            Wireguard::WGmeta::Cli::Commands::YourCmd->new(@cmd_args)->entry_point();
            last;
        };


B<Parameters>

=over 1

=item

C<$ref_list_input_args> Reference to C<@ARGV>)

=back

B<Returns>

None

=cut
sub route_command($ref_list_input_args) {
    my ($cmd,@cmd_args) = @$ref_list_input_args;
    if (!defined $cmd){
        Wireguard::WGmeta::Cli::Commands::Help->new->entry_point;
    }
    for ($cmd) {
        /^show$/ && do {
            Wireguard::WGmeta::Cli::Commands::Show->new(@cmd_args)->entry_point();
            last;
        };
        /^set$/ && do {
            Wireguard::WGmeta::Cli::Commands::Set->new(@cmd_args)->entry_point();
            last;
        };
        /^enable$/ && do {
            Wireguard::WGmeta::Cli::Commands::Enable->new(@cmd_args)->entry_point();
            last;
        };
        /^disable$/ && do {
            Wireguard::WGmeta::Cli::Commands::Disable->new(@cmd_args)->entry_point();
            last;
        };
        /^addpeer$/ && do {
            Wireguard::WGmeta::Cli::Commands::Add->new(@cmd_args)->entry_point();
            last;
        };
        /^removepeer$/ && do {
            Wireguard::WGmeta::Cli::Commands::Remove->new(@cmd_args)->entry_point();
            last;
        };
        /^apply$/ && do {
            Wireguard::WGmeta::Cli::Commands::Apply->new(@cmd_args)->entry_point();
            last;
        };
        Wireguard::WGmeta::Cli::Commands::Help->new->entry_point;
    }
}

1;