# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the user login level which log player in the game
class_name UserLogin
extends Control


## used to save singleton of the Main scene
var game_instance: GameInstance = null


## initiate the game instance variable, cognito user pool client, identity pool client
func _init():
	game_instance = GameInstance.singleton
	
	if game_instance.region.is_empty():
		game_instance.notification.emit(
			game_instance.NotificationLevel.Error, 
			"cognito region is empty. "
			)
		return
		
	for region in game_instance.cognito_identity_provider_clients:
		var client_configuration: AWSSDKCore_Client_ClientConfiguration = (
			GameInstance.get_aws_client_configuration(region)
			)
			
		game_instance.cognito_identity_provider_clients[region] = (
			CognitoIdentityProviderClient.new(null, client_configuration)
			)
	
#	just in case if we missed the region
	if not game_instance.cognito_identity_provider_clients.has(game_instance.region):
		var client_configuration: AWSSDKCore_Client_ClientConfiguration = (
			GameInstance.get_aws_client_configuration(game_instance.region)
			)
			
		game_instance.cognito_identity_provider_clients[game_instance.region] = (
			CognitoIdentityProviderClient.new(null, client_configuration)
			)


var is_subpanel_processing: bool = false


## a sub panel is processing
func _on_processing(temp_is_processing: bool):
	is_subpanel_processing = temp_is_processing
	if temp_is_processing:
		$AnimationPlayer.play("processing")
	else:
		$AnimationPlayer.play_backwards("processing")


## control mouse filter with blur modulate
@export var blur_modulate: Color = Color.TRANSPARENT:
	set(value):
		blur_modulate = value
		$Blur.modulate = value
		mouse_filter = Control.MOUSE_FILTER_IGNORE if (value.a < 0.01) else Control.MOUSE_FILTER_STOP
