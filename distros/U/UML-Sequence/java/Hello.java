public class Hello {
  public static void main(String[] args) {
    String[][] tmp = new String[4][2];
    HelloHelper hi = null;
    if (args.length == 0) {
      hi = new HelloHelper();
    }
    else {
      // System.out.println("wrong number of args");
      hi = new HelloHelper(args[0]);
    }
    hi.printIt("happy", (float)2.3, tmp, hi);
  }
}
