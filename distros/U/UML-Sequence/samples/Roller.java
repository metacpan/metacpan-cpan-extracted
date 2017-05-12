public class Roller {
    public static void main(String[] s) {
        DiePair dice = new DiePair(6, 6);
        int     total;
        boolean doubles;

        dice.roll();
        total   = dice.total();
        doubles = dice.doubles();
        System.out.print("You rolled " + total + " which ");
        if (doubles) {
            System.out.println("was doubles.");
        }
        else {
            System.out.println("was not doubles.");
        }
    }
}
