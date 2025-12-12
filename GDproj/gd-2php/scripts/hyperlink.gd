extends Button

@export_file("*.tscn") var targetScene : String

func _ready() -> void:
	connect("button_down",onClick)

func onClick() -> void:
	get_tree().change_scene_to_file(targetScene)
