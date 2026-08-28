# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## pop up notification
class_name NotificationList
extends Control


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


# notification set up

## notification ui scene
@export var notification_scene: PackedScene = preload("res://scenes/notification.tscn")


## pop up notification
func _ready():
	if OS.has_feature("dedicated_server"):
		game_instance.notification.connect(log_notification)
	else:
		game_instance.notification.connect(pop_up_notification)


## store a notification
class NotificationStruct:
	var level: GameInstance.NotificationLevel
	var notification_message: String
	
	func _init(temp_level: GameInstance.NotificationLevel, temp_notification_message: String):
		level = temp_level
		notification_message = temp_notification_message


## pending notifications
var notification_list: Array[NotificationStruct] = []
var is_popping_up_notification: bool = false
@export var notification_pop_up_interval: float = 0.5


## pop up notification in UI
func pop_up_notification(level: GameInstance.NotificationLevel, notification_message: String):
	notification_list.push_back(NotificationStruct.new(level, notification_message))
	
	if notification_scene and notification_scene.can_instantiate():
		if is_popping_up_notification:
			return
		
		is_popping_up_notification = true
		
		while not notification_list.is_empty():
			var notification_struct: NotificationStruct = notification_list.pop_front()
			var notification_ui: Notification = notification_scene.instantiate()
			notification_ui.pop_up(notification_struct.level, notification_struct.notification_message)
			add_child(notification_ui)
			
			await get_tree().create_timer(notification_pop_up_interval).timeout
		
		is_popping_up_notification = false


## log notification to log
func log_notification(level: GameInstance.NotificationLevel, notification_message: String):
	match level:
		GameInstance.NotificationLevel.Fatal:
			push_error(notification_message)
		GameInstance.NotificationLevel.Error:
			push_error(notification_message)
		GameInstance.NotificationLevel.Warning:
			push_warning(notification_message)
		GameInstance.NotificationLevel.Log:
			print(notification_message)
		GameInstance.NotificationLevel.Verbose:
			print_verbose(notification_message)
