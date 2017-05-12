use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();
use utf8;

run 'valid-comment-block-01', [ JSON::null, 0xDEADBEEF, "yay" ];
run 'valid-comment-block-02', {
    mysql_default_config => {
        port     => 3306,
        user     => "cocoa",
        password => "s3cret",
        database => "users",
        charset  => "utf8mb4",
    },
    mysql => {
        MYSQL_USER_MASTER => { host => "master.users.mysql.local" },
        MYSQL_USER_SLAVE  => [
            { host => "0.user.products.mysql.local", port => 33060 },
            { host => "1.user.products.mysql.local", port => 33061 },
        ]
    },
    redis => {
        REDIS_PRODUCT_SHARD => [
            { host => "0.shard.products.redis.local", port => 3600, },
            { host => "1.shard.products.redis.local", port => 3601, },
        ]
    }
};

done_testing;

