# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the login panel in UserLogin level
class_name LoginPanel
extends Control


## triggerred when it's processing
signal processing(is_processing: bool)


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable
func _init():
	game_instance = GameInstance.singleton


@onready var username_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer/Username
@onready var password_input: LineEdit = $MarginContainer2/VBoxContainer/HBoxContainer2/Password
@onready var confirm: Button = $MarginContainer4/Confirm


## enable confirm button when input is valid
func _on_login_panel_text_changed(_new_text):
	if username_input.text.is_empty() or password_input.text.is_empty():
		confirm.disabled = true
	else:
		confirm.disabled = false


## login
func _on_confirm_pressed():
	processing.emit(true)
	
	game_instance.auth_result = await _login(username_input.text, password_input.text)
	if game_instance.auth_result == null:
		processing.emit(false)
		return
	
	game_instance.notification.emit(game_instance.NotificationLevel.Log, "login success")
	processing.emit(false)


## autofill and login
func _on_account_updated(username: String, password: String):
	username_input.text = username
	password_input.text = password
	
	processing.emit(true)
	
	game_instance.auth_result = await _login(username_input.text, password_input.text)
	if game_instance.auth_result == null:
		processing.emit(false)
		return
	
	game_instance.notification.emit(game_instance.NotificationLevel.Log, "login success")
	processing.emit(false)


## login
func _login(username: String, password: String) -> \
AWSSDKCognitoIdentityProvider_Model_AuthenticationResultType:
	if (
		game_instance.region.is_empty() 
		or not game_instance.cognito_identity_provider_clients.has(game_instance.region)
	):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Can't find cognito idp client object for region: %s" % game_instance.region
			)
		return null
		
	var cognito_identity_provider_client: CognitoIdentityProviderClient = (
		game_instance.cognito_identity_provider_clients[game_instance.region]
		)
	
	if (cognito_identity_provider_client == null):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Cognito idp client object for region: %s is not initiated" % game_instance.region
			)
		return null
	
	game_instance.srp_helper = SRPHelper.new()
	var srp_a: String = game_instance.srp_helper.compute_srp_a()
	
	var request: AWSSDKCognitoIdentityProvider_Model_InitiateAuthRequest = (
		AWSSDKCognitoIdentityProvider_Model_InitiateAuthRequest.new()
		)
	request.auth_flow = AWSSDKCognitoIdentityProvider_Model_AuthFlowType.USER_SRP_AUTH
	request.auth_parameters = {
		"USERNAME": username,
		"SRP_A": srp_a,
		"SECRET_HASH": AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
			username,
			game_instance.cognito_client_id, 
			game_instance.cognito_client_secret_key,
			)
	}
	request.client_id = game_instance.cognito_client_id
	var response_receive_handler: \
		AWSSDKCognitoIdentityProvider_Model_InitiateAuthResponseReceivedHandler = (
			cognito_identity_provider_client.initiate_auth(request)
			)
	
	if response_receive_handler == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito identity provider client is not init properly."
			)
		return null
	
	var outcome: AWSSDKCognitoIdentityProvider_Model_InitiateAuthOutcome = (
		await response_receive_handler.complete
		)
	
	if !outcome.success or outcome.result == null:
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			outcome.error_message
			)
		return null
		
	if outcome.result.challenge_name == (
		AWSSDKCognitoIdentityProvider_Model_ChallengeNameType.NOT_SET
		):
		return outcome.result.authentication_result
		
	return await _response_auth_challenge(
		username,
		password,
		outcome.result.challenge_name, 
		outcome.result.challenge_parameters, 
		outcome.result.session
		)


