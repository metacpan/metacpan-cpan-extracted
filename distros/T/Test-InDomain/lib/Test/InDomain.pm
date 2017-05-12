package Test::InDomain;

use 5.010;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Data::Domain (); # empty list because import() is called explicitly below
use Scalar::Does;

our $VERSION = '0.01';

our @EXPORT = qw/in_domain not_in_domain/;

sub import {
  my ($class, @data_domain_import_args) = @_;

  # export functions in @EXPORT through Exporter
  $class->export_to_level(1, $class);

  # export Data::Domain functions; by default: :all, one level up
  unshift @data_domain_import_args, {} 
    unless does($data_domain_import_args[0], 'HASH');
  $data_domain_import_args[0]{into_level} //= 1;
  $data_domain_import_args[1]             //= ':all';
  Data::Domain->import(@data_domain_import_args);
}


sub in_domain ($$;$) {
  my ($data, $domain, $name) = @_;

  my $err_msg      = $domain->inspect($data);
  my $test_builder = __PACKAGE__->builder;
  $test_builder->ok(!$err_msg, $name);
  $test_builder->diag($test_builder->explain($err_msg)) if $err_msg;
}

sub not_in_domain ($$;$$) {
  my ($data, $domain, $name, $want_explanation) = @_;

  my $err_msg      = $domain->inspect($data);
  my $test_builder = __PACKAGE__->builder;
  $test_builder->ok($err_msg, $name);
  $test_builder->note($test_builder->explain($err_msg)) if $want_explanation;
}

1; # End of Test::InDomain


__END__


=head1 NAME

Test::InDomain - Testing deep datastructures against data domains

=head1 SYNOPSIS

  use Test::More;
  use Test::InDomain;
  plan tests => $number_of_tests;

  in_domain $v1, List(-all => Int(-min => 0), -size => [5, 10]),
                 "5 to 10 positive integers";

  my $expr_domain;
  $expr_domain = One_of(Num, Struct(operator => String(qr(^[-+*/]$)),
                                    left     => sub {$expr_domain},
                                    right    => sub {$expr_domain}));
  in_domain $v2, $expr_domain, "binary expression tree";

  in_domain $v3, Struct(data    => Defined,
                        printer => Obj(-can => 'print')),
                 "struct with data hash and printer object";


=head1 DESCRIPTION

This module is a complement to L<Test::Simple> or L<Test::More> (or
any other testing module based on L<Test::Builder>). It adds the
function C<in_domain> to your panoply of testing tools; that function
uses the functionalities of L<Data::Domain> to check deep
datastructures and produce detailed reports about where the data
differs from the expectations.

The synopsis above is just an appetizer : many more kinds of
comparisons can be performed; see L<Data::Domain> for details.

=head1 EXPORTS

=head2 Exports from Test::InDomain

=head3 in_domain

  in_domain $data, $domain, $test_name;

Calls C<< $domain->inspect($data) >> to check if the data belongs
to the domain. The third argument C<$test_name> is optional; if present,
it will be printed together with the test result.

If the test fails, the structured error messages issued from
L<Data::Domain> are printed as a diagnostic.

=head3 not_in_domain

  not_in_domain $data, $domain, $test_name, $want_explanation;

This test succeeds if C<< $domain->inspect($data) >> fails, i.e. the
data is not in the domain. By default the error messages will not be
printed (since the error was expected, the messages are not
interesting!); however, if the fourth argument C<$want_explanation>
is true, then the messages will be printed as a note (so they won't
be seen when the test in run in a harness, but will be visible in
the verbose TAP stream).

=head2 Exports from Data::Domain

By default, all symbols from L<Data::Domain> will be exported into
the caller's namespace : C<Int>, C<String>, C<List>, C<Struct>,
C<True>, C<Defined>, C<Obj>, etc. However it is also possible to
explicitly state what to import, and even to rename the imported
symbols through L<Sub::Exporter> options, like for example :

  use Test::InDomain -constructors => {-prefix => "dom_"};

To achieve this, the import list passed to C<Test::InDomain> is
transmitted directly to L<Data::Domain>; by contrast, functions
specific to C<Test::InDomain>, namely C<in_domain> and
C<not_in_domain>, are not affected by the import list and will be
exported in any case.


=head1 SEE ALSO

Other ways to perform deep comparisons :
L<Test::More/is_deeply>, L<Test::Deep>.


=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-indomain at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-InDomain>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


