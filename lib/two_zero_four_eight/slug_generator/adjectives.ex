defmodule TwoZeroFourEight.SlugGenerator.Adjectives do
  @adjectives ~w(
    welsh bully rush third dewy valid mum balmy close fated
    bad gawky ashen wise main bald smoky risky cocky wroth gold
    local made trim lossy misty before piano dying above lofty
    red mossy fifty harsh agile misty handy small puffy acned
    dodgy white tight fatal weedy rushy icky waxen sooty jolly
    worth unfit numb bushy fine tubed solid away soft snowy tan crisp
    calm red bulky yummy cosy elfin afoot risen lowly tense magic
    dead owing tepid glad sneak ahead gummy silky godly over testy
    focal male funky small dinky usual back jade angry quasi lacy balmy
    bland worn vocal
  )

  def random do
    Enum.random(@adjectives)
  end
end
