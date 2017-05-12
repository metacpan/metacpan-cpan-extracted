use strict;
use warnings;

package PPI::Transform::PackageName;

# ABSTRACT: Subclass of PPI::Transform specific for modifying package names
our $VERSION = 'v0.0.7'; # VERSION

use base qw(PPI::Transform);

use Carp;

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    my %arg = @_;
    if(exists $arg{-all}) {
        croak "-all and other options are contradictory" if exists $arg{-package_name} || exists $arg{-word} || exists $arg{-quote};
        $arg{-package_name} = $arg{-all};
        $arg{-word}         = $arg{-all};
        $arg{-quote}        = $arg{-all};
    }
    return bless {
        _PKG => $arg{-package_name},
        _WORD => $arg{-word},
        _QUOTE => $arg{-quote},
    }, $class;
}

sub document
{
    my ($self, $doc) = @_;
    $doc->prune('PPI::Token::Comment');
    if(defined $self->{_PKG} && defined $self->{_WORD}) {
        my $words = $doc->find('PPI::Token::Word');
        $words ||= [];
        for my $word (@$words) {
            if(defined $self->{_PKG} && $word->statement->class eq 'PPI::Statement::Package') {
                my $content = $word->content;
                $_ = $content;
                $self->{_PKG}->();
                $word->set_content($_) if $_ ne $content;    
            } elsif(defined $self->{_WORD}) {
                my $content = $word->content;
                $_ = $content;
                $self->{_WORD}->();
                $word->set_content($_) if $_ ne $content;    
            }
        }
    }
    if(defined $self->{_QUOTE}) {
        my $quotes = $doc->find('PPI::Token::Quote');
        $quotes ||= [];
        for my $quote (@$quotes) {
                my $string = $quote->string;
                $_ = $string;
                $self->{_QUOTE}->();
                if($_ ne $string) {
                    my $content = $quote->content;
                    my $index = index($content, $string);
                    substr($quote->{content}, $index, length($string)) = $_;
                }
        }
    }
    return 1;
}

1;

__END__

=pod

=head1 NAME

PPI::Transform::PackageName - Subclass of PPI::Transform specific for modifying package names

=head1 VERSION

version v0.0.7

=head1 SYNOPSIS

  use PPI::Transform::PackageName;

  my $trans = PPI::Transform::PackageName->new(-package_name => sub { s/Test//g }, -word => sub { s/Test//g });
  $trans->file('Input.pm' => 'Output.pm');

=head1 DESCRIPTION

This module is a subclass of PPI::Transform specific for modifying package name.

=head1 OPTIONS

=head2 I<-package_name>

Specify code reference called for modifying arguments of C<package> statements.
The code reference is called for each argument.
Original is passed as $_  and it is expected that $_ is modified.

=head2 I<-word>

Specify code reference called for modifying bare words other than arguments of C<package> statement.
The code reference is called for each bare word.
Original is passed as $_  and it is expected that $_ is modified.

=head2 I<-quote>

Specify code reference called for modifying quotes.
The code reference is called for each quote.
Original is passed as $_  and it is expected that $_ is modified.
Please NOTE that you SHOULD be careful to handle them because all quotes are considered.

=head2 I<-all>

Specify code reference called for all the above options.
Original is passed as $_  and it is expected that $_ is modified.
This option and others are contradictory.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
