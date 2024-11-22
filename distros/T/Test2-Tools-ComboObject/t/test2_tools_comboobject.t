use Test2::V0 1.302178 -no_srand => 1;
use Test2::Tools::ComboObject;

my $frame;

subtest 'context' => sub {

  sub test_tool1 {
    my $combo = combo;
    $frame = $combo->context->trace->frame;
    $combo->context->release;
    $combo->_done(1);
  }
  test_tool1(); my $ln = __LINE__;

  is(
    $frame,
    [__PACKAGE__, __FILE__, $ln, 'main::test_tool1' ],
    'correct location for function',
  );

  sub test_tool2 {
    my $combo = Test2::Tools::ComboObject->new;
    $frame = $combo->context->trace->frame;
    $combo->context->release;
    $combo->_done(1);
  }
  test_tool2(); $ln = __LINE__;

  is(
    $frame,
    [__PACKAGE__, __FILE__, $ln, 'main::test_tool2' ],
    'correct location for constructor',
  );

  sub test_tool3 {
    my $combo = combo;
    $frame = $combo->context->trace->frame;
    $combo->context->release;
    $combo->_done(1);
  }

  sub test_tool4 {
    Test2::API::context_do(sub {
      test_tool3();
    });
  }

  test_tool4();  $ln = __LINE__;

  is(
    $frame,
    [__PACKAGE__, __FILE__, $ln, 'main::test_tool4' ],
    'tool wrapped in a tool',
  );

};

is(
  intercept(sub {
    my $combo = combo;
    $combo->pass;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field diag => DNE();
      field note => DNE();
      etc;
    };
    end;
  },
  'simple pass',
);

is(
  intercept(sub {
    my $combo = combo 'custom name';
    $combo->pass;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'custom name';
      field diag => DNE();
      field note => DNE();
      etc;
    };
    end;
  },
  'name override',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->fail;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => DNE();
      field note => DNE();
      etc;
    };
    end;
  },
  'simpel fail',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(1);
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field diag => DNE();
      field note => DNE();
      etc;
    };
    end;
  },
  'ok(1)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(0);
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => DNE();
      field note => DNE();
      etc;
    };
    end;
  },
  'ok(0)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => ['Test::ComboTest object had no checks'];
      field note => DNE();
      etc;
    };
    end;
  },
  'no checks',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->pass('note1','note2');
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field note => ['note1','note2'];
      field diag => DNE();
      etc;
    };
    end;
  },
  'pass(note1,note2)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->fail('note1','note2');
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => ['note1','note2'];
      field note => DNE();
      etc;
    };
    end;
  },
  'fail(note1,note2)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(0, 'note1','note2');
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => ['note1','note2'];
      field note => DNE();
      etc;
    };
    end;
  },
  'ok(0,note1,note2)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(1, 'note1','note2');
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field note => ['note1','note2'];
      field diag => DNE();
      etc;
    };
    end;
  },
  'ok(1,note1,note2)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->fail;
    $combo->pass;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'fail,pass',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->pass;
    $combo->fail;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'pass,fail',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(1);
    $combo->ok(0);
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'ok(1),ok(0)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(0);
    $combo->ok(1);
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'ok(0),ok(1)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->ok(0);
    $combo->ok(0);
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'ok(0),ok(0)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->fail;
    $combo->fail;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'fail,fail',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->pass;
    $combo->pass;
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field note => DNE();
      field diag => DNE();
      etc;
    };
    end;
  },
  'pass,pass',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->pass;
    $combo->log("foo","bar");
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => T();
      field name => 'combo object test';
      field note => ["foo","bar"];
      field diag => DNE();
      etc;
    };
    end;
  },
  'pass,log(foo,bar)',
);

is(
  intercept(sub {
    my $combo = combo;
    $combo->fail;
    $combo->log("foo","bar");
    $combo->finish;
  })->squash_info->flatten,
  array {
    item hash {
      field pass => F();
      field name => 'combo object test';
      field diag => ["foo","bar"];
      field note => DNE();
      etc;
    };
    end;
  },
  'fail,log(foo,bar)',
);

done_testing;


