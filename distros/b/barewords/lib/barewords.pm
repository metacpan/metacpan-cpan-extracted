package barewords;

our $VERSION = '0.01';

require constant;

sub import {
    my %constants = map { $_ => $_ } @_;
    @_ = (constant => \%constants);
    goto &constant::import;
}

1;

__END__


=head1 NAME

barewords - create "strictable" barewords

=head1 SYNOPSIS

  use barewords qw(foo bar);

  $v = foo;
  print "$v\n"; # prints foo

=head1 DESCRIPTION

this module creates constants whose values are their own names.

=head1 SEE ALSO

L<constant>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
