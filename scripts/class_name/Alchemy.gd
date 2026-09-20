class_name Alchemy

enum Quality { HOT, COLD, DRY, WET }
enum Element { NEUTRAL, FIRE, EARTH, WATER, AIR }

## How a reactant ball's element relates to the peg it hit (design doc §5).
enum Relationship { NEUTRAL, SAME, ADJACENT, OPPOSITE }

const OPPOSITES := {
	Element.FIRE: Element.WATER,
	Element.WATER: Element.FIRE,
	Element.AIR: Element.EARTH,
	Element.EARTH: Element.AIR,
}

## A NEUTRAL peg always resolves NEUTRAL, whatever the ball is: flat baseline,
## no boost and no chain effect either way.
static func relationship(ball_element: Element, peg_element: Element) -> Relationship:
	if peg_element == Element.NEUTRAL:
		return Relationship.NEUTRAL
	if ball_element == peg_element:
		return Relationship.SAME
	if OPPOSITES.get(ball_element) == peg_element:
		return Relationship.OPPOSITE
	return Relationship.ADJACENT

static func color_for_quality(q: Quality) -> Color:
	match q:
		Quality.HOT:	return Color("e8642a")
		Quality.COLD:	return Color("7ec8e8")  # icy blue
		Quality.WET:	return Color("2a5de8")  # deep blue
		Quality.DRY:	return Color("c8a464")  # tan
		_:				return Color.WHITE
