public class HelloHelper {
  String s;
  public HelloHelper() {
    this("Hi!");
  }
  public HelloHelper (String s) {
    this.s = s;
  }
  public void printIt(String f, float i, String[][] st, HelloHelper h) {
    System.out.println(s);
  }
}
