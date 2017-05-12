# pyyaml/lib/yaml/tokens.py

package YAML::Perl::Tokens;
use strict;
use warnings;
use YAML::Perl::Base -base;

package YAML::Perl::Token;
use YAML::Perl::Base -base;

field 'start_mark';
field 'end_mark';

use overload '""' => 'stringify';

sub stringify {
    my $self = shift;
    my $class = ref($self) || $self;

    my @attributes = grep not(/_mark$/), keys %$self;
    my $arguments = join ', ', map
        sprintf("%s=%s", $_, $self->{$_}), @attributes;
    return "$class ($arguments)";
}

package YAML::Perl::Token::Directive;
use YAML::Perl::Token -base;

field id => '<directive>';
field 'name';
field 'value';

package YAML::Perl::Token::DocumentStart;
use YAML::Perl::Token -base;

field id => '<document start>';

package YAML::Perl::Token::DocumentEnd;
use YAML::Perl::Token -base;

field id => '<document end>';

package YAML::Perl::Token::StreamStart;
use YAML::Perl::Token -base;

field id => '<stream start>';
field 'encoding';

package YAML::Perl::Token::StreamEnd;
use YAML::Perl::Token -base;

field id => '<stream end>';

package YAML::Perl::Token::BlockSequenceStart;
use YAML::Perl::Token -base;

field id => '<block sequence start>';

package YAML::Perl::Token::BlockMappingStart;
use YAML::Perl::Token -base;

field id => '<block mapping start>';

package YAML::Perl::Token::BlockEnd;
use YAML::Perl::Token -base;

field id => '<block end>';


package YAML::Perl::Token::FlowSequenceStart;
use YAML::Perl::Token -base;

field id => '[';


package YAML::Perl::Token::FlowMappingStart;
use YAML::Perl::Token -base;

field id => '{';


package YAML::Perl::Token::FlowSequenceEnd;
use YAML::Perl::Token -base;

field id => ']';


package YAML::Perl::Token::FlowMappingEnd;
use YAML::Perl::Token -base;

field id => '}';


package YAML::Perl::Token::Key;
use YAML::Perl::Token -base;

field id => '?';


package YAML::Perl::Token::Value;
use YAML::Perl::Token -base;

field id => ':';


package YAML::Perl::Token::BlockEntry;
use YAML::Perl::Token -base;

field id => '-';


package YAML::Perl::Token::FlowEntry;
use YAML::Perl::Token -base;

field id => ',';

package YAML::Perl::Token::Alias;
use YAML::Perl::Token -base;

field id => '<alias>';
field 'value';

package YAML::Perl::Token::Anchor;
use YAML::Perl::Token -base;

field id => '<anchor>';
field 'value';

package YAML::Perl::Token::Tag;
use YAML::Perl::Token -base;

field id => '<tag>';
field 'value';

package YAML::Perl::Token::Scalar;
use YAML::Perl::Token -base;

field id => '<scalar>';
field 'value';
field 'plain';
field 'style';

1;
