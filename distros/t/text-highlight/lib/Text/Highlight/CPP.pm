package Text::Highlight::CPP;
use strict;

sub syntax
{
	return {
          'name' => 'C/C++',
          'blockCommentOn' => [
                                '/*'
                              ],
          'case' => 1,
          'key2' => {
                      'ifndef' => 1,
                      'elif' => 1,
                      'undef' => 1,
                      'ifdef' => 1,
                      'include' => 1,
                      'else' => 1,
                      'define' => 1,
                      'if' => 1,
                      'pragma' => 1,
                      'error' => 1,
                      'endif' => 1,
                      'line' => 1
                    },
          'lineComment' => [
                             '//'
                           ],
          'delimiters' => ',(){}[]-+*%/="\'~!&|<>?:;.#',
          'key1' => {
                      '__based' => 1,
                      'static' => 1,
                      'if' => 1,
                      'sizeof' => 1,
                      'double' => 1,
                      'typedef' => 1,
                      'unsigned' => 1,
                      'new' => 1,
                      'this' => 1,
                      'break' => 1,
                      'inline' => 1,
                      'explicit' => 1,
                      'template' => 1,
                      'bool' => 1,
                      'for' => 1,
                      'private' => 1,
                      'default' => 1,
                      'else' => 1,
                      'const' => 1,
                      '__pascal' => 1,
                      'delete' => 1,
                      'class' => 1,
                      'continue' => 1,
                      '__fastcall' => 1,
                      'union' => 1,
                      'extern' => 1,
                      '__cdecl' => 1,
                      'friend' => 1,
                      '__inline' => 1,
                      'int' => 1,
                      'do' => 1,
                      '__virtual_inheritance' => 1,
                      'void' => 1,
                      'case' => 1,
                      '__multiple_inheritance' => 1,
                      'short' => 1,
                      'operator' => 1,
                      '__asm' => 1,
                      'float' => 1,
                      'struct' => 1,
                      'cout' => 1,
                      'public' => 1,
                      'enum' => 1,
                      'long' => 1,
                      'goto' => 1,
                      '__single_inheritance' => 1,
                      'volatile' => 1,
                      'throw' => 1,
                      'namespace' => 1,
                      'protected' => 1,
                      'virtual' => 1,
                      'return' => 1,
                      'signed' => 1,
                      'register' => 1,
                      'while' => 1,
                      'auto' => 1,
                      'try' => 1,
                      'switch' => 1,
                      'char' => 1,
                      'catch' => 1,
                      'cerr' => 1,
                      'cin' => 1
                    },
          'quot' => [
                      '\'',
                      '"'
                    ],
          'blockCommentOff' => [
                                 '*/'
                               ],
          'escape' => '\\',
          'continueQuote' => 0
        };

}

1;
__END__
