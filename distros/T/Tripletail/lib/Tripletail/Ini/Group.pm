package Tripletail::Ini::Group;
use strict;
use warnings;
use Tripletail::Ini::Group::Variant;
use List::MoreUtils qw(any);

1;

=encoding utf-8

=head1 NAME

Tripletail::Ini::Group - 内部用


=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。


=head2 METHODS

=over 4

=item C<< new >>

=cut

use fields qw(basename variant_for variants);
sub new {
    my Tripletail::Ini::Group $this = shift;
    my $basename                    = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{basename   } = $basename;
    $this->{variant_for} = {};    # annotation => Variant
    $this->{variants   } = [];    # [Variant]

    return $this;
}


=item C<< basename >>

=cut

sub basename {
    my Tripletail::Ini::Group $this = shift;

    return $this->{basename};
}


=item C<< variants >>

=cut

sub variants {
    my Tripletail::Ini::Group $this = shift;

    return @{ $this->{variants} };
}


=item C<< touchVariant >>

=cut

sub touchVariant {
    my Tripletail::Ini::Group             $this = shift;
    my Tripletail::Ini::Group::Annotation $anno = shift;

    if (exists $this->{variant_for}{$anno}) {
        return $this->{variant_for}{$anno};
    }
    else {
        my $variant
          = Tripletail::Ini::Group::Variant->new($anno);

        $this->{variant_for}{$anno} = $variant;
        push @{ $this->{variants} }, $variant;

        return $variant;
    }
}


=item C<< hasVariant >>

=cut

sub hasVariant {
    my Tripletail::Ini::Group             $this = shift;
    my Tripletail::Ini::Group::Annotation $anno = shift;

    if (exists $this->{variant_for}{$anno}) {
        return 1;
    }
    else {
        return;
    }
}


=item C<< getVariant >>

=cut

sub getVariant {
    my Tripletail::Ini::Group             $this = shift;
    my Tripletail::Ini::Group::Annotation $anno = shift;

    if (exists $this->{variant_for}{$anno}) {
        return $this->{variant_for}{$anno};
    }
    else {
        return;
    }
}


=item C<< filterVariants >>

    my @variants = $group->filterVariants($hosts); # $hosts is optional

Return a list of L<Tripletail::Ini::Group::Variant> objects whose
annotation (or lack thereof) matches to the current environment. The
list is sorted by precedence in descending order (highest first).

C<$hosts> should be another L<Tripletail::Ini::Group::Variant> object
representing the lone variant of the special C<[HOST]> group. When
it's C<undef> it is assumed that the C<[HOST]> group is missing.

=cut

sub filterVariants {
    my Tripletail::Ini::Group          $this  = shift;
    my Tripletail::Ini::Group::Variant $hosts = shift;

    my @annotated;
    my $vanilla;

    foreach my $variant (@{ $this->{variants} }) {
        my $anno = $variant->annotation;

        if ($anno->isEmpty) {
            $vanilla = $variant;
        }
        elsif ($anno->matches($hosts)) {
            push @annotated, $variant;
        }
    }

    if (defined $vanilla) {
        return (@annotated, $vanilla);
    }
    else {
        return @annotated;
    }
}


=item C<< deleteVariants >>

=cut

sub deleteVariants {
    my Tripletail::Ini::Group $this = shift;
    my @annotations                 = @_;

    delete @{ $this->{variant_for} }{@annotations};

    @{ $this->{variants} }
      = grep {
            my $variant = $_;
            !any {$variant->annotation ne $_};
          }
          @{ $this->{variants} };

    return $this;
}


=item C<< toStr >>

=cut

sub toStr {
    my Tripletail::Ini::Group $this = shift;

    my @chunks = map {
                     $_->toStr($this->{basename})
                   }
                   @{$this->{variants} };
    return join("\n", @chunks);
}


=back


=head1 SEE ALSO

L<Tripletail>


=head1 AUTHOR INFORMATION

Copyright 2006-2013 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site : http://tripletail.jp/

=cut
