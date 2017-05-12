The sample file is used to test routing on the exim.org mail system.

It is run something like this (from the Test-MTA-Exim4 directory):-
  $ prove  --blib sample/
  sample/exim-org....ok
  All tests successful.

If run in verbose mode the output looks like:-
  $ prove -v --blib sample/
  sample/exim-org....ok 1 - use Test::MTA::Exim4;
  ok 2 - Created exim test object
  ok 3 - config /etc/exim/exim.conf is valid
  ok 4 - Check version number
  ok 5 - Check build number
  ok 6 - Checking for lookup/lsearch capability
  ok 7 - Checking for lookup/cdb capability
  ok 8 - Checking for lookup/mysql capability
  ok 9 - Checking for router/accept capability
  ok 10 - Checking for router/dnslookup capability
  ok 11 - Checking for router/manualroute capability
  ok 12 - Checking for router/redirect capability
  ok 13 - Checking for transport/appendfile capability
  ok 14 - Checking for transport/maildir capability
  ok 15 - Checking for transport/autoreply capability
  ok 16 - Checking for transport/pipe capability
  ok 17 - Checking for transport/smtp capability
  ok 18 - Checking for support_for/ipv6 capability
  ok 19 - Checking for support_for/openssl capability
  ok 20 - Checking for support_for/content_scanning capability
  ok 21 - Can route to postmaster@tahini.csx.cam.ac.uk
  ok 22 - Can route to abuse@tahini.csx.cam.ac.uk
  ok 23 - Can route to postmaster@exim.org
  ok 24 - Can route to abuse@exim.org
  ok 25 - Can route to postmaster@pcre.org
  ok 26 - Can route to abuse@pcre.org
  ok 27 - Can route to postmaster@bugs.exim.org
  ok 28 - Can route to abuse@bugs.exim.org
  ok 29 - Can route to 23@bugs.exim.org
  ok 30 - Undeliverable to 99999999@bugs.exim.org
  ok 31 - Can route to bug23@exim.org
  ok 32 - Undeliverable to bug99999999@exim.org
  ok 33 - Can route to exim-announce@exim.org
  ok 34 - Can route to exim-announce-admin@exim.org
  ok 35 - Can route to exim-announce-bounces@exim.org
  ok 36 - Can route to exim-announce-confirm@exim.org
  ok 37 - Can route to exim-announce-join@exim.org
  ok 38 - Can route to exim-announce-leave@exim.org
  ok 39 - Can route to exim-announce-owner@exim.org
  ok 40 - Can route to exim-announce-request@exim.org
  ok 41 - Can route to exim-announce-subscribe@exim.org
  ok 42 - Can route to exim-announce-unsubscribe@exim.org
  ok 43 - Can route to exim-future@exim.org
  ok 44 - Can route to exim-future-admin@exim.org
  ok 45 - Can route to exim-future-bounces@exim.org
  ok 46 - Can route to exim-future-confirm@exim.org
  ok 47 - Can route to exim-future-join@exim.org
  ok 48 - Can route to exim-future-leave@exim.org
  ok 49 - Can route to exim-future-owner@exim.org
  ok 50 - Can route to exim-future-request@exim.org
  ok 51 - Can route to exim-future-subscribe@exim.org
  ok 52 - Can route to exim-future-unsubscribe@exim.org
  ok 53 - Can route to exim-users@exim.org
  ok 54 - Can route to exim-users-admin@exim.org
  ok 55 - Can route to exim-users-bounces@exim.org
  ok 56 - Can route to exim-users-confirm@exim.org
  ok 57 - Can route to exim-users-join@exim.org
  ok 58 - Can route to exim-users-leave@exim.org
  ok 59 - Can route to exim-users-owner@exim.org
  ok 60 - Can route to exim-users-request@exim.org
  ok 61 - Can route to exim-users-subscribe@exim.org
  ok 62 - Can route to exim-users-unsubscribe@exim.org
  ok 63 - Can route to mailman-admin@exim.org
  ok 64 - Can route to mailman-bounces@exim.org
  ok 65 - Can route to mailman-confirm@exim.org
  ok 66 - Can route to mailman-join@exim.org
  ok 67 - Can route to mailman-leave@exim.org
  ok 68 - Can route to mailman-owner@exim.org
  ok 69 - Can route to mailman-request@exim.org
  ok 70 - Can route to mailman-subscribe@exim.org
  ok 71 - Can route to mailman-unsubscribe@exim.org
  ok 72 - Can route to site-maintainers@exim.org
  ok 73 - Can route to site-maintainers-admin@exim.org
  ok 74 - Can route to site-maintainers-bounces@exim.org
  ok 75 - Can route to site-maintainers-confirm@exim.org
  ok 76 - Can route to site-maintainers-join@exim.org
  ok 77 - Can route to site-maintainers-leave@exim.org
  ok 78 - Can route to site-maintainers-owner@exim.org
  ok 79 - Can route to site-maintainers-request@exim.org
  ok 80 - Can route to site-maintainers-subscribe@exim.org
  ok 81 - Can route to site-maintainers-unsubscribe@exim.org
  ok 82 - Can route to exim-cvs@exim.org
  ok 83 - Can route to exim-cvs-admin@exim.org
  ok 84 - Can route to exim-cvs-bounces@exim.org
  ok 85 - Can route to exim-cvs-confirm@exim.org
  ok 86 - Can route to exim-cvs-join@exim.org
  ok 87 - Can route to exim-cvs-leave@exim.org
  ok 88 - Can route to exim-cvs-owner@exim.org
  ok 89 - Can route to exim-cvs-request@exim.org
  ok 90 - Can route to exim-cvs-subscribe@exim.org
  ok 91 - Can route to exim-cvs-unsubscribe@exim.org
  ok 92 - Can route to exim-maintainers@exim.org
  ok 93 - Can route to exim-maintainers-admin@exim.org
  ok 94 - Can route to exim-maintainers-bounces@exim.org
  ok 95 - Can route to exim-maintainers-confirm@exim.org
  ok 96 - Can route to exim-maintainers-join@exim.org
  ok 97 - Can route to exim-maintainers-leave@exim.org
  ok 98 - Can route to exim-maintainers-owner@exim.org
  ok 99 - Can route to exim-maintainers-request@exim.org
  ok 100 - Can route to exim-maintainers-subscribe@exim.org
  ok 101 - Can route to exim-maintainers-unsubscribe@exim.org
  ok 102 - Can route to exim-users-de@exim.org
  ok 103 - Can route to exim-users-de-admin@exim.org
  ok 104 - Can route to exim-users-de-bounces@exim.org
  ok 105 - Can route to exim-users-de-confirm@exim.org
  ok 106 - Can route to exim-users-de-join@exim.org
  ok 107 - Can route to exim-users-de-leave@exim.org
  ok 108 - Can route to exim-users-de-owner@exim.org
  ok 109 - Can route to exim-users-de-request@exim.org
  ok 110 - Can route to exim-users-de-subscribe@exim.org
  ok 111 - Can route to exim-users-de-unsubscribe@exim.org
  ok 112 - Can route to pcre-dev@exim.org
  ok 113 - Can route to pcre-dev-admin@exim.org
  ok 114 - Can route to pcre-dev-bounces@exim.org
  ok 115 - Can route to pcre-dev-confirm@exim.org
  ok 116 - Can route to pcre-dev-join@exim.org
  ok 117 - Can route to pcre-dev-leave@exim.org
  ok 118 - Can route to pcre-dev-owner@exim.org
  ok 119 - Can route to pcre-dev-request@exim.org
  ok 120 - Can route to pcre-dev-subscribe@exim.org
  ok 121 - Can route to pcre-dev-unsubscribe@exim.org
  ok 122 - Can route to exim-dev@exim.org
  ok 123 - Can route to exim-dev-admin@exim.org
  ok 124 - Can route to exim-dev-bounces@exim.org
  ok 125 - Can route to exim-dev-confirm@exim.org
  ok 126 - Can route to exim-dev-join@exim.org
  ok 127 - Can route to exim-dev-leave@exim.org
  ok 128 - Can route to exim-dev-owner@exim.org
  ok 129 - Can route to exim-dev-request@exim.org
  ok 130 - Can route to exim-dev-subscribe@exim.org
  ok 131 - Can route to exim-dev-unsubscribe@exim.org
  ok 132 - Can route to exim-mirrors@exim.org
  ok 133 - Can route to exim-mirrors-admin@exim.org
  ok 134 - Can route to exim-mirrors-bounces@exim.org
  ok 135 - Can route to exim-mirrors-confirm@exim.org
  ok 136 - Can route to exim-mirrors-join@exim.org
  ok 137 - Can route to exim-mirrors-leave@exim.org
  ok 138 - Can route to exim-mirrors-owner@exim.org
  ok 139 - Can route to exim-mirrors-request@exim.org
  ok 140 - Can route to exim-mirrors-subscribe@exim.org
  ok 141 - Can route to exim-mirrors-unsubscribe@exim.org
  ok 142 - Can route to foundation@exim.org
  ok 143 - Can route to foundation-admin@exim.org
  ok 144 - Can route to foundation-bounces@exim.org
  ok 145 - Can route to foundation-confirm@exim.org
  ok 146 - Can route to foundation-join@exim.org
  ok 147 - Can route to foundation-leave@exim.org
  ok 148 - Can route to foundation-owner@exim.org
  ok 149 - Can route to foundation-request@exim.org
  ok 150 - Can route to foundation-subscribe@exim.org
  ok 151 - Can route to foundation-unsubscribe@exim.org
  ok 152 - Can route to pcre-svn@exim.org
  ok 153 - Can route to pcre-svn-admin@exim.org
  ok 154 - Can route to pcre-svn-bounces@exim.org
  ok 155 - Can route to pcre-svn-confirm@exim.org
  ok 156 - Can route to pcre-svn-join@exim.org
  ok 157 - Can route to pcre-svn-leave@exim.org
  ok 158 - Can route to pcre-svn-owner@exim.org
  ok 159 - Can route to pcre-svn-request@exim.org
  ok 160 - Can route to pcre-svn-subscribe@exim.org
  ok 161 - Can route to pcre-svn-unsubscribe@exim.org
  ok 162 - Can route to mailman@exim.org
  ok 163 - Can route to nm4@exim.org
  1..163
  ok
  All tests successful.
  Files=1, Tests=163, 14 wallclock secs ( 3.18 cusr +  0.98 csys =  4.16 CPU)