class_name Alchemy

enum Quality { HOT, COLD, DRY, WET }
enum Element { NEUTRAL, FIRE, EARTH, WATER, AIR }

static func color_for_quality(q: Quality) -> Color:
	match q:
		Quality.HOT:	return Color("e8642a")
		Quality.COLD:	return Color("7ec8e8")  # icy blue
		Quality.WET:	return Color("2a5de8")  # deep blue
		Quality.DRY:	return Color("c8a464")  # tan
		_:				return Color.WHITE
