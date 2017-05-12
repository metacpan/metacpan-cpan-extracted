package Test::Uses;
BEGIN {
  $Test::Uses::VERSION = '0.01';
}

# ABSTRACT: Test sources for presence/absence of particular modules

use strict;
use warnings;

use Carp;
use PPI;

use Test::Builder;

sub import {
    my ($self) = @_;
    my $caller = caller;
    {
        no strict 'refs';
        *{$caller.'::uses_ok'} = \&uses_ok;
        *{$caller.'::avoids_ok'} = \&avoids_ok;
    }
}

my $tb = Test::Builder->new();

sub uses_ok {
    my($file, $module, $name) = @_;

    _verify($file, $module, $name);
}

sub avoids_ok {
    my($file, $module, $name) = @_;

    _verify($file, {-avoids => $module}, $name);
}

sub _verify {
    my ($file, $descriptor, $name) = @_;
    
    my $includes = (ref($descriptor) eq 'HASH') ? $descriptor->{-uses} : $descriptor;
    my $excludes = (ref($descriptor) eq 'HASH') ? $descriptor->{-avoids} : [];
    $includes = [$includes] unless (ref($includes) eq 'ARRAY');
    $excludes = [$excludes] unless (ref($excludes) eq 'ARRAY');
    
    # First go through the code, and build an array containing all the modules
    # referenced. This could be smarter, but it handles the use stuff OK.
    # We could use a hash, but real code doesn't often use a module more than
    # once. 
    
    my @modules = ();
    my $document = PPI::Document->new($file);
    my $requires = $document->find('PPI::Statement::Include');
    if ($requires) {
        foreach my $declaration (@$requires) {
            my $keyword = $declaration->find_first('PPI::Token::Word');
            $declaration->remove_child($keyword);
            my $module = $declaration->find_first('PPI::Token::Word');
            if ($keyword && $module) {
                push @modules, $module->content();
            }            
        }
    }
    
    # We need to satisfy all the includes and all the excludes against this hash.
    # It's also a good idea to generate feedback when needed.
    
    my @missing = ();
    my @found = ();
    foreach my $entry (@$includes) {
        next unless ($entry);
        if (! grep { (ref($entry) eq 'Regexp') ? $_ =~ $entry : $_ eq $entry } @modules) {
            push @missing, $entry;
        }
    }
    foreach my $entry (@$excludes) {
        next unless ($entry);
        if (grep { (ref($entry) eq 'Regexp') ? $_ =~ $entry : $_ eq $entry } @modules) {
            push @found, $entry;
        }
    }
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    my $result = $tb->ok(! @found && ! @missing, $name);
    if (@missing) {
        $tb->diag("$file was missing: ".join(", ", map { "$_" } @missing));
    }
    if (@found) {
        $tb->diag("$file contained: ".join(", ", map { "$_" } @found));
    }
    
    return $result;
}

# This marks when we satisfy a descriptor, regardless of whether it is in a uses
# or an avoids sense. 

sub _matches {
    my ($modules, $descriptor) = @_;
    
    $descriptor = [$descriptor] unless (ref($descriptor) eq 'ARRAY');
    foreach my $entry (@$descriptor) {
        if (grep { (ref($entry) eq 'Regexp') ? $_ =~ $entry : $_ eq $entry } @$modules) {
            return 0;
        }
    }
}

1;

=head1 NAME

Test::Uses

=head1 SYNOPSIS

  use Test::More tests => $Num_Tests;
  use Test::Uses;
  
  uses_ok($myperlfile, 'strict', "$myperlfile is properly strict");
  uses_ok($myperlfile, 'File::Spec', "$myperlfile uses File::Spec");
  uses_ok($myperlfile, qr/^Test::/, "$myperlfile actually does some testing");
  uses_ok($myperlfile, { -avoids => [qr/^Win32::/], 
                      -uses => ['strict', qr/^Test::/] },
    "$myperlfile does all sorts of stuff, and avoids Win32 modules");
  
  avoids_ok($myperlfile, qr/^Win32::/, "Quick way of saying }
  avoids_ok($myperlfile, ['bytes', qr/^Win32::/], "Quick way of saying we avoid grubby stuff
  
=head1 DESCRIPTION

This is a test helper module, so it is designed to be used in cooperation with
other test modules, such as Test::Simple and Test::More.

The module helps you check through a bunch of code for references to modules 
you either (a) want to use, or (b) want to avoid. The module reads and parses 
the file (using L<PPI>, and, therefore, dependencies of the file are not checked). 
the syntactic check has some advantages. Because no actual code is loaded, it is
safe to use as a test. 

One of the best reasons for using this, is to handle code where your production
environment may limit use of modules. This test allows you to avoid modules that
you know are going to cause problems, by adding test cases which fail when people
write code that uses them. 

Because pragmas are invoked similarly, you can also detect use of "bad" pragmas. 

Note that a pragma turned off (e.g., "no bytes") still counts as using the
pragma, and will be found as a use by this module. This seemed more sensible
to me, as in virtually all cases, using "no" loads the component and requires it
to function, and this is generally what you are trying to find using these tests. 

Test::Uses is not the same as L<Test::use::ok> or L<Test::More::use_ok>,
which checks that these modules can be L<use|perlfunc/"use">()d successfully. 

=head1 FUNCTIONS

=head2 uses_ok($filename, $module, $testname);

This test succeeds of the passed file does use this particular module. This looks
for a use statement referring to this module. The module specification can be one
of the following:

=over 4

=item * 

A string module name

=item * 

A regular expression value, based on the qr// quoting

=item * 

An arrayref of multiple values, all of which should be satisfied

=item * 

A hashref of specifications, keyed by -uses  and -avoids. All the
-uses specifications must be met, and none of the -avoids specifications
must be present

=back

=head2 avoids_ok($filename, $module, $testname);

A convenient shortcut for:

 uses_ok($filename, {-avoids => $module}, $testname);

=head1 TODO

This module is based on L<PPI>, and uses it to parse the text. This might 
well change at some point. 

=over 4

=item

Add some handling for require, at least when the cases are obvious

=item

Add some handling for test cases, such as use_ok

=back

=head1 AUTHOR

Stuart Watt E<lt>stuart@morungos.comE<gt>

=head1 COPYRIGHT

Copyright 2010 by the authors.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<PPI> is used to parse the module. 

=cut
