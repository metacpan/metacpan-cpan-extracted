package Test::Inspector;

=head1 NAME

  Test::Inspector - are you testing everything?

=head1 SYNOPSIS

  my $inspector = Test::Inspector->setup({
    modules => [ 'Foo::Bar', 'Bar::Baz', ... ],
    dirs    => [ '/path/to/test/dir1', '/path/to/test/dir2', ... ],
    ignore  => [ 'import_from_elsewhere_method1', 'also_imported', ... ],
    private => 1, # tests *all* methods, don't ignore ones that start _
  });

  print $inspector->inspect;

=head1 DESCRIPTION

Ever been asked to write tests for an unknown codebase? A large codebase,
that may, or may not, have tests associated with it? How do you know if you
need to test a method? Is it already tested?

This doesn't answer those questions per se. It tries to make a first best
stab at it for you.

Supply a list of modules, supply a list of test directories, and we see if
the methods in the modules are called anywhere in those directories. It
doesn't mean that the tests are good, but it might help you in where to add a
new test, or which tests you should be running.

If you import methods into a module, you may not want to know if they are
tested by your good self. That should be up to the exporting module's test
suite, right? Using the 'ignore' key to the hashref or args, you can say you
don't care about those methods. Like, say, in this itself, I use File::Find,
but don't really want to be worrying about if I have tested 'find' or
'finddepth'. Y'see?

=head1 METHODS

=cut

use strict;
use warnings;

our $VERSION = '0.03';

use File::Find;
use lib '/Users/mkerr/code';

=head2 setup

  my $inspector = Test::Inspector->setup({
    modules => [ 'Foo::Bar', 'Bar::Baz', ... ],
    dirs    => [ '/path/to/test/dir1', '/path/to/test/dir2', ... ],
    ignore  => [ 'import_from_elsewhere_method1', 'also_imported', ... ],
    private => 1, # tests *all* methods, don't ignore ones that start _
  });

Set the Inspector up with some modules and directories. Both passed in as
listrefs in the keys of the hashref.

=cut

sub _module_methods {
  my ($class, $private, @modules) = @_;
  my %stuff;
  no strict 'refs';
  for my $module (@modules) {
    eval "require $module";
    $module->import();
    for my $what (%{*{"$module\::"}}) {
      next unless $what =~ m/$module/;
      (my $meth = $what) =~ s/^\*$module\:\://;
      next unless $module->can($meth);
      next if $meth =~ /^_/ && $private;
      $stuff{$module}{$meth}++;
    }
  }
  return %stuff;
}

sub _find_tests {
  my ($class, @dirs) = @_;
  my @test_files;
  my $wanted = sub {
    push @test_files, $File::Find::name if $_ =~ m/\.(pl|pm|t)$/
  };
  find($wanted, @dirs);
  return 'test_files', [ @test_files ];
}

sub setup {
  my ($class, $info) = @_;
  die "Incorrect args" unless ref $info eq 'HASH';
  bless {
    $class->_find_tests(@{ $info->{dirs} }),
    $class->_module_methods($info->{private} ? 1 : 0, @{ $info->{modules} }),
    %$info,
  }, $class;
}

=head2 inspect

  my %report = $inspector->inspect;

This will inspect the tests to see if all the methods in the module were
referenced in any way.

=cut

sub _check {
  my ($self, $mod, $file) = @_;
  my $methods = join '|', keys %{ $self->{$mod} };
  my (%results, $use);
  open FILE, '<', $file or return;
  for my $line (<FILE>) {
    $results{'__is_used__'}++ if $line =~ m/(use|use_ok|require|require_ok).*$mod/;
    for my $meth (keys %{ $self->{$mod} }) {
      $results{$meth} ||= 0;
      next unless $line =~ m/$meth/;
      $results{$meth}++;
    }
  }
  close FILE;
  return %results;
}

sub _results { %{ shift->{results} } }

sub inspect {
  my $self = shift;
  return %{ $self->{results} } if exists $self->{results};
  my %results;
  for my $test_script (@{ $self->{test_files} }) {
    for my $module (@{ $self->{modules} }) {
      $results{$module}{$test_script} = { $self->_check($module, $test_script) };
    }
  }
  $self->{results} = { %results };
  return %results;
}

=head2 pretty_report

  print $inspector->pretty_report;

As it says, this is pretty report. The output looks like:

  Module::Name
    test_script_name
      method_name1 => FOUND
      method_name2 => NOT FOUND
 ...

OK, so it is a report, not that pretty. If you want to know how much time I
spent on this in total...wait! come back!

=cut

sub pretty_report {
  my $self = shift;
  my %results = $self->inspect;
  my $ignore = join "|", @{ $self->{ignore} || [] }, '__is_used__';
  for my $module (sort keys %results) {
    print "$module\n";
    for my $test_script (sort keys %{ $results{$module} }) {
      print "\t$test_script\n";
      my ($found, $not, $status) = (0, 0, '');
      for my $method (sort keys %{ $results{$module}{$test_script} }) {
        do {
          print "\t\t$module not used in this script\n";
          last;
        } unless exists $results{$module}{$test_script}{'__is_used__'};
        next if $ignore && $method =~ m/$ignore/;
        if ($results{$module}{$test_script}{$method}) {
          $status = 'FOUND'; $found++;
        } else {
          $status = 'NOT FOUND'; $not++;
        }
        print "\t\t$method $status\n";
      }
      my $denom = ($found + $not) || 1;
      printf "\t\tfound: %d not found %d (%.2f%%)\n\n",
        $found, $not, ($found / $denom) * 100; 
    }
  }
}

=head1 NOTES

Look, you might have worked out, this is a first-pass attempt, it is dumb,
could probably be done better using other modules, yadayadayada. It isn't
meant to be the One True Answer for checking to make sure you have tested all
your methods. It is a crude tool used to aid you somewhat. It might do, it
might not, if it doesn't, then use something else!

=head1 BUGS

When you use the script itself to try and self-test, it all gets a bit
self-referential doesn't it? Probably not the best code I have ever written,
but probably more useful that all the other stuff. Who am I kidding?

=head1 TODO

 o Stuff, no doubt. This did what I wanted it to do, in a crude way.

=head1 AUTHOR

  (c) Stray Toaster 2007.

=cut

return qw/The light bulbs burn and her fingers will learn/;
