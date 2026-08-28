# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the confirm sign up panel in UserLogin level
class_name ConfirmSignUpPanel
extends Control


## triggerred when it's processing
signal processing(is_processing: bool)


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


@onready var code_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer2/Code
@onready var confirm: Button = $MarginContainer4/Confirm


## regex for confirmation code
var confirm_code_regex = RegEx.create_from_string("^\\d{6}$")


## username from sign up panel
var username: String


## receive username from sign up panel
func _on_sign_up_panel_wait_for_confirmation(temp_username: String):
	processing.emit(false)
	username = temp_username


## enable confirm button when input is valid
func _on_confirm_sign_up_panel_text_changed(_new_text):
	if code_input.text.is_empty() or confirm_code_regex.search(code_input.text) == null:
		confirm.disabled = true
	else:
		confirm.disabled = false


## cancel confirm sign up
func _on_back_pressed():
	if game_instance.has_user_signal("confirm_sign_up"):
		var error: Error = game_instance.emit_signal("confirm_sign_up", false)
		if error != Error.OK:
			game_instance.notification.emit(game_instance.NotificationLevel.Error, "emit confirm_sign_up signal failed: %d" % error)


## resend confirm sign up code
func _on_resend_pressed():
	processing.emit(true)
	if await _sign_up_resend(username):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Log, 
			"confirmation code resent. please check your email."
			)
	processing.emit(false)


## confirm sign up
func _on_confirm_pressed():
	if game_instance.has_user_signal("confirm_sign_up"):
		processing.emit(true)
		var error: Error = game_instance.emit_signal(
			"confirm_sign_up", 
			await _confirm_sign_up(username, code_input.text)
			)
		if error != Error.OK:
			processing.emit(false)
			game_instance.notification.emit(
				game_instance.NotificationLevel.Error, 
				"emit confirm_sign_up signal failed: %d" % error
				)
	else:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"game instance doesn't have confirm_sign_up signal"
			)


## resend sign up confirmation code
func _sign_up_resend(temp_username: String) -> bool:
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
	
	var request: AWSSDKCognitoIdentityProvider_Model_ResendConfirmationCodeRequest = (
		AWSSDKCognitoIdentityProvider_Model_ResendConfirmationCodeRequest.new()
		)
	request.client_id = game_instance.cognito_client_id
	request.secret_hash = AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
		temp_username,
		game_instance.cognito_client_id, 
		game_instance.cognito_client_secret_key,
		)
	request.username = temp_username
	var response_receive_handler: \
	AWSSDKCognitoIdentityProvider_Model_ResendConfirmationCodeResponseReceivedHandler = (
		cognito_identity_provider_client.resend_confirmation_code(request)
		)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return false
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_ResendConfirmationCodeOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return false
		
	return true


## confirm sign up
func _confirm_sign_up(temp_username: String, code: String) -> bool:
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
	
	var request: AWSSDKCognitoIdentityProvider_Model_ConfirmSignUpRequest = (
		AWSSDKCognitoIdentityProvider_Model_ConfirmSignUpRequest.new()
		)
	request.client_id = game_instance.cognito_client_id
	request.secret_hash = AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
		temp_username,
		game_instance.cognito_client_id, 
		game_instance.cognito_client_secret_key,
		)
	request.username = temp_username
	request.confirmation_code = code
	var response_receive_handler: \
	AWSSDKCognitoIdentityProvider_Model_ConfirmSignUpResponseReceivedHandler = (
		cognito_identity_provider_client.confirm_sign_up(request)
		)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return false
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_ConfirmSignUpOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return false
		
	return true
