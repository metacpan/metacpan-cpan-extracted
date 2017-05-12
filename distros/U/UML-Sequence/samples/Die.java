public class Die {
    private int sides;
    private int value;

    public Die (int sides) {
        this.sides = sides;
    }

    public int roll() {
        double randomNumber = Math.random();

        this.value = (int)(randomNumber * this.sides) + 1;
        return this.value;
    }

}