## handle auth challenge from login request
static func _response_auth_challenge(
	username: String, 
	password: String,
	challenge_name: 
		AWSSDKCognitoIdentityProvider_Model_ChallengeNameType.
		AWSSDKCognitoIdentityProvider_Model_ChallengeNameType_Enum,
	challenge_parameters: Dictionary[String, String],
	session: String) -> AWSSDKCognitoIdentityProvider_Model_AuthenticationResultType:
	@warning_ignore("shadowed_variable")
	var game_instance: GameInstance = GameInstance.singleton
	
	if (
		game_instance.region.is_empty() 
		or not game_instance.cognito_identity_provider_clients.has(game_instance.region)
	):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Can't find cognito idp client object for region: %s" % game_instance.region
			)
		return null
	
	var cognito_identity_provider_client: CognitoIdentityProviderClient = (
		game_instance.cognito_identity_provider_clients[game_instance.region]
		)
	
	if (cognito_identity_provider_client == null):
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"Cognito idp client object for region: %s is not initiated" % game_instance.region
			)
		return null
		
	if challenge_parameters.has("USER_ID_FOR_SRP"):
		username = challenge_parameters["USER_ID_FOR_SRP"]
	
	match challenge_name:
		AWSSDKCognitoIdentityProvider_Model_ChallengeNameType.PASSWORD_VERIFIER:
			if not challenge_parameters.has_all(["SRP_B", "SALT", "SECRET_BLOCK"]):
				game_instance.notification.emit(
					game_instance.NotificationLevel.Error, 
					"%s is missing in challenge parameters: %s" % [
						", ".join(["SRP_B", "SALT", "SECRET_BLOCK"]), 
						", ".join(challenge_parameters.keys())
						]
					)
				return null
				
			var timestamp: String = AWSSDKCognitoIdentityProvider_SrpHelper.format_timestamp(
				Time.get_unix_time_from_system()
				)
			
			var password_claim_signature: String = (
				game_instance.srp_helper.compute_password_claim_signature(
					challenge_parameters["SECRET_BLOCK"],
					challenge_parameters["SALT"],
					challenge_parameters["SRP_B"],
					timestamp,
					game_instance.cognito_user_pool_id.get_slice("_", 1),
					username,
					password
				)
			)
			
			var request: AWSSDKCognitoIdentityProvider_Model_RespondToAuthChallengeRequest = (
				AWSSDKCognitoIdentityProvider_Model_RespondToAuthChallengeRequest.new()
				)
			request.client_id = game_instance.cognito_client_id
			request.challenge_name = (
				AWSSDKCognitoIdentityProvider_Model_ChallengeNameType.PASSWORD_VERIFIER
				)
			request.session = session
			request.challenge_responses = {
				"PASSWORD_CLAIM_SIGNATURE": password_claim_signature,
				"PASSWORD_CLAIM_SECRET_BLOCK": challenge_parameters["SECRET_BLOCK"],
				"TIMESTAMP": timestamp,
				"USERNAME": username,
				"SECRET_HASH": AWSSDKCognitoIdentityProvider_SecretHashHelper.compute_secret_hash(
					username,
					game_instance.cognito_client_id, 
					game_instance.cognito_client_secret_key,
					)
			}
			var response_receive_handler: \
			AWSSDKCognitoIdentityProvider_Model_RespondToAuthChallengeResponseReceivedHandler = (
				cognito_identity_provider_client.respond_to_auth_challenge(request)
				)
			
			if response_receive_handler == null:
				game_instance.notification.emit(
					game_instance.NotificationLevel.Error, 
					"cognito identity provider client is not init properly."
					)
				return null
	
			var outcome: AWSSDKCognitoIdentityProvider_Model_RespondToAuthChallengeOutcome = (
				await response_receive_handler.complete
				)
	
			if !outcome.success or outcome.result == null:
				game_instance.notification.emit(
					game_instance.NotificationLevel.Error, 
					outcome.error_message)
				return null
		
			if outcome.result.challenge_name == (
				AWSSDKCognitoIdentityProvider_Model_ChallengeNameType.NOT_SET
				):
				return outcome.result.authentication_result
			
			return await _response_auth_challenge(
				username,
				password,
				outcome.result.challenge_name, 
				outcome.result.challenge_parameters, 
				outcome.result.session
				)
		_:
			game_instance.notification.emit(
				GameInstance.NotificationLevel.Error, 
				"unknown challenge: %d" % challenge_name
				)
			return null
