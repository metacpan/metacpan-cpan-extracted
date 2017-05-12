package Text::Livedoor::Wiki::Plugin::Inline::Function;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{([&#]([a-zA-Z]+)\([\s]*([^\)]*)\))((?:\{(?:[^\{\}]|(?:\{(?:[^\{\}]|(?:\{[^\{\}]*\}))*\}))*\})?)});
__PACKAGE__->n_args(4);

sub process {
    my ( $class , $inline, $head_part, $function_name, $opr, $tail_part ) = @_;
    my $original = $head_part . $tail_part;
    $tail_part = $1 if ( $tail_part =~ /^\{(.*)\}$/ );
    # trim
    $opr =~ s/^\s+//;
    $opr =~ s/\s+$//;

    $tail_part =~ s/^\s+//;
    $tail_part =~ s/\s+$//;

    unless ( $inline->function->has_function( $function_name ) ) {
        return  Text::Livedoor::Wiki::Utils::escape_more($original);
    }

    my $data = $inline->function->prepare(  $function_name ,  $opr , $tail_part );
    unless( $data ) {
        return Text::Livedoor::Wiki::Utils::escape_more( $original );
    }

    return $inline->function->parse( $function_name , $data );
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Function - Inline Function Plugin

=head1 DESCRIPTION

This is a very special plugin which called function plugins. 

=head1 SYNOPSIS

 &functionname(){hoge}
 #functionname(){hoge}

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
