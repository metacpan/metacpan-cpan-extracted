package Test::Structure;
use warnings;
use strict;
use PPI;
use File::Spec::Functions;

my $CLASS = __PACKAGE__;

use base 'Test::Builder::Module';

=head1 NAME

Test::Structure - Test for the structure of a package 

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Have you ever wished that you could build tests based on the structure of a package, not 
how a package acts. Ya me either, but I've bumped in to a situation where I needed it. 

    use Test::Structure tests => 5;

    require_ok( 'My::Package' );
    has_includes( 'My::Package', qw{My::Other::Package Some::Other::Package} );
    has_subs( 'My::Package', qw{this that} );
    has_commetns( 'My;::Package' );
    has_pod( 'My::Package' );
    
=head1 EXPORT

=cut

our @EXPORT = qw{ has_includes 
                  has_subs 
                  has_comments 
                  has_pod
               };
# PRIVATE: take My::Package and build the right path for it
sub _pkg2path { catfile( split /::/, shift ) . '.pm' };

# PRIVATE: build up a PPI::Document for the given package
sub _doc { 
   my $pkg = shift;
   eval sprintf q{require %s}, $pkg;
   my $doc = PPI::Document->new( $INC{Test::Structure::_pkg2path($pkg)} || $pkg );
   $doc;
}

=head2 has_includes

=cut

sub has_includes ($@) {
   my $pkg = shift;
   my $tb  = $CLASS->builder;
   my $doc = Test::Structure::_doc($pkg);
   my %inc = map{ $_->module => 1 }
             @{ $doc->find('PPI::Statement::Include') } ;
   my @missing =  grep{ ! $inc{$_} } @_ ;
   $tb->ok(! scalar( @missing ) ) 
      || $tb->diag( sprintf qq{Package %s is missing the following package%s%s}, 
                            $pkg, 
                            (scalar(@missing)>1) ? 's' : '', 
                            join qq{\n - }, '', @missing 
                  );
}

=head2 has_subs

=cut

sub has_subs {
   my $pkg = shift;
   my $tb  = $CLASS->builder;
   my $doc = Test::Structure::_doc($pkg);
   my %subs = map {$_->name => 1} 
              grep{ !$_->isa('PPI::Statement::Scheduled')} 
              @{$doc->find('PPI::Statement::Sub')};

   my @missing =  grep{ ! $subs{$_} } @_ ;
   $tb->ok(! scalar( @missing ) ) 
      || $tb->diag( sprintf qq{Package %s does not define the following sub%s%s}, 
                            $pkg, 
                            (scalar(@missing)>1) ? 's' : '', 
                            join qq{\n - }, '', @missing 
                  );
}


=head2 has_pod

=cut

sub has_pod ($) {
   my $pkg = shift;
   my $tb  = $CLASS->builder;
   $tb->ok( Test::Structure::_doc($pkg)->find_any('PPI::Token::Pod'), sprintf q{Package %s has POD.}, $pkg ) 
      || $tb->diag( sprintf q{Package %s does not seem to have any POD.}, $pkg );
}

=head2 has_comments

=cut

sub has_comments ($) {
   my $pkg = shift;
   my $tb  = $CLASS->builder;
   $tb->ok( Test::Structure::_doc($pkg)->find_any('PPI::Token::Comment'), sprintf q{Package %s has comments.}, $pkg ) 
      || $tb->diag( sprintf q{Package %s does not seem to have any comments.}, $pkg );
}

=head1 AUTHOR

notbenh, C<< <notbenh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-structure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Structure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Structure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Structure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Structure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Structure>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Structure/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 notbenh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; 
