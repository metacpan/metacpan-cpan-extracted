#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use JSON::XS;

sub read_file {
    local $/;
    open FH, shift;
    my $ret = <FH>;
    close FH;
    return $ret;
}

sub test_array {
    my ($array, $struct) = @_;

    my ($prev_class, $has_warn);

    for my $c (0..$#$array) {
        my $value = $array->[$c];
        my $class = ref $value;

        if (!$has_warn) {
            if (defined $prev_class && $prev_class ne $class) {
                warn "Different types in array: $struct";
                $has_warn = 1;
            }

            $prev_class = $class;
        }

        next if !$class || $class eq 'JSON::XS::Boolean';

        if ($class eq 'ARRAY') {
            my $ret = test_array($value, "$struct\[$c]");
            return 0 if !$ret;
        }
        elsif ($class eq 'HASH') {
            warn "Not blessed: $struct\['$c']";
        }
        elsif ($class =~ /::/) {
            my $ret = test_hash($value, "$struct\[$c]");
            return 0 if !$ret;
        }
    }

    return 1;
}

sub test_hash {
    my ($hash, $struct) = @_;

    for my $key (keys %$hash) {
        my $method = $key;
        $method =~ s/[^0-9a-z_]/_/gi;

        if (!$hash->can($method)) {
            warn ref($hash)."->$key() failed";
            return 0;
        }

        my $value = $hash->$method;
        my $class = ref($value);

        next if !$class || $class eq 'JSON::XS::Boolean';

        if ($class eq 'ARRAY') {
            my $ret = test_array($value, "$struct\{'$key'}");
            return 0 if !$ret;
        }
        elsif ($class eq 'HASH') {
            warn "Not blessed: $struct\{'$key'}";
        }
        elsif ($class =~ /::/) {
            my $ret = test_hash($value, "$struct\{'$key'}");
            return 0 if !$ret;
        }
    }

    return 1;
}

sub test_json {
    my ($fname, $class) = @_;

    eval "use $class";
    if ($@) {
        warn $@;
        return 0;
    }

    my $data = decode_json(read_file($fname));
    if (!$data) {
        warn 'Bad JSON';
        return 0;
    }

    my $obj = $class->new($data);
    if (!$obj) {
        warn "$class->new() failed";
        return 0;
    }

    return test_hash($obj, "$class->");
}

ok(test_json('t/json/char.json', 'WoW::Armory::Class::Character'));
ok(test_json('t/json/guild.json', 'WoW::Armory::Class::Guild'));
ok(test_json('t/json/status.json', 'WoW::Armory::Class::RealmStatus'));

1;
