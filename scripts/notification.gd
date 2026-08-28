# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## notification pop up
class_name Notification
extends Node


## how long will this notification last
@export var expiration_time: float = 5.0


## pop up notification
func pop_up(level: GameInstance.NotificationLevel, notification_message: String):
	$PanelContainer/MarginContainer/message.text = notification_message
	match level:
		GameInstance.NotificationLevel.Fatal:
			$PanelContainer/Background.color = Color("5d4037ff")
			$PanelContainer/Control/Border.color = Color("3e2723ff")
			$PanelContainer/Control2/Border.color = Color("3e2723ff")
		GameInstance.NotificationLevel.Error:
			$PanelContainer/Background.color = Color("e64a19ff")
			$PanelContainer/Control/Border.color = Color("bf360cff")
			$PanelContainer/Control2/Border.color = Color("bf360cff")
		GameInstance.NotificationLevel.Warning:
			$PanelContainer/Background.color = Color("ffa000ff")
			$PanelContainer/Control/Border.color = Color("ff6f00ff")
			$PanelContainer/Control2/Border.color = Color("ff6f00ff")
		GameInstance.NotificationLevel.Log:
			$PanelContainer/Background.color = Color("689f38ff")
			$PanelContainer/Control/Border.color = Color("33691eff")
			$PanelContainer/Control2/Border.color = Color("33691eff")
		GameInstance.NotificationLevel.Verbose:
			$PanelContainer/Background.color = Color("00796bff")
			$PanelContainer/Control/Border.color = Color("004d40ff")
			$PanelContainer/Control2/Border.color = Color("004d40ff")
	
	$AnimationPlayer.play("pop up")
