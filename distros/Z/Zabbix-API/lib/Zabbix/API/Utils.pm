package Zabbix::API::Utils;

use strict;
use warnings;
use 5.010;

use parent 'Exporter';

our @EXPORT_OK = qw(RE_FORMULA);

use constant RE_FORMULA =>
    qr/(?<function_call>\w+\(
         (?<function_args_quote>['"]?)
         (?<function_args>
           ((?<host>[\w ._-]+)
           :
           (?<item>[\w.,_]+)
           (?:\[
             (?<item_arg>([\w\/ ]+)(,([\w\/ ]+))*)
           \])?)
           |
           .*?)
         \g{function_args_quote}
       \))/x;

# TODO: rendre les guillemets optionnels, support de plusieurs function_args

1;
__END__
=pod

=head1 NAME

Zabbix::Utils -- Useful miscellanea related to Zabbix

=head1 DESCRIPTION

This is a collection of miscellaneous things useful to have in the event that
you're doing something with the Zabbix::API distribution.

=head1 FUNCTIONS

None so far.

=head1 EXPORTS

None by default.

=head2 EXPORTABLE

=over 4

=item RE_FORMULA

This constant (in the C<use constant> sense) is a regular expression that will
match against parts of formulas of calculated items thusly:

  use Zabbix::Utils qw/RE_FORMULA/;

  # interpolating constants is problematic
  my $regexp = RE_FORMULA;

  my $formula = 'last("MyROuter2:ifHCInOctets5")+last("MyROuter2:ifHCInOctets23")';

  while ($formula =~ m/$regexp/g) {

      print Dumper(\%+);

  }

Which should output:

  $VAR1 = {
            'function_call' => 'last("MyROuter2:ifHCInOctets5")',
            'function_args_quote' => '"',
            'item' => 'ifHCInOctets5',
            'function_args' => 'MyROuter2:ifHCInOctets5',
            'host' => 'MyROuter2'
          };
  $VAR1 = {
            'function_call' => 'last("MyROuter2:ifHCInOctets23")',
            'function_args_quote' => '"',
            'item' => 'ifHCInOctets23',
            'function_args' => 'MyROuter2:ifHCInOctets23',
            'host' => 'MyROuter2'
          };

Item arguments (system.uptimeB<[minutes]>) appear in C<item_arg> which is not
represented here (fixme!).

You'll have noticed that this makes use of the excellent "named capture buffers"
feature, which means you need Perl 5.10 or higher.

=back

=head1 SEE ALSO

L<Zabbix::API>, the Zabbix API documentation at
L<http://www.zabbix.com/documentation/start>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
