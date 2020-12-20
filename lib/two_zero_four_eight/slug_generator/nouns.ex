defmodule TwoZeroFourEight.SlugGenerator.Nouns do
  @nouns ~w(
    wine hole whiff pair piggy route guilt floor fryer stern riot
    index music brake drill tale gleam beet hoops brush balm golf
    cyan tonic toll joist buyer great needy crud glaze rear wire nap
    mouse paw mini mast take leap quota lapel crux shirt kick then fit
    fraud vodka host patch oat crush audio awl unity daily lob dunce
    biker inn asset grail punt tad zoo march lair zebra spout lack poke
    zone boon mylar pane arrow clan robot rates query juke grove hunch
    pop floor rise purge putt udder moped clock six grate arena bind chirp
    trot tar irony
  )

  def random do
    Enum.random(@nouns)
  end
end
