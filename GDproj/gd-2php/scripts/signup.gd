extends Control

@onready var user = $Panel/MarginContainer/VBoxContainer/Username
@onready var email = $Panel/MarginContainer/VBoxContainer/Email
@onready var password = $Panel/MarginContainer/VBoxContainer/Password
@onready var HTTP = $HTTPRequest

@onready var msgPanel = $Panel/MarginContainer/VBoxContainer/MsgPanel
@onready var msgLabel = $Panel/MarginContainer/VBoxContainer/MsgPanel/MarginContainer/Label

func _ready() -> void:
	HTTP.request_completed.connect(on_request_completed)

func _on_SignupButton_button_down() -> void:
	var url = "http://127.0.0.1/GD2PHP/api.php"
	var headers = ["Content-Type: application/json"]
	
	if user.text == null or password.text == null:
		msgPanel.visible = true
		msgLabel.text = "Please fill in the signup form."
		return
	
	var body = JSON.stringify({
		"username": user.text,
		"email": email.text,
		"password": password.text,
		"type": "signup"
	})
	
	HTTP.request(url,headers,HTTPClient.METHOD_POST,body)

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = FileAccess.open("res://cache.json",FileAccess.READ).get_as_text()
	json = JSON.parse_string(json)
	
	msgPanel.visible = true
	if json and json.has("status"):
		
		if json["status"] == "success":
			msgLabel.text = "Signup successful: " + json["message"]
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			add_child(timer)
			timer.start()
			timer.timeout.connect(func() -> void:
				get_tree().change_scene_to_file("res://assets/scene/login.tscn")
			)
		else:
			msgLabel.text = "Signup failed: " + json["message"]
	else:
		msgLabel.text = "Signup failed: "+body.get_string_from_utf8()
