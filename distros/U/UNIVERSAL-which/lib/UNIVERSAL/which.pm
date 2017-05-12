package UNIVERSAL::which;
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.6 $ =~ /(\d+)/g;

sub UNIVERSAL::which {
    my ( $self, $method ) = @_;
    my $coderef = $self->can($method);
    unless ($coderef) {
        $method  = 'AUTOLOAD';
        $coderef = $self->can($method);
    }
    return unless UNIVERSAL::isa($coderef, 'CODE');
    require B;
    my $b       = B::svref_2object($coderef);
    my $cvflags = $b->CvFLAGS;
    my $pkg     = $b->GV->STASH->NAME;
    my $fq      =  $pkg . '::' . $method;
    if (! defined(&{$fq}) ){
	$method = $b->GV->NAME;
	$fq = $pkg . '::' . $method;
	$fq = undef unless defined(&{$fq}); # double-check
    }
    return wantarray ? ( $pkg, $method, $cvflags ) : $fq;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

UNIVERSAL::which - tells fully qualified name of the method

=head1 VERSION

$Id: which.pm,v 0.6 2007/05/15 16:01:20 dankogai Exp dankogai $

=cut

=head1 SYNOPSIS

  use UNIVERSAL::which;
  use Some::Sub::Class; # which inherits lots of modules
  # ....
  my $o   = Some::Sub::Class->new;
  # in scalar context
  my $fqn = $o->which("method");
  # in list context
  my ($pkg, $name) = $o->which("method");
  # as function
  my $fqn = UNIVERSAL::which('Some::Sub::Class', 'method');

=head1 DESCRIPTION

UNIVERSAL::which provides only one method, C<which>.

As the name suggests, it returns the fully qualified name of a given
method.  Sometimes you want to know the true origin of a method but
inheritance and AUTOLOAD gets in your way.  This module does just that.

t/*.t illustrates how UNIVERSAL::which behaves more in details.

=head2 CAVEAT

Consider the code below;

  no warnings 'once';
  package Foo;
  my $code = sub { 1 };
  package Bar;
  *muge = $code;

In this case, you get C<undef> for C<< $fq = Bar>which('muge') >>
while C<< ($pkg, $name) = Bar->which('muge') >> is C<('Foo',
'__ANON__')>.

That way the code snippet works as expeted.

  my $fq = Bar->which('muge'); &$fg if $fg;

if you get 'Bar::__ANON__' instead, perl will croak on you at the 2nd
line.

=head1 SEE ALSO

L<perlobj>, L<UNIVERSAL::canAUTOLOAD>

=head1 AUTHORS

Dan Kogai, E<lt>dankogai at dan.co.jpE<gt>
L<http://search.cpan.org/~dankogai/>

Original idea seeded by: TANIGUCHI
L<http://search.cpan.org/~taniguchi/>

B::svref_2object trick by: HIO
L<http://search.cpan.org/~hio/>

AUTOLOAD case suggested by: DAIBA
L<http://search.cpan.org/~daiba/>

Anon. coderef bug noted by: MIYAZAKI
L<http://search.cpan.org/~miyazaki/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
