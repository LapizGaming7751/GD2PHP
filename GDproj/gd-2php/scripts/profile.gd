extends Control

@onready var welcome = $Panel/MarginContainer/HBoxContainer/Profile/MarginContainer/VBoxContainer/Title
@onready var email = $Panel/MarginContainer/HBoxContainer/Profile/MarginContainer/VBoxContainer/Email/Info
@onready var dat = FileAccess.open("user://acc.json",FileAccess.READ)
@onready var json = JSON.parse_string(dat.get_as_text()) if dat else null
@onready var HTTP = $HTTPRequest
@onready var emailLine = $Panel/MarginContainer/HBoxContainer/Settings/MarginContainer/VBoxContainer/Edit/MarginContainer/VBoxContainer/Email/Value
@onready var userLine = $Panel/MarginContainer/HBoxContainer/Settings/MarginContainer/VBoxContainer/Edit/MarginContainer/VBoxContainer/User/Value

var deleteCounter = 0
@onready var deleteButton = $Panel/MarginContainer/HBoxContainer/Settings/MarginContainer/VBoxContainer/Delete/MarginContainer2/Delete
@onready var logoutButton = $"Panel/MarginContainer/HBoxContainer/Profile/MarginContainer/VBoxContainer/Log Out"

@onready var msgPanel = $Panel/MarginContainer/HBoxContainer/Profile/MarginContainer/VBoxContainer/MsgPanel
@onready var msg = $Panel/MarginContainer/HBoxContainer/Profile/MarginContainer/VBoxContainer/MsgPanel/MarginContainer/Label

var url = "http://127.0.0.1/GD2PHP/api.php"
var headers = ["Content-Type: application/json"]

func _ready() -> void:
	if json == null or !json.has("user") or !json.has("email") or !json.has("token"):
		welcome.text = "Unauthorized access\ndetected.\nBooting to\nlogin panel."
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		add_child(timer)
		timer.start()
		timer.timeout.connect(func()->void:
			get_tree().change_scene_to_file("res://assets/scene/login.tscn")
			)
		return
	
	welcome.text = "Welcome, "+json['user']
	email.text = json['email']
	emailLine.text = json['email']
	userLine.text = json['user']

func logOut() -> void:
	var timer = Timer.new()
	
	msgPanel.visible = true
	msg.text = "Logging out..."
	clearAcc()

	var body = JSON.stringify({
		"token": json['token'],
		"type": "logout"
	})
	HTTP.request(url,headers,HTTPClient.METHOD_POST,body)
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(func() -> void:
		get_tree().change_scene_to_file("res://assets/scene/login.tscn")
	)
	

func editAccount() -> void:
	var emailValue = emailLine.text
	var userValue = userLine.text

	json['email'] = emailValue
	json['user'] = userValue

	var write_file = FileAccess.open("user://acc.json",FileAccess.WRITE)
	write_file.store_string(JSON.stringify(json))
	write_file.close()

	var request = json.duplicate()
	request['type'] = "edit"
	request['username'] = userValue

	var body = JSON.stringify(request)
	HTTP.request(url,headers,HTTPClient.METHOD_POST,body)
	
	# Update UI elements dynamically
	welcome.text = "Welcome, " + userValue
	email.text = emailValue
	
	msgPanel.visible = true
	msg.text = "Account updated successfully!"
	
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(func() -> void:
		msgPanel.visible = false
	)

func clearAcc() -> void:
	var write_file = FileAccess.open("user://acc.json", FileAccess.WRITE)
	write_file.store_string("")
	write_file.close()

func deleteAccount() -> void:
	var timer = Timer.new()
	deleteCounter += 1
	if deleteCounter < 2:
		deleteButton.text = "Are you sure?"
		timer.wait_time = 2.0
		timer.one_shot = true
		add_child(timer)
		timer.start()
		timer.timeout.connect(func() -> void:
			deleteButton.text = "Delete Account"
			deleteCounter = 0
		)
		return
	
	deleteButton.text = "Deleting account. Goodbye, "+json['user']
	clearAcc()
	
	var body = JSON.stringify({
		"token": json['token'],
		"type": "delete"
	})
	HTTP.request(url,headers,HTTPClient.METHOD_POST,body)
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(func() -> void:
		get_tree().change_scene_to_file("res://assets/scene/login.tscn")
	)
