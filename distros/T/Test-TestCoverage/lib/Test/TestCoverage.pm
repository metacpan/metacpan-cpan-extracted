package Test::TestCoverage;

# ABSTRACT: Test if your test covers all "public" subroutines of the package

use strict;
use warnings;
use Devel::Symdump;
use Test::Builder;
use B;
use base qw(Exporter);

our @EXPORT = qw(
                 test_coverage 
                 ok_test_coverage
                 all_test_coverage_ok
                 reset_test_coverage
                 reset_all_test_coverage
                 test_coverage_except
                );
our $VERSION = '0.12';

my $self    = {};
my $test    = Test::Builder->new();
my $invokes = {};
my $last    = '';


sub test_coverage {
    my ($package) = @_;
    return unless defined $package;
    $last = $package;
    _get_subroutines($package);
    
    $invokes->{$package} = {};
    
    my $moosified = $INC{"Moose.pm"} ? 1 : 0;
    
    for my $subref(@{$self->{subs}->{$package}}){
        my $sub      = $subref->[0];
        
        my $sub_with = $package . '::' . $sub;
        unless(exists $invokes->{$package}->{$sub}){
            $invokes->{$package}->{$sub} = 0;
        }
        
        no strict 'refs';
        no warnings 'redefine';
        
        my $old    = $package->can( $sub );
        my $mopped = 0;

        if ( $moosified ) {
            require Class::MOP;
            my $meta
                = $package->can('add_before_method_modifier')
                ? $package
                : Class::MOP::class_of( $package );

            if ( defined $meta ) {
                $mopped++;
                $meta->add_after_method_modifier( $sub, sub {
                    $invokes->{$package}->{$sub}++; 
                } );
            }
        }

        if ( !$mopped ) {
            *{ $package . '::' . $sub } = sub {
                $invokes->{$package}->{$sub}++; 
                $old->( @_ );
            };
        }
    }
        
    1;
}

sub test_coverage_except {
    my ($package,@subroutines) = @_;
    
    for my $subname(@subroutines){
        if(exists $invokes->{$package} and 
           exists $invokes->{$package}->{$subname} and
           exists $self->{subs}->{$package}){
            @{$self->{subs}->{$package}} = grep{$_->[0] ne $subname}@{$self->{subs}->{$package}};
            delete $invokes->{$package}->{$subname};
        }
    }
}

sub all_test_coverage_ok {
    my ($msg) = @_;
    
    for my $package(keys %$invokes){
        ok_test_coverage($package,$msg);
    }
    1;
}

sub ok_test_coverage {
    my ($package,$msg) = @_;
    
    if(!$package or (!exists $invokes->{$package}) 
                     and $package !~ /^(?:\w+(?:::)?)+$/){
        $package = $last;
    }
        
    unless(exists $invokes->{$package}){
        warn $package.' was not tested';
        return;
    }
    
    my $bool_msg = defined $msg ? 1 : 0;
    my $title    = 'Test test-coverage ';
    my $missing;
    
    my $bool_coverage = 1;
    for my $sub(map{$_->[0]}@{$self->{subs}->{$package}}){
        if(!exists $invokes->{$package}->{$sub} or $invokes->{$package}->{$sub} == 0){
            $missing = defined $missing && !$bool_msg ? $missing . $sub . ' ' : $sub . ' ';
            $bool_coverage = 0;
        }
    }
    
    if(!$bool_msg){
        $msg  = $title;
        $msg .= $missing.' are missing' if(defined $missing);
    }
    
    $test->cmp_ok($bool_coverage,"==",1,$msg);
    1;
}

sub reset_test_coverage{
    my ($self,$pkg) = @_;
    for my $key(keys %{$invokes->{$pkg}}){
        $invokes->{$pkg}->{$key} = 0;
    }
}

sub reset_all_test_coverage{
    my ($self) = @_;
    for my $pkg(keys %{$invokes}){
        $self->reset_test_coverage($pkg);
    }
}

sub _get_subroutines{
    my ($pkg,$test) = @_;
        
    eval qq{ require $pkg };
    print STDERR $@ if $@;
    return if $@;
    
    $test ||= $pkg;    

    my $symdump = Devel::Symdump->new($pkg);

    my @symbols;
    for my $func ($symdump->functions ) {
        my $owner = _get_sub(\&{$func});
        $owner =~ s/^\*(.*)::.*?$/$1/;
        next if $owner ne $test;

        # check if it's on the whitelist
        $func =~ s/${pkg}:://;

        push @symbols, [$func,$owner] unless $func =~ /^_/;
    }
    
    $self->{subs}->{$pkg} = \@symbols;
    
    1;
}

sub _get_sub {
    my ($svref) = @_;
    my $b_cv = B::svref_2object($svref);
    no strict 'refs';
    return *{ $b_cv->GV->STASH->NAME . "::" . $b_cv->GV->NAME };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::TestCoverage - Test if your test covers all "public" subroutines of the package

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use Test::TestCoverage;
  
  test_coverage('My::Module');
  
  my $obj = My::Module->new();
  $obj->foo();
  $obj->bar();
  
  # test will be ok, assumed that My::Module has the subroutines new, foo and bar
  ok_test_coverage('My::Module');
  
  reset_test_coverage('My::Module');
  reset_all_test_coverage();
  
  test_coverage('My::Module');
  
  my $obj = My::Method->new();
  $obj->foo();
  
  # test will be not ok, because bar is not invoked
  ok_test_coverage('My::Module');
  
  reset_test_coverage('My::Module');
  reset_all_test_coverage();
  
  test_coverage('My::Module');
  test_coverage_except('My::Module','bar');
  
  my $obj = My::Method->new();
  $obj->foo();
  
  # test will be ok, because bar is excepted of test
  ok_test_coverage('My::Module');

=head1 DESCRIPTION

If a module is written, the tests cover just a few subroutines of the module.
This module aims to support the author in writing "complete" tests. If one
of the "public" subroutines are missed in the testscript, the test C<ok_test_coverage>
will fail.

"private" subroutines are defined as subroutines that names begin with C<_> like 
C<_private_sub{...}> and "public" is the opposite.

=head1 subroutines

=head2 test_coverage $module

Tells C<Test::TestCoverage> for what module the coverage should be tested

=head2 ok_test_coverage $module

Checks if all "public" subroutines of C<$module> were called in the testscript

=head2 reset_test_coverage $module

Resets the counter for all method invokations of C<$module>'s subroutines.

=head2 reset_all_test_coverage

Resets the counter for all subroutines of all modules that were registerd via
C<test_coverage>.

=head2 test_coverage_except $module @subs

Test all "public" subroutines of C<$module> except the subroutines named in
the array.

=head2 all_test_coverage_ok 

tests the test coverage for each registered module.

=head1 EXPORT

C<test_coverage>, C<ok_test_coverage>, C<reset_test_coverage>,
C<reset_all_test_coverage>, C<test_coverage_except>

=head1 SEE ALSO

L<Test::SubCalls>, L<Test::Builder>, L<Test::More>, L<Devel::Cover>

=head1 BUGS / TODO

There are a lot of things to do. If you experience any problems please contact
me. At the moment the subroutines have to be invoked with full qualified names.
Exported subroutines are not detected.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
