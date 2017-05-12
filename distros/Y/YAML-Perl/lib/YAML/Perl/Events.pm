# pyyaml/lib/yaml/events.py

package YAML::Perl::Events;
use strict;
use warnings;

package YAML::Perl::Event;
use YAML::Perl::Base -base;

field 'start_mark';
field 'end_mark';

use overload '""' => sub {
    my $self = shift;
    my $class = ref($self) || $self;

    my @attributes = grep exists($self->{$_}),
       qw(anchor tag implicit value);
    my $arguments = join ', ', map
        sprintf("%s=%s", $_, ($self->{$_}||'')), @attributes;
    return "$class($arguments)";
};

package YAML::Perl::Event::Node;
use YAML::Perl::Event -base;

field 'anchor';

package YAML::Perl::Event::CollectionStart;
use YAML::Perl::Event::Node -base;

field 'tag';
# 01:20 < xitology> for sequences and mappings, implicit tag resolution does not 
#                   depend on the node style, so a single boolean value is enough
# field 'implicit';
# default to 1 makes things easier for now
field 'implicit' => 1;
field 'flow_style';

package YAML::Perl::Event::CollectionEnd;
use YAML::Perl::Event -base;

# Implementations.

package YAML::Perl::Event::StreamStart;
use YAML::Perl::Event -base;

field 'encoding';

package YAML::Perl::Event::StreamEnd;
use YAML::Perl::Event -base;

package YAML::Perl::Event::DocumentStart;
use YAML::Perl::Event -base;

field 'explicit' => 1;  # Different default than PyYaml
field 'version';
field 'tags';

package YAML::Perl::Event::DocumentEnd;
use YAML::Perl::Event -base;

field 'explicit';

package YAML::Perl::Event::Alias;
use YAML::Perl::Event::Node -base;

package YAML::Perl::Event::Scalar;
use YAML::Perl::Event::Node -base;

field 'tag';
# 01:17 < xitology> while !!str "123" could not be emitted in the plain style 
#                   without a tag (123), but could be as ("123")
# 01:17 < xitology> in this case, implicit is (False, True)
# 01:17 < xitology> another example is !!int "123", which can be emitted as 123, 
#                   but not as "123"
# 01:17 < xitology> here, implicit is (True, False)
# 01:18 < xitology> so implicit[0] is whether the tag of a scalar node could be 
#                   omitted when it is emitted in a plain style
# 01:18 < xitology> while implicit[1] is whether the tag could be omitted when 
#                   the node is emitted in any non-plain style
field 'implicit' => [True, True];
field 'value';
field 'style';

package YAML::Perl::Event::SequenceStart;
use YAML::Perl::Event::CollectionStart -base;

package YAML::Perl::Event::SequenceEnd;
use YAML::Perl::Event::CollectionEnd -base;

package YAML::Perl::Event::MappingStart;
use YAML::Perl::Event::CollectionStart -base;

package YAML::Perl::Event::MappingEnd;
use YAML::Perl::Event::CollectionEnd -base;

1;
