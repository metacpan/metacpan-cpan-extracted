package Test::PPPort;
use strict;
use warnings;
our $VERSION = '0.03';

require Test::More;

my $Test = Test::More->builder;

sub import {
    my $self   = shift;
    my $caller = caller;

    {
        no strict 'refs';
        *{"$caller\::ppport_ok"} = \&ppport_ok;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub ppport_ok {
    unless (-f 'ppport.h') {
        $Test->skip_all('No such ppport.h file');
        return;
    }

    my $cmd = "$^X ppport.h";
    my @result = `$cmd 2>&1`;
    if ($result[0] =~ /^No input files given/) {
        $Test->skip_all( "No such XS files");
    } else {
        $Test->plan( tests => 1 );
        if ($result[-1] =~ /^Looks good/) {
            $Test->ok( 1, $cmd);
        } else {
            $Test->ok( 0, $cmd);
            $Test->diag("\nppport.h result:\n@result\n");
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Test::PPPort - test for ppport.h warnings

=head1 SYNOPSIS

  # in a xt/ppport.t

  use strict;
  use warnings;
  use Test::More;
  eval "use Test::PPPort";
  plan skip_all => "Test::PPPort required for testing ppport.h" if $@;
  ppport_ok();

=head1 DESCRIPTION

Test::PPPort is check to foo.xs files test by I<ppport.h>.
The check of XS file by I<ppport.h> can be easily taken in as a test case.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 THANKS

miyagawa

=head1 SEE ALSO

L<Devel::PPPort>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
