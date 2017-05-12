=head1 Name

qbit::Log - Functions to logging

=cut

package qbit::Log;
$qbit::Log::VERSION = '2.4';
use strict;
use warnings;
use utf8;

use base qw(Exporter);
use Data::Dumper;

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      l ldump
      );
    @EXPORT_OK = @EXPORT;
}


=head1 Functions

=head2 l

B<Arguments:>

=over

=item

B<@args> - array of strings, messages;

=back

Print joined messsages to STDERR with new line at end.

=cut

sub l {
    print STDERR join(' ', @_) . "\n";
}

=head2 ldump

B<Arguments:>

=over

=item

B<@args> - array, variables;

=back

Print variables dumps with Data::Dumper::Dumper to STDERR. Unicode sequenses will be converted to readable text.

=cut

sub ldump(@) {
    local $Data::Dumper::Indent  = 2;
    local $Data::Dumper::Varname = '';

    my $dump = Dumper(@_);
    $dump =~ s/\\x\{([a-f0-9]{2,})\}/chr(hex($1))/ge;
    print STDERR $dump;
}

1;
