use dtRdr::Logger;
dtRdr::Logger->init(filename =>
  ($ENV{LOG_NOISE} ? 'client/data/' : 'test_inc/') . 'log.conf'
);

1;
# vim:ts=2:sw=2:et:sta
