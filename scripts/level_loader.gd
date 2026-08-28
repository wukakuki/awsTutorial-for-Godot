# Copyright (C) Siqi.Wu 2026 - All Rights Reserved
# Written by Siqi.Wu<lion547016@gmail.com>, Apr 2026

## control which level to load
class_name LevelLoader
extends Node


## the default level a dedicated server build will be loaded by default
@export var default_server_level: PackedScene
## the default level a dedicated server build will be loaded by default
@export var default_client_level: PackedScene
var loaded_level: Node


## load default server level for server build and default client level for other build
func _ready():
	if OS.has_feature("dedicated_server"):
		if default_server_level and default_server_level.can_instantiate():
			loaded_level = default_server_level.instantiate()
			add_child(loaded_level)
	else:
		if default_client_level and default_client_level.can_instantiate():
			loaded_level = default_client_level.instantiate()
			add_child(loaded_level)
