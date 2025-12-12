extends Control

@onready var user = $Panel/MarginContainer/VBoxContainer/Username
@onready var password = $Panel/MarginContainer/VBoxContainer/Password
@onready var HTTP = $HTTPRequest

@onready var msgPanel = $Panel/MarginContainer/VBoxContainer/MsgPanel
@onready var msgLabel = $Panel/MarginContainer/VBoxContainer/MsgPanel/MarginContainer/Label

func _ready() -> void:
	HTTP.request_completed.connect(on_request_completed)

func _on_LoginButton_button_down() -> void:
	var url = "http://127.0.0.1/GD2PHP/api.php"
	var headers = ["Content-Type: application/json"]
	
	if user.text == "" or password.text == "":
		msgPanel.visible = true
		msgLabel.text = "Please fill in the login form."
		return
	
	var body = JSON.stringify({
		"username": user.text,
		"password": password.text,
		"type": "login"
	})
	
	HTTP.request(url,headers,HTTPClient.METHOD_POST,body)

func on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var json = FileAccess.open("res://cache.json",FileAccess.READ).get_as_text()
	json = JSON.parse_string(json)
	
	msgPanel.visible = true
	if json and json.has("status"):
		
		if json["status"] == "success":
			msgLabel.text = "Login successful: " + json["message"]
			
			var acc = FileAccess.open("user://acc.json",FileAccess.WRITE)
			if acc:
				acc.store_string(JSON.stringify({
					"user": json["user"]["user"],
					"email": json["user"]["email"],
					"id": json["user"]["id"],
					"token": json["user"]["token"]
				}))
				acc.close()
			
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			add_child(timer)
			timer.start()
			timer.timeout.connect(func() -> void:
				get_tree().change_scene_to_file("res://assets/scene/profile.tscn")
			)
		else:
			msgLabel.text = "Login failed: " + json["message"]
	else:
		msgLabel.text = "Login failed: "+body.get_string_from_utf8()
