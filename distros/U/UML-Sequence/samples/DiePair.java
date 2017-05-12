public class DiePair {
    private Die     di1;
    private Die     di2;
    private int     value1;
    private int     value2;
    private int     totalPoints;
    private boolean wasItDoubles;

    public DiePair(int sides1, int sides2) {
        this.di1 = new Die(sides1);
        this.di2 = new Die(sides2);
    }

    public void roll() {
        value1 = di1.roll();
        value2 = di2.roll();
        totalPoints = value1 + value2;
        wasItDoubles = (value1 == value2);
    }

    public int total() {
        return totalPoints;
    }

    public boolean doubles() {
        return wasItDoubles;
    }

    public String toString() {
        return "You rolled " + this.value1 + " and " + this.value2;
    }
}
