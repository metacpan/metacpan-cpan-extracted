package Test::File::Find::Rule;

use strict;
use base qw(Exporter);
use vars qw(@EXPORT);

use Test::Builder;
use File::Spec;
use Number::Compare;

our $VERSION = '1.00';

@EXPORT = qw(
	match_rule_nb_results
	match_rule_array
	match_rule_no_result
);

my $Test = Test::Builder->new();

=head1 NAME

Test::File::Find::Rule - Test files and directories with File::Find::Rule

=head1 SYNOPSIS

 use Test::File::Find::Rule;
 
 # Check that all files in $dir have sensible names
 my $rule = File::Find::Rule
     ->file
     ->relative
     ->not_name(qr/^[\w]{1,8}\.[a-z]{3,4}$/);
 match_rule_no_result($rule, $dir, 'File names ok');
 
 # Check that all our perl scripts have use strict !
 my $rule = File::Find::Rule
    ->file
    ->relative
    ->name(@perl_ext)
    ->not_grep(qr/^\s*use\s+strict;/m, sub { 1 });
 match_rule_no_result($rule, $dir, 'use strict usage');
 
 # With some help of File::Find::Rule::MMagic
 # Check that there is less than 10 images in $dir 
 # with a size > 1Mo
 my $rule = File::Find::Rule
     ->file
     ->relative
     ->magic('image/*')
     ->size('>1Mo');
 match_rule_nb_result($rule, $dir, '<10', 'Few big images');
 # We can reuse our F:F:R object
 match_rule_nb_result($rule, $another_dir, '>100', 'A lot of big images');
 
 # Check the exact result from a rule
 my $dirs = [qw(web lib data tmp)];
 my $rule = File::Find::Rule
     ->directory
     ->mindepth(1)
     ->maxdepth(1)
     ->relative;
 match_rule_array($rule, $dir, $dirs, 'Directory structure ok'));

=head1 DESCRIPTION

This module provides some functions to test files and directories
with all the power of the wonderful File::Find::Rule module.

The test functionnality is based on Test::Builder.

=head2 EXPORT

 match_rule_nb_results
 match_rule_array
 match_rule_no_result

=head2 FUNCTIONS

=over 4

=item match_rule_nb_result(RULE, DIR, COMPARE [, NAME])

RULE is a File::Find::Rule object without a query method. The
C<in> method will be called automatically.

DIR is a directory. To be safe, I recommend to give an absolute directory
and use the C<relative> function for your rule so that error messages
are shorter.

COMPARE is a Number::Compare object. You have to follow 
L<Number::Compare> semantics.

NAME is the optional name of the test.

=cut

# $compare is a Number::Compare string (>3 <10Ki 4 ...)
sub match_rule_nb_results {
	my ($rule, $dir, $compare, $name) = @_;
	$name ||= "Match the rule";

	my @files = $rule->in($dir);
	if (Number::Compare->new($compare)->test(scalar(@files))) {
		$Test->ok(1, $name);
	} else {
		$Test->ok(0, $name);
		$Test->diag("Expected [$compare]");
		$Test->diag("Got      [".scalar(@files)."]");
		$Test->diag("Matched  [".join(', ', @files)."]");
	}
}

=item match_rule_no_result(RULE, DIR [, NAME])

Just a convenient shortcut for

 match_rule_nb_result(RULE, DIR, 0 [, NAME])

=cut

sub match_rule_no_result {
	my ($rule, $dir, $name) = @_;

	match_rule_nb_results($rule, $dir, 0, $name);
}

=item match_rule_array(RULE, DIR, RESULTS [, NAME])

The only difference with the C<match_rule_nb_result>
is the RESULTS param wich is an array ref with
the expected results (order does not matter).

=cut

sub match_rule_array {
	my ($rule, $dir, $results, $name) = @_;
	$name ||= "Match the rule";

	my @files = $rule->in($dir);
	my $files_stringy = join '¨^¨', sort @files;
	my $results_stringy = join '¨^¨', sort @$results;
	if ($results_stringy eq $files_stringy) {
		$Test->ok(1, $name);
	} else {
		$Test->ok(0, $name);
		$Test->diag("Expected [".join(', ', sort @files)."]");
		$Test->diag("Got      [".join(', ', sort @$results)."]");
	}
}

1;

=back

=head1 SEE ALSO

L<File::Find::Rule>, L<Number::Compare>
L<Test::File>, L<Test::Files>
L<Test::More>, L<Test::Builder>

=head1 AUTHOR

Fabien POTENCIER, E<lt>fabpot@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003-2004, Fabien POTENCIER, All Rights Reserved

=head1 LICENSE

You may use, modify, and distribute this under the same terms
as Perl itself.

=cut
