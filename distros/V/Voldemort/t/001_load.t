# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 12;

BEGIN {
    use_ok('Voldemort::ProtoBuff::BaseMessage');
    use_ok('Voldemort::ProtoBuff::Resolver');
    use_ok('Voldemort::ProtoBuff::Connection');
    use_ok('Voldemort::ProtoBuff::GetMessage');
    use_ok('Voldemort::ProtoBuff::DeleteMessage');
    use_ok('Voldemort::ProtoBuff::Spec2');
    use_ok('Voldemort::ProtoBuff::PutMessage');
    use_ok('Voldemort::ProtoBuff::DefaultResolver');
    use_ok('Voldemort::Connection');
    use_ok('Voldemort::Store');
    use_ok('Voldemort::Message');
    use_ok('Voldemort');
}

