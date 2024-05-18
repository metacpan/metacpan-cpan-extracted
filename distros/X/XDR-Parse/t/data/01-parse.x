
const c1 = 1;
const c2 = 0x2;
const c3 = c1;

typedef char tc1;
typedef tc1 *optional_tc1;
typedef string ts1<>;

enum e1 {
  e1_1 = 1,
  e1_2 = 2
};

struct s1 {
   int f1;
   struct {
     int f3;
   } f2;
   union switch (int d) {
     case c1:
       char f1;
     case c2:
       char f2;
   } f3;
   enum {
     f4_1 = 1,
     f4_2 = 2
   } f4;
};

union u1 switch (int d) {
   case el_1:
     opaque f1[c2];
   case el_2:
     string f2<>;
   case 3:
     optional_tc1 f3;
   default:
     s1 f4;
};
