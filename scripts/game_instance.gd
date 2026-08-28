# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## the game instance that represent the game. this script should be attach to the root node of scene tree.
class_name GameInstance
extends Node


## game instance singleton. provide access to game instance
static var singleton: GameInstance = null


## initiate game instance singleton
func _init():
	if singleton != null:
		notification.emit(NotificationLevel.Warning, "there is already another game instance initialized, overiding singleton.")
		
	singleton = self


# in game notification. provide debug info to pop up in game and notify player what's wrong

## notification level
enum NotificationLevel {
	Fatal,
	Error,
	Warning,
	Log,
	Verbose,
}
## triggered when there is a notification from code
@warning_ignore("unused_signal")
signal notification(level: NotificationLevel, notification_message: String)


# aws

## aws region
@export var region: String


# cognito

## cognito user pool id
@export var cognito_user_pool_id: String
## cognito identity pool id
@export var cognito_identity_pool_id: String
## cognito client id
@export var cognito_client_id: String
## cognito client secret key
@export var cognito_client_secret_key: String


## srp helper object for srp login
var srp_helper: SRPHelper
## region to cognito idp client dictionary
var cognito_identity_provider_clients: Dictionary[String, CognitoIdentityProviderClient] = {
	"us-east-1": null,
	"us-east-2": null,
	"us-west-1": null,
	"us-west-2": null,
	"af-south-1": null,
	"ap-east-1": null,
	"ap-south-2": null,
	"ap-southeast-3": null,
	"ap-southeast-5": null,
	"ap-southeast-4": null,
	"ap-south-1": null,
	"ap-southeast-6": null,
	"ap-northeast-3": null,
	"ap-northeast-2": null,
	"ap-southeast-1": null,
	"ap-southeast-2": null,
	"ap-east-2": null,
	"ap-southeast-7": null,
	"ap-northeast-1": null,
	"ca-central-1": null,
	"ca-west-1": null,
	"eu-central-1": null,
	"eu-west-1": null,
	"eu-west-2": null,
	"eu-south-1": null,
	"eu-west-3": null,
	"eu-south-2": null,
	"eu-north-1": null,
	"eu-central-2": null,
	"il-central-1": null,
	"mx-central-1": null,
	"me-south-1": null,
	"me-central-1": null,
	"sa-east-1": null,
}
## auth result. contains access, id, refresh tokens and expiration (when the tokens expire)
var auth_result: AWSSDKCognitoIdentityProvider_Model_AuthenticationResultType = null
## logged in user
var username: String


static func get_aws_client_configuration(temp_region: String) -> AWSSDKCore_Client_ClientConfiguration:
	var client_configuration: AWSSDKCore_Client_ClientConfiguration = AWSSDKCore_Client_ClientConfiguration.new()
	client_configuration.region = temp_region
	client_configuration.scheme = AWSSDKCore_Http_Schema.HTTPS
	client_configuration.disable_imds = true
	client_configuration.disable_imds_v1 = true
	if OS.has_feature("macos"):
		client_configuration.ca_file = "/etc/ssl/cert.pem"
	elif OS.has_feature("android"):
		client_configuration.ca_path = "/system/etc/security/cacerts"
	
	return client_configuration
