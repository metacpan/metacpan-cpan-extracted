package Test::t;
BEGIN {
  $Test::t::VERSION = '0.0031';
}
# ABSTRACT: 0 to testing in 1 line


use strict;
use warnings;

our ( @ISA, @EXPORT );

BEGIN {

    require Test::Most;
    Test::Most->import;

}

require File::Spec;

BEGIN {
    @ISA = qw/ Test::Builder::Module /;
}

@EXPORT = @Test::Most::EXPORT;

sub import {

    strict->import;
    warnings->import;

    my $no_plan = 1;
    m/^(?:no_plan|defer_plan|tests|skip_all)$/ and undef $no_plan for @_;
    splice @_, 1, 1, ( 'no_plan' ) if $no_plan;

    goto &Test::Most::import; # Let the good Test::Most do the magic

}

sub path { 
    shift;
    File::Spec->canonpath( @_ );
}

1;

__END__
=pod

=head1 NAME

Test::t - 0 to testing in 1 line

=head1 VERSION

version 0.0031

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use Test::t;

    ok( 1 )

    ...

Which is equivalent to

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use Test::Most 'no_plan';

    ...

With a custom plan

    #!/usr/bin/env perl
    use Test::t tests => 8;

    ...

=head1 DESCRIPTION

Test::t will get you testing in one short line. It will import Test::Most, activate strict and warnings, and issue 'no_plan' (unless you specify a plan manually)

The (non-existent) interface is in flux and will be changed soon.

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

