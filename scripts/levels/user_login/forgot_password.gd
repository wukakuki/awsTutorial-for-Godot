# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the forgot password panel in UserLogin level
class_name ForgotPasswordPanel
extends Control


## triggerred when it's processing
signal processing(is_processing: bool)
## triggerred when it's waiting for confirm
signal wait_for_confirmation(username: String)
## triggerred when forgot password completed
signal forgot_password(username: String, password: String)


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


@onready var username_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer/Username
@onready var confirm: Button = $MarginContainer4/Confirm


## enable confirm button when input is valid
func _on_forgot_password_panel_text_changed(_new_text):
	if username_input.text.is_empty():
		confirm.disabled = true
	else:
		confirm.disabled = false


## forgot password username
var username: String
## forgot password password
var password: String


## forgot password
func _on_confirm_pressed():
	processing.emit(true)
	
	var success: bool = await _forgot_password(username_input.text)
	processing.emit(false)
	
	if success:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Log, 
			"reset password success"
			)
		forgot_password.emit(username, password)


## forgot password
func _forgot_password(temp_username: String) -> bool:
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
		
	game_instance.add_user_signal("confirm_forgot_password", [
		{ "name": "password", "type": TYPE_STRING},
	])
	
	wait_for_confirmation.emit(temp_username)
	
	var temp_password: String = await Signal(game_instance, "confirm_forgot_password")
	
	game_instance.remove_user_signal("confirm_forgot_password")
	
	if temp_password.is_empty():
		return false
	
	username = temp_username
	password = temp_password
	
	return true
