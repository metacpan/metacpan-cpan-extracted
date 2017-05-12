package Test::More::Behaviour;

use strict;
use warnings;

use base 'Test::More';
use Test::More;
use Test::More::Behaviour::Helper qw(evaluate_and_print_subtest spec_description context_description);

use version; our $VERSION = qv('1.0.1');

our @EXPORT = ( @Test::More::EXPORT, qw(describe context it) );

sub describe {
  spec_description(shift);
  my $block      = shift;

  caller->before_all if caller->can('before_all');
  $block->();
  caller->after_all if caller->can('after_all');

  spec_description(undef);

  return;
}

sub context {
  context_description(shift);
  my $block         = shift;

  $block->();
  context_description(undef);

  return;
}

sub it {
  my ($description, $block) = @_;

  caller->before_each if caller->can('before_each');
  evaluate_and_print_subtest($description, $block);
  caller->after_each if caller->can('after_each');

  return;
}

1;

__END__

=head1 NAME

Test::More::Behaviour - BDD module for Perl

=head1 INSTALL

  cpan -i Test::More::Behaviour

=head1 DESCRIPTION

Test::More::Behaviour is a Behaviour-Driven Development module for Perl
programmers.  It is modeled after Rspec (F<http://rspec.info>), the BDD tool for Ruby programmers.

Because Test::More::Behaviour uses Test::More as its 'base', you can treat every Test::More::Behaviour test as if it were Test::More!

=head1 SYNOPSIS

=head2 Basic structure

Test::More::Behaviour uses the words `describe` and `it` so we can
express concepts of the application as we would in conversation:

  "Describe a bank account."
  "It transfers money between two accounts."

code:

  describe 'Bank Account' => sub {
      it 'transfers money between two accounts' => sub {
          my $source = BankAccount->new(100);
          my $target = BankAccount->new(0);
          $source->transfer(50, $target);

          is($source->balance, 50);
          is($target->balance, 50);
      };
  };

Then the output should be:

    Bank Account
       transfers money between two accounts

The `describe` subroutine takes a description and a block. Inside the
block you can declare examples using the `it` subroutine.

=head2 Nested groups

You can also declare nested groups using the  `describe` or `context`
subroutines.

  describe 'Bank Account' => sub {
      context 'when opening without an initial amount' => sub {
          it 'has an initial balance of 0' => sub {
              ...
          };
      };

      context 'when opening with an initial amount of 100' => sub {
          it 'has an initial balance of 100' => sub {
              ...
          };
      };
  };

=head1 QUICK REFERENCE

This project is built with the philosophy that 'Tests are the Documentation'.  For a full set of features, please read through the test scenarios.

Some examples are listed with the source code (F<https://github.com/bostonaholic/test-more-behaviour>) under `examples/`.

=over

=item B<describe>

Used to group a set of examples of a particular behaviour of the
system that you wish you describe.

  describe 'Bank Account' sub => {
      ...
  };

=item B<it>

An example to run.

  describe 'Bank Account' => sub {
      it 'transfers money between two accounts' => sub {
          ...
      };
  };

=item B<context>

Used to further establish deeper relations for a set of examples.  This is best used when several examples have similar interactions with the system but have differring expectations.

  describe 'Bank Account' => sub {
      context 'when opening without an initial amount' => sub {
          it 'has an initial balance of 0' => sub {
              ...
          };
      };

      context 'when opening with an initial amount of 100' => sub {
          it 'has an initial balance of 100' => sub {
              ...
          };
      };
  };

=item B<before_all>

=item B<after_all>

These subroutines will run before and after all the `it` examples.

  sub before_all {
      ...
  };
    
  sub after_all {
      ...
  };

  describe 'Bank Account' => sub {
      it 'transfers money between two accounts' => sub {
          ...
      };
  };

=item B<before_each>

=item B<after_each>

Used to define code which executes before and after each `it` example.

  sub before_each {
      ...
  };
    
  sub after_each {
      ...
  };

  describe 'Bank Account' => sub {
      it 'transfers money between two accounts' => sub {
          ...
      };
  };

=back

=head1 SOURCE

The source code for Test::More::Behaviour can be found at F<https://github.com/bostonaholic/test-more-behaviour>

=head1 BUGS AND LIMITATIONS

Currently, each `it` will not run as a Test::More::subtest.  This is because the coloring was not working correctly because subtest needed the description before evaluating the block passed in.  If you can fix this, please submit a github pull request and I will take a look.

If you do find any bugs, please send me an email or create a github issue (F<https://github.com/bostonaholic/test-more-behaviour/issues>) or pull request with a failing test (and your fix if you're able to) and I will be more than happy to fix.

=head1 DEPENDENCIES

L<Test::More>

L<Term::ANSIColor>

L<version>

L<IO::Capture::Stdout> (test only)

=head1 CONTRIBUTING

Please report bugs via Github issues F<https://github.com/bostonaholic/test-more-behaviour/issues> and provide as many details as possible regarding your version of Perl, Test::More::Behaviour and anything else that may help with reproducing.

For enhancements and feature requests, please use Github issues and/or by submitting a pull request.

=head1 AUTHOR

Matthew Boston <matthew DOT boston AT gmail DOT com> with special thanks to Dustin Williams.

=head1 COPYRIGHT

(The MIT License)

Copyright (c) 2011 Matthew Boston

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
