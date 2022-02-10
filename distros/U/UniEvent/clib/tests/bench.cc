#include "lib/test.h"
#include <catch2/benchmark/catch_benchmark.hpp>

TEST_PREFIX("bench: ", "[.]");

TEST("create handle") {
	LoopSP loop = new Loop();
    BENCHMARK("tcp") {
    	TcpSP h = new Tcp();
    };
    BENCHMARK("timer") {
    	TimerSP h = new Timer();
    };
}
