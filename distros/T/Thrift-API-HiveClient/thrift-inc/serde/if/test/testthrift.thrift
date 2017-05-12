
namespace java org.apache.hadoop.hive.serde.test
namespace perl Thrift.Hive.Serde.Test

struct InnerStruct {
  1: i32 field0
}

struct ThriftTestObj {
  1: i32 field1,
  2: string field2,
  3: list<InnerStruct> field3
}
