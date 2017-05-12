
typedef struct entityref entityref_t;
struct entityref {
	unsigned char  c;
	unsigned char *entity;
	unsigned int   length;
	unsigned       children;
	entityref_t   *more;
};

            static entityref_t _e_001[1] = { { 'p', "&", 1, 0, NULL } };
                static entityref_t _e_002[1] = { { 's', "'", 1, 0, NULL } };
            static entityref_t _e_003[1] = { { 'o', NULL, 0, 1, _e_002 } };
        static entityref_t _e_004[2] = { { 'm', NULL, 0, 1, _e_001 }, { 'p', NULL, 0, 1, _e_003 } };
        static entityref_t _e_005[1] = { { 't', ">", 1, 0, NULL } };
        static entityref_t _e_006[1] = { { 't', "<", 1, 0, NULL } };
                static entityref_t _e_007[1] = { { 't', "\"", 1, 0, NULL } };
            static entityref_t _e_008[1] = { { 'o', NULL, 0, 1, _e_007 } };
        static entityref_t _e_009[1] = { { 'u', NULL, 0, 1, _e_008 } };
    static entityref_t _e_010[4] = { { 'a', NULL, 0, 2, _e_004 }, { 'g', NULL, 0, 1, _e_005 }, { 'l', NULL, 0, 1, _e_006 }, { 'q', NULL, 0, 1, _e_009 } };
static entityref_t entities[1] = { { '*', NULL, 0, 4, _e_010 } };
