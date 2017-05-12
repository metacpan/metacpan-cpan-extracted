package CmdTest::Thing::Create;
use UR;
class CmdTest::Thing::Create {
    is => 'Command::SubCommandFactory',
};
sub _sub_commands_from { 'CmdTest::Thing' }
sub _build_sub_command {
    my ($self, $class_name, @inheritance) = @_;
    return if $class_name =~ /Two/;
    class {$class_name} { 
        is => \@inheritance, 
        doc => '',
    };
    return $class_name;
}
1;
