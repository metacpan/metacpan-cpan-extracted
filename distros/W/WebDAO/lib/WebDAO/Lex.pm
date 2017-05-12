#===============================================================================
#
#  DESCRIPTION:  New Ng Lexer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package WebDAO::Lex;

=head1 NAME

WebDAO::Lex - Lexer class

=head1 DESCRIPTION

WebDAO::Lex - Lexer class


=head1 METHODS

=cut

our $VERSION = '0.01';

use strict;
use warnings;
use WebDAO::Base;
use XML::Flow;
use base 'WebDAO::Base';
use WebDAO::Lexer::base;
use WebDAO::Lexer::method;
use WebDAO::Lexer::object;
use WebDAO::Lexer::regclass;
use WebDAO::Lexer::text;


__PACKAGE__->mk_attr( __tmpl__ => '' );

sub new {
    my $class = shift;
    my $self = bless( $#_ == 0 ? {shift} : {@_}, ref($class) || $class );
    $self

}

sub _parsed_template_ {
    my $self = shift;
    my $eng  = shift;
    my @res;
    foreach ( @{ $self->split_template( shift || $self->__tmpl__ ) } ) {
        my $res = ref($_) ? $self->buld_tree($$_) : [];
        push @res, $res;
    }
    return \@res;
}

=head2 split_template

Return [ $pre_part, $main_html, $post_part ]

=cut

sub split_template {
    my $self  = shift;
    my $txt   = shift || return [ undef, undef, undef ];
    my @parts = split( m%<!--\s*\<\/?wd:fetch>\s*-->%, $txt );
    return [ undef, $parts[0], undef ] if scalar(@parts) == 1;
    return [ @parts, undef ] if scalar(@parts) == 2;
    \@parts;
}

sub value {
    my $self    = shift;
    my $eng     = shift;
    my $content = $self->{tmpl};
    my @res;
    foreach ( @{ $self->split_template($content) } ) {
        my $res = $_ ? $self->buld_tree( $eng, $_ ) : [];
        push @res, $res;
    }
    return \@res;
}

sub parse {
    my $self     = shift;
    my $txt      = shift || return [];
    my %classmap = (
        object    => 'WebDAO::Lexer::object',
        regclass  => 'WebDAO::Lexer::regclass',
        objectref => 'WebDAO::Lexer::objectref',
        text      => 'WebDAO::Lexer::text',
        include   => 'WebDAO::Lexer::include',
        default   => 'WebDAO::Lexer::base',
        method    => 'WebDAO::Lexer::method'
    );
    our $result = [];
    my %tags = (
        wd => sub { shift; $result = \@_ },
        '*' => sub {
            my $name   = shift;
            my $a      = shift;
            my $childs = \@_;
            my $class  = $classmap{$name} || $classmap{'default'};
            my $o = $class->new(
                name   => $name,
                attr   => $a,
                childs => $childs
            );
            return $o;
        }
    );
    my $rd = new XML::Flow:: \$txt;
    $rd->read( \%tags );
    $result;
}

sub buld_tree {
    my $self     = shift;
    my $eng      = shift;
    my $raw_html = shift || return [];

    #Mac and DOS line endings
    $raw_html =~ s/\r\n?/\n/g;
    my $mass;
    $mass = [ split( /(\<WD>.*?<\/WD>)/is, $raw_html ) ];
    my @res;
    foreach my $text (@$mass) {
        my @ref;
        unless ( $text =~ /^<wd/i ) {
            push @ref,
              WebDAO::Lexer::object->new(
                attr=>{
                    class=>'_rawhtml_element',
                    'id'=>'none'
                },
               'childs' =>
                      [ WebDAO::Lexer::text->new( value => \$text ) ],
              )->value($eng)
              unless $text =~ /^\s*$/;
        }
        else {
            my $tree = $self->parse($text);
            foreach my $o (@$tree) {
                my $res = $o->value($eng);
                push @ref, $res if defined $res;
            }
        }
        next unless @ref;
        push @res, @ref;
    }
    return \@res;
}
1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

