# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the sign up panel in UserLogin level
class_name SignUpPanel
extends Control


## triggerred when it's processing
signal processing(is_processing: bool)
## triggerred when it's waiting for confirm
signal wait_for_confirmation(username: String)
## triggerred when sign up completed
signal signed_up(username: String, password: String)


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


@onready var username_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer/Username
@onready var password_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer2/Password
@onready var email_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer3/Email
@onready var confirm: Button = $MarginContainer4/Confirm


## enable confirm button when input is valid
func _on_sign_up_panel_text_changed(_new_text):
	if username_input.text.is_empty() or password_input.text.is_empty():
		confirm.disabled = true
	else:
		confirm.disabled = false


## signed up username
var username: String
## signed up password
var password: String


## sign up
func _on_confirm_pressed():
	processing.emit(true)
	
	var success: bool = await _sign_up(username_input.text, password_input.text, email_input.text)
	processing.emit(false)
	
	if success:
		game_instance.notification.emit(game_instance.NotificationLevel.Log, "sign up success")
		signed_up.emit(username, password)


## sign up and auto login
func _sign_up(temp_username: String, temp_password: String, email: String) -> bool:
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
	
	var request: AWSSDKCognitoIdentityProvider_Model_SignUpRequest = (
		AWSSDKCognitoIdentityProvider_Model_SignUpRequest.new()
		)
	request.client_id = game_instance.cognito_client_id
	request.secret_hash = AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
		temp_username,
		game_instance.cognito_client_id, 
		game_instance.cognito_client_secret_key,
		)
	request.username = temp_username
	request.password = temp_password
	var email_attribute: AWSSDKCognitoIdentityProvider_Model_AttributeType = (
		AWSSDKCognitoIdentityProvider_Model_AttributeType.new()
		)
	email_attribute.name = "email"
	email_attribute.value = email
	request.user_attributes = [email_attribute]
	
	var response_receive_handler: \
	AWSSDKCognitoIdentityProvider_Model_SignUpResponseReceivedHandler = (
		cognito_identity_provider_client.sign_up(request)
		)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return false
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_SignUpOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return false
	
	game_instance.add_user_signal("confirm_sign_up", [
		{ "name": "confirmed", "type": TYPE_BOOL }
	])
	
	wait_for_confirmation.emit(temp_username)
	
	var confirmed: bool = await Signal(game_instance, "confirm_sign_up")
	
	game_instance.remove_user_signal("confirm_sign_up")
	
	if not confirmed:
		return false
	
	username = temp_username
	password = temp_password
	
	return true
