extends Node
class_name DeployQueue

## Holds whatever's queued to fire/place next for one phase. Each item is a
## Resource that knows its own scene (PotionType, BallType, and later
## GadgetType all carry a `scene: PackedScene`) — the queue itself doesn't
## need to know or care what kind of thing it's holding.

var _queued: Array[Resource] = []

func queue_item(item: Resource) -> void:
	_queued.append(item)

func has_next() -> bool:
	return not _queued.is_empty()

## Next item without removing it (null if empty), e.g. for the aim preview.
func peek_next() -> Resource:
	return _queued[0] if not _queued.is_empty() else null

func pop_next() -> Resource:
	return _queued.pop_front()

func remaining() -> int:
	return _queued.size()
