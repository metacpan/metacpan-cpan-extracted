#!perl -w

use strict;
use warnings;

use Test::More;

package MyXslate;

use Any::Moose;

extends qw(Text::Xslate);

sub parser_option {
    my $self = shift;
    +{
        %{ $self->SUPER::parser_option },
        input_filter => undef,
    };
}
sub replace_option_value_for_magic_token {
    my($self, $name, $value) = @_;

    return $name if $name eq 'input_filter';
    return $value;
}


no Any::Moose;

package main;

my $tx = MyXslate->new(syntax => 'HTMLTemplate',
                       type => 'html',
                       compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                       input_filter => sub {
                           my $input_ref = shift;
                           $$input_ref = uc($$input_ref);
                       },
                   );
is($tx->render_string(<<'END;'),<<'END;');
<html><TMPL_VAR EXPR="1+2"></html>
END;
<HTML>3</HTML>
END;

$tx = MyXslate->new(syntax => 'HTMLTemplate',
                       type => 'html',
                       compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                       input_filter => sub {
                           my $input_ref = shift;
                           $$input_ref = $$input_ref . $$input_ref;
                       },
                   );
is($tx->render_string(<<'END;'),<<'END;');
<html><TMPL_VAR EXPR="1+2"></html>
END;
<html>3</html>
<html>3</html>
END;

done_testing;

