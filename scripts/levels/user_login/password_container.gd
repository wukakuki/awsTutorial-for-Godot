# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## contains Password input, Password_Visibility button. Control password visibility
class_name PasswordContainer
extends Node


## toggle password visibility
func _on_password_visibility_pressed():
	$Password.secret = !$Password_Visibility.button_pressed
