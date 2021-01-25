=head1 NAME

WGmeta::Wrapper::Bridge - Interface with shell using IPC::Open3

=head1 METHODS

=cut

package Wireguard::WGmeta::Wrapper::Bridge;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use base 'Exporter';
our @EXPORT = qw(gen_keypair get_pub_key get_wg_show run_external);

use Symbol 'gensym';
use IPC::Open3;

use constant FALSE => 0;
use constant TRUE => 1;


=head2 gen_keypair()

Runs the C<wg genkey> command and returns a private and the corresponding public-key

B<Returns>

Two strings: private-key and public-key

=cut
sub gen_keypair() {
    my (@out_priv, undef) = run_external('wg genkey');
    my (@out_pub, undef) = run_external('wg pubkey', $out_priv[0]);
    chomp @out_priv;
    chomp @out_pub;
    return $out_priv[0], $out_pub[0];
}
=head2 get_pub_key($priv_key)

Runs C<wg pubkey> on C<$priv_key>.

B<Parameters>

=over 1

=item

C<$priv_key> A valid private key

=back

B<Returns>

A string containing the derived publickey.

=cut
sub get_pub_key($priv_key){
    my (@out, undef) = run_external('wg pubkey', $priv_key);
    chomp @out;
    return $out[0];
}

=head2 get_wg_show()

Runs C<wg show dump> and captures the output into str_out and str_err.

B<Raises>

Please refer to L</run_external($command_line [, $input, $soft_fail])>

B<Returns>

First array of STD_OUT

=cut
sub get_wg_show() {
    my $cmd = 'wg show dump';
    my (@out, undef) = run_external($cmd);
    chomp @out;
    return @out;
}

=head2 run_external($command_line [, $input, $soft_fail])

Runs an external program and throws an exception (or a warning if C<$soft_fail> is true) if the return code is != 0

B<Parameters>

=over 1

=item *

C<$command_line> Complete commandline for the external program to execute.

=item *

C<[$input = undef]> If defined, this is feed into STD_IN of C<$command_line>.

=item *

C<[$soft_fail = FALSE]> If set to true, a warning is thrown instead of an exception

=back

B<Raises>

Exception if return code is not 0 (if C<$soft_fail> is set to true, just a warning)

B<Returns>

Returns two lists with all lines of I<STDout> and I<STDerr>

=cut
sub run_external($command_line, $input = undef, $soft_fail = FALSE) {
    my $pid = open3(my $std_in, my $std_out, my $std_err = gensym, $command_line);
    if (defined($input)) {
        print $std_in $input;
    }
    close $std_in;
    my @output = <$std_out>;
    my @err = <$std_err>;
    close $std_out;
    close $std_err;

    waitpid($pid, 0);

    my $child_exit_status = $? >> 8;
    if ($child_exit_status != 0) {
        if ($soft_fail == TRUE) {
            warn "Command `$command_line` failed @err";
        }
        else {
            die "Command `$command_line` failed @err";
        }

    }
    return @output, @err;
}

1;