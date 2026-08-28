# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## control throbber spin
class_name Throbber
extends Control


## rotation speed of the throbber
@export var rotation_speed: float = 5.0


## rotate the throbber
func _process(delta) -> void:
	rotation += rotation_speed * delta
