# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the confirm forgot password panel in UserLogin level
class_name ConfirmForgotPasswordPanel
extends Control


## triggerred when it's processing
signal processing(is_processing: bool)


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


@onready var code_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer2/Code
@onready var password_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer3/Password
@onready var confirm: Button = $MarginContainer4/Confirm


## regex for confirmation code
var confirm_code_regex = RegEx.create_from_string("^\\d{6}$")


## username from sign up panel
var username: String


## receive username from forgot password panel
func _on_forgot_password_panel_wait_for_confirmation(temp_username: String):
	processing.emit(false)
	username = temp_username


## enable confirm button when input is valid
func _on_confirm_forgot_password_panel_text_changed(_new_text):
	if code_input.text.is_empty() or confirm_code_regex.search(code_input.text) == null or password_input.text.is_empty():
		confirm.disabled = true
	else:
		confirm.disabled = false


## cancel confirm forgot password
func _on_back_pressed():
	if game_instance.has_user_signal("confirm_forgot_password"):
		var error: Error = game_instance.emit_signal("confirm_forgot_password", "")
		if error != Error.OK:
			game_instance.notification.emit(game_instance.NotificationLevel.Error, "emit confirm_forgot_password signal failed: %d" % error)


## resend confirm forgot password code
func _on_resend_pressed():
	processing.emit(true)
	if await _forgot_password_resend(username):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Log, 
			"confirmation code resent. please check your email."
			)
	processing.emit(false)


## confirm forgot password
func _on_confirm_pressed():
	if game_instance.has_user_signal("confirm_forgot_password"):
		processing.emit(true)
		var error: Error = game_instance.emit_signal(
			"confirm_forgot_password", 
			password_input.text if await _confirm_forgot_password(
				username, 
				code_input.text, 
				password_input.text
				) 
			else ""
			)
		if error != Error.OK:
			processing.emit(false)
			game_instance.notification.emit(
				game_instance.NotificationLevel.Error, 
				"emit confirm_forgot_password signal failed: %d" % error
				)
	else:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"game instance doesn't have confirm_sign_up signal"
			)


## resend forgot password confirmation code
func _forgot_password_resend(temp_username: String) -> bool:
	if (
		game_instance.region.is_empty() 
		or not game_instance.cognito_identity_provider_clients.has(game_instance.region)
	):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Can't find cognito idp client object for region: %s" % game_instance.region
			)
		return false
		
	var cognito_identity_provider_client: CognitoIdentityProviderClient = (
		game_instance.cognito_identity_provider_clients[game_instance.region]
		)
	
	if (cognito_identity_provider_client == null):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Cognito idp client object for region: %s is not initiated" % game_instance.region
			)
		return false
	
	var request: AWSSDKCognitoIdentityProvider_Model_ForgotPasswordRequest = (
		AWSSDKCognitoIdentityProvider_Model_ForgotPasswordRequest.new()
		)
	request.client_id = game_instance.cognito_client_id
	request.secret_hash = AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
		temp_username,
		game_instance.cognito_client_id, 
		game_instance.cognito_client_secret_key,
		)
	request.username = temp_username
	
	var response_receive_handler: \
	AWSSDKCognitoIdentityProvider_Model_ForgotPasswordResponseReceivedHandler = (
		cognito_identity_provider_client.forgot_password(request)
		)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return false
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_ForgotPasswordOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return false
		
	return true


## confirm forgot password
func _confirm_forgot_password(temp_username: String, code: String, password: String) -> bool:
	if (
		game_instance.region.is_empty() 
		or not game_instance.cognito_identity_provider_clients.has(game_instance.region)
	):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Can't find cognito idp client object for region: %s" % game_instance.region
			)
		return false
		
	var cognito_identity_provider_client: CognitoIdentityProviderClient = (
		game_instance.cognito_identity_provider_clients[game_instance.region]
		)
	
	if (cognito_identity_provider_client == null):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Cognito idp client object for region: %s is not initiated" % game_instance.region
			)
		return false
	
	var request: AWSSDKCognitoIdentityProvider_Model_ConfirmForgotPasswordRequest = (
		AWSSDKCognitoIdentityProvider_Model_ConfirmForgotPasswordRequest.new()
		)
	request.client_id = game_instance.cognito_client_id
	request.secret_hash = AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
		temp_username,
		game_instance.cognito_client_id, 
		game_instance.cognito_client_secret_key,
		)
	request.username = temp_username
	request.confirmation_code = code
	request.password = password
	var response_receive_handler: \
	AWSSDKCognitoIdentityProvider_Model_ConfirmForgotPasswordResponseReceivedHandler = (
		cognito_identity_provider_client.confirm_forgot_password(request)
		)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return false
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_ConfirmForgotPasswordOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return false
		
	return true
