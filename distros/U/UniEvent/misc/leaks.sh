#!/usr/bin/env bash
# run me from UniEvent root misc/leaks.sh

misc/find_leaks.sh t/tcp/tcp.t
misc/find_leaks.sh t/tcp/connect_timeout.t
