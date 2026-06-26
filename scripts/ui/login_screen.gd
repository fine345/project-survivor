extends Control

@onready var status_label: Label = $StatusLabel
@onready var loading_label: Label = $LoadingLabel
@onready var login_button: TextureButton = $LoginButton
@onready var logout_button: Button = $LogoutButton

var _sdk_ready := false
var _checking_login := false

func _ready() -> void:
	status_label.text = ""
	loading_label.visible = false
	_set_font_size(self, 44)

	if Engine.has_singleton("FlowerTapSDK"):
		Tap.logined.connect(_on_logined)
		Tap.login_not.connect(_on_login_not)
		Tap.login_fail.connect(_on_login_fail)
		Tap.anti_pass.connect(_on_anti_pass)
		Tap.anti_age_less.connect(_on_anti_age_less)
		Tap.anti_timeout.connect(_on_anti_timeout)
		Tap.init_ok.connect(_on_init_ok)
		_status("SDK 初始化中...")
	else:
		_status("TapTap SDK 不可用，跳过登录")
		get_tree().create_timer(1.0).timeout.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	logout_button.pressed.connect(_on_logout_pressed)

func _on_init_ok() -> void:
	_sdk_ready = true
	_checking_login = true
	Tap.is_login()

func _on_login_pressed() -> void:
	if not _sdk_ready:
		if Engine.has_singleton("FlowerTapSDK"):
			Tap.reinit()
			_sdk_ready = true
		else:
			_status("TapTap SDK 不可用")
			return
	_checking_login = false
	login_button.visible = false
	loading_label.visible = true
	loading_label.text = "登录中..."
	status_label.text = ""
	Tap.login()

func _on_logined() -> void:
	if _checking_login:
		_checking_login = false
		_show_login_button()
		return
	_status("登录成功，正在验证身份...")
	login_button.visible = false
	logout_button.visible = true
	loading_label.visible = true
	loading_label.text = "身份验证中..."
	Tap.init_tap_anti()
	get_tree().create_timer(1.0).timeout.connect(func(): Tap.quick_anti())

func _on_login_not() -> void:
	if not _sdk_ready:
		return
	if _checking_login:
		_checking_login = false
		_show_login_button()
		return
	_show_login_button()
	_status("登录已取消")

func _on_login_fail() -> void:
	_show_login_button()
	_status("登录失败")

func _on_anti_pass() -> void:
	_status("验证通过")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_anti_age_less() -> void:
	_show_login_button()
	_status("未满年龄限制，无法进入游戏")

func _on_anti_timeout() -> void:
	_show_login_button()
	_status("游戏时间已到期")

func _show_login_button() -> void:
	login_button.visible = true
	logout_button.visible = false
	loading_label.visible = false

func _status(msg: String) -> void:
	status_label.text = msg

func _set_font_size(node: Node, size: int) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_size_override("font_size", size)
	for child in node.get_children():
		_set_font_size(child, size)

func _on_logout_pressed() -> void:
	if Engine.has_singleton("FlowerTapSDK"):
		Tap.login_out()
	_sdk_ready = false
	get_tree().reload_current_scene()
