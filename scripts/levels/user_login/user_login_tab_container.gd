# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## control which tab should be shown
class_name UserLoginTabContainer
extends TabContainer


## switch to forgot password pannel
func _on_forgot_password_pressed():
	current_tab = 3


## switch to sign up pannel
func _on_sign_up_pressed():
	current_tab = 1


## switch to login pannel
func _on_login_pressed():
	current_tab = 0


## switch to sign up pannel
func _on_confirm_sign_up_back_pressed():
	current_tab = 1


## switch to forgot password pannel
func _on_confirm_forgot_password_back_pressed():
	current_tab = 3


## switch to confirm sign up pannel
func _on_sign_up_panel_wait_for_confirmation(_username):
	current_tab = 2


## switch to confirm forgot password pannel
func _on_forgot_password_wait_for_confirmation(_username):
	current_tab = 4


## switch to login pannel
func _on_account_updated(_username, _password):
	current_tab = 0
